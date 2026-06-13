import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';
import '../auth_repository.dart';

/// Firebase implementation of AuthRepository.
/// Uses Firebase Phone Authentication.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<UserModel?> login({
    required String username,
    required String password,
  }) async {
    try {
      final email = '$username@netlearn.com';
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUser(userCredential.user!);
    } catch (e) {
      throw Exception('Login gagal. Periksa username dan password Anda.');
    }
  }

  @override
  Future<UserModel?> register({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final email = '$username@netlearn.com';
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user!.updateDisplayName(name);
      
      // In a real app, save to Firestore:
      // await _firestore.collection('users').doc(userCredential.user!.uid).set({...})
      
      return _mapFirebaseUser(
        userCredential.user!,
        overrideName: name,
        overridePhone: phoneNumber,
      );
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    // In a real app, you would fetch additional data from Firestore here
    return _mapFirebaseUser(user);
  }

  /// Initiates Google Sign-In flow
  Future<UserModel?> signInWithGoogle() async {
    // try {
    //   final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    //   if (googleUser == null) return null; // Cancelled by user

    //   final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    //   final AuthCredential credential = GoogleAuthProvider.credential(
    //     accessToken: googleAuth.accessToken,
    //     idToken: googleAuth.idToken,
    //   );

    //   final userCredential = await _auth.signInWithCredential(credential);
    //   return _mapFirebaseUser(userCredential.user!);
    // } catch (e) {
    //   throw Exception('Gagal login dengan Google: $e');
    // }
    return null; // Placeholder for Phase 2
  }

  @override
  Future<void> updateUser(UserModel user) async {
    // In a real app, save updated user object to Firestore
  }

  @override
  Future<UserModel?> createUser({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    return register(
      name: name,
      username: username,
      phoneNumber: phoneNumber,
      password: password,
    );
  }

  @override
  Future<void> deleteUser(String userId) async {
    // Not implemented for FirebaseAuth-only flow.
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final current = await getCurrentUser();
    if (current == null) return [];
    return [current];
  }

  UserModel _mapFirebaseUser(User fbUser, {String? overrideName, String? overridePhone}) {
    return UserModel(
      id: fbUser.uid,
      displayName: overrideName ?? fbUser.displayName ?? 'Pengguna',
      phoneNumber: overridePhone ?? fbUser.phoneNumber ?? '',
      lastActive: DateTime.now(),
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    );
  }
}
