import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../widgets/glass_card.dart';

class KonuTakvimEkrani extends StatefulWidget {
  const KonuTakvimEkrani({super.key});
  @override
  State<KonuTakvimEkrani> createState() => _KonuTakvimEkraniState();
}

class _KonuTakvimEkraniState extends State<KonuTakvimEkrani> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  String _filterMode = 'ALL'; // 'ALL', 'TYT', 'AYT'

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _verileriCekVeTakvimeIsle();
  }

  String _normalizeDurum(String? raw) {
    if (raw == null) return "Yapılacak";
    String d = raw.toString().toLowerCase();

    // Check main keywords
    if (d.contains('calis') || d.contains('devam')) return "Çalışılıyor";
    if (d.contains('tekrar')) return "Tekrar";
    if (d.contains('bit') || d.contains('tamam')) return "Bitti";

    // Legacy mapping (kept for safety)
    const map = {
      "Başlanmadı": "Yapılacak",
      "Calisiyorum": "Çalışılıyor",
      "Devam Ediyor": "Çalışılıyor",
      "Tekrar Lazım": "Tekrar",
      "Bitirdim": "Bitti",
      "Tamamlandı": "Bitti",
      "calisiliyor": "Çalışılıyor",
      "bitti": "Bitti",
      "tekrar": "Tekrar",
      "baslanmadi": "Yapılacak"
    };
    if (map.containsKey(raw)) return map[raw]!;

    return raw;
  }

  Future<void> _verileriCekVeTakvimeIsle() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("users/${user.uid}");

    ref.onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value == null) {
        setState(() => _events = {});
        return;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      debugPrint("Calendar: Raw data received from Firebase for user.");
      Map<DateTime, List<dynamic>> yeniEventler = {};

      void isleyici(String alan) {
        if (data[alan] != null) {
          dynamic derslerData = data[alan];

          void dersDongusu(dynamic dKey, dynamic ders) {
            if (ders == null || ders['konular'] == null) return;
            dynamic konularData = ders['konular'];

            void konuDongusu(dynamic kKey, dynamic konu) {
              if (konu == null) return;
              Map<String, dynamic> temelVeri = {
                ...Map<String, dynamic>.from(konu),
                'alan': alan,
                'dKey': dKey,
                'kKey': kKey
              };

              if (konu['planlananTarihler'] != null) {
                List<dynamic> tarihler = konu['planlananTarihler'];
                for (var tarihStr in tarihler) {
                  DateTime? tarih = DateTime.tryParse(tarihStr.toString());
                  if (tarih != null) {
                    DateTime gun =
                        DateTime.utc(tarih.year, tarih.month, tarih.day);
                    if (yeniEventler[gun] == null) yeniEventler[gun] = [];
                    yeniEventler[gun]!.add({
                      ...temelVeri,
                      'tip': 'tekrar',
                      'hedefTarih': tarihStr
                    });
                  }
                }
              }

              String durum = _normalizeDurum(konu['durum']);

              if (durum == 'Çalışılıyor' && konu['baslamaTarihi'] != null) {
                DateTime? baslama = DateTime.tryParse(konu['baslamaTarihi']);
                if (baslama != null) {
                  DateTime bugun = DateTime.now();
                  DateTime sonTarih = konu['bitisTarihi'] != null
                      ? DateTime.parse(konu['bitisTarihi'])
                      : bugun;

                  for (int i = 0;
                      i <= sonTarih.difference(baslama).inDays;
                      i++) {
                    DateTime t = baslama.add(Duration(days: i));
                    DateTime gun = DateTime.utc(t.year, t.month, t.day);
                    if (yeniEventler[gun] == null) yeniEventler[gun] = [];
                    if (!yeniEventler[gun]!.any((e) =>
                        e['isim'] == konu['isim'] &&
                        e['tip'] == 'calisiyorum')) {
                      yeniEventler[gun]!
                          .add({...temelVeri, 'tip': 'calisiyorum'});
                    }
                  }
                }
              }

              if (durum == 'Bitti' && konu['bitisTarihi'] != null) {
                DateTime? bitis = DateTime.tryParse(konu['bitisTarihi']);
                if (bitis != null) {
                  DateTime gun =
                      DateTime.utc(bitis.year, bitis.month, bitis.day);
                  if (yeniEventler[gun] == null) yeniEventler[gun] = [];
                  if (!yeniEventler[gun]!.any((e) =>
                      e['isim'] == konu['isim'] && e['tip'] == 'konu_bitti')) {
                    yeniEventler[gun]!.add({...temelVeri, 'tip': 'konu_bitti'});
                  }
                }
              }

              if (konu['tamamlananTekrarlar'] != null) {
                List<dynamic> gecmis = konu['tamamlananTekrarlar'];
                for (var tarihStr in gecmis) {
                  DateTime? tarih = DateTime.tryParse(tarihStr.toString());
                  if (tarih != null) {
                    DateTime gun =
                        DateTime.utc(tarih.year, tarih.month, tarih.day);
                    if (yeniEventler[gun] == null) yeniEventler[gun] = [];
                    yeniEventler[gun]!.add({...temelVeri, 'tip': 'tamamlandi'});
                  }
                }
              }
            }

            if (konularData is List) {
              for (int i = 0; i < konularData.length; i++)
                konuDongusu(i, konularData[i]);
            } else if (konularData is Map) {
              konularData.forEach((k, v) => konuDongusu(k, v));
            }
          }

          if (derslerData is List) {
            for (int i = 0; i < derslerData.length; i++)
              dersDongusu(i, derslerData[i]);
          } else if (derslerData is Map) {
            derslerData.forEach((k, v) => dersDongusu(k, v));
          }
        }
      }

      isleyici('TYT');
      isleyici('AYT');

      if (mounted) setState(() => _events = yeniEventler);
    });
  }

  void _goreviTamamla(Map<dynamic, dynamic> event, BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
        .ref(
            "users/${user!.uid}/${event['alan']}/${event['dKey']}/konular/${event['kKey']}");

    int yapilan = (event['yapilanTekrarSayisi'] ?? 0) + 1;
    int toplam = event['toplamTekrarSayisi'] ?? 1;
    String sistem = event['tekrarSistemi'] ?? 'Özel';

    List<dynamic> tamamlananlar = event['tamamlananTekrarlar'] != null
        ? List.from(event['tamamlananTekrarlar'])
        : [];
    tamamlananlar.add(event['hedefTarih']);

    List<dynamic> planlananlar = event['planlananTarihler'] != null
        ? List.from(event['planlananTarihler'])
        : [];
    planlananlar.remove(event['hedefTarih']);

    Map<String, dynamic> updates = {
      "yapilanTekrarSayisi": yapilan,
      "tamamlananTekrarlar": tamamlananlar,
      "planlananTarihler": planlananlar,
    };

    if ((sistem == 'Özel' || sistem == 'Haftasonu') && yapilan < toplam) {
      DateTime? yeniTarih = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
          helpText: "${yapilan + 1}. TEKRAR İÇİN TARİH SEÇİN",
          locale: const Locale('tr', 'TR'));

      if (yeniTarih != null) {
        DateTime temizTarih =
            DateTime.utc(yeniTarih.year, yeniTarih.month, yeniTarih.day);
        planlananlar.add(temizTarih.toIso8601String());
        updates["planlananTarihler"] = planlananlar;
      }
    } else if (yapilan >= toplam && planlananlar.isEmpty) {
      updates["durum"] = "Bitti";
      updates["bitisTarihi"] = DateTime.now().toIso8601String();
    }

    ref.update(updates);
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    List<dynamic> allEvents =
        _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
    if (_filterMode == 'ALL') return allEvents;
    return allEvents.where((e) => e['alan'] == _filterMode).toList();
  }

  Color _getColorForTip(String tip) {
    switch (tip) {
      case 'calisiyorum':
        return AppTheme.primaryColor;
      case 'tekrar':
        return Colors.amber.shade700;
      case 'tamamlandi':
        return const Color(0xFF10B981); // Emerald 500
      case 'konu_bitti':
        return AppTheme.secondaryColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForTip(String tip) {
    switch (tip) {
      case 'calisiyorum':
        return Icons.auto_stories_rounded;
      case 'tekrar':
        return Icons.history_edu_rounded;
      case 'tamamlandi':
        return Icons.verified_rounded;
      case 'konu_bitti':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  Widget _buildFilterButton(String text, String mode) {
    bool isSelected = _filterMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 10)
                ]
              : [],
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Konu Takvimi",
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
          // Background
          AppTheme.meshBackground(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Filter Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFilterButton("Tümü", "ALL"),
                        const SizedBox(width: 8),
                        _buildFilterButton("TYT", "TYT"),
                        const SizedBox(width: 8),
                        _buildFilterButton("AYT", "AYT"),
                      ],
                    ),
                  ),

                  // Calendar Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      radius: 32,
                      opacity: 0.05, // Crystal Clear
                      borderColor: Colors.white.withValues(alpha: 0.1),
                      child: TableCalendar(
                        locale: 'tr_TR',
                        rowHeight:
                            58, // Adjusted for compact view while keeping dot spacing
                        firstDay: DateTime.utc(2024, 1, 1),
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
                              color: Colors.white), // White Text
                          leftChevronIcon: const Icon(Icons.chevron_left,
                              color: Colors.white70),
                          rightChevronIcon: const Icon(Icons.chevron_right,
                              color: Colors.white70),
                        ),
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          defaultTextStyle: GoogleFonts.inter(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          weekendTextStyle: GoogleFonts.inter(
                              color: AppTheme.secondaryColor, // Weekend Color
                              fontWeight: FontWeight.bold),
                          // Ensure markers are at bottom
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
                        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                        eventLoader: _getEventsForDay,
                        calendarBuilders: CalendarBuilders(
                          selectedBuilder: (context, date, events) {
                            return Container(
                              // Shift UP to fix overlap
                              margin: const EdgeInsets.only(
                                  bottom: 21.0,
                                  left: 6.0,
                                  right: 6.0,
                                  top: 4.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        spreadRadius: 2)
                                  ]),
                              child: Text(date.day.toString(),
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            );
                          },
                          todayBuilder: (context, date, events) {
                            return Container(
                              // Shift UP to fix overlap
                              margin: const EdgeInsets.only(
                                  bottom: 21.0,
                                  left: 6.0,
                                  right: 6.0,
                                  top: 4.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.5))),
                              child: Text(date.day.toString(),
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            );
                          },
                          singleMarkerBuilder: (context, date, event) {
                            final map = event as Map<dynamic, dynamic>;
                            return Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getColorForTip(map['tip']),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _getColorForTip(map['tip'])
                                            .withValues(alpha: 0.6),
                                        blurRadius: 4)
                                  ]),
                              width: 6.0,
                              height: 6.0,
                              margin: const EdgeInsets.only(
                                  left: 1.5, right: 1.5, bottom: 4.0),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Selected Date Header
                  if (_selectedDay != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                                color: AppTheme.secondaryColor,
                                borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('d MMMM yyyy', 'tr_TR')
                                .format(_selectedDay!),
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.1))),
                            child: Text(
                              "${_getEventsForDay(_selectedDay!).length} Etkinlik",
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Event List
                  _selectedDay == null
                      ? Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                              child: Text("Takvimden bir gün seçin",
                                  style: GoogleFonts.inter(
                                      color: Colors.white54))),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _getEventsForDay(_selectedDay!).length,
                          itemBuilder: (context, index) {
                            final event =
                                _getEventsForDay(_selectedDay!)[index];
                            String tip = event['tip'];
                            bool isCompleted = tip == 'tamamlandi';
                            bool isWorking = tip == 'calisiyorum';
                            bool isRepeat = tip == 'tekrar';
                            bool isFinishedSubject = tip == 'konu_bitti';

                            int yapilan = event['yapilanTekrarSayisi'] ?? 0;

                            String kaynakMetni =
                                "${event['kaynak'] ?? 'Kaynak Yok'}";
                            if (event['kaynakDetay'] != null &&
                                event['kaynakDetay'].toString().isNotEmpty) {
                              kaynakMetni += " • ${event['kaynakDetay']}";
                            }

                            String durumMetni = "";
                            if (isWorking)
                              durumMetni = "Konu Çalışılıyor...";
                            else if (isRepeat)
                              durumMetni = "${yapilan + 1}. Tekrar Zamanı";
                            else if (isCompleted)
                              durumMetni = "Tekrar Tamamlandı";
                            else if (isFinishedSubject)
                              durumMetni = "Konu Bitirildi";

                            Color mainColor = _getColorForTip(tip);
                            IconData icon = _getIconForTip(tip);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: mainColor.withValues(alpha: 0.3),
                                    width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: mainColor.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: isRepeat
                                      ? () => _goreviTamamla(event, context)
                                      : null,
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // Icon Container
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: mainColor.withValues(
                                                alpha: 0.1),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: mainColor.withValues(
                                                      alpha: 0.2),
                                                  blurRadius: 10)
                                            ],
                                          ),
                                          child: Icon(icon,
                                              color: mainColor, size: 24),
                                        ),
                                        const SizedBox(width: 16),

                                        // Content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(event['isim'],
                                                  style: GoogleFonts.outfit(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: isCompleted
                                                          ? Colors.white54
                                                          : Colors.white,
                                                      decoration: null)),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  if (isRepeat) ...[
                                                    Icon(Icons.bookmark_rounded,
                                                        size: 12,
                                                        color: mainColor),
                                                    const SizedBox(width: 4),
                                                  ],
                                                  Text(durumMetni,
                                                      style: GoogleFonts.inter(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: mainColor)),
                                                ],
                                              ),
                                              if (isRepeat) ...[
                                                const SizedBox(height: 2),
                                                Text(kaynakMetni,
                                                    style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: Colors.white38))
                                              ]
                                            ],
                                          ),
                                        ),

                                        // Action Button
                                        if (isRepeat)
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                color: AppTheme.emeraldColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                    color: AppTheme.emeraldColor
                                                        .withValues(
                                                            alpha: 0.2))),
                                            child: const Icon(
                                                Icons.check_rounded,
                                                color: AppTheme.emeraldColor,
                                                size: 20),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
