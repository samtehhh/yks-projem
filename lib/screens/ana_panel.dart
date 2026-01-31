import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:home_widget/home_widget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/sabitler.dart';
import '../widgets/glass_card.dart';
import '../theme.dart';

import 'profil_screen.dart';
import 'ders_listesi_screen.dart';
import 'konu_takvim_screen.dart';
import 'gunluk_takvim_screen.dart';
import 'pomodoro_screen.dart';
import 'ders_programi_screen.dart';
import 'yapamadiklarim_screen.dart';
import 'trial_tracker_screen.dart';
import 'deneme_takvim_screen.dart';

class AnaPanel extends StatefulWidget {
  const AnaPanel({super.key});

  @override
  State<AnaPanel> createState() => _AnaPanelState();
}

class _AnaPanelState extends State<AnaPanel> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _tumVerileriTemizle(BuildContext context) async {
    final bool? eminMi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tüm Verileri Temizle"),
        content: const Text(
            "⚠️ DİKKAT!\n\nBütün ilerlemeniz, deneme sonuçlarınız, profil bilgileriniz ve ayarlarınız KALICI OLARAK silinecek.\n\nBu işlem geri alınamaz. Devam etmek istiyor musunuz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("İptal")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("SİL VE SIFIRLA")),
        ],
      ),
    );

    if (eminMi == true) {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete everything: users/$uid
        final refRoot = FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL:
                    'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
            .ref("users/${user.uid}");

        await refRoot.remove();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "✅ Tüm veriler başarıyla silindi. Uygulama fabrika ayarlarına döndü."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ));
        }
      }
    }
  }

  Future<void> _verileriGuncelle(BuildContext context) async {
    final bool? eminMi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Müfredatı Güncelle"),
        content: const Text(
            "Konu listeleri 2026 MEB müfredatına göre güncellenecek. Onaylıyor musun?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("İptal")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Evet, Güncelle")),
        ],
      ),
    );

    if (eminMi == true) {
      final User? user = FirebaseAuth.instance.currentUser;
      final refRoot = FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL:
                  'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
          .ref("users/${user!.uid}");

      List<Map<String, dynamic>> tytVerisi = [];
      tytKonulari.forEach((dersAdi, konular) {
        tytVerisi.add({
          'isim': dersAdi,
          'konular':
              konular.map((k) => {'isim': k, 'durum': 'Baslamadim'}).toList()
        });
      });
      await refRoot.child("TYT").set(tytVerisi);

      final profilSnapshot = await refRoot.child("profil").get();
      if (profilSnapshot.exists) {
        final profilData = profilSnapshot.value as Map<dynamic, dynamic>;
        final String? alan = profilData['alan'];

        if (alan != null) {
          List<Map<String, dynamic>> aytVerisi = [];
          List<String> dersler = [];

          if (alan.contains('Sayısal')) {
            dersler = [
              'AYT Matematik',
              'AYT Fizik',
              'AYT Kimya',
              'AYT Biyoloji',
              'AYT Geometri'
            ];
          } else if (alan.contains('Eşit Ağırlık')) {
            dersler = [
              'AYT Matematik',
              'AYT Edebiyat',
              'AYT Tarih-1',
              'AYT Coğrafya-1',
              'AYT Geometri'
            ];
          } else if (alan.contains('Sözel')) {
            dersler = [
              'AYT Edebiyat',
              'AYT Tarih-1',
              'AYT Coğrafya-1',
              'AYT Tarih-2',
              'AYT Coğrafya-2',
              'AYT Felsefe Grubu',
              'AYT Din'
            ];
          } else if (alan.contains('Dil')) {
            dersler = ['YDT İngilizce', 'TYT Tekrarı'];
          }

          for (var dersAdi in dersler) {
            if (aytMufredati.containsKey(dersAdi)) {
              aytVerisi.add({
                'isim': dersAdi,
                'konular': aytMufredati[dersAdi]!
                    .map((k) => {'isim': k, 'durum': 'Baslamadim'})
                    .toList()
              });
            }
          }
          await refRoot.child("AYT").set(aytVerisi);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Müfredat 2026 Takvimine Göre Güncellendi!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    // LayoutBuilder ile ekran boyutunu alıyoruz ki drawer açılınca hata vermesin
    return Scaffold(
      key: _scaffoldKey,
      // Modern Gradient Background
      body: Stack(
        children: [
          // Premium Mesh Gradient Background
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.backgroundDark,
            ),
          ),
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.08),
                    AppTheme.primaryColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondaryColor.withValues(alpha: 0.05),
                    AppTheme.secondaryColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Merhaba, 👋",
                            style: GoogleFonts.inter(
                              color: AppTheme.textSub,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            user?.displayName?.split(' ')[0] ?? 'Öğrenci',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              color: AppTheme.textMain,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        // FIX: Use GlobalKey to open drawer
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.primaryColor, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(user?.photoURL ?? ""),
                            child: user?.photoURL == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // YKS Sayacı
                        const YksSayacWidget(),

                        const SizedBox(height: 25),

                        // Grid Menu
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          children: [
                            _buildMenuItem(
                              context,
                              "TYT\nKonuları",
                              Icons.auto_stories_rounded,
                              AppTheme.primaryColor,
                              const DersListesiEkrani(alan: "TYT"),
                            ),
                            _buildMenuItem(
                              context,
                              "AYT\nKonuları",
                              Icons.collections_bookmark_rounded,
                              AppTheme.secondaryColor,
                              const DersListesiEkrani(alan: "AYT"),
                            ),
                            _buildMenuItem(
                              context,
                              "Konu &\nTekrar",
                              Icons.event_note_rounded,
                              AppTheme.amberColor,
                              const KonuTakvimEkrani(),
                            ),
                            _buildMenuItem(
                              context,
                              "Günlük\nTakvim",
                              Icons.today_rounded,
                              const Color(0xFF6366F1),
                              const GunlukTakvimEkrani(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Full Width Items
                        _buildWideMenuItem(
                          context,
                          "Yapamadığım Sorular",
                          "Hatalarından ders çıkar!",
                          Icons.error_outline_rounded,
                          AppTheme.roseColor,
                          const YapamadiklarimScreen(),
                        ),
                        const SizedBox(height: 16),
                        _buildWideMenuItem(
                          context,
                          "Pomodoro & Kronometre",
                          "Odaklan ve çalış!",
                          Icons.timer_outlined,
                          AppTheme.roseColor,
                          const PomodoroEkrani(),
                        ),
                        const SizedBox(height: 16),
                        _buildWideMenuItem(
                          context,
                          "Deneme & Tekrar Takvimi",
                          "Hatalarını ve denemelerini gör!",
                          Icons.calendar_month_rounded,
                          const Color(0xFF8B5CF6), // Violet
                          const DenemeTakvimEkrani(),
                        ),
                        const SizedBox(height: 16),
                        _buildWideMenuItem(
                          context,
                          "Deneme Takibi",
                          "İlerlemeni gör!",
                          Icons.insights_rounded,
                          AppTheme.primaryColor,
                          const TrialTrackerScreen(),
                        ),
                        const SizedBox(height: 16),
                        _buildWideMenuItem(
                          context,
                          "Ders Programı",
                          "Planlı çalış!",
                          Icons.auto_awesome_motion_rounded,
                          AppTheme.emeraldColor,
                          const DersProgramiEkrani(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildModernDrawer(context, user),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon,
      Color color, Widget page) {
    return GlassCard(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => page)),
      padding: EdgeInsets.zero,
      radius: 28,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textMain,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideMenuItem(BuildContext context, String title, String subtitle,
      IconData icon, Color color, Widget page) {
    return GlassCard(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => page)),
      padding: const EdgeInsets.all(20),
      radius: 28,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.textMain,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: AppTheme.textSub.withValues(alpha: 0.3), size: 16),
        ],
      ),
    );
  }

  Widget _buildModernDrawer(BuildContext context, User? user) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Stack(
        children: [
          // Background matches Profile Screen
          AppTheme.meshBackground(),

          // Glass Effect
          Container(
            color: AppTheme.backgroundDark.withValues(alpha: 0.8),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor
                          ]),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: AppTheme.surfaceDark,
                          backgroundImage: NetworkImage(user?.photoURL ?? ""),
                          child: user?.photoURL == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? "Öğrenci",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.email ?? "",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),

                // Menu Items
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Profilim ve Tercihlerim',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilEkrani()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.sync_rounded,
                  title: 'Müfredatı Güncelle',
                  onTap: () {
                    Navigator.pop(context);
                    _verileriGuncelle(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.delete_forever_rounded,
                  title: 'Tüm Verileri Temizle',
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _tumVerileriTemizle(context);
                  },
                ),

                const Spacer(),
                const Divider(color: Colors.white24, height: 1),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Çıkış Yap',
                  color: AppTheme.roseColor,
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    await GoogleSignIn().signOut();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color color = Colors.white}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: color.withValues(alpha: 0.8), size: 24),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: color == Colors.white ? Colors.white : color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Colors.white.withValues(alpha: 0.05),
    );
  }
}

