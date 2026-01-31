import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../data/sabitler.dart';
import '../widgets/glass_card.dart';
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilEkrani extends StatefulWidget {
  const ProfilEkrani({super.key});

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  final User? user = FirebaseAuth.instance.currentUser;
  late final DatabaseReference _profilRef;

  final TextEditingController _adController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _secilenSinif;
  String? _secilenAlan;
  String? _eskiAlan;
  bool _isLoading = true;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _siniflar = [
    '9. Sınıf',
    '10. Sınıf',
    '11. Sınıf',
    '12. Sınıf',
    'Mezun'
  ];
  final List<String> _alanlar = [
    'Sayısal (MF)',
    'Eşit Ağırlık (TM)',
    'Sözel (TS)',
    'Dil (DİL)'
  ];

  @override
  void initState() {
    super.initState();
    _profilRef = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("users/${user!.uid}/profil");

    _adController.text = user?.displayName ?? "";
    _emailController.text = user?.email ?? "";

    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final snapshot = await _profilRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        if (data['ad'] != null) _adController.text = data['ad'];
        _secilenSinif = data['sinif'];
        _secilenAlan = data['alan'];
        _eskiAlan = data['alan'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      debugPrint("Resim seçme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Resim seçilemedi: $e")),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null || user == null) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Resim yükleniyor...")));
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('${user!.uid}.jpg');

      await storageRef.putFile(_imageFile!);
      final String downloadUrl = await storageRef.getDownloadURL();

      // Update Auth
      await user!.updatePhotoURL(downloadUrl);

      // Update Realtime DB (Optional, but good for sync)
      await _profilRef.update({'photoUrl': downloadUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profil fotoğrafı güncellendi! ✅")));
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Yükleme başarısız. İnternetini kontrol et.")),
        );
      }
    }
  }

  Future<void> _kaydet() async {
    if (_secilenAlan == null || _secilenSinif == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen sınıf ve alan seçiniz.")));
      return;
    }

    if (_eskiAlan != null && _eskiAlan != _secilenAlan) {
      final bool? onayla = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text("Alan Değişikliği",
              style: GoogleFonts.outfit(color: Colors.white)),
          content: Text(
              "Alanınızı $_eskiAlan'dan $_secilenAlan'a değiştirmek üzeresiniz. \n\n⚠️ Bu işlem AYT ilerlemenizi SİLECEK ve yeni alana göre dersleri yükleyecektir.",
              style: GoogleFonts.inter(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("İptal")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Onayla")),
          ],
        ),
      );

      if (onayla != true) return;

      final refRoot = FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL:
                  'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
          .ref("users/${user!.uid}");
      await refRoot.child("AYT").remove();

      await _yeniAlanDersleriniYukle(_secilenAlan!, refRoot);
    } else if (_eskiAlan == null) {
      final refRoot = FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL:
                  'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
          .ref("users/${user!.uid}");
      await _yeniAlanDersleriniYukle(_secilenAlan!, refRoot);
    }

    await _profilRef.set({
      'ad': _adController.text,
      'email': _emailController.text,
      'sinif': _secilenSinif,
      'alan': _secilenAlan,
      'photoUrl': user?.photoURL
    });

    setState(() => _eskiAlan = _secilenAlan);

    await user?.updateDisplayName(_adController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bilgiler kaydedildi! ✅")));
    }
  }

  Future<void> _yeniAlanDersleriniYukle(
      String alan, DatabaseReference refRoot) async {
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
        'AYT Din Kültürü'
      ];
    } else if (alan.contains('Dil')) {
      dersler = ['YDT (İngilizce)', 'TYT Tekrarı'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Kişisel Bilgilerim",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background
          AppTheme.meshBackground(),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // Profile Picture Section
                        Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        Colors.purple.shade300
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: AppTheme.surfaceDark,
                                    backgroundImage: _imageFile != null
                                        ? FileImage(_imageFile!)
                                        : (user?.photoURL != null
                                            ? NetworkImage(user!.photoURL!)
                                            : null) as ImageProvider?,
                                    child: (_imageFile == null &&
                                            user?.photoURL == null)
                                        ? const Icon(Icons.person,
                                            size: 60, color: Colors.white54)
                                        : null,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      size: 20, color: Colors.white),
                                ),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          "Profil Fotoğrafını Değiştirmek İçin Tıkla",
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Form Card
                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          radius: 32,
                          opacity: 0.05,
                          borderColor: Colors.white.withValues(alpha: 0.1),
                          child: Column(
                            children: [
                              _buildProfileField(
                                controller: _adController,
                                label: "Adınız Soyadınız",
                                icon: Icons.badge_rounded,
                              ),
                              const SizedBox(height: 20),
                              _buildProfileField(
                                controller: _emailController,
                                label: "E-Posta Adresi",
                                icon: Icons.alternate_email_rounded,
                                readOnly: true,
                              ),
                              const SizedBox(height: 20),
                              _buildProfileDropdown(
                                value: _secilenSinif,
                                label: "Sınıfınız",
                                icon: Icons.school_rounded,
                                items: _siniflar,
                                onChanged: (v) =>
                                    setState(() => _secilenSinif = v),
                              ),
                              const SizedBox(height: 20),
                              _buildProfileDropdown(
                                value: _secilenAlan,
                                label: "Alanınız (Bölüm)",
                                icon: Icons.category_rounded,
                                items: _alanlar,
                                onChanged: (v) =>
                                    setState(() => _secilenAlan = v),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _kaydet,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 8,
                                    shadowColor: AppTheme.primaryColor
                                        .withValues(alpha: 0.4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.save_rounded),
                                      const SizedBox(width: 10),
                                      Text("DEĞİŞİKLİKLERİ KAYDET",
                                          style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label.toUpperCase(),
              style: GoogleFonts.outfit(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: Colors.white54),
              filled: false,
              hintText: hintText,
              hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label.toUpperCase(),
              style: GoogleFonts.outfit(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
        Container(
          // Removed horizontal padding which caused the gap
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true, // This helps align with text fields
              child: DropdownButtonFormField<String>(
                initialValue: value,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, size: 20, color: Colors.white54),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                  // Align icon and text properly
                ),
                dropdownColor: const Color(0xFF1E1E2C),
                iconEnabledColor: Colors.white54,
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w500),
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
