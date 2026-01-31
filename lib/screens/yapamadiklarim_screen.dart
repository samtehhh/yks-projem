import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/question_model.dart';
import '../services/question_service.dart';
import '../data/sabitler.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/topic_card.dart';

class YapamadiklarimScreen extends StatefulWidget {
  const YapamadiklarimScreen({super.key});

  @override
  State<YapamadiklarimScreen> createState() => _YapamadiklarimScreenState();
}

class _YapamadiklarimScreenState extends State<YapamadiklarimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = QuestionService();
  final _user = FirebaseAuth.instance.currentUser;

  // Form Fields
  String? _secilenDers;
  String? _secilenKonu;
  final TextEditingController _notController = TextEditingController();
  File? _selectedImage;
  ReviewStrategy _selectedStrategy = ReviewStrategy.ebbinghaus;
  int _targetRepeatCount = 4;
  List<DateTime> _customDates = [];
  bool _isUploading = false;
  bool _usePremiumUI = true; // Premium UI Toggle

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Yapamadıklarım",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          indicatorColor: AppTheme.primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: "Sorularım"),
            Tab(text: "Yeni Ekle"),
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
                _buildListTab(),
                _buildAddTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 1: LIST =================
  Widget _buildListTab() {
    if (_user == null) return const Center(child: Text("Giriş yapmalısınız"));

    final ref = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("users/${_user!.uid}/mistakes");

    return StreamBuilder(
      stream: ref.onValue.asBroadcastStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_search_rounded,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text("Henüz eklenmiş soru yok.",
                    style: GoogleFonts.inter(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        List<Question> questions = [];
        data.forEach((key, value) {
          questions.add(Question.fromMap(value));
        });

        questions.sort((a, b) => b.eklenmeTarihi.compareTo(a.eklenmeTarihi));

        return Column(
          children: [
            // Premium Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _usePremiumUI ? "PREMIUM GÖRÜNÜM ✨" : "STANDART GÖRÜNÜM",
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
                      onChanged: (v) => setState(() => _usePremiumUI = v),
                      activeThumbColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  return _usePremiumUI
                      ? _buildPremiumQuestionCard(q)
                      : _buildQuestionCard(q);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumQuestionCard(Question q) {
    bool isCompleted =
        q.tamamlananTekrarlar.length == q.planlananTekrarlar.length;

    return TopicCard(
      title: q.ders,
      subtitle: q.konu,
      type: TopicCardType.question,
      stats: [
        "${q.tamamlananTekrarlar.length}/${q.planlananTekrarlar.length} Tekrar",
        if (isCompleted) "Bitti" else "Devam Ediyor",
      ],
      customColor: isCompleted ? AppTheme.emeraldColor : AppTheme.amberColor,
      customIcon: Icons.help_outline_rounded,
      onTap: () {
        // Here we can show the details or original card expand logic
        // For simplicity, let's just show a bottom sheet with the original card or image
        _showQuestionDetailsSheet(q);
      },
    );
  }

  void _showQuestionDetailsSheet(Question q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(child: _buildQuestionCard(q)),
      ),
    );
  }

  Widget _buildQuestionCard(Question q) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 20),
      radius: 24,
      opacity: 0.4,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.ders,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(q.konu,
                          style: GoogleFonts.inter(
                              color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                _buildStatusChip(
                    q.tamamlananTekrarlar.length, q.planlananTekrarlar.length)
              ],
            ),
          ),

          // Image
          if (q.imageUrl != null)
            GestureDetector(
              onTap: () => _showFullImage(q.imageUrl!),
              child: Hero(
                tag: q.imageUrl!,
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    image: DecorationImage(
                        image: NetworkImage(q.imageUrl!), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),

          // Review Progress
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (q.notlar != null && q.notlar!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(q.notlar!,
                        style: GoogleFonts.inter(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700)),
                  ),
                Text("Tekrar İlerlemesi",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: q.planlananTekrarlar.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final date = q.planlananTekrarlar[index];
                      final isDone = index < q.tamamlananTekrarlar.length;
                      return _buildDateChip(date, isDone, index + 1, () {
                        if (isDone) {
                          _undoMark(q.id);
                        } else if (index == q.tamamlananTekrarlar.length) {
                          _markDone(q.id);
                        }
                      });
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusChip(int done, int total) {
    bool isCompleted = done == total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.emeraldColor.withValues(alpha: 0.1)
            : AppTheme.amberColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isCompleted ? AppTheme.emeraldColor : AppTheme.amberColor)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        isCompleted ? "Tamamlandı" : "$done/$total",
        style: GoogleFonts.inter(
            color: isCompleted ? AppTheme.emeraldColor : AppTheme.amberColor,
            fontWeight: FontWeight.bold,
            fontSize: 12),
      ),
    );
  }

  Widget _buildDateChip(
      DateTime date, bool isDone, int index, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDone
              ? AppTheme.emeraldColor
              : (DateTime.now().isAfter(date)
                  ? AppTheme.roseColor.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? AppTheme.emeraldColor
                : (DateTime.now().isAfter(date)
                    ? AppTheme.roseColor.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.2)),
          ),
          boxShadow: isDone
              ? [
                  BoxShadow(
                      color: AppTheme.emeraldColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Tekrar $index",
                style: TextStyle(
                    fontSize: 10,
                    color: isDone ? Colors.white70 : Colors.grey)),
            Text("${date.day}.${date.month}",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDone ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  void _showFullImage(String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(
          child: Hero(
            tag: url,
            child: InteractiveViewer(child: Image.network(url)),
          ),
        ),
      ),
    ));
  }

  // ================= TAB 2: ADD =================
  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(24),
            radius: 32,
            opacity: 0.05,
            borderColor: Colors.white.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Picker Area
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark.withOpacity(0.95),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(32)),
                                border: Border(
                                    top: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.1))),
                              ),
                              child: SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      "Fotoğraf Kaynağı",
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildImageSourceCard(
                                              context,
                                              "Kamera",
                                              Icons.camera_alt_rounded,
                                              ImageSource.camera, [
                                            AppTheme.primaryColor,
                                            AppTheme.secondaryColor
                                          ]),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildImageSourceCard(
                                              context,
                                              "Galeri",
                                              Icons.photo_library_rounded,
                                              ImageSource.gallery, [
                                            AppTheme.emeraldColor,
                                            Colors.teal
                                          ]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ));
                  },
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: _selectedImage != null
                              ? AppTheme.primaryColor
                              : Colors.white.withValues(alpha: 0.1),
                          width: 2),
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_rounded,
                                    size: 32, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(height: 16),
                              Text("Soru Fotoğrafı Ekle",
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("Kamera veya Galeriden",
                                  style: GoogleFonts.inter(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child:
                                Image.file(_selectedImage!, fit: BoxFit.cover)),
                  ),
                ),
                const SizedBox(height: 24),

                // Fields
                _buildDropdownField(
                    label: "Ders Seçin",
                    value: _secilenDers,
                    items: getTumDersler(),
                    icon: Icons.book_rounded,
                    onChanged: (val) => setState(() {
                          _secilenDers = val;
                          _secilenKonu = null;
                        })),

                const SizedBox(height: 16),

                _buildDropdownField(
                    label: "Konu Seçin",
                    value: _secilenKonu,
                    items: _secilenDers == null
                        ? []
                        : getKonularForDers(_secilenDers!),
                    icon: Icons.topic_rounded,
                    onChanged: (val) => setState(() => _secilenKonu = val)),

                const SizedBox(height: 16),

                TextField(
                  controller: _notController,
                  style: GoogleFonts.inter(color: Colors.white),
                  maxLines: 2,
                  decoration: _inputDeco("Notlar", Icons.note_alt_rounded),
                ),

                const SizedBox(height: 32),

                // Strategy Header
                Row(
                  children: [
                    const Icon(Icons.repeat_rounded,
                        color: AppTheme.secondaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text("Tekrar Planı Seç",
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),

                _buildStrategyOption(ReviewStrategy.ebbinghaus, "Ebbinghaus",
                    "Bilimsel (1-3-7-30)"),
                _buildStrategyOption(
                    ReviewStrategy.weekend, "Haftasonu", "Cumartesi - Pazar"),
                _buildStrategyOption(
                    ReviewStrategy.custom, "Özel Plan", "Tarihleri kendin seç"),

                if (_selectedStrategy == ReviewStrategy.custom) ...[
                  const SizedBox(height: 20),
                  _buildCustomDateSelector(),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded),
                              const SizedBox(width: 10),
                              Text("SORUYU KAYDET",
                                  style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
                            ],
                          ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          isExpanded: true, // Fix overflow
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          dropdownColor: const Color(0xFF1E1E2C),
          iconEnabledColor: Colors.white54,
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w500),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1), // Ensure text doesn't break layout
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCustomDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tekrar Sayısı:",
                  style: GoogleFonts.inter(color: Colors.white70)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<int>(
                  value: _targetRepeatCount,
                  dropdownColor: const Color(0xFF1E1E2C),
                  underline: const SizedBox(),
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: List.generate(7, (index) => index + 1)
                      .map((i) => DropdownMenuItem(value: i, child: Text("$i")))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _targetRepeatCount = v!;
                    if (_customDates.length > _targetRepeatCount)
                      _customDates =
                          _customDates.sublist(0, _targetRepeatCount);
                  }),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: [
              ..._customDates.map((d) => Chip(
                    label: Text("${d.day}/${d.month}"),
                    labelStyle: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold),
                    onDeleted: () => setState(() => _customDates.remove(d)),
                    deleteIconColor: AppTheme.primaryColor,
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    side: BorderSide(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  )),
              if (_customDates.length < _targetRepeatCount)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text("Tarih Ekle"),
                  labelStyle: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w500),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  onPressed: _selectCustomDate,
                )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStrategyOption(
      ReviewStrategy strategy, String title, String subtitle) {
    bool selected = _selectedStrategy == strategy;
    return GestureDetector(
      onTap: () => setState(() => _selectedStrategy = strategy),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : Colors.white.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryColor
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? Icons.auto_awesome : Icons.circle_outlined,
                color: selected ? Colors.white : Colors.white24,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color:
                              selected ? AppTheme.primaryColor : Colors.white)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white54)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.white54),
      prefixIcon: Icon(icon, size: 20, color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Logic Helpers
  Future<void> _kaydet() async {
    // Keep original logic, just UI modernized
    if (_user == null) return;
    if (_secilenDers == null ||
        _secilenKonu == null ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Eksik bilgi girdiniz (Ders, Konu veya Fotoğraf)")));
      return;
    }
    if (_selectedStrategy == ReviewStrategy.custom &&
        _customDates.length != _targetRepeatCount) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$_targetRepeatCount tarih seçmelisiniz.")));
      return;
    }

    setState(() => _isUploading = true);
    try {
      await _service.addQuestion(
        userId: _user!.uid,
        ders: _secilenDers!,
        konu: _secilenKonu!,
        notlar: _notController.text,
        imageFile: _selectedImage,
        strategy: _selectedStrategy,
        customRepeatCount: _selectedStrategy == ReviewStrategy.custom
            ? null
            : _targetRepeatCount,
        customDates:
            _selectedStrategy == ReviewStrategy.custom ? _customDates : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Kaydedildi!"), backgroundColor: Colors.green));
        setState(() {
          _secilenDers = null;
          _secilenKonu = null;
          _notController.clear();
          _selectedImage = null;
          _customDates = [];
          _isUploading = false;
        });
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _selectCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
        context: context,
        initialDate: now.add(const Duration(days: 1)),
        firstDate: now,
        lastDate: DateTime(2027),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primaryColor,
                onPrimary: Colors.white,
                surface: AppTheme.surfaceDark,
                onSurface: Colors.white,
              ),
              dialogTheme:
                  DialogThemeData(backgroundColor: AppTheme.surfaceDark),
            ),
            child: child!,
          );
        });
    if (picked != null && !_customDates.contains(picked)) {
      setState(() {
        _customDates.add(picked);
      });
    }
  }

  Widget _buildImageSourceCard(BuildContext context, String title,
      IconData icon, ImageSource source, List<Color> gradientColors) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                gradientColors.map((c) => c.withValues(alpha: 0.2)).toList(),
          ),
          border: Border.all(
            color: gradientColors.first.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: gradientColors.first),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markDone(String qId) async {
    await _service.markReviewDone(_user!.uid, qId);
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Tamamlandı!")));
  }

  Future<void> _undoMark(String qId) async {
    await _service.undoReview(_user!.uid, qId);
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Geri alındı.")));
  }

  List<String> getTumDersler() {
    final Set<String> dersler = {};
    dersler.addAll(tytKonulari.keys);
    dersler.addAll(aytMufredati.keys);
    return dersler.toList();
  }

  List<String> getKonularForDers(String ders) {
    if (tytKonulari.containsKey(ders)) return tytKonulari[ders]!;
    if (aytMufredati.containsKey(ders)) return aytMufredati[ders]!;
    return [];
  }
}
