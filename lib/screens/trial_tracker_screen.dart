import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:google_fonts/google_fonts.dart';

import '../models/trial_exam_model.dart';
import '../services/trial_service.dart';
import '../data/sabitler.dart';

import '../data/advice_data.dart';
import '../data/breakdown_data.dart';
import '../widgets/glass_card.dart';
import '../widgets/topic_card.dart';
import '../theme.dart';

class TrialTrackerScreen extends StatefulWidget {
  const TrialTrackerScreen({super.key});

  @override
  State<TrialTrackerScreen> createState() => _TrialTrackerScreenState();
}

class _TrialTrackerScreenState extends State<TrialTrackerScreen> {
  int _selectedIndex = 0;
  TrialExam? _trialToEdit; // For Edit Mode
  bool _usePremiumUI = true; // Premium UI Toggle

  // Function to switch tab, potentially entering edit mode
  void _jumpToTab(int index, {TrialExam? editTrial}) {
    setState(() {
      _selectedIndex = index;
      _trialToEdit = editTrial;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pass callback to History tab, and editing state to Add tab
    final List<Widget> tabs = [
      const DashboardTab(),
      DenemeGecmisiTab(
        onEdit: (t) => _jumpToTab(3, editTrial: t),
        usePremiumUI: _usePremiumUI,
        onToggle: (v) => setState(() => _usePremiumUI = v),
      ),
      const AnalizTab(),
      DenemeEkleTab(
          trialToEdit: _trialToEdit,
          onSaved: () => setState(() => _trialToEdit = null)),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          AppTheme.meshBackground(),
          SafeArea(
            child: tabs[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.8),
          border: Border(
              top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1), width: 1.5)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (idx) {
            setState(() {
              _selectedIndex = idx;
              if (idx != 3) _trialToEdit = null;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppTheme.primaryColor.withOpacity(0.1),
          destinations: [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined, color: AppTheme.textSub),
                selectedIcon:
                    Icon(Icons.dashboard_rounded, color: AppTheme.primaryColor),
                label: 'Panel'),
            NavigationDestination(
                icon: Icon(Icons.history_rounded, color: AppTheme.textSub),
                selectedIcon:
                    Icon(Icons.history_rounded, color: AppTheme.primaryColor),
                label: 'Geçmiş'),
            NavigationDestination(
                icon: Icon(Icons.analytics_outlined, color: AppTheme.textSub),
                selectedIcon:
                    Icon(Icons.analytics_rounded, color: AppTheme.primaryColor),
                label: 'Analiz'),
            NavigationDestination(
                icon: Icon(Icons.add_circle_outline, color: AppTheme.textSub),
                selectedIcon: Icon(Icons.add_circle_rounded,
                    color: AppTheme.primaryColor),
                label: 'Ekle'),
          ],
        ),
      ),
    );
  }
}

// ================= TAB 1: DASHBOARD (LEAD DEV SIMPLIFIED) =================
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final TrialService _service = TrialService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Expert Logic Filters
  String _mainFilter = "Genel"; // Genel Deneme vs Branş Deneme
  String _areaFilter = "TYT"; // TYT vs AYT
  String _specificFilter =
      "Genel - Tüm Dersler"; // "Genel - Tüm Dersler" (Total) or Specific Lesson like "Matematik"
  String? _selectedTrack; // Student Track for AYT filtering

  bool _isBreakdownActive = false; // Drill-Down Toggle State

  @override
  void initState() {
    super.initState();
    // Fetch User's Track (Alan) from Profile
    FirebaseDatabase.instance
        .ref("users/${FirebaseAuth.instance.currentUser!.uid}/profil/alan")
        .get()
        .then((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _selectedTrack = snapshot.value.toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TrialExam>>(
      stream: _service.getTrialsStream(_uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent));
        List<TrialExam> allTrials = snapshot.data!;

        // --- LOGIC: STRICT SEPARATION ---
        List<TrialExam> filteredTrials = allTrials.where((t) {
          bool areaMatch = t.area.trim() == _areaFilter.trim();
          bool typeMatch = _mainFilter == "Genel"
              ? (t.type.trim() == "Genel")
              : (t.type.trim() == "Branş" || t.type.trim() == "Genel");

          if (!areaMatch || !typeMatch) return false;

          // FIX: Filter unrelated branch trials
          // e.g. If viewing "Math", don't include "Turkish" branch trials (which have 0 math net)
          if (_mainFilter == "Branş" && !_specificFilter.contains("Genel")) {
            return _isTrialRelevant(t, _specificFilter);
          }

          return true;
        }).toList();

        // Sort by date old -> new for chart
        filteredTrials.sort((a, b) => a.date.compareTo(b.date));

        // Calculate Stats
        double avgNet =
            _calculateStats(filteredTrials, _specificFilter, isMax: false);
        double maxNet =
            _calculateStats(filteredTrials, _specificFilter, isMax: true);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSimplifiedHeader(), // 2. Nav Simplification
              const SizedBox(height: 20),

              // GENEL / BRANŞ TOGGLE + TRACK INFO
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ["Genel", "Branş"].map((e) {
                        bool isSelected = _mainFilter == e;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _mainFilter = e;
                            if (e == "Genel") {
                              _specificFilter = "Genel - Tüm Dersler";
                            } else {
                              var options = _getLessonOptions(_areaFilter);
                              _specificFilter = options.isNotEmpty
                                  ? options.first
                                  : "Genel - Tüm Dersler";
                            }
                            _isBreakdownActive = false;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Text(
                              e,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70, // Whiter text
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_areaFilter == "AYT") ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: SizedBox(), // Space filler
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 15),

              // Area & Lesson Filter
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Fix width
                      children: ["TYT", "AYT"].map((e) {
                        bool isSelected = _areaFilter == e;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _areaFilter = e;
                            if (e == "TYT") _selectedTrack = null;
                            if (_mainFilter == "Genel") {
                              _specificFilter = "Genel - Tüm Dersler";
                            } else {
                              var options = _getLessonOptions(e);
                              _specificFilter = options.isNotEmpty
                                  ? options.first
                                  : "Genel - Tüm Dersler";
                            }
                            _isBreakdownActive = false;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.secondaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              e,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSub,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Lesson Dropdown
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      radius: 16,
                      opacity: 0.1, // Reduced opacity
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _specificFilter,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(20),
                          dropdownColor:
                              const Color(0xFF1E1E2C), // Dark dropdown
                          items: _getLessonOptions(_areaFilter)
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: GoogleFonts.inter(
                                        color: Colors.white, // White text
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  )))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _specificFilter = v!;
                            _isBreakdownActive = false;
                          }),
                          icon: const Icon(Icons.expand_more_rounded,
                              color: AppTheme.secondaryColor),
                        ),
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 15),

              // UNIVERSAL DRILL-DOWN TOGGLE
              if (_hasBreakdown()) _buildBreakdownSwitch(),

              const SizedBox(height: 25),

              // Summary Cards
              Row(
                children: [
                  Expanded(
                      child: _buildPremiumSummaryCard(
                          "Ortalama",
                          avgNet.toStringAsFixed(1),
                          "Net",
                          AppTheme.accentColor)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildPremiumSummaryCard(
                          "En Yüksek",
                          maxNet.toStringAsFixed(1),
                          "Net",
                          AppTheme.secondaryColor)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildPremiumSummaryCard(
                          "Deneme",
                          "${filteredTrials.length}",
                          "Adet",
                          AppTheme.primaryColor)),
                ],
              ),

              const SizedBox(height: 30),

