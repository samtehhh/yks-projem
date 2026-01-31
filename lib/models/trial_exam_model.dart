class TrialExam {
  final String id;
  final String userId;
  final DateTime date;
  final String area; // TYT, AYT, YDT
  final String type; // Genel, Brans
  final String? lesson; // Eğer Brans ise, örn: Matematik
  final String? publisher; // Yayınevi
  final String? details; // Genel notlar

  // Detaylı Sonuçlar
  final Map<String, LessonResult>? lessonResults;

  // Hatalı Sorular ve Sebepleri
  final List<WrongAnswer> wrongAnswers;

  // Türkiye Geneli mi?
  final bool isTurkiyeGeneli;
  // Eski yapı uyumluluğu için (Opsiyonel)
  final double? totalNet;
  // Deneme Sayisi (Toplu Giris icin)
  final int trialCount;

  TrialExam({
    required this.id,
    required this.userId,
    required this.date,
    required this.area,
    required this.type,
    this.lesson,
    this.publisher,
    this.details,
    this.lessonResults,
    this.wrongAnswers = const [],
    this.isTurkiyeGeneli = false,
    this.totalNet,
    this.trialCount = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'area': area,
      'type': type,
      'lesson': lesson,
      'publisher': publisher,
      'details': details,
      'lessonResults': lessonResults?.map((k, v) => MapEntry(k, v.toMap())),
      'wrongAnswers': wrongAnswers.map((x) => x.toMap()).toList(),
      'isTurkiyeGeneli': isTurkiyeGeneli,
      'totalNet': totalNet,
      'trialCount': trialCount,
    };
  }

  factory TrialExam.fromMap(Map<dynamic, dynamic> map) {
    return TrialExam(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      area: map['area'] ?? '',
      type: map['type'] ?? '',
      lesson: map['lesson'],
      publisher: map['publisher'],
      details: map['details'],
      lessonResults: map['lessonResults'] != null
          ? (map['lessonResults'] as Map<dynamic, dynamic>)
              .map((k, v) => MapEntry(k.toString(), LessonResult.fromMap(v)))
          : null,
      wrongAnswers: map['wrongAnswers'] != null
          ? List<WrongAnswer>.from((map['wrongAnswers'] as List<dynamic>)
              .map((x) => WrongAnswer.fromMap(x)))
          : [],
      isTurkiyeGeneli: map['isTurkiyeGeneli'] ?? false,
      totalNet: map['totalNet'] != null
          ? double.tryParse(map['totalNet'].toString())
          : null,
      trialCount: map['trialCount'] ?? 1,
    );
  }
}

class LessonResult {
  final int correct;
  final int wrong;
  final int empty;
  final double net;

  LessonResult({
    required this.correct,
    required this.wrong,
    required this.empty,
    required this.net,
  });

  Map<String, dynamic> toMap() {
    return {
      'correct': correct,
      'wrong': wrong,
      'empty': empty,
      'net': net,
    };
  }

  factory LessonResult.fromMap(Map<dynamic, dynamic> map) {
    return LessonResult(
      correct: map['correct'] ?? 0,
      wrong: map['wrong'] ?? 0,
      empty: map['empty'] ?? 0,
      net: (map['net'] ?? 0).toDouble(),
    );
  }
}

class WrongAnswer {
  final String lesson;
  final String topic;
  final String reason; // Bilgi Eksiği, Dikkatsizlik, vb.
  final String? note; // <--- Yeni alan: Kullanıcı notu
  final String?
      category; // <--- Yeni alan: Hata Kategorisi (Dikkat, Bilgi, Strateji)

  WrongAnswer({
    required this.lesson,
    required this.topic,
    required this.reason,
    this.note,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'lesson': lesson,
      'topic': topic,
      'reason': reason,
      'note': note,
      'category': category,
    };
  }

  factory WrongAnswer.fromMap(Map<dynamic, dynamic> map) {
    return WrongAnswer(
      lesson: map['lesson'] ?? '',
      topic: map['topic'] ?? '',
      reason: map['reason'] ?? '',
      note: map['note'],
      category: map['category'],
    );
  }
}
