import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/tekrar_dialog.dart';
import '../data/sabitler.dart'; // Ensure access to tytKonulari/aytMufredati

enum KonuSikligi { yuksek, orta, az }

class DersListesiEkrani extends StatefulWidget {
  final String alan; // TYT or AYT
  const DersListesiEkrani({super.key, required this.alan});

  @override
  State<DersListesiEkrani> createState() => _DersListesiEkraniState();
}

class _DersListesiEkraniState extends State<DersListesiEkrani> {
  late DatabaseReference _dbRef;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  final Map<String, String> durumYazilari = {
    'baslanmadi': 'Başlanmadı',
    'calisiliyor': 'Çalışılıyor',
    'tekrar': 'Tekrar Lazım',
    'bitti': 'Bitti',
  };

  final Map<String, Color> durumRenkleri = {
    'baslanmadi': Color(0xFF94A3B8), // slate-400
    'calisiliyor': Color(0xFF2DD4BF), // teal-400 neon
    'tekrar': Color(0xFFFACC15), // amber-400 neon
    'bitti': Color(0xFF10B981), // emerald-500 neon
  };

  final Map<String, IconData> durumIkonlari = {
    'baslanmadi': Icons.radio_button_unchecked_rounded,
    'calisiliyor': Icons.bolt_rounded,
    'tekrar': Icons.refresh_rounded,
    'bitti': Icons.verified_rounded,
  };

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      // Point to users/$uid/TYT or users/$uid/AYT
      _dbRef = FirebaseDatabase.instance
          .ref('users/${currentUser!.uid}/${widget.alan}');
      _checkAndSeedData();
    }
  }

  Future<void> _checkAndSeedData() async {
    final snapshot = await _dbRef.get();
    if (!snapshot.exists || snapshot.value == null) {
      debugPrint(
          "⚠️ No data for ${widget.alan}. Seeding from sabitler.dart...");
      List<Map<String, dynamic>> initialData = [];

      if (widget.alan == 'TYT') {
        tytKonulari.forEach((dersAdi, konuListesi) {
          List<Map<String, dynamic>> konular = konuListesi
              .map((k) =>
                  {"isim": k, "durum": "baslanmadi", "bitisTarihi": null})
              .toList();
          initialData.add({"isim": dersAdi, "alan": "TYT", "konular": konular});
        });
      } else if (widget.alan == 'AYT') {
        // For AYT, we might want to respect the user's field (Sayısal, EA, etc.)
        // But for the generic list view, we might just load everything or filter later.
        // For now, let's load all AYT subjects that are in aytMufredati
        // Ideally, we should filter by user's field, but let's stick to the current pattern.
        // If the user hasn't selected a field, or to cover all:

        // However, AnaPanel usually seeds restricted sets.
        // Let's seed ALL AYT for now to be safe, or just check 'profil' if needed.
        // Simple approach: Seed all available in aytMufredati.

        aytMufredati.forEach((dersAdi, konuListesi) {
          List<Map<String, dynamic>> konular = konuListesi
              .map((k) =>
                  {"isim": k, "durum": "baslanmadi", "bitisTarihi": null})
              .toList();
          initialData.add({"isim": dersAdi, "alan": "AYT", "konular": konular});
        });
      }

      await _dbRef.set(initialData);
      debugPrint("✅ Data seeded for ${widget.alan}!");
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text("Hata: Kullanıcı bulunamadı."));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          AppTheme.meshBackground(),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header
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
                      Text(
                        "${widget.alan} Konuları",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : StreamBuilder(
                          stream: _dbRef.onValue,
                          builder:
                              (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                _isLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text("Hata: ${snapshot.error}",
                                      style: GoogleFonts.inter(
                                          color: Colors.white70)));
                            }

                            if (!snapshot.hasData ||
                                snapshot.data?.snapshot.value == null) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            List<dynamic> hamDersler = [];
                            final value = snapshot.data!.snapshot.value;

                            if (value is List) {
                              hamDersler =
                                  List.from(value.where((d) => d != null));
                            } else if (value is Map) {
                              hamDersler = value.values.toList();
                            }

                            if (hamDersler.isEmpty) {
                              return Center(
                                  child: Text("Henüz konu yok.",
                                      style: GoogleFonts.inter(
                                          color: Colors.white54)));
                            }

                            return ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: hamDersler.length,
                              itemBuilder: (context, index) {
                                final ders = hamDersler[index];
                                final String dersAdi = ders['isim'];
                                List<dynamic> konular =
                                    List.from(ders['konular'] ?? []);

                                // Calculate Progress
                                int completed = konular
                                    .where((k) =>
                                        _normalizeDurum(k['durum']) == 'bitti')
                                    .length;
                                double progress = konular.isEmpty
                                    ? 0
                                    : completed / konular.length;

                                return GlassCard(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: EdgeInsets.zero,
                                  radius: 24,
                                  opacity: 0.05, // Modern Dark
                                  borderColor:
                                      Colors.white.withValues(alpha: 0.08),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      iconColor: AppTheme.secondaryColor,
                                      collapsedIconColor: Colors.white54,
                                      tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              dersAdi,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (progress > 0)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  right: 12),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: AppTheme.emeraldColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: AppTheme
                                                          .emeraldColor
                                                          .withOpacity(0.2))),
                                              child: Text(
                                                "%${(progress * 100).toInt()}",
                                                style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppTheme.emeraldColor),
                                              ),
                                            )
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.white10,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppTheme.secondaryColor),
                                            minHeight: 4,
                                          ),
                                        ),
                                      ),
                                      children: [
                                        Container(
                                          color: Colors.black12,
                                          child: Column(
                                            children: konular
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              var konu = entry.value;
                                              int originalKonuIndex = entry.key;
                                              String durum = _normalizeDurum(
                                                  konu['durum']);
                                              String konuIsmi = konu['isim'];

                                              return ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 4),
                                                title: Text(
                                                  konuIsmi,
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                    color: durum == 'bitti'
                                                        ? Colors.white
                                                            .withValues(
                                                                alpha: 0.5)
                                                        : Colors.white,
                                                    decoration: null,
                                                  ),
                                                ),
                                                trailing: _buildNeonStatusBadge(
                                                    durum,
                                                    context,
                                                    dersAdi,
                                                    index,
                                                    originalKonuIndex,
                                                    konuIsmi),
                                              );
                                            }).toList(),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeDurum(dynamic durum) {
    if (durum == null) return 'baslanmadi';
    String d = durum.toString().toLowerCase();
    if (d.contains('bit') || d.contains('tamam')) return 'bitti';
    if (d.contains('calis') || d.contains('devam')) return 'calisiliyor';
    if (d.contains('tekrar')) return 'tekrar';
    return 'baslanmadi';
  }

  Widget _buildNeonStatusBadge(String durum, BuildContext context,
      String dersAdi, int dersIndex, int konuIndex, String konuAdi) {
    Color color = durumRenkleri[durum] ?? Colors.grey;
    IconData icon = durumIkonlari[durum] ?? Icons.help_outline;

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        _showModernStatusSheet(context, dersIndex, konuIndex, durum, dersAdi);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              durumYazilari[durum]?.toUpperCase() ?? "BAŞLAMADI",
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModernStatusSheet(BuildContext context, int dersIndex,
      int konuIndex, String currentStatus, String dersAdi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "DURUMU GÜNCELLE",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              _buildStatusOption(
                context,
                "baslanmadi",
                "Başlanmadı",
                Icons.radio_button_unchecked_rounded,
                dersIndex,
                konuIndex,
                currentStatus,
                dersAdi,
              ),
              const SizedBox(height: 12),
              _buildStatusOption(
                context,
                "calisiliyor",
                "Çalışılıyor",
                Icons.bolt_rounded,
                dersIndex,
                konuIndex,
                currentStatus,
                dersAdi,
              ),
              const SizedBox(height: 12),
              _buildStatusOption(
                context,
                "tekrar",
                "Tekrar Planla",
                Icons.refresh_rounded,
                dersIndex,
                konuIndex,
                currentStatus,
                dersAdi,
              ),
              const SizedBox(height: 12),
              _buildStatusOption(
                context,
                "bitti",
                "Bitti",
                Icons.verified_rounded,
                dersIndex,
                konuIndex,
                currentStatus,
                dersAdi,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    String value,
    String text,
    IconData icon,
    int dersIndex,
    int konuIndex,
    String currentStatus,
    String dersAdi,
  ) {
    bool isSelected = value == currentStatus;
    Color color = durumRenkleri[value] ?? Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (value == 'tekrar') {
          _durumDegistir(dersIndex, konuIndex, 'calisiliyor', dersAdi,
              forceTekrar: true);
        } else {
          _durumDegistir(dersIndex, konuIndex, currentStatus, dersAdi,
              forceStatus: value);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 20,
                  color:
                      isSelected ? color : Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _durumDegistir(
      int dersIndex, int konuIndex, String mevcutDurum, String dersAdi,
      {String? forceStatus, bool forceTekrar = false}) async {
    String yeniDurum;

    if (forceStatus != null) {
      yeniDurum = forceStatus;
    } else if (forceTekrar) {
      yeniDurum = 'tekrar';
    } else {
      List<String> states = ['baslanmadi', 'calisiliyor', 'tekrar', 'bitti'];
      int nextIdx = (states.indexOf(mevcutDurum) + 1) % states.length;
      yeniDurum = states[nextIdx];
    }

    if (yeniDurum == 'tekrar') {
      showDialog(
        context: context,
        builder: (context) => TekrarDetayDialog(
          dersAdi: dersAdi,
          onIptal: () => Navigator.pop(context),
          onKaydet: (kaynak, detay, tip, sistem, tarihListesi, tekrarSayisi) {
            Navigator.pop(context);

            // Logic for repeating directly uses update on the specific path
            Map<String, dynamic> updates = {
              'durum': 'tekrar',
              'kaynak': kaynak,
              'kaynakDetay': detay,
              'tekrarTipi': tip,
              'tekrarSistemi': sistem,
              'planlananTarihler':
                  tarihListesi.map((e) => e.toIso8601String()).toList(),
              'toplamTekrarSayisi':
                  int.tryParse(tekrarSayisi) ?? tarihListesi.length,
              'yapilanTekrarSayisi': 0,
            };

            if (currentUser != null) {
              _dbRef.child('$dersIndex/konular/$konuIndex').update(updates);
            }
          },
        ),
      );
    } else {
      Map<String, dynamic> updates = {'durum': yeniDurum};
      DateTime now = DateTime.now();

      if (yeniDurum == 'calisiliyor') {
        updates['baslamaTarihi'] = now.toIso8601String();
        updates['bitisTarihi'] = null;
      } else if (yeniDurum == 'bitti') {
        updates['bitisTarihi'] = now.toIso8601String();
      } else if (yeniDurum == 'baslanmadi') {
        updates['baslamaTarihi'] = null;
        updates['bitisTarihi'] = null;
      }

      if (currentUser != null) {
        _dbRef.child('$dersIndex/konular/$konuIndex').update(updates);
      }
    }
  }
}