              // 3. Deep Chart Implementation (Publisher Tooltip)
              Text("İlerleme Analizi",
                  style: GoogleFonts.outfit(
                      color: AppTheme.textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // ANIMATED CHART SWITCHER
              AnimatedCrossFade(
                firstChild: Container(
                  height: 320, // Match breakdown height roughly
                  padding: const EdgeInsets.fromLTRB(10, 25, 15, 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: _buildExpertChart(filteredTrials, _specificFilter),
                ),
                secondChild: _buildBreakdownView(filteredTrials),
                crossFadeState: _isBreakdownActive
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 600),
                sizeCurve: Curves.easeInOutBack,
              ),
            ],
          ),
        );
      },
    );
  }

  // Simplified Header Logic
  Widget _buildSimplifiedHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              const Icon(Icons.insights_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Performans Analizi",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMain,
              ),
            ),
            Text(
              _mainFilter == "Branş"
                  ? "Uzman Modu Aktif ✨"
                  : "Genel Durum Özeti",
              style: GoogleFonts.inter(
                color: AppTheme.textSub,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildPremiumSummaryCard(
      String title, String value, String unit, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      radius: 20,
      opacity: 0.05, // Crystal clear
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(title,
            style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.4), blurRadius: 10)
                    ]))),
        const SizedBox(height: 2),
        Text(unit,
            style: GoogleFonts.inter(
                color: Colors.white30,
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // NEW: Modern Toggle for Breakdown
  Widget _buildBreakdownSwitch() {
    return GestureDetector(
      onTap: () => setState(() => _isBreakdownActive = !_isBreakdownActive),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        radius: 20,
        opacity: 0.05, // Crystal Clear
        borderColor: _isBreakdownActive
            ? AppTheme.secondaryColor.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Alan Parçala",
                style: GoogleFonts.outfit(
                    color: _isBreakdownActive
                        ? AppTheme.secondaryColor
                        : AppTheme.textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _isBreakdownActive
                      ? AppTheme.secondaryColor
                      : Colors.black.withValues(alpha: 0.3)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: _isBreakdownActive
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4) // Legacy shadow fine here
                      ]),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper to check breakdown availability
  bool _hasBreakdown() {
    return breakdownMap.containsKey(_specificFilter);
  }

  // NEW: Breakdown View (Multiple Mini Charts)
  // NEW: Breakdown View (Multiple Mini Charts)
  Widget _buildBreakdownView(List<TrialExam> trials) {
    List<String> subLessons = breakdownMap[_specificFilter] ?? [];

    if (subLessons.isEmpty) return const SizedBox();

    return Column(
      children: subLessons.map((sub) {
        // FILTER: Only show trials that actually have data for this specific sub-lesson
        List<TrialExam> relevantTrials = trials.where((t) {
          if (t.lessonResults == null) return false;

          // 1. Basic Existence Check (Robust)
          // For Branch Trials, strictly check if the Main Lesson matches the Category
          if (t.type == "Branş" && t.lesson != null) {
            String branch = t.lesson!.toLowerCase();
            String category = sub.toLowerCase();

            // FIX: Strip common prefixes to prevent "TYT Matematik" matching "TYT Türkçe"
            List<String> ignored = ["tyt", "ayt", "genel", "branş"];

            // Clean Branch Name
            String cleanBranch = branch;
            for (var i in ignored)
              cleanBranch = cleanBranch.replaceAll(i, "").trim();

            // Clean Category Name
            String cleanCategory = category;
            for (var i in ignored)
              cleanCategory = cleanCategory.replaceAll(i, "").trim();

            bool match = false;

            // 1. Direct Match (e.g. "Matematik" == "Matematik")
            if (cleanCategory.contains(cleanBranch) ||
                cleanBranch.contains(cleanCategory)) match = true;

            // 2. Sub-Branch Match (e.g. "Fen" -> "Fizik")
            if (cleanCategory == "fen bilimleri" || cleanCategory == "fen") {
              if (cleanBranch.contains("fizik") ||
                  cleanBranch.contains("kimya") ||
                  cleanBranch.contains("biyoloji")) match = true;
            }
            if (cleanCategory == "sosyal bilimler" ||
                cleanCategory == "sosyal") {
              if (cleanBranch.contains("tarih") ||
                  cleanBranch.contains("coğrafya") ||
                  cleanBranch.contains("felsefe") ||
                  cleanBranch.contains("din")) match = true;
            }
            if (cleanCategory == "sosyal 1") {
              if (cleanBranch.contains("edebiyat") ||
                  cleanBranch.contains("tarih-1") ||
                  cleanBranch.contains("coğrafya-1")) match = true;
            }
            if (cleanCategory == "sosyal 2") {
              if (cleanBranch.contains("tarih-2") ||
                  cleanBranch.contains("coğrafya-2")) match = true;
            }

            // 3. Reverse Sub-Branch (e.g. Math -> Geo)
            if ((cleanBranch == "matematik" ||
                    cleanBranch == "sadece matematik") &&
                cleanCategory == "geometri") match = true;

            if (!match) return false;
          }

          // Just like _isTrialRelevant, we need to handle key variations
          bool keyExists = false;
          List<String> validSubKeys = _getBranchFilterKeys(sub);
          for (var k in validSubKeys) {
            if (t.lessonResults!.containsKey(k)) {
              keyExists = true;
              break;
            }
            if (t.lessonResults!.keys
                .any((ek) => ek.toLowerCase() == k.toLowerCase())) {
              keyExists = true;
              break;
            }
          }
          if (!keyExists) return false;

          // 2. SEMANTIC CHECK: Is this a "ghost zero" from Aggregate Mode?
          // If Aggregate Net > Sum of Detailed Components, then Detail is invalid/missing.
          bool isAggregateDominant = false;

          // Helper for inline calculation (same as _getNet logic)
          double getMax(List<String> keys) {
            double maxVal = 0;
            for (var k in keys) {
              if (t.lessonResults!.containsKey(k) &&
                  t.lessonResults![k]!.net > maxVal)
                maxVal = t.lessonResults![k]!.net;
              // Fuzzy fallback
              var matches = t.lessonResults!.keys
                  .where((ek) => ek.toLowerCase() == k.toLowerCase());
              for (var m in matches) {
                if (t.lessonResults![m]!.net > maxVal)
                  maxVal = t.lessonResults![m]!.net;
              }
            }
            return maxVal;
          }

          String category = _specificFilter; // e.g. "AYT Matematik"

          if (category == "TYT Matematik" || category == "Matematik") {
            double agg = getMax(["Matematik", "TYT Matematik"]);
            double det = getMax(["Sadece Matematik", "TYT Sadece Matematik"]) +
                getMax(["Geometri", "TYT Geometri"]);
            if (agg > det + 0.1) isAggregateDominant = true;
          } else if (category == "TYT Fen" ||
              category == "Fen" ||
              category == "Fen Bilimleri") {
            double agg = getMax(["Fen", "Fen Bilimleri", "TYT Fen"]);
            double det = getMax(["Fizik", "TYT Fizik"]) +
                getMax(["Kimya", "TYT Kimya"]) +
                getMax(["Biyoloji", "TYT Biyoloji"]);
            if (agg > det + 0.1) isAggregateDominant = true;
          } else if (category == "AYT Matematik") {
            double agg = getMax(["Matematik (AYT)", "AYT Matematik"]);
            double det =
                getMax(["Sadece Matematik (AYT)", "AYT Sadece Matematik"]) +
                    getMax(["Geometri (AYT)", "AYT Geometri"]);
            if (agg > det + 0.1) isAggregateDominant = true;
          } else if (category == "AYT Fen Bilimleri" || category == "AYT Fen") {
            double agg = getMax(["Fen Bilimleri", "AYT Fen Bilimleri"]);
            double det = getMax(["AYT Fizik", "Fizik"]) +
                getMax(["AYT Kimya", "Kimya"]) +
                getMax(["AYT Biyoloji", "Biyoloji"]);
            if (agg > det + 0.1) isAggregateDominant = true;
          }

          if (isAggregateDominant)
            return false; // Skip this trial for breakdown

          return true;
        }).toList();

        if (relevantTrials.isEmpty) return const SizedBox();

        // Color Logic based on subject
        Color col;
        if (sub.contains("Matematik") ||
            sub.contains("Fizik") ||
            sub.contains("Tarih"))
          col = const Color(0xFFFF7043); // Orange
        else if (sub.contains("Kimya") ||
            sub.contains("Coğrafya") ||
            sub.contains("Edebiyat"))
          col = const Color(0xFF42A5F5); // Blue
        else if (sub.contains("Biyoloji") ||
            sub.contains("Felsefe") ||
            sub.contains("Geometri"))
          col = const Color(0xFF66BB6A); // Green
        else
          col = const Color(0xFFAB47BC); // Purple (Din, etc)

        // Calculate latest net for badge (Using filtered trials)
        double latestNet = 0;
        if (relevantTrials.isNotEmpty)
          latestNet = _getNet(relevantTrials.last, sub);

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          height: 220,
          child: Stack(
            children: [
              // GLASSMORPHIC CARD
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: col.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 45, 40, 10),
                  child:
                      _buildExpertChart(relevantTrials, sub, customColor: col),
                ),
              ),

              // LABEL (Top Left)
              Positioned(
                top: 18,
                left: 20,
                child: Text(
                    sub
                        .replaceAll("Sadece ", "")
                        .replaceAll(" (AYT)", "")
                        .replaceAll("AYT ", ""),
                    style: GoogleFonts.outfit(
                        color: AppTheme.textMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),

              // FLOATING BADGE (Top Right - Chart End)
              Positioned(
                top: 16,
                right: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: col.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: col.withOpacity(0.2))),
                  child: Text("${latestNet.toStringAsFixed(1)} Net",
                      style: GoogleFonts.inter(
                          color: col,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpertChart(List<TrialExam> trials, String filterKey,
      {Color? customColor}) {
    if (trials.isEmpty)
      return const Center(
          child: Text("Grafik için veri yok",
              style: TextStyle(color: Colors.white54)));

    Color lineColor;
    if (customColor != null) {
      lineColor = customColor;
    } else {
      // Automatic Neon Color Assignment
      if (filterKey.contains("Matematik"))
        lineColor = const Color(0xFF2DD4BF); // Cyber Turquoise
      else if (filterKey.contains("Fizik") || filterKey.contains("Fen"))
        lineColor = const Color(0xFF8B5CF6); // Electric Violet
      else if (filterKey.contains("Kimya"))
        lineColor = const Color(0xFFF472B6); // Neon Pink
      else if (filterKey.contains("Biyoloji"))
        lineColor = const Color(0xFF34D399); // Neon Emerald
      else if (filterKey.contains("Türkçe") || filterKey.contains("Edebiyat"))
        lineColor = const Color(0xFFF97316); // Sunset Orange
      else if (filterKey.contains("Sosyal") || filterKey.contains("Tarih"))
        lineColor = const Color(0xFFFACC15); // Solar Yellow
      else
        lineColor = AppTheme.primaryColor;
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < trials.length; i++) {
      spots.add(FlSpot(i.toDouble(), _getNet(trials[i], filterKey)));
    }

    // Y-Axis Max logic
    double yMax;
    if (filterKey.contains("Genel")) {
      yMax = _areaFilter == "TYT" ? 120 : 80;
    } else {
      String key = filterKey;
      // Resolve Area conflicts for Chart Scaling
      if (_areaFilter == "AYT") {
        if (key == "Matematik") {
          // Special case: AYT Math Group is 40 (30 Mat + 10 Geo)
          // Do not map to 'AYT Matematik' which is 30.
          key = "Matematik";
        } else if (key == "Fizik")
          key = "AYT Fizik";
        else if (key == "Kimya")
          key = "AYT Kimya";
        else if (key == "Biyoloji")
          key = "AYT Biyoloji";
        else if (key == "Din") key = "Din (AYT)";
      }
      if (_areaFilter == "AYT" && (key == "Genel" || key.contains("Genel")))
        yMax = 80; // Safety for names

      // Strict Lookup using updated sabitler.dart
      if (key == "Matematik" ||
          key == "AYT Fen Bilimleri" ||
          key == "Fen Bilimleri") {
        yMax = 40; // Force 40 for Math Group (Both TYT/AYT) or AYT Science
      } else {
        yMax = (maxSoruSayilari[key] ?? maxSoruSayilari[filterKey] ?? 10)
            .toDouble();
      }

      // Validation: If data exceeds regular max (e.g. user entered 50/40), stretch locally
      double currentMaxData =
          spots.map((e) => e.y).fold(0, (p, c) => c > p ? c : p);
      if (currentMaxData > yMax) yMax = currentMaxData + 5;
    }

    // FIX: Use LayoutBuilder to get the exact parent width dynamically
    return LayoutBuilder(builder: (context, constraints) {
      double availableWidth = constraints.maxWidth;

      // If trials < 10, expand to full available width.
      // If trials >= 10, scrollable with fixed item width (42.0).
      double contentWidth = trials.length * 42.0;

      // Final width is at least the available width (to avoid left alignment)
      double finalWidth = (trials.length < 10 || contentWidth < availableWidth)
          ? availableWidth
          : contentWidth;

      return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: finalWidth,
            height: 250, // Fixed height
            padding: const EdgeInsets.fromLTRB(
                10, 24, 24, 0), // Added Top Padding for Labels
            child: LineChart(LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax > 0
                      ? yMax / 4
                      : 10, // Nice intervals (0, 10, 20, 30, 40)
                  getDrawingHorizontalLine: (val) => FlLine(
                      color: Colors.white.withValues(alpha: 0.1),
                      strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                    show: true,
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1, // Show every trial
                            getTitlesWidget: (val, meta) {
                              // FIX: Dedup labels. Only show on exact integers.
                              if (val % 1 != 0) return const SizedBox();

                              int idx = val.toInt();
                              if (idx < 0 || idx >= trials.length)
                                return const SizedBox();
                              return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                      "${trials[idx].date.day}/${trials[idx].date.month}",
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10)));
                            },
                            reservedSize: 30)),
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value == 0 || value == yMax)
                                return Text(value.toInt().toString(),
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 10));
                              return Text(value.toInt().toString(),
                                  style: const TextStyle(
                                      color: Colors.white30, fontSize: 10));
                            },
                            reservedSize: 30))),
                minY: 0,
                maxY: yMax,
                // FIX: Tight Padding (-0.15) to stretch chart to edges aesthetic
                minX: -0.15,
                maxX: trials.length.toDouble() - 1 + 0.15,
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting:
                          true, // FIX: Prevents dipping below 0
                      color: lineColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: lineColor)),
                      belowBarData: BarAreaData(
                          show: true, color: lineColor.withValues(alpha: 0.15)))
                ],
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        fitInsideVertically: true, // Prevents clipping at top
                        fitInsideHorizontally: true,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipColor: (_) => const Color(0xFF16213E),
                        tooltipBorder: BorderSide(color: lineColor),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            int idx = spot.x.toInt();
                            String publisher = (idx >= 0 && idx < trials.length)
                                ? (trials[idx].publisher ?? "Yayın Yok")
                                : "";

                            return LineTooltipItem(
                                "${spot.y.toStringAsFixed(2)} Net\n",
                                TextStyle(
                                    color: lineColor,
                                    fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(
                                      text: publisher,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.normal))
                                ]);
                          }).toList();
                        })))),
          ));
    });
  }

  // Reuse existing helpers...
  List<String> _getLessonOptions(String area) {
    if (_mainFilter == "Genel") {
      return ["Genel - Tüm Dersler"];
    }

    if (area == "TYT") {
      return ["TYT Türkçe", "TYT Matematik", "TYT Fen", "TYT Sosyal"];
    }

    // AYT with track filtering
    if (_selectedTrack != null) {
      if (_selectedTrack!.contains("Sayısal")) {
        return ["AYT Matematik", "AYT Fen Bilimleri"];
      }
      if (_selectedTrack!.contains("Eşit Ağırlık")) {
        return ["AYT Matematik", "AYT Sosyal 1"];
      }
      if (_selectedTrack!.contains("Sözel")) {
        return ["AYT Sosyal 1", "AYT Sosyal 2"];
      }
      if (_selectedTrack!.contains("Dil")) {
        return ["YDT"];
      }
    }

    // Default: All AYT subjects
    return [
      "AYT Matematik",
      "AYT Fen Bilimleri",
      "AYT Sosyal 1",
      "AYT Sosyal 2"
    ];
  }

  // REFACTOR: Central Source of Truth for Key Mapping
  List<String> _getBranchFilterKeys(String filterName) {
    // Normalization
    String normalized = filterName.trim();

    // 1. TYT Mappings
    if (normalized == "TYT Türkçe" || normalized == "Türkçe") {
      return ["Türkçe", "TYT Türkçe"];
    }
    if (normalized == "TYT Matematik" ||
        normalized == "Matematik" ||
        normalized == "Sadece Matematik") {
      return ["Matematik", "TYT Matematik", "Sadece Matematik", "Geometri"];
    }
    if (normalized == "TYT Fen" ||
        normalized == "Fen" ||
        normalized == "Fen Bilimleri") {
      return ["Fen", "Fen Bilimleri", "TYT Fen", "Fizik", "Kimya", "Biyoloji"];
    }
    if (normalized == "TYT Sosyal" || normalized == "Sosyal") {
      return [
        "Sosyal",
        "Sosyal Bilimler",
        "TYT Sosyal",
        "Tarih",
        "Coğrafya",
        "Felsefe",
        "Din"
      ];
    }

    // 2. AYT Mappings
    if (normalized == "AYT Matematik" || normalized == "Matematik (AYT)") {
      return [
        "AYT Matematik",
        "Matematik (AYT)",
        "Sadece Matematik (AYT)",
        "Geometri (AYT)",
        // Fallback for Branch Saved as simple keys
        "Matematik",
        "Matematik (TYT)"
      ];
    }
    if (normalized == "AYT Fen Bilimleri" || normalized == "AYT Fen") {
      return [
        "AYT Fen Bilimleri",
        "Fen Bilimleri",
        // Components
        "AYT Fizik",
        "AYT Kimya",
        "AYT Biyoloji",
        // Fallback simple keys
        "Fizik",
        "Kimya",
        "Biyoloji"
      ];
    }
    if (normalized == "AYT Sosyal 1" ||
        normalized == "Sosyal 1" ||
        normalized == "Ed-Sos-1") {
      return [
        "AYT Sosyal 1",
        "Ed-Sos-1",
        "Sosyal 1",
        "Edebiyat",
        "Tarih-1",
        "Coğrafya-1"
      ];
    }
    if (normalized == "AYT Sosyal 2" ||
        normalized == "Sosyal 2" ||
        normalized == "Sosyal-2") {
      return [
        "AYT Sosyal 2",
        "Sosyal-2",
        "Sosyal 2",
        "Tarih-2",
        "Coğrafya-2",
        "Felsefe Grubu",
        "Din (AYT)",
        "Din" // Fallback
      ];
    }
    if (normalized == "YDT") return ["YDT", "AYT YDT"]; // Add YDT Support

    // Default Fallback: Return itself (for exact matches like 'Fizik')
    return [normalized];
  }

  double _getNet(TrialExam t, String lesson) {
    if (lesson == "Genel - Tüm Deneme" ||
        lesson == "Genel" ||
        lesson == "Genel - Tüm Dersler") return t.totalNet ?? 0;

    if (t.lessonResults == null) return 0;

    // Helper: Find value for any of these keys (Case Insensitive)
    // Returns max found value to be safe against 0 entries
    double findMaxInKeys(List<String> keys) {
      double maxVal = 0;
      for (var k in keys) {
        // Direct
        if (t.lessonResults!.containsKey(k)) {
          if (t.lessonResults![k]!.net > maxVal)
            maxVal = t.lessonResults![k]!.net;
        }
        // Fuzzy
        var match = t.lessonResults!.keys.firstWhere(
            (key) => key.toLowerCase() == k.toLowerCase(),
            orElse: () => "");
        if (match.isNotEmpty) {
          if (t.lessonResults![match]!.net > maxVal)
            maxVal = t.lessonResults![match]!.net;
        }
      }
      return maxVal;
    }

    // 1. TYT Fen (Components vs Aggregate)
    if (lesson == "TYT Fen" || lesson == "Fen" || lesson == "Fen Bilimleri") {
      double agg =
          findMaxInKeys(["Fen", "Fen Bilimleri", "TYT Fen"]); // Check all aggs
      double det = findMaxInKeys(["Fizik", "TYT Fizik"]) +
          findMaxInKeys(["Kimya", "TYT Kimya"]) +
          findMaxInKeys(["Biyoloji", "TYT Biyoloji"]);
      return det > agg ? det : agg;
    }

    // 2. TYT Sosyal (Components vs Aggregate)
    if (lesson == "TYT Sosyal" || lesson == "Sosyal") {
      double agg = findMaxInKeys(
          ["Sosyal", "Sosyal Bilimler", "TYT Sosyal"]); // Check all aggs
      double det = findMaxInKeys(["Tarih", "TYT Tarih"]) +
          findMaxInKeys(["Coğrafya", "TYT Coğrafya"]) +
          findMaxInKeys(["Felsefe", "TYT Felsefe"]) +
          findMaxInKeys(["Din", "TYT Din"]);
      return det > agg ? det : agg;
    }

    // 3. TYT Matematik (Components vs Aggregate)
    if (lesson == "TYT Matematik" || lesson == "Matematik") {
      double agg = findMaxInKeys(["Matematik", "TYT Matematik"]);
      double det = findMaxInKeys(["Sadece Matematik", "TYT Sadece Matematik"]) +
          findMaxInKeys(["Geometri", "TYT Geometri"]);
      return det > agg ? det : agg;
    }

    // 4. Default / Other Lessons (e.g. Türkçe, AYT Specifics)
    // Use the comprehensive map logic, but take MAX value instead of first match
    List<String> validKeys = _getBranchFilterKeys(lesson);
    double foundVal = findMaxInKeys(validKeys);

    // If still 0, try 'Contains' fallback for extreme robustness
    if (foundVal == 0) {
      for (var k in validKeys) {
        var match = t.lessonResults!.keys.firstWhere(
            (key) => key.toLowerCase().contains(k.toLowerCase()),
            orElse: () => "");
        if (match.isNotEmpty) return t.lessonResults![match]!.net;
      }
    }

    return foundVal;
  }

  bool _isTrialRelevant(TrialExam t, String filterName) {
    if (filterName.contains("Genel")) return true;

    // DATA-DRIVEN FILTER (User Request)
    // For Branch Trials, exclude if Net is 0 (implies irrelevant branch).
    // This allows exact separation without complex string parsing.
    if (t.type == "Branş") {
      double net = _getNet(t, filterName);
      // However, we must allow Legitimate 0s if the user actually took THIS branch.
      // E.g. User took "TYT Matematik" and got 0 net. It should shown.
      // But if he took "TYT Matematik", checks "TYT Sosyal", net is 0 (missing). Hide it.

      // Strict Check: active branch name vs filter name
      if (t.lesson != null) {
        // Normalized comparison to see if this trial intends to cover this filter
        String lessonNorm = t.lesson!
            .toLowerCase()
            .replaceAll("tyt", "")
            .replaceAll("ayt", "")
            .trim();
        String filterNorm = filterName
            .toLowerCase()
            .replaceAll("tyt", "")
            .replaceAll("ayt", "")
            .trim();
        if (filterNorm.contains(lessonNorm) ||
            lessonNorm.contains(filterNorm)) {
          return true; // Show even if 0 (Legitimate 0)
        }
      }

      return net > 0;
    }

    // For General Trials, look for data existence
    List<String> validKeys = _getBranchFilterKeys(filterName);
    for (String key in validKeys) {
      // Direct Match
      if (t.lessonResults!.containsKey(key)) return true;

      // Case-Insensitive Match
      if (t.lessonResults!.keys
          .any((k) => k.toLowerCase() == key.toLowerCase())) return true;

      // Contains Match (Robustness for partials like "Türkçe" matching "TYT Türkçe")
      if (t.lessonResults!.keys
          .any((k) => k.toLowerCase().contains(key.toLowerCase()))) return true;
    }

    return false;
  }

  double _calculateStats(List<TrialExam> list, String lesson,
      {required bool isMax}) {
    if (list.isEmpty) return 0;
    return list.fold(0.0, (prev, t) {
          double val = _getNet(t, lesson);
          if (isMax) return val > prev ? val : prev;
          return prev + val;
        }) /
        (isMax ? 1 : list.length);
  }
} // End of _DashboardTabState

