import 'dart:async';
import 'dart:math'; // Rastgele zaman hesaplaması için gerekli
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Kaydırmalı seçim için
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/glass_card.dart';
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';

class PomodoroEkrani extends StatefulWidget {
  const PomodoroEkrani({super.key});

  @override
  State<PomodoroEkrani> createState() => _PomodoroEkraniState();
}

class _PomodoroEkraniState extends State<PomodoroEkrani>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;

  // --- YENİ EKLENEN DEĞİŞKENLER (Reality Check) ---
  Timer? _deadlineTimer; // 120 saniyelik cevap süresi sayacı
  int? _randomCheckThreshold; // Hangi saniyede (kalan süre) soru sorulacak?
  bool _dogrulamaYapildiMi = false; // Bu oturumda soru soruldu mu?
  bool _dogrulamaEkraniAcik = false; // Şu an ekranda soru var mı?

  // Pomodoro Değişkenleri
  int _calismaSuresiDk = 25; // Klasik Başlangıç
  int _kisaMolaSuresiDk = 5;
  int _uzunMolaSuresiDk = 15;

  int _kalanSaniye = 25 * 60;
  int _baslangicSaniyesi = 25 * 60;

  bool _pomodoroCalisiyor = false;
  bool _molaModu = false;
  int _pomodoroSayaci = 0; // Kaç pomodoro bitti?

  // Kronometre Değişkenleri
  int _gecenSaniye = 0;
  bool _kronometreCalisiyor = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _deadlineTimer?.cancel(); // Yeni timer temizliği
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Normal Alarm Sesi (Gürültülü)
  void _sesCal() async {
    try {
      await _audioPlayer.setVolume(1.0); // Sesi fulle
      await _audioPlayer.play(UrlSource(
          'https://actions.google.com/sounds/v1/alarms/beep_short.ogg'));
    } catch (e) {
      debugPrint("Ses hatası: $e");
    }
  }

  // --- YENİ VE GARANTİ: Hafif Uyarı Sesi (Asset'ten Çalar) ---
  void _uyariSesiCal() async {
    try {
      // Önce varsa çalan sesi durdur
      await _audioPlayer.stop();

      // Sesi %30 seviyesine ayarla (0.3)
      await _audioPlayer.setVolume(0.3);

      // Dosyadan çal (assets/sounds/uyari.mp3)
      // AssetSource kullanırken başına "assets/" yazmana gerek yok, kütüphane otomatik anlar.
      await _audioPlayer.play(AssetSource('sounds/uyari.mp3'));

      // Gelecek alarmlar gür çıksın diye 2 saniye sonra sesi tekrar fulle
      Future.delayed(const Duration(seconds: 2), () {
        _audioPlayer.setVolume(1.0);
      });
    } catch (e) {
      debugPrint("Ses hatası: $e");
    }
  }

  Future<void> _calismayiKaydet(int sureDk, String tur) async {
    if (sureDk < 1) return;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Kullanıcı yoksa hata vermesin

    final ref = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("users/${user.uid}/SerbestCalisma");

    await ref.push().set({
      'tarih': DateTime.now().toIso8601String(),
      'sure': sureDk,
      'tur': tur,
      'not': ''
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ $sureDk dk çalışma kaydedildi!"),
        backgroundColor: Colors.green,
      ));
    }
  }

  // --- REALITY CHECK (Doğrulama) FONKSİYONLARI ---

  void _rastgeleZamanBelirle() {
    // Mola modundaysak veya süre çok kısaysa sorma
    if (_molaModu || _calismaSuresiDk < 3) {
      _randomCheckThreshold = -1;
      return;
    }

    int toplamSaniye = _calismaSuresiDk * 60;
    // İlk 60 sn ve son 60 sn hariç rastgele bir yer seç
    int minSinir = 60;
    int maxSinir = toplamSaniye - 60;

    if (maxSinir > minSinir) {
      int rastgeleSaniye = minSinir + Random().nextInt(maxSinir - minSinir);
      // Geri sayım mantığına çevir (Kalan süre kaç olunca sorulsun?)
      _randomCheckThreshold = toplamSaniye - rastgeleSaniye;
      debugPrint(
          "Doğrulama, kalan süre $_randomCheckThreshold saniye olunca yapılacak.");
    }
  }

  void _dogrulamaEkraniAc() {
    _uyariSesiCal(); // <--- İSTEDİĞİN KISIK SES BURADA ÇALIYOR
    _dogrulamaEkraniAcik = true;

    // 120 Saniye Geri Sayımı Başlat
    _deadlineTimer = Timer(const Duration(seconds: 120), () {
      if (_dogrulamaEkraniAcik && mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dialogu kapat
        _dogrulamaBasarisiz();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false, // Boşluğa basınca kapanmasın
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Text("Kontrol Zamanı!"),
          ],
        ),
        content: const Text(
          "Hala odaklanmış durumda mısın?\n\nDevam etmek için 120 saniye içinde onayla.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text("BURADAYIM, ÇALIŞIYORUM 🚀",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                _deadlineTimer?.cancel(); // Ölüm sayacını iptal et
                _dogrulamaEkraniAcik = false;
                Navigator.pop(context); // Dialogu kapat

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Süpersin! Odaklanmaya devam."),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.blueAccent,
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _dogrulamaBasarisiz() {
    _pomodoroSifirla(); // Sayacı durdur ve sıfırla

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yakalandın! 😴"),
        content: const Text(
            "120 saniye içinde doğrulama yapmadığın için Pomodoro iptal edildi."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam"),
          )
        ],
      ),
    );
  }

  // --- POMODORO MANTIĞI ---
  void _pomodoroBaslatDuraklat() {
    if (_pomodoroCalisiyor) {
      // DURAKLATMA
      _timer?.cancel();
      _deadlineTimer?.cancel(); // Duraklatınca arka planda süre işlemesin
      setState(() => _pomodoroCalisiyor = false);
    } else {
      // BAŞLATMA
      setState(() => _pomodoroCalisiyor = true);

      // Yeni bir çalışma başlıyorsa rastgele zamanı belirle
      if (!_molaModu && !_dogrulamaYapildiMi && _randomCheckThreshold == null) {
        _rastgeleZamanBelirle();
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_kalanSaniye > 0) {
          setState(() => _kalanSaniye--);

          // -- REALITY CHECK KONTROLÜ --
          if (!_molaModu &&
              !_dogrulamaYapildiMi &&
              _randomCheckThreshold != null &&
              _kalanSaniye == _randomCheckThreshold) {
            _dogrulamaYapildiMi = true; // Bir daha sorma
            _dogrulamaEkraniAc();
          }
          // ----------------------------
        } else {
          _timer?.cancel();
          _sesCal();
          _pomodoroBitti();
        }
      });
    }
  }

  void _pomodoroBitti() {
    setState(() => _pomodoroCalisiyor = false);

    if (!_molaModu) {
      // ÇALIŞMA BİTTİ
      _pomodoroSayaci++;
      _calismayiKaydet(_calismaSuresiDk, "Pomodoro");

      bool uzunMolaVakti = (_pomodoroSayaci % 4 == 0);
      int molaSuresi = uzunMolaVakti ? _uzunMolaSuresiDk : _kisaMolaSuresiDk;

      // Çalışma bitince bir sonraki set için doğrulama durumunu sıfırla
      _dogrulamaYapildiMi = false;
      _randomCheckThreshold = null;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Süre Doldu! 🍅"),
          content: Text("Tebrikler! $_pomodoroSayaci. çalışmanı bitirdin.\n" +
              (uzunMolaVakti
                  ? "4. set bittiği için UZUN MOLA ($molaSuresi dk) hakedildi!"
                  : "Sırada kısa mola ($molaSuresi dk) var.")),
          actions: [
            TextButton(
                child: const Text("Bitir"),
                onPressed: () {
                  Navigator.pop(context);
                  _pomodoroSifirla();
                }),
            ElevatedButton(
              child: Text("Mola Başlat ($molaSuresi dk)"),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _molaModu = true;
                  _kalanSaniye = molaSuresi * 60;
                  _baslangicSaniyesi = molaSuresi * 60;
                });
                _pomodoroBaslatDuraklat();
              },
            ),
          ],
        ),
      );
    } else {
      // MOLA BİTTİ
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Mola Bitti! ☕"),
          content: const Text("Yeni bir sete hazır mısın?"),
          actions: [
            ElevatedButton(
              child: const Text("Yeni Set Başlat"),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _molaModu = false;
                  _kalanSaniye = _calismaSuresiDk * 60;
                  _baslangicSaniyesi = _calismaSuresiDk * 60;
                  // Yeni set için resetler
                  _dogrulamaYapildiMi = false;
                  _randomCheckThreshold = null;
                });
                _pomodoroBaslatDuraklat();
              },
            ),
          ],
        ),
      );
    }
  }

  void _pomodoroSifirla() {
    _timer?.cancel();
    _deadlineTimer?.cancel();
    setState(() {
      _pomodoroCalisiyor = false;
      _molaModu = false;
      _kalanSaniye = _calismaSuresiDk * 60;
      _baslangicSaniyesi = _calismaSuresiDk * 60;

      // Reality check değişkenlerini sıfırla
      _dogrulamaYapildiMi = false;
      _randomCheckThreshold = null;
      _dogrulamaEkraniAcik = false;
    });
  }

  // --- KAYDIRMALI SÜRE SEÇİCİ ---
  void _sureAyarlariGoster() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true, // Tam ekran/klavye uyumu için
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            height: 400,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text("Süre Ayarları",
                    style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 30),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPickerColumn("Çalışma", _calismaSuresiDk,
                          (val) => setState(() => _calismaSuresiDk = val)),
                      _buildPickerColumn("Kısa Mola", _kisaMolaSuresiDk,
                          (val) => setState(() => _kisaMolaSuresiDk = val)),
                      _buildPickerColumn("Uzun Mola", _uzunMolaSuresiDk,
                          (val) => setState(() => _uzunMolaSuresiDk = val)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _pomodoroSifirla(); // Ayarlar değişince sayacı sıfırla
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("Uygula ve Sıfırla",
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickerColumn(
      String title, int initValue, Function(int) onChanged) {
    return Column(
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: AppTheme.textSub)),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          width: 80,
          child: CupertinoPicker(
            scrollController:
                FixedExtentScrollController(initialItem: initValue),
            itemExtent: 40,
            onSelectedItemChanged: (index) => onChanged(index),
            selectionOverlay: Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
            children: List<Widget>.generate(121, (int index) {
              // 0-120 arası
              return Center(
                  child: Text('$index dk',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)));
            }),
          ),
        ),
      ],
    );
  }

  // --- KRONOMETRE FONKSİYONLARI ---
  void _kronometreBaslat() {
    if (_kronometreCalisiyor) return;
    setState(() => _kronometreCalisiyor = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _gecenSaniye++);
    });
  }

  void _kronometreMolaVer() {
    _timer?.cancel();
    setState(() => _kronometreCalisiyor = false);
  }

  void _kronometreBitir() {
    _timer?.cancel();
    setState(() => _kronometreCalisiyor = false);

    int dakika = (_gecenSaniye / 60).floor();
    if (dakika > 0) {
      _calismayiKaydet(dakika, "Serbest Çalışma");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Süre çok kısa, kaydedilmedi.")));
    }
    setState(() => _gecenSaniye = 0);
  }

  String _formatTime(int seconds) {
    int m = (seconds / 60).floor();
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Çalışma Asistanı"),
        actions: [
          TextButton(
            onPressed: _sureAyarlariGoster,
            child: Text("Ayarla",
                style: GoogleFonts.inter(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSub,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.timer_rounded), text: "Pomodoro"),
            Tab(icon: Icon(Icons.watch_later_rounded), text: "Sayaç"),
          ],
        ),
      ),
      body: Stack(
        children: [
          AppTheme.meshBackground(),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPomodoroTab(),
                _buildKronometreTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroTab() {
    double yuzde =
        _baslangicSaniyesi == 0 ? 0 : 1 - (_kalanSaniye / _baslangicSaniyesi);
    Color themeColor = _molaModu ? AppTheme.emeraldColor : AppTheme.roseColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            radius: 16,
            opacity: 0.3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMinInfo("Çalışma", "$_calismaSuresiDk'"),
                _buildMinInfo("Kısa Mola", "$_kisaMolaSuresiDk'"),
                _buildMinInfo("Uzun Mola", "$_uzunMolaSuresiDk'"),
              ],
            ),
          ),
          const SizedBox(height: 40),
          CircularPercentIndicator(
            radius: 120.0,
            lineWidth: 12.0,
            percent: yuzde.clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _molaModu ? "MOLA" : "ODAKLAN",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(_kalanSaniye),
                  style: GoogleFonts.outfit(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        BoxShadow(
                            color: themeColor.withValues(alpha: 0.5),
                            blurRadius: 20)
                      ]),
                ),
                const SizedBox(height: 8),
                Text(
                  "${_pomodoroSayaci % 4}/4 Döngü",
                  style: GoogleFonts.inter(
                      color: Colors.white54, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            progressColor: themeColor,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            circularStrokeCap: CircularStrokeCap.round,
            animateFromLastPercent: false,
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // RESET Button
              _buildModernIconBtn(
                onTap: _pomodoroSifirla,
                icon: Icons.refresh_rounded,
                color: Colors.white24,
                isSmall: true,
              ),
              const SizedBox(width: 24),
              // PLAY/PAUSE Button (Big)
              _buildModernIconBtn(
                onTap: _pomodoroBaslatDuraklat,
                icon: _pomodoroCalisiyor
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: themeColor,
                isBig: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinInfo(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildModernIconBtn(
      {required VoidCallback onTap,
      required IconData icon,
      required Color color,
      bool isBig = false,
      bool isSmall = false}) {
    double size = isBig ? 80 : (isSmall ? 56 : 64);
    double iconSize = isBig ? 40 : (isSmall ? 24 : 32);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildKronometreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            radius: 32,
            opacity: 0.05,
            borderColor: Colors.white.withValues(alpha: 0.1),
            child: Column(
              children: [
                Text("Toplam Süre",
                    style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Text(
                  _formatTime(_gecenSaniye),
                  style: GoogleFonts.outfit(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20)
                    ],
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          if (!_kronometreCalisiyor && _gecenSaniye == 0)
            _buildModernIconBtn(
                onTap: _kronometreBaslat,
                icon: Icons.play_arrow_rounded,
                color: AppTheme.primaryColor,
                isBig: true),
          if (_gecenSaniye > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bitir
                _buildModernIconBtn(
                    onTap: () {
                      if (_gecenSaniye < 60) {
                        _kronometreBitir(); // Direkt sıfırla
                      } else {
                        // Onay al
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E2C),
                            title: const Text("Çalışmayı Bitir",
                                style: TextStyle(color: Colors.white)),
                            content: Text(
                                "Toplam ${_formatTime(_gecenSaniye)} süre kaydedilecek.",
                                style: const TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("İptal")),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _kronometreBitir();
                                  },
                                  child: const Text("Bitir ve Kaydet",
                                      style: TextStyle(color: Colors.white))),
                            ],
                          ),
                        );
                      }
                    },
                    icon: Icons.stop_rounded,
                    color: AppTheme.roseColor,
                    isSmall: true),

                const SizedBox(width: 32),

                // Başlat / Duraklat
                _buildModernIconBtn(
                    onTap: _kronometreCalisiyor
                        ? _kronometreMolaVer
                        : _kronometreBaslat,
                    icon: _kronometreCalisiyor
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: _kronometreCalisiyor
                        ? Colors.amber
                        : AppTheme.primaryColor,
                    isBig: true),
              ],
            ),
        ],
      ),
    );
  }
}
