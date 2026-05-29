import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_schema.dart';
import '../services/notification_service.dart';
import '../services/locale_service.dart';

// --- KELAS VIEWMODEL: Layar Utama (Home Screen) ---
// Ini adalah "Otak" utama dari aplikasi. HomeViewModel menarik data profil user
// dan daftar misi hari ini secara REAL-TIME (terus-menerus), lalu menyalurkannya
// ke berbagai widget (seperti bar HP, bar XP, dan daftar tugas).
class HomeViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State Variables
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _userName = 'User';
  String get userName => _userName;

  String _username = '';
  String get username => _username;

  int _xp = 0;
  int get xp => _xp;

  int _level = 1;
  int get level => _level;

  int _hp = 80;
  int get hp => _hp;

  int _maxHp = 100;
  int get maxHp => _maxHp;

  int _coin = 0;
  int get coin => _coin;

  String _role = 'user';
  String get role => _role;

  String _rank = 'F';
  String get rank => _rank;

  Map<String, String> _equippedItems = {};
  Map<String, String> get equippedItems => _equippedItems;

  String? _baseBody;
  String? get baseBody => _baseBody;

  String _dynamicTitle = 'The Beginner';
  String get dynamicTitle => _dynamicTitle;

  Timestamp? _xpBonusUntil;
  Timestamp? get xpBonusUntil => _xpBonusUntil;

  // Stream untuk memberi tahu UI (HomeScreen) bahwa julukan baru saja berubah
  final _titleUnlockEvent = StreamController<String>.broadcast();
  Stream<String> get titleUnlockEvent => _titleUnlockEvent.stream;

  bool _isFirstLoad = true;

  Map<String, dynamic> _tutorialsCompleted = {};
  Map<String, dynamic> get tutorialsCompleted => _tutorialsCompleted;

  List<QueryDocumentSnapshot> _todayTasks = [];
  List<QueryDocumentSnapshot> get todayTasks => _todayTasks;

  List<QueryDocumentSnapshot> _allTasks = [];
  List<QueryDocumentSnapshot> get allTasks => _allTasks;

  int _doneCount = 0;
  int get doneCount => _doneCount;

  List<QueryDocumentSnapshot> _recentCompletedTasks = [];
  List<QueryDocumentSnapshot> get recentCompletedTasks => _recentCompletedTasks;

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _tasksSubscription;
  StreamSubscription<User?>? _authSubscription;

  HomeViewModel() {
    // Mendengarkan perubahan status login secara real-time.
    // Jika user berganti (login/logout), data akan direset dan dimuat ulang.
    _authSubscription = _auth.authStateChanges().listen((user) {
      _cancelDataSubscriptions();
      if (user != null) {
        _initData(user.uid);
      } else {
        _clearData();
      }
    });
  }

  // Membatalkan semua stream data (profil & tugas)
  void _cancelDataSubscriptions() {
    _userSubscription?.cancel();
    _tasksSubscription?.cancel();
    _userSubscription = null;
    _tasksSubscription = null;
  }

  // Mengosongkan semua data saat user logout
  void _clearData() {
    _isLoading = true;
    _userName = 'User';
    _username = '';
    _xp = 0;
    _level = 1;
    _hp = 80;
    _maxHp = 100;
    _coin = 0;
    _role = 'user';
    _rank = 'F';
    _equippedItems = {};
    _baseBody = null;
    _tutorialsCompleted = {};
    _todayTasks = [];
    _allTasks = [];
    _doneCount = 0;
    _recentCompletedTasks = [];
    notifyListeners();
  }

  // --- FUNGSI INISIALISASI (Dijalankan Pertama Kali) ---
  // Membuka "Soket Langsung" (StreamSubscription) ke database Firestore.
  // Setiap kali data user atau misi berubah di server, tampilan di HP akan otomatis berubah.
  void _initData(String uid) {

    // Subscribe to User Profile
    _userSubscription = _db.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        final d = doc.data()!;
        _userName = d[UserSchema.name] ?? 'User';
        _username = d[UserSchema.username] ?? '';
        _xp = d[UserSchema.xp] ?? 0;
        _level = d['level'] ?? 1;
        _hp = d[UserSchema.hp] ?? d['hp'] ?? 80;
        _maxHp = d[UserSchema.maxHp] ?? 100;
        _coin = d[UserSchema.gold] ?? d['coin'] ?? 0;
        _role = d[UserSchema.role] ?? 'user';
        _rank = RankSystem.calculateRank(_level);
        
        if (d[UserSchema.equippedItems] != null) {
          _equippedItems = Map<String, String>.from(d[UserSchema.equippedItems]);
        }
        _baseBody = d[UserSchema.baseBody] as String?;

        if (d['tutorialsCompleted'] != null) {
          _tutorialsCompleted = Map<String, dynamic>.from(d['tutorialsCompleted']);
        }

        final str = d[UserSchema.strengthXp] ?? 0;
        final intl = d[UserSchema.intelligenceXp] ?? 0;
        final agi = d[UserSchema.agilityXp] ?? 0;
        final vit = d[UserSchema.vitalityXp] ?? 0;
        final def = d[UserSchema.defenseXp] ?? 0;
        final totalDone = d[UserSchema.totalTasksDone] ?? 0;

        final newTitle = RankSystem.getDynamicTitle(str, def, intl, vit, agi, _rank, _level, totalDone);
        
        if (!_isFirstLoad && newTitle != _dynamicTitle) {
          _titleUnlockEvent.add(newTitle); 
        }
        _dynamicTitle = newTitle;
        _xpBonusUntil = d[UserSchema.xpBonusUntil] as Timestamp?;
        _isFirstLoad = false;
        
        _isLoading = false;
        notifyListeners();
      }
    });

    // Subscribe to Tasks
    _tasksSubscription = _db.collection('users').doc(uid).collection('tasks').snapshots().listen((snap) {
      _allTasks = snap.docs;
      
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      _todayTasks = _allTasks.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final ts = data[TaskSchema.createdAt] as Timestamp?;
        if (ts == null) return false;
        final dt = ts.toDate();
        return dt.isAfter(todayStart) && dt.isBefore(todayEnd);
      }).toList();

      _doneCount = _todayTasks.where((d) {
        final data = d.data() as Map<String, dynamic>;
        return data['done'] == true;
      }).length;

      // Ambil tugas yang sudah selesai, urutkan dari yang terbaru
      _recentCompletedTasks = _allTasks.where((d) {
        final data = d.data() as Map<String, dynamic>;
        return data[TaskSchema.done] == true;
      }).toList();
      _recentCompletedTasks.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        final tA = dataA[TaskSchema.completedAt] as Timestamp?;
        final tB = dataB[TaskSchema.completedAt] as Timestamp?;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });

      notifyListeners();
    });
  }

  // --- FUNGSI: Mengingatkan Misi Yang Belum Selesai ---
  // Memeriksa adakah tugas hari ini yang belum selesai.
  // Jika ada, panggil NotificationService untuk menampilkan pop-up pengingat.
  Future<void> checkPendingTasksAndNotify(LocaleService locSvc) async {
    final pendingTasks = _todayTasks.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return data['done'] == false;
    }).toList();

    if (pendingTasks.isNotEmpty) {
      final l = locSvc.l;
      await NotificationService().showNotification(
        id: 999,
        title: l.notifPendingTitle(pendingTasks.length),
        body: l.notifPendingBody(pendingTasks.length),
      );
    }
  }

  Future<void> completeTutorial(String tabName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _db.collection('users').doc(uid).update({
      'tutorialsCompleted.$tabName': true,
    });
  }

  Future<void> skipAllTutorials() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _db.collection('users').doc(uid).update({
      'tutorialsCompleted.home': true,
      'tutorialsCompleted.daily': true,
      'tutorialsCompleted.stats': true,
      'tutorialsCompleted.profile': true,
    });
  }

  Future<void> markTutorialDone(String tutorialKey) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    _tutorialsCompleted[tutorialKey] = true;
    notifyListeners();

    await _db.collection('users').doc(uid).update({
      'tutorialsCompleted.$tutorialKey': true,
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelDataSubscriptions();
    super.dispose();
  }
}