// ================= TAB 2: GEÇMİŞ (VISUAL HIERARCHY) =================
class DenemeGecmisiTab extends StatelessWidget {
  final Function(TrialExam) onEdit;
  final bool usePremiumUI;
  final Function(bool) onToggle;

  const DenemeGecmisiTab({
    super.key,
    required this.onEdit,
    required this.usePremiumUI,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final TrialService srv = TrialService();
    return StreamBuilder<List<TrialExam>>(
        stream:
            srv.getTrialsStream(FirebaseAuth.instance.currentUser?.uid ?? ""),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent));
          var trials = snapshot.data!;
          trials.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              // Premium Toggle Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      usePremiumUI ? "PREMIUM GÖRÜNÜM ✨" : "STANDART GÖRÜNÜM",
                      style: GoogleFonts.outfit(
                        color: usePremiumUI
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
                        value: usePremiumUI,
                        onChanged: onToggle,
                        activeThumbColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: trials.length,
                  itemBuilder: (context, index) {
                    final t = trials[index];
                    return usePremiumUI
                        ? _buildPremiumTrialCard(context, t, srv)
                        : _buildStandardTrialCard(context, t, srv);
                  },
                ),
              ),
            ],
          );
        });
  }

  Widget _buildPremiumTrialCard(
      BuildContext context, TrialExam t, TrialService srv) {
    bool isGeneral = t.type == "Genel";
    List<String> stats = [
      if (t.totalNet != null) "${t.totalNet!.toStringAsFixed(1)} Net",
      if (t.trialCount > 1) "${t.trialCount} Adet",
      DateFormat("d MMM", 'tr_TR').format(t.date),
    ];

    Color color = isGeneral
        ? (t.area == "AYT" ? const Color(0xFF8B5CF6) : AppTheme.primaryColor)
        : AppTheme.emeraldColor;

    return TopicCard(
      title: t.publisher ?? "İsimsiz Deneme",
      subtitle:
          "${t.area} ${isGeneral ? 'Genel' : 'Branş'}${t.lesson != null ? ' - ${t.lesson}' : ''}",
      type: isGeneral ? TopicCardType.study : TopicCardType.question,
      stats: stats,
      customColor: color,
      customIcon: isGeneral ? Icons.history_edu_rounded : Icons.biotech_rounded,
      onTap: () => _showOptions(context, t, srv),
    );
  }

  Widget _buildStandardTrialCard(
      BuildContext context, TrialExam t, TrialService srv) {
    bool isGeneral = t.type == "Genel";
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      radius: 24,
      opacity: 0.05, // Crystal Clear
      onTap: () => _showOptions(context, t, srv),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Gradient Badge
            Container(
              width: 65,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: t.type == "Genel"
                      ? (t.area == "AYT"
                          ? [const Color(0xFF8B5CF6), const Color(0xFF6366F1)]
                          : [const Color(0xFF3B82F6), const Color(0xFF2DD4BF)])
                      : [const Color(0xFF10B981), const Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (t.type == "Genel"
                            ? (t.area == "AYT"
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF3B82F6))
                            : const Color(0xFF10B981))
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t.area,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isGeneral ? "GENEL" : "BRANŞ",
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t.publisher ?? "İsimsiz Deneme",
                    style: GoogleFonts.outfit(
                      color: AppTheme.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (t.lesson != null)
                        _buildMiniTag(t.lesson!, AppTheme.primaryColor),
                      _buildMiniTag(
                          DateFormat("d MMM yyyy", 'tr_TR').format(t.date),
                          AppTheme.textSub),
                      if (t.trialCount > 1)
                        _buildMiniTag(
                            "${t.trialCount} Adet", AppTheme.accentColor),
                    ],
                  ),
                ],
              ),
            ),
            // Right Side Net
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isGeneral
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryColor)
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    t.totalNet != null ? t.totalNet!.toStringAsFixed(1) : "-",
                    style: GoogleFonts.outfit(
                      color: isGeneral
                          ? AppTheme.primaryColor
                          : AppTheme.secondaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "NET",
                    style: GoogleFonts.inter(
                      color: (isGeneral
                              ? AppTheme.primaryColor
                              : AppTheme.secondaryColor)
                          .withValues(alpha: 0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, TrialExam t, TrialService srv) {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A2E),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Wrap(children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.cyanAccent),
                title: const Text("Düzenle",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit(t);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text("Sil",
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  srv.deleteTrial(FirebaseAuth.instance.currentUser!.uid, t.id);
                  Navigator.pop(ctx);
                },
              )
            ]));
  }

  Widget _buildMiniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ================= TAB 3: ANALİZ (COACH INSIGHTS) =================
