import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/topic_card.dart';
import '../services/question_service.dart'; // Import Service

class DenemeTakvimEkrani extends StatefulWidget {
  const DenemeTakvimEkrani({super.key});

  @override
  State<DenemeTakvimEkrani> createState() => _DenemeTakvimEkraniState();
}

class _DenemeTakvimEkraniState extends State<DenemeTakvimEkrani> {
  final _service = QuestionService(); // Service Instance
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Events Map: DateTime -> List of Events
  // Events structure: { 'type': 'mistake'|'trial', 'title': String, 'subtitle': String, 'color': Color, 'data': dynamic, 'id': String? }
  Map<DateTime, List<dynamic>> _events = {};

  String _filterMode = 'ALL'; // 'ALL', 'MISTAKES', 'TRIALS'
  bool _usePremiumUI = true; // Toggle for premium look

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchData();
  }

  Future<void> _fetchData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app');

    // 1. Fetch Mistakes
    final mistakesRef = db.ref("users/${user.uid}/mistakes");
    // 2. Fetch Trials
    final trialsRef = db.ref("users/${user.uid}/trials");

    Map<DateTime, List<dynamic>> newEvents = {};

    // Helper to add events
    void addEvent(DateTime date, Map<String, dynamic> event) {
      DateTime dayKey = DateTime.utc(date.year, date.month, date.day);
      if (newEvents[dayKey] == null) newEvents[dayKey] = [];
      newEvents[dayKey]!.add(event);
    }

    try {
      // Process Mistakes
      final mistakesSnapshot = await mistakesRef.get();
      if (mistakesSnapshot.exists && mistakesSnapshot.value != null) {
        final data = mistakesSnapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          // Normalize completed dates to YYYYMMDD for easier comparison
          Set<String> completedDayKeys = {};
          if (value['tamamlananTekrarlar'] != null) {
            List<dynamic> cDates = value['tamamlananTekrarlar'];
            for (var dStr in cDates) {
              DateTime? dt = DateTime.tryParse(dStr.toString());
              if (dt != null) {
                // Formatting as yyyy-MM-dd
                completedDayKeys.add(DateFormat('yyyy-MM-dd').format(dt));
              }
            }
          }

          // Check planned repeats
          if (value['planlananTekrarlar'] != null) {
            List<dynamic> dates = value['planlananTekrarlar'];
            for (var dStr in dates) {
              DateTime? date = DateTime.tryParse(dStr);
              if (date != null) {
                String dayKey = DateFormat('yyyy-MM-dd').format(date);
                // If this day is already in completed list, SKIP IT.
                if (completedDayKeys.contains(dayKey)) continue;

                addEvent(date, {
                  'type': 'mistake',
                  'title': "Tekrar: ${value['ders']}",
                  'subtitle': "${value['konu']} - ${value['notlar'] ?? ''}",
                  'color': AppTheme.roseColor,
                  'id': key,
                  'isDone': false,
                  'date': date,
                  'imageUrl': value['imageUrl'],
                  'full_notes': value['notlar'],
                  'ders': value['ders'],
                  'konu': value['konu']
                });
              }
            }
          }

          // Check completed repeats
          if (value['tamamlananTekrarlar'] != null) {
            List<dynamic> dates = value['tamamlananTekrarlar'];
            for (var dStr in dates) {
              DateTime? date = DateTime.tryParse(dStr);
              if (date != null) {
                addEvent(date, {
                  'type': 'mistake_done',
                  'title': "Tamamlandı: ${value['ders']}",
                  'subtitle': "${value['konu']}",
                  'color': Colors.greenAccent,
                  'id': key,
                  'isDone': true,
                  'date': date,
                  'imageUrl': value['imageUrl'],
                  'full_notes': value['notlar'],
                  'ders': value['ders'],
                  'konu': value['konu']
                });
              }
            }
          }
        });
      }

      // Process Trials
      final trialsSnapshot = await trialsRef.get();
      if (trialsSnapshot.exists && trialsSnapshot.value != null) {
        // Trials are stored as a List usually based on the logic in TrialService,
        // but let's handle Map or List just in case.
        final rawData = trialsSnapshot.value;
        List<dynamic> trialList = [];
        if (rawData is List) {
          trialList = rawData;
        } else if (rawData is Map) {
          trialList = rawData.values.toList();
        }

        for (var t in trialList) {
          if (t == null) continue;
          if (t['date'] != null) {
            DateTime? date = DateTime.tryParse(t['date']);
            if (date != null) {
              addEvent(date, {
                'type': 'trial',
                'title': "${t['type']} Denemesi",
                'subtitle': "${t['area']} - ${t['net']} Net",
                'color': AppTheme.primaryColor,
                'data': t
              });
            }
          }
        }
      }

      if (mounted) setState(() => _events = newEvents);
    } catch (e) {
      debugPrint("Error fetching calendar data: $e");
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    List<dynamic> all =
        _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
    if (_filterMode == 'ALL') return all;
    if (_filterMode == 'MISTAKES')
      return all
          .where((e) => e['type'].toString().contains('mistake'))
          .toList();
    if (_filterMode == 'TRIALS')
      return all.where((e) => e['type'] == 'trial').toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          centerTitle: true,
          title: Text("Deneme & Tekrar",
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: -0.5)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            // Background matches other screens
            AppTheme.meshBackground(),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Filter Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFilterButton("Tümü", "ALL", Colors.white),
                          const SizedBox(width: 8),
                          _buildFilterButton(
                              "Hatalar", "MISTAKES", AppTheme.roseColor),
                          const SizedBox(width: 8),
                          _buildFilterButton(
                              "Denemeler", "TRIALS", AppTheme.primaryColor),
                        ],
                      ),
                    ),
                  ),

                  // Premium Toggle
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _usePremiumUI
                                ? "PREMIUM GÖRÜNÜM ✨"
                                : "STANDART GÖRÜNÜM",
                            style: GoogleFonts.outfit(
                              color: _usePremiumUI
                                  ? AppTheme.primaryColor
                                  : Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: _usePremiumUI,
                              onChanged: (v) =>
                                  setState(() => _usePremiumUI = v),
                              activeThumbColor: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Calendar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        radius: 32,
                        opacity: 0.05,
                        borderColor: Colors.white.withOpacity(0.1),
                        child: TableCalendar(
                          locale: 'tr_TR',
                          rowHeight: 58, // Matches Konu Takvimi compact view
                          firstDay: DateTime.utc(2023, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          availableGestures: AvailableGestures.horizontalSwipe,
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            leftChevronIcon: const Icon(Icons.chevron_left,
                                color: Colors.white70),
                            rightChevronIcon: const Icon(Icons.chevron_right,
                                color: Colors.white70),
                          ),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            defaultTextStyle: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            weekendTextStyle: GoogleFonts.inter(
                                color: AppTheme.roseColor,
                                fontWeight: FontWeight.bold),
                            markersAlignment: Alignment.bottomCenter,
                            markersMaxCount: 4,
                            markerMargin:
                                const EdgeInsets.symmetric(horizontal: 1.0),
                          ),
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) =>
                              _focusedDay = focusedDay,
                          eventLoader: _getEventsForDay,
                          calendarBuilders: CalendarBuilders(
                            // 1. Selected Builder
                            selectedBuilder: (context, date, events) {
                              return Container(
                                // Shift UP to fix overlap - Exact match from KonuTakvim
                                margin: const EdgeInsets.only(
                                    bottom: 21.0,
                                    left: 6.0,
                                    right: 6.0,
                                    top: 4.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(
                                        14), // Rounds square
                                    boxShadow: [
                                      BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2)
                                    ]),
                                child: Text(date.day.toString(),
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              );
                            },
                            // 2. Today Builder
                            todayBuilder: (context, date, events) {
                              return Container(
                                // Shift UP to fix overlap - Exact match from KonuTakvim
                                margin: const EdgeInsets.only(
                                    bottom: 21.0,
                                    left: 6.0,
                                    right: 6.0,
                                    top: 4.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.5))),
                                child: Text(date.day.toString(),
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              );
                            },
                            // Marker Builder matches perfectly
                            singleMarkerBuilder: (context, date, event) {
                              final map = event as Map<String, dynamic>;
                              return Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: map['color'] ?? Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                          color: (map['color'] as Color)
                                              .withOpacity(0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1)
                                    ]),
                                width: 6.0,
                                height: 6.0,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1.5),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: const SizedBox(height: 10)),

                  // 3. Content Title
                  if (_selectedDay != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                                DateFormat('d MMMM', 'tr_TR')
                                    .format(_selectedDay!),
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text(
                                DateFormat('EEEE', 'tr_TR')
                                    .format(_selectedDay!),
                                style: GoogleFonts.inter(
                                    color: Colors.white54, fontSize: 14)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                  "${_getEventsForDay(_selectedDay!).length} Etkinlik",
                                  style: GoogleFonts.inter(
                                      color: Colors.white, fontSize: 12)),
                            )
                          ],
                        ),
                      ),
                    ),

                  // 4. Events List (SliverList)
                  if (_selectedDay == null)
                    SliverFillRemaining(
                      child: Center(
                          child: Text("Bir gün seçiniz",
                              style: GoogleFonts.inter(color: Colors.white54))),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final event =
                                _getEventsForDay(_selectedDay!)[index];
                            return _usePremiumUI
                                ? _buildPremiumEventCard(event)
                                : _buildEventCard(event);
                          },
                          childCount: _getEventsForDay(_selectedDay!).length,
                        ),
                      ),
                    ),

                  // Extra padding at bottom
                  SliverToBoxAdapter(child: const SizedBox(height: 50)),
                ],
              ),
            )
          ],
        ));
  }

  Widget _buildFilterButton(String text, String mode, Color activeColor) {
    bool isSelected = _filterMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _filterMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1))),
        child: Text(text,
            style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      ),
    );
  }

  // Function to show detailed question info
  Future<void> _showQuestionDetails(Map<String, dynamic> event) async {
    final String? qId = event['id'];
    final DateTime? targetDate = event['date'];
    final String? imageUrl = event['imageUrl'];
    final String? notes = event['full_notes'];
    final String lesson = event['ders'] ?? '';
    final String subject = event['konu'] ?? '';
    final bool isDone = event['isDone'] ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C).withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Section
              if (imageUrl != null && imageUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: Image.network(imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                              height: 150,
                              color: Colors.white10,
                              child: const Icon(Icons.broken_image,
                                  color: Colors.white54))),
                    ),
                  ),
                ),
              if (imageUrl != null && imageUrl.isNotEmpty)
                const SizedBox(height: 16),

              // 2. Info Section
              Text(lesson,
                  style: GoogleFonts.outfit(
                      color: AppTheme.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subject,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),

              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Notlar:",
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(notes,
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 3. Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text("Kapat",
                        style: GoogleFonts.inter(color: Colors.white54)),
                  ),
                  if (!isDone && qId != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);

                        // Call Service
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await _service.markReviewDone(user.uid, qId,
                              targetDate: targetDate);
                          await _fetchData();
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  "Tekrar tamamlandı! Harika gidiyorsun 🚀"),
                              backgroundColor: Colors.green,
                            ));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 20),
                      label: Text("Tamamla",
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    )
                  ] else if (isDone) ...[
                    const SizedBox(width: 8),
                    // Optional: Add Undo button here later if needed
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.3))),
                      child: Row(
                        children: [
                          const Icon(Icons.check,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text("Tamamlandı",
                              style: GoogleFonts.inter(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    )
                  ]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumEventCard(Map<String, dynamic> event) {
    // Collect Stats
    List<String> stats = [];
    if (event['type'] == 'trial') {
      final t = event['data'];
      if (t != null) {
        if (t['net'] != null) stats.add("${t['net']} Net");
        if (t['area'] != null) stats.add(t['area']);
      }
    } else {
      if (event['isDone'] == true) stats.add("Tamamlandı");
      if (event['date'] != null) {
        stats.add(DateFormat('HH:mm').format(event['date']));
      }
    }

    Color color = event['color'] ?? AppTheme.primaryColor;
    IconData icon = event['type'] == 'trial'
        ? Icons.insights_rounded
        : (event['isDone']
            ? Icons.check_circle_outline
            : Icons.refresh_rounded);

    return TopicCard(
      title: event['title'] ?? '',
      subtitle: event['subtitle'] ?? '',
      type: event['type'] == 'trial'
          ? TopicCardType.study
          : TopicCardType.question,
      stats: stats,
      customColor: color,
      customIcon: icon,
      onTap: () {
        if (event['type'] == 'mistake' || event['type'] == 'mistake_done') {
          _showQuestionDetails(event);
        }
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    Color color = event['color'];
    IconData icon = event['type'] == 'trial'
        ? Icons.insights_rounded
        : (event['isDone']
            ? Icons.check_circle_outline
            : Icons.refresh_rounded);

    return GestureDetector(
      onTap: () {
        // Show details for both mistake types
        if (event['type'] == 'mistake' || event['type'] == 'mistake_done') {
          _showQuestionDetails(event);
        }
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        radius: 20,
        opacity: 0.08,
        borderColor: color.withValues(alpha: 0.2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['title'],
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(event['subtitle'],
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            if (event['type'] == 'mistake' || event['type'] == 'mistake_done')
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white24, size: 16)
          ],
        ),
      ),
    );
  }
}
