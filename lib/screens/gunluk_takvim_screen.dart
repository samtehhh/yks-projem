import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/sabitler.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/topic_card.dart';

class GunlukTakvimEkrani extends StatefulWidget {
  const GunlukTakvimEkrani({super.key});
  @override
  State<GunlukTakvimEkrani> createState() => _GunlukTakvimEkraniState();
}

class _GunlukTakvimEkraniState extends State<GunlukTakvimEkrani> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

  // Form Fields
  String _secilenAlan = "TYT";
  String? _secilenDers;
  String? _secilenKonu;
  String _aktiviteTuru = "Konu Çalıştım";
  String? _secilenKaynak;
  String? _kullaniciAlani; // Stores fetched user area
  final TextEditingController _ozelKaynakController = TextEditingController();
  final TextEditingController _hocaController = TextEditingController();
  final TextEditingController _soruSayisiController = TextEditingController();
  final TextEditingController _videoSayisiController = TextEditingController();
  final TextEditingController _sureController = TextEditingController();
  final TextEditingController _notlarController = TextEditingController();
  bool _usePremiumUI = true; // Experimental UI Toggle

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _verileriCekVeTakvimeIsle().catchError((error) {
      print('❌ Error loading calendar data: $error');
      if (mounted) {
        setState(() {
          _events = {}; // Initialize with empty events on error
        });
      }
    });
  }

  String _formatSure(dynamic gelenSure) {
    int dakika = int.tryParse(gelenSure.toString()) ?? 0;
    if (dakika < 60) return "${dakika}dk";
    int saat = dakika ~/ 60;
    int kalanDakika = dakika % 60;
    return kalanDakika == 0 ? "${saat}sa" : "${saat}sa ${kalanDakika}dk";
  }

  Future<void> _verileriCekVeTakvimeIsle() async {
    final User? user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("users/${user!.uid}");

    ref.onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value == null) {
        setState(() => _events = {});
        return;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      Map<DateTime, List<dynamic>> yeniEventler = {};

      if (data['SerbestCalisma'] != null) {
        final Map<dynamic, dynamic> calismalar = data['SerbestCalisma'];
        calismalar.forEach((key, value) {
          if (value['tarih'] != null) {
            DateTime tarih = DateTime.parse(value['tarih']);
            DateTime gun = DateTime.utc(tarih.year, tarih.month, tarih.day);
            if (yeniEventler[gun] == null) yeniEventler[gun] = [];
            yeniEventler[gun]!.add({
              'isim': "Çalışma Süreniz: ${_formatSure(value['sure'])}",
              'tip': 'serbest_calisma',
              'detay': "${value['tur']} kaydı alındı.",
              'sure': value['sure'],
              'dbKey': key // Serbest çalışma silinemez ama yapıyı bozmuyoruz
            });
          }
        });
      }

      if (data['GunlukAktiviteler'] != null) {
        final Map<dynamic, dynamic> aktiviteler = data['GunlukAktiviteler'];
        aktiviteler.forEach((key, value) {
          if (value['tarih'] != null) {
            DateTime tarih = DateTime.parse(value['tarih']);
            DateTime gun = DateTime.utc(tarih.year, tarih.month, tarih.day);
            if (yeniEventler[gun] == null) yeniEventler[gun] = [];

            String hoca = value['hoca'] ?? "";
            String kaynak = value['kaynak'] ?? "";
            String notlar = value['detay'] ?? "";

            yeniEventler[gun]!.add({
              'isim': "${value['konu']} - ${value['ders']}",
              'konu': value['konu'],
              'ders': value['ders'],
              'tip': _getTipFromTur(value['tur']),
              'turYazisi': value['tur'],
              'soruSayisi': value['soruSayisi'],
              'videoSayisi': value['videoSayisi'],
              'sure_dk': value['sure_dk'],
              'hoca': hoca,
              'kaynak': kaynak,
              'detay': notlar,
              'dbKey': key
            });
          }
        });
      }

      // Fetch Profile Info for Area
      if (data['profil'] != null) {
        final profil = data['profil'] as Map<dynamic, dynamic>;
        if (profil['alan'] != null) {
          _kullaniciAlani = profil['alan'].toString();
        }
      }

      setState(() {
        _events = yeniEventler;
      });
    });
  }

  String _getTipFromTur(String? tur) {
    if (tur == 'Soru Çözdüm') return 'soru_cozdum';
    if (tur == 'Konu Çalıştım') return 'konu_calistim';
    if (tur == 'Tekrar Ettim') return 'tekrar_ettim';
    if (tur == 'Başladım') return 'basladim';
    return 'konu_calistim';
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Günlük Takvim",
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
                color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [AppTheme.secondaryColor, AppTheme.primaryColor],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _aktiviteEkleDialogGoster,
          label: Text("Aktivite Ekle",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          icon: const Icon(Icons.add_task, color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: Stack(
        children: [
          // Background
          AppTheme.meshBackground(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
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
                        rowHeight: 58, // Matches Konu Takvimi compact view
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

                  // Daily Summary
                  if (_selectedDay != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildDailySummary()),

                  const SizedBox(height: 16),

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
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Activity List
                  _buildActivityList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Not used anymore since we integrated directly in build

  Widget _buildDailySummary() {
    int topSoru = 0;
    int topSure = 0;
    int topVideo = 0;
    Set<String> uniqueKonular = {};
    List<dynamic> gununEventleri = _getEventsForDay(_selectedDay!);

    for (var ev in gununEventleri) {
      if (ev['soruSayisi'] != null)
        topSoru += int.tryParse(ev['soruSayisi'].toString()) ?? 0;
      if (ev['sure_dk'] != null)
        topSure += int.tryParse(ev['sure_dk'].toString()) ?? 0;
      if (ev['videoSayisi'] != null)
        topVideo += int.tryParse(ev['videoSayisi'].toString()) ?? 0;
      if (ev['konu'] != null && ev['konu'].isNotEmpty)
        uniqueKonular.add(ev['konu']);
    }

    String sureMetni = "${topSure} dk";
    if (topSure >= 60) {
      int sa = topSure ~/ 60;
      int dk = topSure % 60;
      sureMetni = dk > 0 ? "${sa}sa ${dk}dk" : "${sa}sa";
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      opacity: 0.1,
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppTheme.secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text("Günün Özeti",
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          // Grid for stats
          Row(
            children: [
              Expanded(
                  child: _buildStatItem(Icons.access_time_filled, sureMetni,
                      "Çalışma", Colors.orangeAccent)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildStatItem(
                      Icons.help, "$topSoru", "Soru", Colors.cyanAccent)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem(Icons.play_circle_fill, "$topVideo",
                      "Video", Colors.redAccent)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildStatItem(Icons.menu_book,
                      "${uniqueKonular.length}", "Konu", Colors.greenAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white)),
              Text(label,
                  style:
                      GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  // Formerly _buildSummaryRow - deprecated by _buildStatItem

  Widget _buildActivityList() {
    List<dynamic> events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
            child: Text("Henüz bir aktivite yok.",
                style: GoogleFonts.inter(color: Colors.white54))),
      );
    }

    return Column(
      children: [
        // Experimental Toggle Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _usePremiumUI ? "PREMIUM GÖRÜNÜM ✨" : "STANDART GÖRÜNÜM",
                style: GoogleFonts.outfit(
                  color: _usePremiumUI ? AppTheme.primaryColor : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Switch(
                value: _usePremiumUI,
                onChanged: (v) => setState(() => _usePremiumUI = v),
                activeThumbColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
        _usePremiumUI
            ? _buildPremiumEventList(events)
            : _buildLegacyEventList(events),
      ],
    );
  }

  Widget _buildPremiumEventList(List<dynamic> events) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final String tip = event['tip'] ?? '';

        // Determine Type
        final TopicCardType cardType =
            (tip == 'soru_cozdum' || tip == 'tekrar_ettim')
                ? TopicCardType.question
                : TopicCardType.study;

        // Collect Stats
        List<String> stats = [];
        if (event['soruSayisi'] != null)
          stats.add("${event['soruSayisi']} Soru");
        if (event['sure_dk'] != null) stats.add("${event['sure_dk']} dk");
        if (event['videoSayisi'] != null)
          stats.add("${event['videoSayisi']} Video");

        return Dismissible(
          key: Key("premium_${event['dbKey'] ?? index}"),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24)),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child:
                const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          onDismissed: (_) {
            if (event['tip'] != 'serbest_calisma') _aktiviteSil(event['dbKey']);
          },
          child: TopicCard(
            title: event['isim'] ?? 'İsimsiz',
            subtitle: event['turYazisi'] ?? 'Aktivite',
            type: cardType,
            stats: stats,
            onTap: () {
              // Details or edit logic if needed
            },
          ),
        );
      },
    );
  }

  Widget _buildLegacyEventList(List<dynamic> events) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        Color mainColor = _getColorForTip(event['tip']);
        IconData icon = _getIconForTip(event['tip']);

        return Dismissible(
          key: Key(event['dbKey'] ?? DateTime.now().toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24)),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child:
                const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          onDismissed: (_) {
            if (event['tip'] != 'serbest_calisma') _aktiviteSil(event['dbKey']);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: mainColor.withValues(alpha: 0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mainColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: mainColor.withValues(alpha: 0.2),
                                blurRadius: 10)
                          ],
                        ),
                        child: Icon(icon, color: mainColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['isim'],
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            if (event['turYazisi'] != null)
                              Text(event['turYazisi'],
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: mainColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (event['soruSayisi'] != null)
                        _buildTag(
                            "${event['soruSayisi']} Soru", Colors.cyanAccent),
                      if (event['sure_dk'] != null)
                        _buildTag(
                            "${event['sure_dk']} dk", Colors.orangeAccent),
                      if (event['videoSayisi'] != null)
                        _buildTag(
                            "${event['videoSayisi']} Video", Colors.redAccent),
                    ],
                  ),
                  if (event['detay'] != null &&
                      event['detay'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(event['detay'],
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.white54)),
                  ]
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(text,
          style: GoogleFonts.inter(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // Kept for compatibility if other methods call it, or remove if unused.

  // DIALOG ve LOGIC Functions (Keep mostly same but update styles)
  // DIALOG ve LOGIC Functions (Modernized)
  Future<void> _aktiviteEkleDialogGoster() async {
    // Robustly fetch user area if missing before opening dialog
    if (_kullaniciAlani == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final snapshot = await FirebaseDatabase.instanceFor(
                  app: Firebase.app(),
                  databaseURL:
                      'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
              .ref("users/${user.uid}/profil/alan")
              .get();
          if (snapshot.exists) {
            _kullaniciAlani = snapshot.value.toString();
          }
        } catch (e) {
          print("⚠️ Error fetching area: $e");
        }
      }
    }

    _secilenAlan = "TYT";
    _secilenDers = null;
    _secilenKonu = null;
    _aktiviteTuru = "Konu Çalıştım";
    _secilenKaynak = null;
    _ozelKaynakController.clear();
    _hocaController.clear();
    _soruSayisiController.clear();
    _videoSayisiController.clear();
    _sureController.clear();
    _notlarController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            List<String> dersListesi = (_secilenAlan == 'TYT')
                ? tytKonulari.keys.toList()
                : _getFilteredAytLessons();
            List<String> konuListesi = [];
            if (_secilenDers != null) {
              konuListesi = (_secilenAlan == 'TYT')
                  ? (tytKonulari[_secilenDers] ?? [])
                  : (aytMufredati[_secilenDers] ?? []);
            }
            List<String> kaynakListesi = [];
            if (_secilenDers != null) {
              String anahtarKelime = 'Genel';
              dersBazliKaynaklar.forEach((k, v) {
                if (_secilenDers!.contains(k)) anahtarKelime = k;
              });
              kaynakListesi =
                  List.from(dersBazliKaynaklar[anahtarKelime] ?? []);
              kaynakListesi.add("Diğer / Özel Giriş");
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                radius: 32,
                opacity: 0.65, // Dense 2026 crystal feel
                color: const Color(0xFF020617), // Perfectioned blue-black
                borderColor: Colors.white.withValues(alpha: 0.1),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppTheme.secondaryColor,
                                AppTheme.primaryColor
                              ]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: AppTheme.secondaryColor
                                        .withValues(alpha: 0.4),
                                    blurRadius: 10)
                              ]),
                          child: const Icon(Icons.add_task,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text("Aktivite Ekle",
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white)),
                        ),
                        if (_kullaniciAlani != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _kullaniciAlani!,
                              style: GoogleFonts.inter(
                                  color: AppTheme.primaryColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close,
                              color: Colors.white54, size: 20),
                        )
                      ]),
                      const SizedBox(height: 24),

                      // Toggle TYT/AYT
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Expanded(
                                child: _buildSegmentButton(
                                    "TYT",
                                    _secilenAlan == "TYT",
                                    () => setStateDialog(() {
                                          _secilenAlan = "TYT";
                                          _secilenDers = null;
                                          _secilenKonu = null;
                                        }))),
                            Expanded(
                                child: _buildSegmentButton(
                                    "AYT",
                                    _secilenAlan == "AYT",
                                    () => setStateDialog(() {
                                          _secilenAlan = "AYT";
                                          _secilenDers = null;
                                          _secilenKonu = null;
                                        }))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dropdowns
                      _buildGlassDropdown(
                          "Ders Seçiniz", _secilenDers, dersListesi, (v) {
                        setStateDialog(() {
                          _secilenDers = v;
                          _secilenKonu = null;
                        });
                      }),
                      const SizedBox(height: 12),
                      _buildGlassDropdown(
                          "Konu Seçiniz/Ekle",
                          _secilenKonu,
                          konuListesi,
                          (v) => setStateDialog(() => _secilenKonu = v)),

                      const SizedBox(height: 20),

                      // Activity Type Selection (2x2 Grid for Symmetry)
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 8),
                          Text("Aktivite Türü",
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          Row(
                            children: [
                              _buildPremiumTypeCard(
                                label: 'Konu Çalıştım',
                                icon: Icons.auto_stories_rounded,
                                isSelected: _aktiviteTuru == 'Konu Çalıştım',
                                onTap: () => setStateDialog(
                                    () => _aktiviteTuru = 'Konu Çalıştım'),
                              ),
                              const SizedBox(width: 10),
                              _buildPremiumTypeCard(
                                label: 'Soru Çözdüm',
                                icon: Icons.quiz_rounded,
                                isSelected: _aktiviteTuru == 'Soru Çözdüm',
                                onTap: () => setStateDialog(
                                    () => _aktiviteTuru = 'Soru Çözdüm'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildPremiumTypeCard(
                                label: 'Tekrar Ettim',
                                icon: Icons.history_rounded,
                                isSelected: _aktiviteTuru == 'Tekrar Ettim',
                                onTap: () => setStateDialog(
                                    () => _aktiviteTuru = 'Tekrar Ettim'),
                              ),
                              const SizedBox(width: 10),
                              _buildPremiumTypeCard(
                                label: 'Başladım',
                                icon: Icons.rocket_launch_rounded,
                                isSelected: _aktiviteTuru == 'Başladım',
                                onTap: () => setStateDialog(
                                    () => _aktiviteTuru = 'Başladım'),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Inputs based on choice
                      if (_aktiviteTuru == 'Soru Çözdüm' ||
                          _aktiviteTuru == 'Tekrar Ettim') ...[
                        _buildPremiumInputField(
                            hint: "Soru Sayısı (Kaç tane?)",
                            icon: Icons.help_outline,
                            controller: _soruSayisiController,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                      ],

                      // Resource Selection
                      _buildGlassDropdown(
                          "Kaynak",
                          _secilenKaynak,
                          kaynakListesi,
                          (v) => setStateDialog(() => _secilenKaynak = v)),

                      if (_secilenKaynak == "Diğer / Özel Giriş") ...[
                        const SizedBox(height: 12),
                        _buildPremiumInputField(
                            hint: "Özel Kaynak İsmi",
                            icon: Icons.edit,
                            controller: _ozelKaynakController),
                      ],
                      const SizedBox(height: 12),

                      _buildPremiumInputField(
                          hint: "Hoca / Kanal (Opsiyonel)",
                          icon: Icons.person_outline,
                          controller: _hocaController),

                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _buildPremiumInputField(
                              hint: "Süre (Dakika)",
                              icon: Icons.access_time_filled,
                              controller: _sureController,
                              keyboardType: TextInputType.number),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPremiumInputField(
                              hint: "Video İzleme",
                              icon: Icons.play_circle_fill,
                              controller: _videoSayisiController,
                              keyboardType: TextInputType.number),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildPremiumInputField(
                          hint: "Notlar...",
                          icon: Icons.note_alt_outlined,
                          controller: _notlarController,
                          maxLines: 2),

                      const SizedBox(height: 28),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_secilenDers == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Lütfen Ders Seçiniz!")));
                              return;
                            }
                            Navigator.pop(context); // Close dialog
                            _aktiviteyiKaydet();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16))),
                          child: Ink(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.secondaryColor
                                ]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ]),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text("Kaydet",
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
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

  Color _getColorForTip(String tip) {
    switch (tip) {
      case 'soru_cozdum':
        return Colors.blue.shade600;
      case 'konu_calistim':
        return Colors.green.shade600;
      case 'tekrar_ettim':
        return Colors.orange.shade600;
      case 'basladim':
        return Colors.purple.shade600;
      case 'serbest_calisma':
        return Colors.indigo.shade600;
      default:
        return Colors.grey;
    }
  }

  // Modern UI Helpers
  Widget _buildSegmentButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8)
                  ]
                : []),
        child: Text(text,
            style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
    );
  }

  Widget _buildGlassDropdown(String hint, String? value, List<String> items,
      Function(String?) onChanged) {
    return GestureDetector(
      onTap: () {
        if (items.isEmpty) return;
        _showModernPicker(
          context: context,
          title: hint,
          items: items,
          onSelected: (val) => onChanged(val),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: const Color(0xFF020617).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: GoogleFonts.inter(
                    color: value == null ? Colors.white38 : Colors.white,
                    fontSize: 14),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }

  void _showModernPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: const Color(0xFF0c0c0c)
                    .withValues(alpha: 0.95), // Pure Black as requested
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12))),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              onSelected(item);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                      alpha:
                                          0.05), // Better contrast on Pure Black
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.08),
                                        blurRadius: 10,
                                        spreadRadius: 1)
                                  ],
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.12))),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle),
                                    child: Icon(_getIconForLesson(item),
                                        color: AppTheme.primaryColor, size: 16),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      color: Colors.white24, size: 12),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumTypeCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.white24,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForTip(String tip) {
    switch (tip) {
      case 'soru_cozdum':
        return Icons.quiz_rounded;
      case 'konu_calistim':
        return Icons.menu_book_rounded;
      case 'tekrar_ettim':
        return Icons.sync_rounded;
      case 'basladim':
        return Icons.flag_rounded;
      case 'serbest_calisma':
        return Icons.timer_rounded;
      default:
        return Icons.circle;
    }
  }

  Widget _buildPremiumInputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF020617).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style:
            GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.4),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 18),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Future<void> _aktiviteyiKaydet() async {
    // ... [Logic same as before] ...
    final User? user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("users/${user!.uid}/GunlukAktiviteler");
    DateTime kayitTarihi = _selectedDay ?? DateTime.now();
    String finalKaynak = _secilenKaynak ?? "";
    if (_secilenKaynak == "Diğer / Özel Giriş")
      finalKaynak = _ozelKaynakController.text;

    await ref.push().set({
      'tarih': kayitTarihi.toIso8601String(),
      'alan': _secilenAlan,
      'ders': _secilenDers,
      'konu': _secilenKonu,
      'tur': _aktiviteTuru,
      'kaynak': finalKaynak,
      'hoca': _hocaController.text,
      'soruSayisi': _soruSayisiController.text.isNotEmpty
          ? int.tryParse(_soruSayisiController.text)
          : null,
      'videoSayisi': _videoSayisiController.text.isNotEmpty
          ? int.tryParse(_videoSayisiController.text)
          : null,
      'sure_dk': _sureController.text.isNotEmpty
          ? int.tryParse(_sureController.text)
          : null,
      'detay': _notlarController.text
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Aktivite eklendi! ✨"), backgroundColor: Colors.green));
  }

  Future<void> _aktiviteSil(String? dbKey) async {
    if (dbKey == null) return;
    final User? user = FirebaseAuth.instance.currentUser;
    await FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("users/${user!.uid}/GunlukAktiviteler/$dbKey")
        .remove();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Silindi")));
  }

  // Filter AYT lessons based on user area
  List<String> _getFilteredAytLessons() {
    if (_kullaniciAlani == null) {
      return aytMufredati.keys.toList();
    }

    String area = _kullaniciAlani!.trim();
    List<String> result = [];

    if (area.contains('Sayısal')) {
      result = [
        'AYT Matematik',
        'AYT Fizik',
        'AYT Kimya',
        'AYT Biyoloji',
        'AYT Geometri'
      ];
    } else if (area.contains('Eşit Ağırlık')) {
      result = [
        'AYT Matematik',
        'AYT Edebiyat',
        'AYT Tarih-1',
        'AYT Coğrafya-1',
        'AYT Geometri'
      ];
    } else if (area.contains('Sözel')) {
      result = [
        'AYT Edebiyat',
        'AYT Tarih-1',
        'AYT Coğrafya-1',
        'AYT Tarih-2',
        'AYT Coğrafya-2',
        'AYT Felsefe Grubu',
        'AYT Din'
      ];
    } else if (area.contains('Dil')) {
      result = ['YDT İngilizce', 'TYT Tekrarı'];
    } else {
      return aytMufredati.keys.toList();
    }

    return result;
  }

  IconData _getIconForLesson(String lesson) {
    if (lesson.contains('Matematik') || lesson.contains('Geometri'))
      return Icons.calculate_rounded;
    if (lesson.contains('Fizik')) return Icons.bolt_rounded;
    if (lesson.contains('Kimya')) return Icons.science_rounded;
    if (lesson.contains('Biyoloji')) return Icons.grass_rounded;
    if (lesson.contains('Edebiyat') || lesson.contains('Türkçe'))
      return Icons.history_edu_rounded;
    if (lesson.contains('Tarih')) return Icons.account_balance_rounded;
    if (lesson.contains('Coğrafya')) return Icons.public_rounded;
    if (lesson.contains('Felsefe') || lesson.contains('Din'))
      return Icons.self_improvement_rounded;
    if (lesson.contains('İngilizce') || lesson.contains('YDT'))
      return Icons.translate_rounded;
    return Icons.auto_stories_rounded;
  }
}
