import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/user_model.dart';
import '../auth_repository.dart';

/// Firebase Realtime Database implementation of AuthRepository (Custom Auth).
class RtdbAuthRepository implements AuthRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('users');
  final _storage = GetStorage();

  @override
  Future<UserModel?> login({
    required String username,
    required String password,
  }) async {
    try {
      final snapshot = await _db.child(username).get();
      if (!snapshot.exists) {
        throw Exception('Akun tidak ditemukan. Silakan mendaftar terlebih dahulu.');
      }
      
      // Mengatasi masalah "LinkedMap" / JSInterop di Flutter Web
      final Object? value = snapshot.value;
      Map<String, dynamic> map;
      try {
        // Coba parsing standar
        map = Map<String, dynamic>.from(value as Map);
      } catch (_) {
        // Fallback paling aman untuk tipe data internal Web
        map = Map<String, dynamic>.from(jsonDecode(jsonEncode(value)));
      }
      
      if (map['password'] != password) {
        throw Exception('Password salah.');
      }

      map['id'] = username; // Ensure ID matches username
      final userModel = UserModel.fromJson(map);
      
      // Save session locally
      await _storage.write('currentUser', userModel.toJson());
      
      return userModel;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
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
      final snapshot = await _db.child(username).get();
      if (snapshot.exists) {
        throw Exception('Username sudah dipakai. Silakan gunakan yang lain.');
      }
      
      final userModel = UserModel(
        id: username,
        displayName: name,
        phoneNumber: phoneNumber,
        password: password,
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
        role: username == 'admin' ? 'admin' : 'student',
      );
      
      // Save to RTDB
      await _db.child(username).set(userModel.toJson());
      
      // Save session locally
      await _storage.write('currentUser', userModel.toJson());
      
      return userModel;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> logout() async {
    await _storage.remove('currentUser');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // Read from local storage (Offline support)
    final localData = _storage.read('currentUser');
    if (localData != null) {
      try {
        final userModel = UserModel.fromJson(Map<String, dynamic>.from(localData));
        
        // Background sync to update local storage with the latest from server
        _db.child(userModel.id).get().then((snapshot) {
          if (snapshot.exists) {
            Map<String, dynamic> map;
            try {
              map = Map<String, dynamic>.from(snapshot.value as Map);
            } catch (_) {
              map = Map<String, dynamic>.from(jsonDecode(jsonEncode(snapshot.value)));
            }
            map['id'] = userModel.id;
            _storage.write('currentUser', map); // Update cache
          }
        }).catchError((_) {}); // Ignore network errors during sync
        
        return userModel;
      } catch (e) {
        // Fallback
      }
    }
    return null;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _db.child(user.id).update(user.toJson());
    await _storage.write('currentUser', user.toJson());
  }

  @override
  Future<UserModel?> createUser({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final snapshot = await _db.child(username).get();
      if (snapshot.exists) {
        throw Exception('Username sudah dipakai. Silakan gunakan yang lain.');
      }

      final now = DateTime.now();
      final userModel = UserModel(
        id: username,
        displayName: name,
        phoneNumber: phoneNumber,
        password: password,
        lastActive: now,
        createdAt: now,
        role: 'student',
      );

      await _db.child(username).set(userModel.toJson());
      return userModel;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _db.child(userId).remove();
    final currentUser = _storage.read('currentUser');
    if (currentUser is Map && currentUser['id'] == userId) {
      await _storage.remove('currentUser');
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _db.get();
      if (snapshot.exists) {
        Map<String, dynamic> data;
        try {
          data = Map<String, dynamic>.from(snapshot.value as Map);
        } catch (_) {
          data = Map<String, dynamic>.from(jsonDecode(jsonEncode(snapshot.value)));
        }

        return data.entries.map((entry) {
          final map = Map<String, dynamic>.from(entry.value as Map);
          map['id'] = entry.key;
          return UserModel.fromJson(map);
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}