// ---------------------------------------------------------
// MODERN YKS 2026 SAYAC WIDGET
// ---------------------------------------------------------

class YksSayacWidget extends StatefulWidget {
  const YksSayacWidget({super.key});

  @override
  State<YksSayacWidget> createState() => _YksSayacWidgetState();
}

class _YksSayacWidgetState extends State<YksSayacWidget> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isLoading = true;

  late DateTime _examDate;
  String _basvuruTarihleri = "";

  @override
  void initState() {
    super.initState();
    _fetchOsymData().catchError((error) {
      print('❌ Error fetching OSYM data: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _examDate = DateTime(2026, 6, 20, 10, 15); // Fallback date
          _basvuruTarihleri = "6 Şub - 3 Mar";
        });
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOsymData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _examDate = DateTime(2026, 6, 20, 10, 15);
        _basvuruTarihleri = "6 Şub - 3 Mar";
        _isLoading = false;
      });
      _startTimer();
      await _updateAndroidWidget(_examDate);
    }
  }

  Future<void> _updateAndroidWidget(DateTime tytDate) async {
    final now = DateTime.now();
    final tytGun = tytDate.difference(now).inDays;
    await HomeWidget.saveWidgetData<String>('tyt_gun', tytGun.toString());
    await HomeWidget.updateWidget(
        name: 'TytWidgetProvider', androidName: 'TytWidgetProvider');
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_examDate.isAfter(now)) {
        if (mounted) {
          setState(() {
            _remainingTime = _examDate.difference(now);
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GlassCard(child: Center(child: CircularProgressIndicator()));
    }

    return GlassCard(
      padding: const EdgeInsets.all(28),
      radius: 32,
      opacity: 0.05, // Ultra-low opacity for Deep Obsidian depth
      borderColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "YKS 2026",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: -0.5,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      "SINAVA KALAN SÜRE",
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      "BAŞVURU",
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor),
                    ),
                    Text(
                      _basvuruTarihleri,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeUnit("${_remainingTime.inDays}", "GÜN"),
                _buildTimeUnit("${_remainingTime.inHours % 24}", "SAAT"),
                _buildTimeUnit("${_remainingTime.inMinutes % 60}", "DAKİKA"),
                _buildTimeUnit("${_remainingTime.inSeconds % 60}", "SANİYE"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppTheme.textSub),
              const SizedBox(width: 8),
              Text(
                "${_examDate.day} Haziran ${_examDate.year} • Hedefine Odaklan",
                style: GoogleFonts.inter(
                  color: AppTheme.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String unit) {
    return Column(
      children: [
        Text(
          value.padLeft(2, '0'),
          style: GoogleFonts.outfit(
            color: AppTheme.textMain,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: GoogleFonts.inter(
            color: AppTheme.textSub,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
