import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/user_model.dart';
import '../auth_repository.dart';

/// Firebase Realtime Database implementation of AuthRepository (Custom Auth).
class RtdbAuthRepository extends AuthRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('users');
  final _storage = GetStorage();

  @override
  bool get supportsRealtime => true;

  /// Normalise any RTDB payload (native Map on mobile, JS interop map on web).
  static Map<String, dynamic> _asMap(Object? value) {
    try {
      return Map<String, dynamic>.from(value as Map);
    } catch (_) {
      return Map<String, dynamic>.from(jsonDecode(jsonEncode(value)));
    }
  }

  /// Live user record, so XP/level/streak/settings on screen always match the
  /// database — including changes made from another device or by the admin.
  @override
  Stream<UserModel?> watchUser(String userId) {
    if (userId.trim().isEmpty || userId == 'admin') {
      return const Stream<UserModel?>.empty();
    }
    return _db.child(userId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return null;
      final map = _asMap(snapshot.value);
      map['id'] = userId;
      try {
        final user = UserModel.fromJson(map);
        _storage.write('currentUser', user.toJson());
        return user;
      } catch (_) {
        return null;
      }
    });
  }

  /// XP is incremented inside a transaction so two rewards fired close together
  /// (e.g. finishing a slide and a quiz) can never overwrite each other.
  @override
  Future<UserModel?> addXp(String userId, int amount) async {
    if (userId.trim().isEmpty || amount <= 0) return null;
    final ref = _db.child(userId);

    final result = await ref.runTransaction((raw) {
      if (raw == null) return Transaction.abort();
      final Map<String, dynamic> map;
      try {
        map = _asMap(raw);
      } catch (_) {
        return Transaction.abort();
      }
      final currentXp = switch (map['xp']) {
        int v => v,
        num v => v.toInt(),
        String v => int.tryParse(v) ?? 0,
        _ => 0,
      };
      final newXp = currentXp < 0 ? amount : currentXp + amount;
      map['xp'] = newXp;
      map['level'] = (newXp ~/ 100) + 1;
      return Transaction.success(map);
    });

    if (!result.committed) return null;
    final value = result.snapshot.value;
    if (value == null) return null;
    try {
      final map = _asMap(value);
      map['id'] = userId;
      final user = UserModel.fromJson(map);
      await _storage.write('currentUser', user.toJson());
      return user;
    } catch (_) {
      return null;
    }
  }

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
    String? schoolName,
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
        schoolName: schoolName,
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
    String? schoolName,
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
        schoolName: schoolName,
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
