import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/trial_exam_model.dart';

class TrialService {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app');

  // Add a new trial exam
  // Add a new trial exam
  Future<void> addTrial(String userId, TrialExam exam) async {
    final ref = _db.ref("users/$userId/trials/${exam.id}");
    await ref.set(exam.toMap());
  }

  // Delete a trial exam
  Future<void> deleteTrial(String userId, String trialId) async {
    final ref = _db.ref("users/$userId/trials/$trialId");
    await ref.remove();
  }

  // Stream of trials for a user
  Stream<List<TrialExam>> getTrialsStream(String userId) {
    final ref = _db.ref("users/$userId/trials");
    return ref.onValue.map((event) {
      if (event.snapshot.value == null) {
        return [];
      }
      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      return data.values
          .map((e) {
            try {
              // Eğer veri null veya map değilse atla
              if (e == null || e is! Map) return null;
              return TrialExam.fromMap(e);
            } catch (error) {
              // Hatalı veri varsa logla ama uygulamayı çökertme
              print("Trial parse error: $error");
              return null;
            }
          })
          .whereType<TrialExam>()
          .toList(); // Null'ları temizle
    });
  }
}
