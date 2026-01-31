enum ReviewStrategy { ebbinghaus, weekend, custom }

class Question {
  final String id;
  final String userId;
  final String? imageUrl;
  final String ders; // Lesson
  final String konu; // Subject
  final String? notlar; // Notes
  final DateTime eklenmeTarihi;
  final ReviewStrategy tekrarStratejisi;
  final int
      hedefTekrarSayisi; // How many times user wants to review (legacy/simple count) or total steps

  // List of dates when this question SHOULD be reviewed
  final List<DateTime> planlananTekrarlar;

  // List of dates when this question WAS actually reviewed
  final List<DateTime> tamamlananTekrarlar;

  Question({
    required this.id,
    required this.userId,
    this.imageUrl,
    required this.ders,
    required this.konu,
    this.notlar,
    required this.eklenmeTarihi,
    required this.tekrarStratejisi,
    this.hedefTekrarSayisi = 1,
    required this.planlananTekrarlar,
    required this.tamamlananTekrarlar,
  });

  // Convert to Map for Firebase Realtime Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'ders': ders,
      'konu': konu,
      'notlar': notlar,
      'eklenmeTarihi': eklenmeTarihi.toIso8601String(),
      'tekrarStratejisi': tekrarStratejisi.index, // Store as int
      'hedefTekrarSayisi': hedefTekrarSayisi,
      'planlananTekrarlar':
          planlananTekrarlar.map((d) => d.toIso8601String()).toList(),
      'tamamlananTekrarlar':
          tamamlananTekrarlar.map((d) => d.toIso8601String()).toList(),
    };
  }

  // Create from Map
  factory Question.fromMap(Map<dynamic, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'],
      ders: map['ders'] ?? '',
      konu: map['konu'] ?? '',
      notlar: map['notlar'],
      eklenmeTarihi: DateTime.parse(map['eklenmeTarihi']),
      tekrarStratejisi: ReviewStrategy.values[map['tekrarStratejisi'] ?? 0],
      hedefTekrarSayisi: map['hedefTekrarSayisi'] ?? 1,
      planlananTekrarlar: (map['planlananTekrarlar'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e.toString()))
              .toList() ??
          [],
      tamamlananTekrarlar: (map['tamamlananTekrarlar'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e.toString()))
              .toList() ??
          [],
    );
  }

  // Calculate logic for next due date based on strategy can be helper methods here
}
