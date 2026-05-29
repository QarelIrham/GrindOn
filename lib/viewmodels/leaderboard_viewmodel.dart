import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_schema.dart';

// --- KELAS VIEWMODEL: Papan Peringkat (Leaderboard) ---
// Bertugas mengambil 50 pemain terbaik dari seluruh dunia berdasarkan Level mereka.
class LeaderboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _leaderboardList = [];
  List<Map<String, dynamic>> get leaderboardList => _leaderboardList;

  StreamSubscription<QuerySnapshot>? _leaderboardSubscription;

  LeaderboardViewModel() {
    _initData();
  }

  // --- FUNGSI INISIALISASI ---
  // Membuka stream ke koleksi 'users', diurutkan berdasarkan field 'level' secara menurun (descending).
  void _initData() {
    _leaderboardSubscription = _db
        .collection('users')
        .orderBy(UserSchema.level, descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      _leaderboardList = snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error listening to leaderboard: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _leaderboardSubscription?.cancel();
    super.dispose();
  }
}
