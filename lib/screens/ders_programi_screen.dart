import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class DersProgramiEkrani extends StatefulWidget {
  const DersProgramiEkrani({super.key});

  @override
  State<DersProgramiEkrani> createState() => _DersProgramiEkraniState();
}

class _DersProgramiEkraniState extends State<DersProgramiEkrani> {
  final List<String> _gunler = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];

  // Map<DayName, List<LessonMap>>
  Map<String, List<Map<String, dynamic>>> _tumDersler = {};
  bool _isLoading = true;

  final List<Color> _genisRenkPaleti = [
    const Color(0xFFEF5350), // Red
    const Color(0xFFAB47BC), // Purple
    const Color(0xFF5C6BC0), // Indigo
    const Color(0xFF42A5F5), // Blue
    const Color(0xFF26A69A), // Teal
    const Color(0xFF66BB6A), // Green
    const Color(0xFFFFCA28), // Amber
    const Color(0xFFFFA726), // Orange
    const Color(0xFF8D6E63), // Brown
    const Color(0xFF78909C), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _verileriCek();
  }

  void _verileriCek() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("users/${user.uid}/DersProgrami");

    ref.onValue.listen((event) {
      if (!mounted) return;

      Map<String, List<Map<String, dynamic>>> yeniData = {};
      for (var g in _gunler) {
        yeniData[g] = [];
      }

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((dayKey, dayVal) {
          if (dayVal is Map) {
            List<Map<String, dynamic>> dayLessons = [];
            dayVal.forEach((lessonKey, lessonVal) {
              dayLessons.add({
                'key': lessonKey,
                'day': dayKey,
                'ders': lessonVal['ders'],
                'saat': lessonVal['saat'],
                'renk': lessonVal['renk'] ?? 0xFF42A5F5
              });
            });
            // Sort by time
            dayLessons.sort((a, b) => a['saat'].compareTo(b['saat']));
            yeniData[dayKey] = dayLessons;
          }
        });
      }

      setState(() {
        _tumDersler = yeniData;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          AppTheme.meshBackground(),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(8),
                        radius: 12,
                        opacity: 0.1,
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Haftalık Programım",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Add Button
                      GestureDetector(
                        onTap: () => _dersEkleDuzenleDialog(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppTheme.secondaryColor,
                                AppTheme.primaryColor
                              ]),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 4))
                              ]),
                          child: Row(
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text("Ekle",
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                // Weekly Scroll View
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 40),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _gunler
                                .map((day) => Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: _buildDayColumn(day),
                                    ))
                                .toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(String day) {
    List<Map<String, dynamic>> lessons = _tumDersler[day] ?? [];
    // Identify today
    bool isToday = _gunler[DateTime.now().weekday - 1] == day;

    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 20,
      opacity: isToday ? 0.15 : 0.05,
      borderColor: isToday
          ? AppTheme.secondaryColor.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.1),
      child: Container(
        width: 160,
        height: 500, // Fixed height for alignment
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Day Header
            Text(day,
                style: GoogleFonts.outfit(
                    color: isToday ? AppTheme.secondaryColor : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 40,
              decoration: BoxDecoration(
                  color: isToday
                      ? AppTheme.secondaryColor
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),

            // Lessons List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: lessons.length + 1, // +1 for Add Button
                itemBuilder: (context, index) {
                  if (index == lessons.length) {
                    return GestureDetector(
                      onTap: () => _dersEkleDuzenleDialog(initialDay: day),
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white54, size: 20),
                      ),
                    );
                  }

                  var lesson = lessons[index];
                  String time = lesson['saat'].toString().split(' - ')[0];

                  return GestureDetector(
                    onTap: () => _dersEkleDuzenleDialog(mevcutDers: lesson),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Color(lesson['renk'])
                              .withValues(alpha: 0.25), // Reduced opacity
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  Color(lesson['renk']).withValues(alpha: 0.4),
                              width: 1), // Added subtle border
                          boxShadow: [
                            BoxShadow(
                                color: Color(lesson['renk'])
                                    .withValues(alpha: 0.1), // Reduced shadow
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(time,
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          Text(lesson['ders'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                        color: Color(lesson['renk']),
                                        blurRadius: 12),
                                    const Shadow(
                                        color: Colors.black45,
                                        offset: Offset(0, 1),
                                        blurRadius: 2)
                                  ])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- ADD / EDIT DIALOG ---
  void _dersEkleDuzenleDialog(
      {Map<String, dynamic>? mevcutDers, String? initialDay}) {
    final TextEditingController dersController =
        TextEditingController(text: mevcutDers?['ders'] ?? "");
    int secilenRenkKod = mevcutDers?['renk'] ?? _genisRenkPaleti[3].toARGB32();
    String secilenGun = mevcutDers?['day'] ?? (initialDay ?? _gunler[0]);

    TimeOfDay baslangic = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay bitis = const TimeOfDay(hour: 9, minute: 40);

    if (mevcutDers != null) {
      try {
        String hamSaat = mevcutDers['saat'];
        List<String> parcalar = hamSaat.split(" - ");
        if (parcalar.length == 2) {
          baslangic = _parseTime(parcalar[0]);
          bitis = _parseTime(parcalar[1]);
        }
      } catch (e) {/* ignore */}
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                radius: 32,
                opacity: 0.1,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Text(
                              mevcutDers == null ? "Program Ekle" : "Düzenle",
                              style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white))),
                      const SizedBox(height: 24),

                      // Day Selector
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1))),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: secilenGun,
                          dropdownColor: const Color(0xFF1E2742),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            labelText: "Gün",
                            labelStyle: TextStyle(color: Colors.white54),
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: GoogleFonts.inter(
                              color: Colors.white, fontWeight: FontWeight.w600),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white54),
                          items: _gunler
                              .map((g) =>
                                  DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => secilenGun = v!),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lesson Name
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1))),
                        child: TextField(
                          controller: dersController,
                          style: GoogleFonts.inter(color: Colors.white),
                          cursorColor: AppTheme.secondaryColor,
                          decoration: const InputDecoration(
                              labelText: "Ders / Yazılı",
                              labelStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Time Pickers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildTimePickerBtn(
                                context, "Başlangıç", baslangic, (val) {
                              setDialogState(() {
                                baslangic = val;
                                bitis = _dakikaEkle(baslangic, 40);
                              });
                            }),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimePickerBtn(context, "Bitiş", bitis,
                                (val) => setDialogState(() => bitis = val)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Color Picker
                      Text("Renk Seçimi",
                          style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _genisRenkPaleti.map((c) {
                          bool isSelected = secilenRenkKod == c.toARGB32();
                          return GestureDetector(
                            onTap: () => setDialogState(
                                () => secilenRenkKod = c.toARGB32()),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: c.withOpacity(0.6),
                                            blurRadius: 12,
                                            spreadRadius: 2)
                                      ]
                                    : null,
                              ),
                              child: CircleAvatar(
                                backgroundColor: c,
                                radius: 16,
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Actions
                      Row(
                        children: [
                          if (mevcutDers != null)
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  _deleteLesson(mevcutDers);
                                  Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor:
                                        Colors.redAccent.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16))),
                                child: Text("Sil",
                                    style: GoogleFonts.inter(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          if (mevcutDers != null) const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () {
                                if (dersController.text.isEmpty) return;
                                _saveLesson(
                                    mevcutDers,
                                    secilenGun,
                                    dersController.text,
                                    baslangic,
                                    bitis,
                                    secilenRenkKod);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      AppTheme.secondaryColor,
                                      AppTheme.primaryColor
                                    ]),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                          color: AppTheme.secondaryColor
                                              .withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4))
                                    ]),
                                alignment: Alignment.center,
                                child: Text("Kaydet",
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimePickerBtn(BuildContext context, String label, TimeOfDay time,
      Function(TimeOfDay) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
                context: context,
                initialTime: time,
                builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      timePickerTheme: TimePickerThemeData(
                        backgroundColor: const Color(0xFF1E2742),
                        hourMinuteTextColor: Colors.white,
                        dayPeriodTextColor: Colors.white70,
                        dialHandColor: AppTheme.secondaryColor,
                        dialBackgroundColor: Colors.white10,
                        entryModeIconColor: AppTheme.secondaryColor,
                        helpTextStyle: GoogleFonts.inter(color: Colors.white),
                        cancelButtonStyle: ButtonStyle(
                            foregroundColor:
                                WidgetStateProperty.all(Colors.white70)),
                        confirmButtonStyle: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all(
                                AppTheme.secondaryColor)),
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                    child: child!));
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_formatTime(time),
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        )
      ],
    );
  }

  void _saveLesson(Map<String, dynamic>? existing, String day, String name,
      TimeOfDay start, TimeOfDay end, int color) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app');

    // If changing days, delete the old one first
    if (existing != null && existing['day'] != day) {
      db
          .ref(
              "users/${user.uid}/DersProgrami/${existing['day']}/${existing['key']}")
          .remove();
      existing = null; // Treat as new
    }

    final ref = db.ref("users/${user.uid}/DersProgrami/$day");
    String timeStr = "${_formatTime(start)} - ${_formatTime(end)}";

    Map<String, dynamic> data = {'ders': name, 'saat': timeStr, 'renk': color};

    if (existing == null) {
      ref.push().set(data);
    } else {
      ref.child(existing['key']).update(data);
    }
  }

  void _deleteLesson(Map<String, dynamic> lesson) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("users/${user.uid}/DersProgrami/${lesson['day']}/${lesson['key']}")
        .remove();
  }

  TimeOfDay _parseTime(String s) {
    var p = s.split(":");
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _formatTime(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  TimeOfDay _dakikaEkle(TimeOfDay t, int min) {
    int total = t.hour * 60 + t.minute + min;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }
}
