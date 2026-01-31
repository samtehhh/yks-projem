import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/question_model.dart';

class QuestionService {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Review Intervals for Ebbinghaus (approximate)
  // 1 day, 3 days, 1 week, 1 month
  static const List<Duration> ebbinghausIntervals = [
    Duration(days: 1),
    Duration(days: 3),
    Duration(days: 7),
    Duration(days: 30),
  ];

  Future<void> addQuestion({
    required String userId,
    required String ders,
    required String konu,
    String? notlar,
    File? imageFile,
    required ReviewStrategy strategy,
    int? customRepeatCount,
    List<DateTime>? customDates,
  }) async {
    final String qId = _uuid.v4();
    String? imageUrl;

    // 1. Upload Image (Robust Method - Debugging)
    if (imageFile != null) {
      if (!await imageFile.exists()) {
        // Changed exists_sync() to exists() as per File API
        throw 'Dosya cihazda bulunamadı (Path: ${imageFile.path})';
      }

      final ref = _storage.ref().child('mistakes/$userId/$qId.jpg');

      // Step A: Upload (Simple)
      try {
        // Debug: Print bucket
        print("Uploading to bucket: ${_storage.app.options.storageBucket}");

        // Put Data (Bytes) directly without metadata to test
        final bytes = await imageFile.readAsBytes();
        final UploadTask task = ref.putData(bytes);

        final TaskSnapshot snapshot = await task;

        if (snapshot.state != TaskState.success) {
          throw 'Yükleme başarısız: Durum=${snapshot.state}';
        }
      } catch (e) {
        throw 'Yükleme (Upload) Hatası: $e';
      }

      // Step B: Get URL (with slight delay)
      try {
        await Future.delayed(
            const Duration(milliseconds: 1000)); // Wait for consistency
        imageUrl = await ref.getDownloadURL();
      } catch (e) {
        // If we can't get the URL, we might still want to save the question without the image link
        // OR warn the user. For now, let's show the error.
        // Check if it's object-not-found specifically
        throw 'URL Alma Hatası: $e \n(Lütfen Firebase Storage Kurallarını kontrol edin: allow read/write)';
      }
    }

    // 2. Calculate Planned Dates
    List<DateTime> planned = [];
    final now = DateTime.now();

    if (strategy == ReviewStrategy.ebbinghaus) {
      // Use standard intervals based on customRepeatCount or default 4
      int count = customRepeatCount ?? 4;
      for (int i = 0; i < count; i++) {
        if (i < ebbinghausIntervals.length) {
          planned.add(now.add(ebbinghausIntervals[i]));
        } else {
          // Fallback pattern if count > 4: add 30 days for each extra step
          planned.add(now.add(Duration(days: 30 * (i - 2))));
        }
      }
    } else if (strategy == ReviewStrategy.weekend) {
      // Find next Saturday and Sunday
      // Note: This logic assumes "Weekend" means reviewing THIS coming weekend or next if today is weekend
      DateTime nextSaturday = now;
      while (nextSaturday.weekday != DateTime.saturday) {
        nextSaturday = nextSaturday.add(const Duration(days: 1));
      }
      DateTime nextSunday = nextSaturday.add(const Duration(days: 1));

      // If user wants multiple weekends, we could extend logic.
      // For now, let's add 1st recurrence this weekend.
      int count = customRepeatCount ?? 1;
      for (int i = 0; i < count; i++) {
        planned.add(nextSaturday.add(Duration(days: 7 * i)));
        planned.add(nextSunday.add(Duration(
            days: 7 *
                i))); // Both Sat & Sun? Or just one? Let's do both as a "weekend block"
      }
    } else if (strategy == ReviewStrategy.custom && customDates != null) {
      planned = customDates;
    }

    // 3. Create Object
    final question = Question(
      id: qId,
      userId: userId,
      imageUrl: imageUrl,
      ders: ders,
      konu: konu,
      notlar: notlar,
      eklenmeTarihi: now,
      tekrarStratejisi: strategy,
      hedefTekrarSayisi: customRepeatCount ?? planned.length,
      planlananTekrarlar: planned,
      tamamlananTekrarlar: [],
    );

    // 4. Save to RTDB
    final ref = _db.ref("users/$userId/mistakes/$qId");
    await ref.set(question.toMap());
  }

  // Mark a review as done for today (or specific date)
  Future<void> markReviewDone(String userId, String questionId,
      {DateTime? targetDate}) async {
    final ref = _db.ref("users/$userId/mistakes/$questionId");
    await ref.runTransaction((Object? post) {
      if (post == null) {
        return Transaction.success(post);
      }
      final Map<dynamic, dynamic> data = post as Map<dynamic, dynamic>;
      List<String> done = [];
      if (data['tamamlananTekrarlar'] != null) {
        done = List<String>.from(data['tamamlananTekrarlar']);
      }

      // Use targetDate if provided, else Now
      DateTime dateToSave = targetDate ?? DateTime.now();

      // Prevent duplicates within standard same-day logic if needed,
      // but for now just add. We might want to avoid spamming.
      done.add(dateToSave.toIso8601String());

      data['tamamlananTekrarlar'] = done;
      return Transaction.success(data);
    });
  }

  // Remove the last review (Undo)
  Future<void> undoReview(String userId, String questionId) async {
    final ref = _db.ref("users/$userId/mistakes/$questionId");
    await ref.runTransaction((Object? post) {
      if (post == null) {
        return Transaction.success(post);
      }
      final Map<dynamic, dynamic> data = post as Map<dynamic, dynamic>;
      List<String> done = [];
      if (data['tamamlananTekrarlar'] != null) {
        done = List<String>.from(data['tamamlananTekrarlar']);
      }
      if (done.isNotEmpty) {
        // Remove the last added date
        // Sort to be safe? usually appended.
        // Let's just remove last.
        done.removeLast();
      }
      data['tamamlananTekrarlar'] = done;
      return Transaction.success(data);
    });
  }
}