class AnalizTab extends StatefulWidget {
  const AnalizTab({super.key});

  @override
  State<AnalizTab> createState() => _AnalizTabState();
}

class _AnalizTabState extends State<AnalizTab> {
  String _areaFilter = "TYT";

  @override
  Widget build(BuildContext context) {
    final TrialService srv = TrialService();
    return Column(
      children: [
        const SizedBox(height: 20),
        // Simple Filter Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(4),
              radius: 16,
              opacity: 0.05, // Crystal Clear
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ["TYT", "AYT"].map((e) {
                    bool isSelected = _areaFilter == e;
                    return GestureDetector(
                      onTap: () => setState(() => _areaFilter = e),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.secondaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          e,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        Expanded(
          child: StreamBuilder<List<TrialExam>>(
              stream: srv.getTrialsStream(
                  FirebaseAuth.instance.currentUser?.uid ?? ""),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.cyanAccent));

                var trials =
                    snapshot.data!.where((t) => t.area == _areaFilter).toList();

                int totalMistakes = 0;
                Map<String, int> catCounts = {
                  'Dikkat ve Okuma Hataları': 0,
                  'Bilgi ve Kavrama Eksikliği': 0,
                  'Strateji ve Psikoloji': 0
                };

                // Detailed Drill Down map: Category -> Reason -> Count
                Map<String, Map<String, int>> detailedStats = {};

                for (var t in trials) {
                  for (var w in t.wrongAnswers) {
                    totalMistakes++;
                    String cat = w.category ?? "Bilinmeyen"; // Fallback
                    // Map old/manual inputs to new categories if needed
                    if (cat == "Bilinmeyen") {
                      // Simple heuristic mapping for legacy data
                      if (w.reason.contains("Dikkat"))
                        cat = 'Dikkat ve Okuma Hataları';
                      else if (w.reason.contains("Bilgi"))
                        cat = 'Bilgi ve Kavrama Eksikliği';
                      else
                        cat = 'Strateji ve Psikoloji';
                    }

                    if (catCounts.containsKey(cat)) {
                      catCounts[cat] = (catCounts[cat] ?? 0) + 1;
                    }

                    if (!detailedStats.containsKey(cat))
                      detailedStats[cat] = {};
                    detailedStats[cat]![w.reason] =
                        (detailedStats[cat]![w.reason] ?? 0) + 1;
                  }
                }

                if (totalMistakes == 0)
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Colors.greenAccent, size: 64),
                        const SizedBox(height: 10),
                        Text("Henüz analiz edilecek hata yok! 🚀",
                            style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 18))
                      ],
                    ),
                  );

                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                  child: Column(
                    children: [
                      // 1. Horizontal Indicators Carousel (Bento-like cards in a scroll)
                      SizedBox(
                        height: 180,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildBentoStatCard(
                                "DİKKAT",
                                "Okuma & Odak",
                                AppTheme.roseColor,
                                (catCounts['Dikkat ve Okuma Hataları']! /
                                    totalMistakes),
                                Icons.remove_red_eye_rounded),
                            const SizedBox(width: 16),
                            _buildBentoStatCard(
                                "BİLGİ",
                                "Kavrama & Temel",
                                AppTheme.primaryColor,
                                (catCounts['Bilgi ve Kavrama Eksikliği']! /
                                    totalMistakes),
                                Icons.menu_book_rounded),
                            const SizedBox(width: 16),
                            _buildBentoStatCard(
                                "STRATEJİ",
                                "Süre & Psikoloji",
                                AppTheme.secondaryColor,
                                (catCounts['Strateji ve Psikoloji']! /
                                    totalMistakes),
                                Icons.psychology_rounded),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Hata Detay Analizi",
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textMain,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Drill Down Cards
                      ...detailedStats.entries.map((entry) {
                        String category = entry.key;
                        Map<String, int> reasons = entry.value;
                        Color catColor = _getCatColor(category);

                        return GlassCard(
                          margin: const EdgeInsets.fromLTRB(
                              24, 0, 24, 16), // Squeeze Width
                          padding: const EdgeInsets.all(16),
                          radius: 30,
                          opacity: 0.03, // Deeper contrast
                          borderColor: catColor.withValues(alpha: 0.15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.analytics_rounded,
                                      color: catColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(category,
                                    style: GoogleFonts.outfit(
                                        color: AppTheme.textMain,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold))
                              ]),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                    color: AppTheme.textSub.withOpacity(0.1)),
                              ),
                              ...reasons.entries.map((reasonEntry) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(reasonEntry.key,
                                      style: GoogleFonts.inter(
                                          color: AppTheme.textMain,
                                          fontWeight: FontWeight.w500)),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                        color:
                                            AppTheme.textSub.withOpacity(0.05),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Text("${reasonEntry.value} Kez",
                                        style: GoogleFonts.inter(
                                            color: AppTheme.textSub,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                  onTap: () => _showCoachInsight(context,
                                      category, reasonEntry.key, trials),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48), // Squeeze Button
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.secondaryColor,
                                  AppTheme.secondaryColor.withValues(alpha: 0.6)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.secondaryColor
                                      .withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.psychology_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Yapay Zekaya Sor",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }),
        )
      ],
    );
  }

  void _showCoachInsight(BuildContext context, String category, String reason,
      List<TrialExam> trials) {
    // Find specific trials with this mistake
    var badTrials = trials.where((t) {
      return t.wrongAnswers.any((w) {
        // Fallback for old data or mismatched categories
        String cat = w.category ?? "Bilinmeyen";
        if (cat == "Bilinmeyen") {
          if (w.reason.contains("Dikkat"))
            cat = 'Dikkat ve Okuma Hataları';
          else if (w.reason.contains("Bilgi"))
            cat = 'Bilgi ve Kavrama Eksikliği';
          else
            cat = 'Strateji ve Psikoloji';
        }
        return cat == category && w.reason == reason;
      });
    }).toList();

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (c) => Container(
            height:
                MediaQuery.of(context).size.height * 0.70, // Slightly shorter
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1A), // Deep Dark
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                )
              ],
            ),
            padding:
                const EdgeInsets.fromLTRB(24, 12, 24, 24), // Revert to normal
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: AppTheme.textSub.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: _getCatColor(category).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.analytics_outlined,
                          color: _getCatColor(category), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category,
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textSub,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(reason,
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textMain,
                                  fontSize: 18, // Revert to original size
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text("Hata Geçmişi",
                        style: GoogleFonts.outfit(
                            color: AppTheme.textMain.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text("${badTrials.length}",
                          style: GoogleFonts.inter(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: badTrials.length,
                    itemBuilder: (c, i) {
                      var t = badTrials[i];
                      var w = t.wrongAnswers.firstWhere(
                          (x) =>
                              x.reason == reason &&
                              (x.category == category || x.category == null),
                          orElse: () => t.wrongAnswers.first);

                      return GlassCard(
                        margin:
                            const EdgeInsets.only(bottom: 8), // Reduced from 12
                        padding: const EdgeInsets.all(12), // Reduced from 16
                        radius: 16,
                        opacity: 0.05, // Crystal Clear
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 14,
                                      color: AppTheme.textSub.withOpacity(0.5)),
                                  const SizedBox(width: 6),
                                  Text(DateFormat("dd MMM").format(t.date),
                                      style: GoogleFonts.inter(
                                          color: AppTheme.textSub,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600))
                                ]),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                      "${t.publisher ?? 'Genel'} • ${t.type}",
                                      style: GoogleFonts.inter(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                )
                              ],
                            ),
                            if (w.lesson.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text("${w.lesson} • ${w.topic}",
                                  style: GoogleFonts.inter(
                                      color: Colors.cyanAccent,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ],

                            // PREMIUM NOTE UI
                            if (w.note != null && w.note!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(
                                        left: BorderSide(
                                            color: _getCatColor(category),
                                            width: 4))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.edit_note_rounded,
                                            size: 18,
                                            color: _getCatColor(category)),
                                        const SizedBox(width: 6),
                                        Text("Ek Açıklama",
                                            style: GoogleFonts.inter(
                                                color: _getCatColor(category),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      w.note!,
                                      style: GoogleFonts.inter(
                                          color: AppTheme.textMain,
                                          fontSize: 13,
                                          height: 1.5),
                                    ),
                                  ],
                                ),
                              )
                            ]
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            )));
  }

  Color _getCatColor(String cat) {
    if (cat.contains("Dikkat")) return Colors.redAccent;
    if (cat.contains("Bilgi")) return Colors.blueAccent;
    return Colors.greenAccent;
  }

  Widget _buildBentoStatCard(String title, String subtitle, Color color,
      double percent, IconData icon) {
    if (percent.isNaN || percent.isInfinite) percent = 0;
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, color: color.withValues(alpha: 0.05), size: 80),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.outfit(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            color: AppTheme.textSub,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${(percent * 100).toInt()}",
                        style: GoogleFonts.outfit(
                            color: AppTheme.textMain,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 2),
                      child: Text("%",
                          style: GoogleFonts.outfit(
                              color: color,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= TAB 4: DENEME EKLE (BUG FIX & ROBUST) =================
class DenemeEkleTab extends StatefulWidget {
  final TrialExam? trialToEdit;
  final VoidCallback? onSaved;
  const DenemeEkleTab({super.key, this.trialToEdit, this.onSaved});

  @override
  State<DenemeEkleTab> createState() => _DenemeEkleTabState();
}

class _DenemeEkleTabState extends State<DenemeEkleTab> {
  int _currentStep = 0;
  DateTime _date = DateTime.now();
  String _area = "TYT";
  String _type = "Genel";
  String? _publisher;
  String? _branchLesson; // Branş denemesi için ders
  String? _subLesson; // Fen branşları için alt dal (Fizik, Kimya, Biyoloji)
  bool _isDetailedInput = true;
  bool _isTurkiyeGeneli = false;

  Map<String, MutableLessonResult> _results = {};
  List<WrongAnswer> _mistakes = [];

  String? _mistakeLesson;
  String?
      _mistakeSubLesson; // New: For splitting composite lessons in Mistake Step
  String? _mistakeTopic;
  String? _mistakeCategory; // Main Category (Attention, Info, Strategy)
  String? _mistakeReason;
  String? _mistakeNote; // User Note
  int _trialCount = 1; // Default 1
  // Feedback state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.trialToEdit != null) {
      final t = widget.trialToEdit!;
      _date = t.date;
      _area = t.area;
      _type = t.type;
      _publisher = t.publisher;
      _isTurkiyeGeneli = t.isTurkiyeGeneli;
      _trialCount = t.trialCount; // RESTORE TRIAL COUNT
      _mistakes = List.from(t.wrongAnswers);

      if (t.lessonResults != null) {
        t.lessonResults!.forEach((k, v) {
          _results[k] = MutableLessonResult()
            ..correct = v.correct
            ..wrong = v.wrong
            ..net = v.net;
        });
      }
      if (_type == "Branş") {
        String? savedLesson = t.lesson ?? t.lessonResults?.keys.firstOrNull;
        _branchLesson = savedLesson;
        _subLesson = null;

        // FIX: Normalize Legacy/Sub-Lesson Names to Parent Category for Edit Mode
        if (_area == "TYT") {
          if (_branchLesson == "Sadece Matematik" ||
              _branchLesson == "Geometri") {
            _branchLesson = "TYT Matematik";
            _subLesson = savedLesson;
            _isDetailedInput = true;
          } else if (["Fizik", "Kimya", "Biyoloji"].contains(_branchLesson)) {
            _branchLesson = "TYT Fen";
            _subLesson = savedLesson;
            _isDetailedInput = true;
          } else if (["Tarih", "Coğrafya", "Felsefe", "Din"]
              .contains(_branchLesson)) {
            _branchLesson = "TYT Sosyal";
            _subLesson = savedLesson;
            _isDetailedInput = true;
          } else if (_branchLesson == "Matematik") {
            _branchLesson = "TYT Matematik";
          }
        } else if (_area == "AYT") {
          if (["AYT Fizik", "AYT Kimya", "AYT Biyoloji"]
              .contains(_branchLesson)) {
            _branchLesson = "AYT Fen Bilimleri";
            _subLesson = savedLesson;
            _isDetailedInput = true;
          } else if (["Edebiyat", "Tarih-1", "Coğrafya-1"]
              .contains(_branchLesson)) {
            _branchLesson = "AYT Sosyal 1";
            _subLesson = savedLesson;
            _isDetailedInput = true;
          } else if (["Tarih-2", "Coğrafya-2", "Felsefe Grubu", "Din (AYT)"]
              .contains(_branchLesson)) {
            _branchLesson = "AYT Sosyal 2";
            _subLesson = savedLesson;
            _isDetailedInput = true;
          }
        }
      }
    }

    // Fetch User's Track (Alan) from Profile
    FirebaseDatabase.instance
        .ref("users/${FirebaseAuth.instance.currentUser!.uid}/profil/alan")
        .get()
        .then((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _selectedTrack = snapshot.value.toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.trialToEdit != null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(isEdit ? "Denemeyi Düzenle" : "Yeni Deneme",
            style: GoogleFonts.outfit(
              color: AppTheme.textMain,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (isEdit)
            IconButton(
                onPressed: widget.onSaved,
                icon: const Icon(Icons.close, color: AppTheme.textMain))
        ],
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.transparent,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primaryColor,
            primary: AppTheme.primaryColor,
            secondary: AppTheme.secondaryColor,
            surface: Colors.transparent,
            onSurface: AppTheme.textMain,
          ),
        ),
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2)
              setState(() => _currentStep++);
            else
              _save();
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isSaving ? null : (details.onStepContinue ?? () {}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_isSaving
                          ? "Kaydediliyor..."
                          : (_currentStep == 2 ? "Kaydet" : "Sonraki Adım")),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                        onPressed: details.onStepCancel,
                        child: Text("Geri Dön",
                            style: GoogleFonts.inter(
                                color: AppTheme.textSub,
                                fontWeight: FontWeight.w600)))
                  ]
                ],
              ),
            );
          },
          steps: [
            Step(
                title: Text("Bilgi",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _currentStep >= 0
                            ? AppTheme.primaryColor
                            : AppTheme.textSub)),
                content: _buildInfoStep(),
                isActive: _currentStep >= 0,
                state:
                    _currentStep > 0 ? StepState.complete : StepState.indexed),
            Step(
                title: Text("Netler",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _currentStep >= 1
                            ? AppTheme.primaryColor
                            : AppTheme.textSub)),
                content: _buildNetStep(),
                isActive: _currentStep >= 1,
                state:
                    _currentStep > 1 ? StepState.complete : StepState.indexed),
            Step(
                title: Text("Hatalar",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _currentStep >= 2
                            ? AppTheme.primaryColor
                            : AppTheme.textSub)),
                content: _buildMistakeStep(),
                isActive: _currentStep >= 2),
          ],
        ),
      ),
    );
  }

  String? _selectedTrack; // Sayısal, EA, Sözel, Dil

  List<String> _getLessonOptions() {
    if (_area == "TYT") {
      return ["TYT Türkçe", "TYT Matematik", "TYT Fen", "TYT Sosyal"];
    }
    // AYT
    if (_selectedTrack != null) {
      if (_selectedTrack!.contains("Sayısal")) {
        return ["AYT Matematik", "AYT Fen Bilimleri"];
      }
      if (_selectedTrack!.contains("Eşit Ağırlık")) {
        return ["AYT Matematik", "AYT Sosyal 1"];
      }
      if (_selectedTrack!.contains("Sözel")) {
        return ["AYT Sosyal 1", "AYT Sosyal 2"];
      }
      if (_selectedTrack!.contains("Dil")) {
        return ["YDT İngilizce"];
      }
    }
    return [
      "AYT Matematik",
      "AYT Fen Bilimleri",
      "AYT Sosyal 1",
      "AYT Sosyal 2"
    ];
  }

  List<String> _getSubLessonOptions(String parent) {
    if (parent == "TYT Fen") return ["Fizik", "Kimya", "Biyoloji"];
    if (parent == "AYT Fen Bilimleri")
      return ["AYT Fizik", "AYT Kimya", "AYT Biyoloji"];
    if (parent == "TYT Sosyal") return ["Tarih", "Coğrafya", "Felsefe", "Din"];
    if (parent == "AYT Sosyal 1") return ["Edebiyat", "Tarih-1", "Coğrafya-1"];
    if (parent == "AYT Sosyal 2")
      return ["Tarih-2", "Coğrafya-2", "Felsefe Grubu", "Din (AYT)"];
    // New: Math Split
    if (parent == "TYT Matematik") return ["Matematik", "Geometri"];
    if (parent == "AYT Matematik") return ["Matematik (AYT)", "Geometri (AYT)"];
    return [];
  }

  Widget _buildInfoStep() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      radius: 24,
      opacity: 0.05,
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Column(
        children: [
          _buildDropdown(
              "Alan",
              _area,
              ["TYT", "AYT"],
              (v) => setState(() {
                    _area = v!;
                    if (_area == "TYT") _selectedTrack = null;
                    _results.clear();
                    _branchLesson = null;
                  })),
          if (_area == "AYT") ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedTrack == null
                          ? "Alan bilgisi profil ayarlarından yükleniyor..."
                          : "Profilinizden: $_selectedTrack",
                      style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildDropdown(
              "Tür",
              _type,
              ["Genel", "Branş"],
              (v) => setState(() {
                    _type = v!;
                    _branchLesson = null;
                  })),
          if (_type == "Branş") ...[
            const SizedBox(height: 16),
            _buildDropdown(
                "Branş Dersi",
                _branchLesson,
                _getLessonOptions(),
                (v) => setState(() {
                      _branchLesson = v;
                      _subLesson = null;
                    })),
            if (_branchLesson != null &&
                (_branchLesson!.contains("Fen") ||
                    _branchLesson!.contains("Sosyal"))) ...[
              const SizedBox(height: 16),
              _buildDropdown(
                  "Alt Branş (Opsiyonel)",
                  _subLesson,
                  _getSubLessonOptions(_branchLesson!),
                  (v) => setState(() {
                        _subLesson = v;
                      })),
            ],
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold),
              initialValue: _trialCount.toString(),
              onChanged: (v) {
                int? val = int.tryParse(v);
                if (val != null && val > 0) {
                  setState(() => _trialCount = val);
                }
              },
              decoration: _inputFieldDeco(
                label: "Kaç Deneme Çözüldü?",
                icon: Icons.library_books_rounded,
                iconColor: AppTheme.amberColor,
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold),
            initialValue: _publisher,
            onChanged: (v) => setState(() => _publisher = v),
            decoration: _inputFieldDeco(
              label: "Yayın Adı",
              icon: Icons.edit_rounded,
              iconColor: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text("Ayrıntılı Alanlar",
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            subtitle: Text("Tüm alanları tek tek gör",
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
            value: _isDetailedInput,
            onChanged: (val) => setState(() => _isDetailedInput = val),
            activeThumbColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: Text("Türkiye Geneli",
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            value: _isTurkiyeGeneli,
            onChanged: (val) => setState(() => _isTurkiyeGeneli = val),
            activeThumbColor: AppTheme.amberColor,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildNetStep() {
    // Task 2: Strict Visibility Logic (Hard Coded)
    bool isSayisal = _selectedTrack?.contains("Sayısal") ?? false;
    bool isEA = _selectedTrack?.contains("Eşit Ağırlık") ?? false;
    bool isSozel = _selectedTrack?.contains("Sözel") ?? false;
    bool isDil = _selectedTrack?.contains("Dil") ?? false;

    if (_type == "Branş") {
      if (_branchLesson == null)
        return const Center(child: Text("Ders Seçiniz"));

      // Priority: Sub-Lesson selection (Batch Entry e.g. 6 Physics trials)
      if (_subLesson != null) {
        return _buildNetInputRow(_subLesson!);
      }

      // DETAILED INPUT LOGIC FOR BRANCH TRIALS
      if (_isDetailedInput) {
        // TYT & AYT Math
        if (_branchLesson!.contains("Matematik")) {
          String mathKey = _branchLesson!.contains("AYT")
              ? "Sadece Matematik (AYT)"
              : "Sadece Matematik";
          String geoKey =
              _branchLesson!.contains("AYT") ? "Geometri (AYT)" : "Geometri";

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNetInputRow(mathKey),
              const SizedBox(height: 12),
              _buildNetInputRow(geoKey)
            ],
          );
        }

        // TYT Fen
        if (_branchLesson == "TYT Fen") {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNetInputRow("Fizik"),
              const SizedBox(height: 12),
              _buildNetInputRow("Kimya"),
              const SizedBox(height: 12),
              _buildNetInputRow("Biyoloji")
            ],
          );
        }

        // TYT Sosyal
        if (_branchLesson == "TYT Sosyal") {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNetInputRow("Tarih"),
              const SizedBox(height: 12),
              _buildNetInputRow("Coğrafya"),
              const SizedBox(height: 12),
              _buildNetInputRow("Felsefe"),
              const SizedBox(height: 12),
              _buildNetInputRow("Din")
            ],
          );
        }

        // AYT Fen
        if (_branchLesson == "AYT Fen Bilimleri") {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNetInputRow("AYT Fizik"),
              const SizedBox(height: 12),
              _buildNetInputRow("AYT Kimya"),
              const SizedBox(height: 12),
              _buildNetInputRow("AYT Biyoloji")
            ],
          );
        }

        // AYT Sosyal
        if (_branchLesson == "AYT Sosyal 1") {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNetInputRow("Edebiyat"),
              const SizedBox(height: 12),
              _buildNetInputRow("Tarih-1"),
              const SizedBox(height: 12),
              _buildNetInputRow("Coğrafya-1"),
            ],
          );
        }
      }

      // Default: Show single aggregate row (Limit 40/20 depending on key)
      return _buildNetInputRow(_branchLesson!);
    }

    // TYT Logic (Toggle Detailed/Aggregated)
    if (_area == "TYT") {
      return Column(children: [
        _buildNetInputRow(_isDetailedInput ? "Türkçe" : "TYT Türkçe"),
        // Math Logic: If detailed, break down. If not, show total.
        if (_isDetailedInput) ...[
          _buildNetInputRow("Sadece Matematik"), // Max 30
          _buildNetInputRow("Geometri"), // Max 10
        ] else ...[
          _buildNetInputRow("TYT Matematik"), // Max 40
        ],

        if (_isDetailedInput) ...[
          _buildNetInputRow("Fizik"),
          _buildNetInputRow("Kimya"),
          _buildNetInputRow("Biyoloji"),
          _buildNetInputRow("Tarih"),
          _buildNetInputRow("Coğrafya"),
          _buildNetInputRow("Felsefe"),
          _buildNetInputRow("Din"),
        ] else ...[
          _buildNetInputRow("TYT Fen"),
          _buildNetInputRow("TYT Sosyal"),
        ]
      ]);
    }

    // AYT Logic (Strict Visibility + Toggle Detailed/Aggregated)
    return Column(
      children: [
        if (_selectedTrack == null)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Lütfen 'Bilgi' sekmesinden Alan seçiniz!",
                style: TextStyle(color: Colors.orange)),
          ),
        Visibility(
          visible: isSayisal || isEA, // Mat + Geo
          child: _isDetailedInput
              ? Column(children: [
                  _buildNetInputRow("Sadece Matematik (AYT)"), // Max 30
                  _buildNetInputRow("Geometri (AYT)") // Max 10
                ])
              : _buildNetInputRow("AYT Matematik"), // Max 40
        ),
        Visibility(
          visible: isSayisal, // Fen
          child: _isDetailedInput
              ? Column(children: [
                  _buildNetInputRow("AYT Fizik"),
                  _buildNetInputRow("AYT Kimya"),
                  _buildNetInputRow("AYT Biyoloji")
                ])
              : _buildNetInputRow("AYT Fen Bilimleri"),
        ),
        Visibility(
          visible: isEA || isSozel, // Edebiyat + Sos1
          child: _isDetailedInput
              ? Column(children: [
                  _buildNetInputRow("Edebiyat"),
                  _buildNetInputRow("Tarih-1"),
                  _buildNetInputRow("Coğrafya-1"),
                ])
              : _buildNetInputRow("AYT Sosyal 1"),
        ),
        Visibility(
          visible: isSozel, // Sos2
          child: _isDetailedInput
              ? Column(children: [
                  _buildNetInputRow("Tarih-2"),
                  _buildNetInputRow("Coğrafya-2"),
                  _buildNetInputRow("Felsefe Grubu"),
                  _buildNetInputRow("Din (AYT)"),
                ])
              : _buildNetInputRow("AYT Sosyal 2"),
        ),
        Visibility(
          visible: isDil,
          child: _buildNetInputRow("YDT İngilizce"),
        ),
      ],
    );
  }

  Widget _buildNetInputRow(String lesson) {
    if (!_results.containsKey(lesson)) _results[lesson] = MutableLessonResult();
    var res = _results[lesson]!;

    // New Strict Limit Logic using sabitler.dart map
    int getMax(String l) {
      // Handle special prefixes for Map Lookup
      String key = l;
      if (_area == "TYT") {
        if (l == "Matematik") key = "Sadece Matematik"; // 30
      } else {
        // AYT
        if (l == "Matematik") key = "Sadece Matematik (AYT)"; // 30
        if (l == "Geometri") key = "Geometri (AYT)";
        if (l == "Fizik") key = "AYT Fizik";
        if (l == "Kimya") key = "AYT Kimya";
        if (l == "Biyoloji") key = "AYT Biyoloji";
        if (l == "Din") key = "Din (AYT)";
      }
      return maxSoruSayilari[key] ?? maxSoruSayilari[l] ?? 40;
    }

    void validateAndSet(int? newCorrect, int? newWrong) {
      int c = newCorrect ?? res.correct;
      int w = newWrong ?? res.wrong;
      int max = getMax(lesson) * _trialCount;

      // 1. Individual Limit Check
      if (c + w > max) {
        _showSnack("⚠️ Hata: $lesson için max soru ($max) aşıldı!");
        return; // Fail safe
      }

      // 2. Math + Geo Combined Check
      // If we are editing Math, check if Math+Geo > 40
      if (lesson == "Matematik" || lesson == "Geometri") {
        String brother = lesson == "Matematik" ? "Geometri" : "Matematik";
        if (_results.containsKey(brother)) {
          var broRes = _results[brother]!;
          int totalMatQuestions = (_area == "TYT" ? 40 : 40) * _trialCount;
          int currentTotal = (c + w) + (broRes.correct + broRes.wrong);
          if (currentTotal > totalMatQuestions) {
            _showSnack(
                "⚠️ Matematik + Geometri toplamı $totalMatQuestions'ı geçemez!");
            // Allow but warn? Or block? Prompt said "uyarısını ekle".
            // We will block for data integrity.
            return;
          }
        }
      }

      setState(() {
        if (c > max) c = max;
        if (w > max) w = max; // Clamp
        res.correct = c;
        res.wrong = w;
        _recalc(lesson);
      });
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      radius: 20,
      opacity: 0.1, // Reduced opacity
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(lesson,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white))), // White Text
          SizedBox(
              width: 55,
              child: TextFormField(
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  initialValue: res.correct == 0 ? "" : res.correct.toString(),
                  decoration: _inputDeco("D"),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    int? val = int.tryParse(v);
                    validateAndSet(val, null);
                  })),
          const SizedBox(width: 8),
          SizedBox(
              width: 55,
              child: TextFormField(
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppTheme.roseColor, fontWeight: FontWeight.bold),
                  initialValue: res.wrong == 0 ? "" : res.wrong.toString(),
                  decoration: _inputDeco("Y", isWrong: true),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    int? val = int.tryParse(v);
                    validateAndSet(null, val);
                  })),
          const SizedBox(width: 12),
          // Net Display
          Container(
            width: 55,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2))),
            child: Text(res.net.toStringAsFixed(1),
                style: GoogleFonts.outfit(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          )
        ],
      ),
    );
  }

  // Helper for Input Decoration to reduce code dupe
  InputDecoration _inputDeco(String label, {bool isWrong = false}) {
    Color activeColor = isWrong ? AppTheme.roseColor : AppTheme.emeraldColor;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
          color: activeColor.withValues(alpha: 0.8),
          fontWeight: FontWeight.bold,
          fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      isDense: true,
      filled: true,
      fillColor: activeColor.withValues(alpha: 0.1),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: activeColor.withValues(alpha: 0.2))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: activeColor, width: 1.5)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  InputDecoration _inputFieldDeco(
      {required String label,
      required IconData icon,
      required Color iconColor}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2), // Dark Glass
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2)));
  }

  Widget _buildMistakeStep() {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          radius: 24,
          opacity: 0.05, // Modern Dark Glass (was 0.4 which looked grey)
          child: Column(
            children: [
              // 1. Mistake Lesson Selection
              if (_type == "Genel")
                _buildDropdown(
                    "Ders",
                    _mistakeLesson,
                    _getLessonOptions(),
                    (v) => setState(() {
                          _mistakeLesson = v;
                          _mistakeSubLesson = null;
                          _mistakeTopic = null;
                        })),

              // 2. Sub-Lesson Selection (Physics/Chem/Bio etc.)
              Builder(builder: (context) {
                String? primaryLesson = _type == "Branş"
                    ? (_subLesson ?? _branchLesson)
                    : _mistakeLesson;

                if (primaryLesson == null) return const SizedBox.shrink();

                List<String> subs = _getSubLessonOptions(primaryLesson);
                if (subs.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildDropdown(
                        "Ders Detayı",
                        _mistakeSubLesson,
                        subs,
                        (v) => setState(() {
                              _mistakeSubLesson = v;
                              _mistakeTopic = null;
                            })),
                  ],
                );
              }),

              const SizedBox(height: 12),

              // 3. Topic Selection
              Builder(builder: (context) {
                String? effectiveLesson = _mistakeSubLesson ??
                    (_type == "Branş"
                        ? (_subLesson ?? _branchLesson)
                        : _mistakeLesson);
                var topics = _getTopics(effectiveLesson);
                return _buildDropdown(
                    "Konu",
                    topics.contains(_mistakeTopic) ? _mistakeTopic : null,
                    topics,
                    (v) => setState(() => _mistakeTopic = v));
              }),
              const SizedBox(height: 12),
              _buildDropdown(
                  "Hata Kategorisi",
                  _mistakeCategory,
                  errorCategories.keys.toList(),
                  (v) => setState(() {
                        _mistakeCategory = v;
                        _mistakeReason = null;
                      })),
              if (_mistakeCategory != null) ...[
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  var reasons =
                      errorCategories[_mistakeCategory]!.keys.toList();
                  return _buildDropdown(
                      "Hata Sebebi",
                      reasons.contains(_mistakeReason) ? _mistakeReason : null,
                      reasons,
                      (v) => setState(() => _mistakeReason = v));
                }),
              ],
              const SizedBox(height: 12),
              TextFormField(
                style: GoogleFonts.inter(color: AppTheme.textMain),
                decoration: _inputFieldDeco(
                    label: "Hata Notu (Opsiyonel)",
                    icon: Icons.edit_note_rounded,
                    iconColor: AppTheme.secondaryColor),
                onChanged: (v) => _mistakeNote = v,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Use Sub-Lesson if selected, otherwise fallback only if valid
                    String? lesson = _mistakeSubLesson ??
                        (_type == "Branş"
                            ? (_subLesson ?? _branchLesson)
                            : _mistakeLesson);
                    if (lesson == null ||
                        _mistakeTopic == null ||
                        _mistakeReason == null) {
                      _showSnack("⚠️ Lütfen tüm alanları doldurun!");
                      return;
                    }

                    // Strict Sub-Lesson enforcement
                    if (_getSubLessonOptions(lesson).isNotEmpty) {
                      _showSnack("⚠️ Lütfen alt branş seçiniz (örn. Fizik)!");
                      return;
                    }

                    setState(() {
                      _mistakes.add(WrongAnswer(
                          lesson: lesson,
                          topic: _mistakeTopic!,
                          reason: _mistakeReason!,
                          note: _mistakeNote,
                          category: _mistakeCategory));
                      _mistakeNote = null;
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Hata Listesine Ekle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Text("Eklenen Hatalar (${_mistakes.length})",
              style: GoogleFonts.outfit(
                  color: AppTheme.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _mistakes
              .map((m) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${m.lesson} • ${m.topic}",
                            style: GoogleFonts.inter(
                                color: AppTheme.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _mistakes.remove(m)),
                          child: Icon(Icons.close_rounded,
                              size: 16,
                              color: AppTheme.primaryColor.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        )
      ],
    );
  }

  void _recalc(String l) =>
      _results[l]!.net = _results[l]!.correct - (_results[l]!.wrong * 0.25);

  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String?) changed) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      menuMaxHeight: 400,
      dropdownColor: const Color(0xFF1E1E2C), // Dark Dropdown Background
      icon:
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
      style: GoogleFonts.inter(color: Colors.white), // White Selected Text
      initialValue: value,
      items: items
          .map((e) => DropdownMenuItem(
              value: e,
              child: Text(
                e,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 14), // White Item Text
              )))
          .toList(),
      onChanged: changed,
      decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.2), // Dark Glass Input
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    );
  }

  List<String> _getTopics(String? lesson) {
    if (lesson == null) return [];

    // FIX: Robust Topic Lookup Logic
    // 1. Try RAW Lesson Name (Priority for Aliases like 'Din (AYT)')
    if (tytKonulari.containsKey(lesson)) return tytKonulari[lesson]!;
    if (aytMufredati.containsKey(lesson)) return aytMufredati[lesson]!;

    // 2. Try Area Prefixed (e.g. "Matematik" -> "TYT Matematik")
    String withArea = "$_area $lesson";
    if (tytKonulari.containsKey(withArea)) return tytKonulari[withArea]!;
    if (aytMufredati.containsKey(withArea)) return aytMufredati[withArea]!;

    // 3. Try Stripping/Adding Prefixes intelligently
    if (lesson.startsWith("AYT ")) {
      // "AYT Matematik" -> Maybe map has "Matematik (AYT)"?
      // Just fallback to aliases
    }

    return ["Konu 1", "Konu 2"];
  }

  void _save() async {
    // 5. Add Fix: Robust Validation and Try-Catch
    setState(() => _isSaving = true);
    try {
      if (_type == "Branş" && _branchLesson == null)
        throw Exception("Lütfen branş seçimi yapın");

      String? activeLesson =
          _type == "Branş" ? (_subLesson ?? _branchLesson) : null;

      double totalNet = 0;
      Map<String, LessonResult> finalRes = {};
      _results.forEach((k, v) {
        totalNet += v.net;
        finalRes[k] = LessonResult(
            correct: v.correct, wrong: v.wrong, empty: 0, net: v.net);
      });

      TrialExam t = TrialExam(
          id: widget.trialToEdit?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          userId: FirebaseAuth.instance.currentUser!.uid,
          date: _date,
          area: _area,
          type: _type,
          lesson: activeLesson, // USE ACTIVE LESSON (SUB-BRANCH)
          publisher: _publisher,
          lessonResults: finalRes,
          totalNet: totalNet,
          wrongAnswers: _mistakes,
          isTurkiyeGeneli: _isTurkiyeGeneli,
          trialCount: _trialCount);

      final srv = TrialService();
      await srv.addTrial(t.userId, t);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Deneme Başarıyla Kaydedildi! 🚀"),
          backgroundColor: Colors.green));
      if (widget.onSaved != null) widget.onSaved!();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class MutableLessonResult {
  int correct = 0;
  int wrong = 0;
  double net = 0.0;
}
