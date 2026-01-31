import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

/// Deneme modelini branş bazlı netleri içerecek şekilde güncelledik.
class Deneme {
  final String id;
  final String isim;
  final DateTime tarih;
  final double toplamNet;
  final Map<String, double>
      bransNetleri; // Örn: {"TYT Türkçe": 32.5, "TYT Matematik": 28.0}
  final String tip; // "TYT" veya "AYT"

  Deneme({
    required this.id,
    required this.isim,
    required this.tarih,
    required this.toplamNet,
    required this.bransNetleri,
    required this.tip,
  });
}

class PerformansAnaliziEkrani extends StatefulWidget {
  const PerformansAnaliziEkrani({super.key});

  @override
  State<PerformansAnaliziEkrani> createState() =>
      _PerformansAnaliziEkraniState();
}

class _PerformansAnaliziEkraniState extends State<PerformansAnaliziEkrani> {
  // Mock veri listesi - Gerçek uygulamada Firebase'den gelen liste buraya bağlanmalı
  List<Deneme> tumDenemeler = [
    Deneme(
      id: "1",
      isim: "3D Deneme",
      tarih: DateTime(2026, 1, 31),
      toplamNet: 58.0,
      tip: "TYT",
      bransNetleri: {
        "TYT Türkçe": 25.0,
        "TYT Matematik": 15.0,
        "TYT Sosyal": 10.0,
        "TYT Fen": 8.0
      },
    ),
    Deneme(
      id: "2",
      isim: "İsimsiz Deneme",
      tarih: DateTime(2026, 1, 30),
      toplamNet: 90.0,
      tip: "TYT",
      bransNetleri: {
        "TYT Türkçe": 35.0,
        "TYT Matematik": 30.0,
        "TYT Sosyal": 15.0,
        "TYT Fen": 10.0
      },
    ),
  ];

  String seciliSekme = "Genel"; // "Genel" veya "Branş"
  String seciliTip = "TYT"; // "TYT" veya "AYT"
  String seciliBrans = "TYT Türkçe";

  final List<String> tytBranslar = [
    "TYT Türkçe",
    "TYT Matematik",
    "TYT Fen",
    "TYT Sosyal"
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Veriyi Filtreleme Mantığı (BUG FIX BURADA)
    List<Deneme> filtrelenmisListe =
        tumDenemeler.where((d) => d.tip == seciliTip).toList();
    filtrelenmisListe.sort((a, b) => a.tarih.compareTo(b.tarih));

    // Branş seçiliyse, sadece o branşın verisi olanları veya o branş değerini al
    List<double> grafikVerisi = [];
    double toplam = 0;
    double enYuksek = 0;

    for (var deneme in filtrelenmisListe) {
      double deger = 0;
      if (seciliSekme == "Genel") {
        deger = deneme.toplamNet;
      } else {
        // Branş netini Map içinden çekiyoruz, yoksa 0.0 dönüyoruz
        deger = deneme.bransNetleri[seciliBrans] ?? 0.0;
      }
      grafikVerisi.add(deger);
      toplam += deger;
      if (deger > enYuksek) enYuksek = deger;
    }

    double ortalama = grafikVerisi.isEmpty ? 0 : toplam / grafikVerisi.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AppTheme.meshBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Genel / Branş Switcher
                  GlassCard(
                    padding: const EdgeInsets.all(4),
                    radius: 12,
                    opacity: 0.1,
                    child: Row(
                      children: [
                        _tabButton("Genel"),
                        _tabButton("Branş"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TYT / AYT ve Branş Seçici
                  Row(
                    children: [
                      _filterChip("TYT"),
                      const SizedBox(width: 8),
                      _filterChip("AYT"),
                      const Spacer(),
                      if (seciliSekme == "Branş")
                        DropdownButton<String>(
                          value: seciliBrans,
                          dropdownColor: AppTheme.surfaceDark,
                          style: const TextStyle(color: Colors.white),
                          items: tytBranslar
                              .map((b) =>
                                  DropdownMenuItem(value: b, child: Text(b)))
                              .toList(),
                          onChanged: (v) => setState(() => seciliBrans = v!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // İstatistik Kartları
                  Row(
                    children: [
                      _statCard("Ortalama", ortalama.toStringAsFixed(1)),
                      const SizedBox(width: 12),
                      _statCard("En Yüksek", enYuksek.toStringAsFixed(1)),
                      const SizedBox(width: 12),
                      _statCard("Top. Deneme", grafikVerisi.length.toString()),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Grafik Alanı
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("İlerleme Analizi",
                        style: TextStyle(
                            color: AppTheme.textMain,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: grafikVerisi.isEmpty
                        ? Center(
                            child: Text("Veri yok",
                                style: TextStyle(color: AppTheme.textSub)))
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      (value.toInt() + 1).toString(),
                                      style: TextStyle(
                                          color: AppTheme.textSub,
                                          fontSize: 10),
                                    ),
                                  ),
                                )),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                      grafikVerisi.length,
                                      (i) => FlSpot(
                                          i.toDouble(), grafikVerisi[i])),
                                  isCurved: true,
                                  color: AppTheme.secondaryColor,
                                  barWidth: 4,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.secondaryColor
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label) {
    bool isSelected = seciliSekme == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => seciliSekme = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.secondaryColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color:
                        isSelected ? AppTheme.secondaryColor : AppTheme.textSub,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = seciliTip == label;
    return ActionChip(
      label: Text(label),
      backgroundColor:
          isSelected ? AppTheme.secondaryColor : AppTheme.surfaceDark,
      labelStyle:
          TextStyle(color: isSelected ? Colors.white : AppTheme.textSub),
      onPressed: () => setState(() => seciliTip = label),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: AppTheme.textSub, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text("Net",
                style: TextStyle(color: AppTheme.secondaryColor, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
