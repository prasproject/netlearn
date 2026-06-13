import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/quiz_model.dart';
import '../quiz_repository.dart';

/// Firebase Firestore implementation of QuizRepository.
class FirestoreQuizRepository implements QuizRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<QuizModel>> getAllQuizzes() async {
    final snapshot = await _firestore.collection('quizzes').get();
    return snapshot.docs.map((doc) => QuizModel.fromJson(doc.data())).toList();
  }

  @override
  Future<QuizModel?> getQuizById(String id) async {
    final doc = await _firestore.collection('quizzes').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return QuizModel.fromJson(doc.data()!);
  }

  @override
  Future<List<QuizModel>> getQuizzesByType(QuizType type) async {
    final snapshot = await _firestore
        .collection('quizzes')
        .where('type', isEqualTo: type.name)
        .get();
    return snapshot.docs.map((doc) => QuizModel.fromJson(doc.data())).toList();
  }

  @override
  Future<QuizModel?> getQuizByUnit(String unitId, QuizType type) async {
    final snapshot = await _firestore
        .collection('quizzes')
        .where('unitId', isEqualTo: unitId)
        .where('type', isEqualTo: type.name)
        .limit(1)
        .get();
        
    if (snapshot.docs.isEmpty) return null;
    return QuizModel.fromJson(snapshot.docs.first.data());
  }

  @override
  Future<void> createQuiz(QuizModel quiz) async {
    await _firestore.collection('quizzes').doc(quiz.id).set(quiz.toJson());
  }

  @override
  Future<void> updateQuiz(QuizModel quiz) async {
    await _firestore
        .collection('quizzes')
        .doc(quiz.id)
        .set(quiz.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteQuiz(String id) async {
    await _firestore.collection('quizzes').doc(id).delete();
  }
}
