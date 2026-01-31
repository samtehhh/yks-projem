import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/sabitler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'glass_card.dart';

class TekrarDetayDialog extends StatefulWidget {
  final Function(String, String?, String, String, List<DateTime>, String)
      onKaydet;
  final VoidCallback onIptal;
  final String dersAdi;

  const TekrarDetayDialog(
      {super.key,
      required this.onKaydet,
      required this.onIptal,
      required this.dersAdi});

  @override
  State<TekrarDetayDialog> createState() => _TekrarDetayDialogState();
}

class _TekrarDetayDialogState extends State<TekrarDetayDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _secilenKaynak;
  String? _tekrarSistemi = "Ebbinghaus"; // Default selection
  final TextEditingController _detayController = TextEditingController();
  final TextEditingController _manuelKaynakController = TextEditingController();

  // Custom Date (for "Özel")
  DateTime _secilenTarih = DateTime.now().add(const Duration(days: 1));

  // Weekend selection
  String _haftasonuGun = "Cumartesi";
  final TextEditingController _tekrarSayisiController =
      TextEditingController(text: "3");
  final TextEditingController _soruSayisiController =
      TextEditingController(); // Added missing controller
  final String _ozelEklemeSecenegi =
      "Farklı Kaynak Ekle"; // Renamed and removed emoji

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _getUygunKaynaklar() {
    String ders = widget.dersAdi;
    List<String> kaynaklar = [];

    // 1. Exact Match
    if (dersBazliKaynaklar.containsKey(ders)) {
      kaynaklar = List.from(dersBazliKaynaklar[ders]!);
    }
    // 2. Fuzzy Match
    else {
      String slug = ders.toLowerCase();
      String? key;
      if (slug.contains('matematik'))
        key = ders.contains('AYT') ? 'AYT Matematik' : 'TYT Matematik';
      else if (slug.contains('geometri'))
        key = ders.contains('AYT') ? 'AYT Geometri' : 'TYT Geometri';
      else if (slug.contains('fizik'))
        key = ders.contains('AYT') ? 'AYT Fizik' : 'TYT Fizik';
      else if (slug.contains('kimya'))
        key = ders.contains('AYT') ? 'AYT Kimya' : 'TYT Kimya';
      else if (slug.contains('biyoloji'))
        key = ders.contains('AYT') ? 'AYT Biyoloji' : 'TYT Biyoloji';
      else if (slug.contains('türkçe') || slug.contains('edebiyat'))
        key = ders.contains('AYT') ? 'AYT Edebiyat' : 'TYT Türkçe';
      else if (slug.contains('tarih'))
        key = ders.contains('AYT') ? 'AYT Tarih' : 'TYT Tarih';
      else if (slug.contains('coğrafya'))
        key = ders.contains('AYT') ? 'AYT Coğrafya' : 'TYT Coğrafya';
      else if (slug.contains('felsefe'))
        key = ders.contains('AYT') ? 'AYT Felsefe Grubu' : 'TYT Felsefe';
      else if (slug.contains('din'))
        key = ders.contains('AYT') ? 'AYT Din' : 'TYT Din';
      else if (slug.contains('ydt') || slug.contains('ingilizce'))
        key = 'YDT İngilizce';

      if (key != null && dersBazliKaynaklar.containsKey(key)) {
        kaynaklar = List.from(dersBazliKaynaklar[key]!);
      }
    }

    // 3. Fallback
    if (kaynaklar.isEmpty) {
      kaynaklar = List.from(dersBazliKaynaklar['Genel'] ?? []);
    }

    kaynaklar.add(_ozelEklemeSecenegi);
    return kaynaklar;
  }

  Future<void> _tarihSec(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _secilenTarih,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceDark,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppTheme.surfaceDark),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _secilenTarih) {
      setState(() {
        _secilenTarih = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> aktifListe = _getUygunKaynaklar();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: 32,
        opacity: 0.1,
        borderColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05))),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.dersAdi.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tekrar Planla",
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // TABS
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(22),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  dividerColor: Colors.transparent,
                  onTap: (index) {
                    setState(() {}); // Rebuild to update button logic if needed
                  },
                  indicatorSize: TabBarIndicatorSize
                      .tab, // Make indicator fill the tab width
                  tabs: const [
                    Tab(text: "SÖZEL Tekrar"),
                    Tab(text: "SORU Çözümü"),
                  ],
                ),
              ),

              // SCROLLABLE CONTENT
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Prevent swiping to avoid conflicts
                  children: [
                    // TAB 1: SÖZEL (Just System Selection)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Tekrar Sistemi"),
                          const SizedBox(height: 12),
                          _buildSystemSelector(),
                          const SizedBox(height: 24),
                          _buildSystemDetails(),
                        ],
                      ),
                    ),

                    // TAB 2: AKTİF (Source + System)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Kaynak Seçimi"),
                          const SizedBox(height: 12),
                          _buildSourceGrid(aktifListe),
                          if (_secilenKaynak == _ozelEklemeSecenegi) ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _manuelKaynakController,
                              label: "Kaynak Adı",
                              icon: Icons.edit_rounded,
                            ),
                          ],
                          const SizedBox(height: 16),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _detayController,
                                  label: "Detay (Sayfa / Test No)",
                                  icon: Icons.description_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _soruSayisiController,
                                  label: "Soru Sayısı",
                                  icon: Icons.help_outline_rounded,
                                  isNumber: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader("Tekrar Sistemi"),
                          const SizedBox(height: 12),
                          _buildSystemSelector(),
                          const SizedBox(height: 24),
                          _buildSystemDetails(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // FOOTER ACTIONS
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05))),
                  color: Colors.black12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: widget.onIptal,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.white54,
                        ),
                        child: Text("İptal",
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.secondaryColor,
                              AppTheme.primaryColor
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _onPlanlaPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            "PLANI OLUŞTUR",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: AppTheme.secondaryColor),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceGrid(List<String> sources) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        itemCount: sources.length,
        separatorBuilder: (c, i) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final source = sources[index];
          final isSelected = _secilenKaynak == source;
          final isSpecialOption = source == _ozelEklemeSecenegi;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _secilenKaynak = source),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : (isSpecialOption
                          ? Colors.amber.withValues(alpha: 0.05)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.5)
                        : (isSpecialOption
                            ? Colors.amber.withValues(alpha: 0.2)
                            : Colors.transparent),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSpecialOption
                          ? Icons.add_circle_outline_rounded
                          : (isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined),
                      size: 18,
                      color: isSpecialOption
                          ? Colors.amber
                          : (isSelected
                              ? AppTheme.primaryColor
                              : Colors.white30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        source,
                        style: GoogleFonts.inter(
                          color: isSelected
                              ? Colors.white
                              : (isSpecialOption
                                  ? Colors.amberAccent
                                  : Colors.white70),
                          fontWeight: (isSelected || isSpecialOption)
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemSelector() {
    return Row(
      children: [
        Expanded(
            child: _buildSystemOption("Ebbinghaus", Icons.auto_graph_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _buildSystemOption("Haftasonu", Icons.weekend_rounded)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildSystemOption("Özel", Icons.edit_calendar_rounded)),
      ],
    );
  }

  Widget _buildSystemOption(String id, IconData icon) {
    final isSelected = _tekrarSistemi == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tekrarSistemi = id;
          if (id == 'Ebbinghaus') _tekrarSayisiController.text = "4";
          if (id == 'Haftasonu') _tekrarSayisiController.text = "3";
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 0 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white54,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              id,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemDetails() {
    if (_tekrarSistemi == 'Ebbinghaus') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Otomatik Zamanlama",
                style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimelineStep("1", "Gün"),
                _buildTimelineArrow(),
                _buildTimelineStep("7", "Gün"),
                _buildTimelineArrow(),
                _buildTimelineStep("14", "Gün"),
                _buildTimelineArrow(),
                _buildTimelineStep("30", "Gün"),
              ],
            ),
          ],
        ),
      );
    } else if (_tekrarSistemi == 'Haftasonu') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildWeekendToggle("Cumartesi")),
              const SizedBox(width: 8),
              Expanded(child: _buildWeekendToggle("Pazar")),
            ],
          ),
          const SizedBox(height: 16),
          _buildNumberInput("Kaç Hafta?", _tekrarSayisiController),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _tarihSec(context),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppTheme.secondaryColor, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd.MM.yyyy').format(_secilenTarih),
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildNumberInput("Sayı", _tekrarSayisiController),
          ),
        ],
      );
    }
  }

  Widget _buildTimelineStep(String num, String text) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor),
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: GoogleFonts.outfit(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(text,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildTimelineArrow() {
    return Container(
      width: 20,
      height: 1,
      color: Colors.white12,
    );
  }

  Widget _buildWeekendToggle(String day) {
    final isSelected = _haftasonuGun == day;
    return GestureDetector(
      onTap: () => setState(() => _haftasonuGun = day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05)),
        ),
        alignment: Alignment.center,
        child: Text(
          day,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        isDense: true,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildNumberInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      decoration: InputDecoration(
        labelText: label.isEmpty ? null : label,
        labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  void _onPlanlaPressed() {
    // Current tab index
    // 0 -> Sözel (No Source), 1 -> Aktif (Requires Source)
    bool isAktif = _tabController.index == 1;

    if (isAktif && _secilenKaynak == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("Lütfen bir kaynak seçin.",
            style: GoogleFonts.inter(color: Colors.white)),
      ));
      return;
    }

    String finalKaynak = "";
    if (isAktif) {
      if (_secilenKaynak == _ozelEklemeSecenegi) {
        if (_manuelKaynakController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Lütfen kaynak adını yazın.",
                style: GoogleFonts.inter(color: Colors.white)),
          ));
          return;
        }
        finalKaynak = _manuelKaynakController.text.trim();
      } else {
        finalKaynak = _secilenKaynak!;
      }
    } else {
      finalKaynak = "Konu Tekrarı"; // Default for Sözel
    }

    // Prepare Date List
    List<DateTime> dateList = [];
    DateTime now = DateTime.now();
    int count = int.tryParse(_tekrarSayisiController.text) ?? 3;

    if (_tekrarSistemi == 'Ebbinghaus') {
      dateList.add(now.add(const Duration(days: 1)));
      dateList.add(now.add(const Duration(days: 7)));
      dateList.add(now.add(const Duration(days: 14)));
      dateList.add(now.add(const Duration(days: 30)));
      count = 4; // visual override
    } else if (_tekrarSistemi == 'Haftasonu') {
      int targetWeekday =
          _haftasonuGun == "Cumartesi" ? DateTime.saturday : DateTime.sunday;
      DateTime runner = now;
      while (runner.weekday != targetWeekday) {
        runner = runner.add(const Duration(days: 1));
      }
      // If today is target, decide if include today. Let's include today for simplicity.
      for (int i = 0; i < count; i++) {
        dateList.add(runner.add(Duration(days: i * 7)));
      }
    } else {
      dateList.add(_secilenTarih);
    }

    widget.onKaydet(
      finalKaynak,
      _detayController.text,
      isAktif ? "Aktif" : "Sözel",
      _tekrarSistemi!,
      dateList,
      count.toString(),
    );
  }
}
