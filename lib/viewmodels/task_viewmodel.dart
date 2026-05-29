import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/app_schema.dart';
import '../models/avatar_data.dart';

// ── TASK VIEW MODEL ──────────────────────────────────────────────────
// Bertugas mengatur semua logika database (Firestore) yang berhubungan
// dengan tugas (Tasks). Termasuk perhitungan RPG kompleks seperti
// XP, Gold, Level Up, Streak, dan hukuman (Penalty).
class TaskViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Menyimpan semua task yang ada di database
  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> get allTasks => _allTasks;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Mencegah double-click yang memunculkan dua popup sekaligus
  final Set<String> _processingTasks = {};

  StreamSubscription<QuerySnapshot>? _tasksSubscription;

  TaskViewModel() {
    _initData();
  }

  // 1. Inisialisasi Data
  void _initData() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _tasksSubscription = _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _allTasks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error listening to tasks: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  // 2. Mengambil Tugas Berdasarkan Kategori
  List<Map<String, dynamic>> getTasksByCategory(String category) {
    return _allTasks.where((task) => task['category'] == category).toList();
  }

  // 3. Menyimpan Tugas Baru
  Future<bool> saveTask({
    required String title,
    required String notes,
    required String category,
    required int difficulty,
    required int durationMinutes,
    required String proofType,
    required DateTime selectedDate,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      final taskId = const Uuid().v4();
      
      // Calculate base reward based on difficulty (0 to 4)
      final xpReward = [0, 20, 40, 80, 150][difficulty.clamp(0, 4)];
      final goldReward = (xpReward / 4).ceil();

      final taskData = {
        TaskSchema.id: taskId,
        TaskSchema.title: title.trim(),
        TaskSchema.category: category,
        TaskSchema.difficulty: difficulty,
        TaskSchema.notes: notes.trim(),
        TaskSchema.createdAt: FieldValue.serverTimestamp(),
        TaskSchema.done: false,
        TaskSchema.completedAt: null,
        TaskSchema.duration: durationMinutes,
        TaskSchema.proofType: proofType,
        TaskSchema.deadline: Timestamp.fromDate(selectedDate),
        TaskSchema.xp: xpReward,
        TaskSchema.goldReward: goldReward,
        TaskSchema.uid: uid,
        TaskSchema.timerStatus: TaskSchema.timerIdle,
        TaskSchema.timerStartAt: null,
        TaskSchema.failedAt: null,
        TaskSchema.proofUrl: '',
        TaskSchema.proofText: '',
        TaskSchema.isVerified: false,
        TaskSchema.isCursed: false,
        TaskSchema.cursedMultiplier: 1.0,
        TaskSchema.frequency: TaskSchema.freqDaily,
      };

      await _db
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .set(taskData);

      return true;
    } catch (e) {
      debugPrint('Error saving task: $e');
      return false;
    }
  }

  // 4. Mengubah Status Misi (Fast Path: Tanpa Proof / Batal Selesai)
  Future<Map<String, int>?> toggleDone(String taskId, bool currentStatus, int diff) async {
    if (currentStatus) {
      // Jika sebelumnya "Selesai" (true) -> "Belum Selesai" (false)
      // Kita hanya membatalkan status done tanpa menarik reward (agar simple)
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      await _db
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .update({
        TaskSchema.done: false,
        TaskSchema.completedAt: null,
      });
      return null;
    } else {
      // Jika sebelumnya "Belum Selesai" (false) -> "Selesai" (true)
      // Gunakan Advanced RPG Logic
      return await completeTask(taskId, proofUrl: '', proofText: '');
    }
  }

  // 5. Menyelesaikan Tugas (Dengan/Tanpa Proof) + Kalkulasi RPG
  Future<Map<String, int>?> completeTask(
    String taskId, {
    required String proofUrl,
    required String proofText,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    if (_processingTasks.contains(taskId)) return null; // Cegah double tap
    _processingTasks.add(taskId);

    try {
      // 1. Ambil Data Task
      final taskDoc = await _db.collection('users').doc(uid).collection('tasks').doc(taskId).get();
      if (!taskDoc.exists || taskDoc.data()?[TaskSchema.done] == true) {
        _processingTasks.remove(taskId);
        return null;
      }
      final taskData = taskDoc.data()!;

      final baseXP = taskData[TaskSchema.xp] ?? 20;
      final baseGold = taskData[TaskSchema.goldReward] ?? 5;
      final category = taskData[TaskSchema.category] ?? 'Strength';

      // 2. Update Status Task di Firebase
      await _db.collection('users').doc(uid).collection('tasks').doc(taskId).update({
        TaskSchema.done: true,
        TaskSchema.isVerified: true,
        TaskSchema.proofUrl: proofUrl,
        TaskSchema.proofText: proofText.trim(),
        TaskSchema.completedAt: FieldValue.serverTimestamp(),
        TaskSchema.timerStatus: TaskSchema.timerCompleted,
      });

      // 3. Kalkulasi Hadiah RPG
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      
      final currentHp = userData[UserSchema.hp] ?? 100;
      final maxHp = userData[UserSchema.maxHp] ?? 100;
      final currentStreak = userData[UserSchema.streak] ?? 0;
      final str = userData[UserSchema.strengthXp] ?? 0;
      final def = userData[UserSchema.defenseXp] ?? 0;
      final intl = userData[UserSchema.intelligenceXp] ?? 0;
      final vit = userData[UserSchema.vitalityXp] ?? 0;
      final agi = userData[UserSchema.agilityXp] ?? 0;
      final totalDone = userData[UserSchema.totalTasksDone] ?? 0;
      final level = userData[UserSchema.level] ?? 1;

      int finalXp = baseXP;

      // A. Cek Item Aktif (Double XP Scroll)
      final xpBonusUntil = userData[UserSchema.xpBonusUntil] as Timestamp?;
      if (xpBonusUntil != null && xpBonusUntil.toDate().isAfter(DateTime.now())) {
        finalXp *= 2;
      }

      // B. Cek HP Penalty (Jika sekarat)
      finalXp = RankSystem.effectiveXp(finalXp, currentHp);
      
      // C. Cek Konsistensi (Streak Bonus)
      finalXp = RankSystem.streakBonusXp(finalXp, currentStreak);

      // D. Cek Pakaian Avatar (Passive Boosts)
      final equipped = Map<String, String>.from(userData[UserSchema.equippedItems] ?? {});
      final passiveStats = AvatarData.getEquippedStats(equipped);
      final xpBoost = passiveStats['xpBoost'] ?? 0.0;
      final goldBoost = passiveStats['goldBoost'] ?? 0.0;

      finalXp = (finalXp * (1.0 + xpBoost)).round();
      final int finalGold = (baseGold * (1.0 + goldBoost)).round();

      // E. Healing (Isi Darah)
      final int newHp = (currentHp + RankSystem.hpGainOnTaskComplete).clamp(0, maxHp);

      // 4. Update Profil Pengguna
      final catXpField = _categoryXpField(category);
      await _db.collection('users').doc(uid).update({
        UserSchema.xp: FieldValue.increment(finalXp),
        UserSchema.gold: FieldValue.increment(finalGold),
        UserSchema.hp: newHp,
        if (catXpField != null) catXpField: FieldValue.increment(finalXp),
        UserSchema.totalTasksDone: FieldValue.increment(1),
      });

      // 5. Update Streak & Level
      await _updateStreak(uid);
      await _checkLevelUp(uid);

      final currentTitle = RankSystem.getDynamicTitle(str, def, intl, vit, agi, RankSystem.calculateRank(level), level, totalDone);
      
      _processingTasks.remove(taskId);
      return {
        'xp': finalXp,
        'coin': finalGold,
      };
    } catch (e) {
      debugPrint('Error completing task: $e');
      _processingTasks.remove(taskId);
      return null;
    }
  }

  // 6. Timer Actions
  Future<void> startTaskTimer(String taskId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('tasks').doc(taskId).update({
      TaskSchema.timerStatus: TaskSchema.timerRunning,
      TaskSchema.timerStartAt: FieldValue.serverTimestamp(),
    });
  }

  Future<void> failTaskTimer(String taskId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // 1. Ubah status task menjadi Gagal
    await _db.collection('users').doc(uid).collection('tasks').doc(taskId).update({
      TaskSchema.timerStatus: TaskSchema.timerFailed,
      TaskSchema.failedAt: FieldValue.serverTimestamp(),
      TaskSchema.done: false,
    });

    // 2. Berikan Penalti
    await _db.collection('users').doc(uid).update({
      UserSchema.hp: FieldValue.increment(-RankSystem.hpLossOnTaskFail),
      UserSchema.gold: FieldValue.increment(-15),
      UserSchema.xp: FieldValue.increment(-10),
      UserSchema.totalTasksFailed: FieldValue.increment(1),
      UserSchema.streak: 0, // Reset Streak
    });
  }

  Future<void> completeTaskTimer(String taskId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('tasks').doc(taskId).update({
      TaskSchema.timerStatus: TaskSchema.timerCompleted,
    });
  }

  // 7. Menghapus Misi
  Future<void> deleteTask(String taskId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // ── Helper Methods ──────────────────────────────────────────────

  String? _categoryXpField(String category) {
    switch (category) {
      case 'Strength': return UserSchema.strengthXp;
      case 'Defense': return UserSchema.defenseXp;
      case 'Intelligence': return UserSchema.intelligenceXp;
      case 'Vitality': return UserSchema.vitalityXp;
      case 'Agility': return UserSchema.agilityXp;
      default: return null;
    }
  }

  String _dateString(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _updateStreak(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final lastActive = data[UserSchema.lastActiveDate] as String? ?? '';
    final today = _dateString(DateTime.now());
    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));

    int currentStreak = data[UserSchema.streak] ?? 0;
    int longestStreak = data[UserSchema.longestStreak] ?? 0;

    if (lastActive == today) return;

    if (lastActive == yesterday) {
      currentStreak += 1;
    } else {
      currentStreak = 1;
    }

    if (currentStreak > longestStreak) longestStreak = currentStreak;

    await _db.collection('users').doc(uid).update({
      UserSchema.streak: currentStreak,
      UserSchema.longestStreak: longestStreak,
      UserSchema.lastActiveDate: today,
    });
  }

  Future<void> _checkLevelUp(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    int xp = data[UserSchema.xp] ?? 0;
    int level = data[UserSchema.level] ?? 1;

    int xpNeeded = RankSystem.xpForLevel(level);
    bool leveledUp = false;
    while (xp >= xpNeeded) {
      xp -= xpNeeded; // Konsumsi XP untuk naik level
      level++;
      xpNeeded = RankSystem.xpForLevel(level);
      leveledUp = true;
    }

    if (leveledUp) {
      final newRank = RankSystem.calculateRank(level);
      await _db.collection('users').doc(uid).update({
        UserSchema.level: level,
        UserSchema.rank: newRank,
        UserSchema.xp: xp, // Simpan sisa XP kembali ke database
      });
    }
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
