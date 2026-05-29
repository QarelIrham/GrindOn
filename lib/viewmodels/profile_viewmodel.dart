import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_schema.dart';
import '../models/avatar_data.dart';
import '../services/audio_service.dart';

// --- KELAS VIEWMODEL: Profil User (Profile Screen) ---
// Bertugas menangani logika di dalam layar profil, termasuk Toko Avatar,
// manajemen Inventory (Tas), dan status karakter RPG secara mendetail.
class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Data
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _userName = 'User';
  String get userName => _userName;

  String _username = '';
  String get username => _username;

  String _email = '';
  String get email => _email;

  int _level = 1;
  int get level => _level;

  int _xp = 0;
  int get xp => _xp;

  int _streak = 0;
  int get streak => _streak;

  int _totalTasksDone = 0;
  int get totalTasksDone => _totalTasksDone;

  int _totalTasksFailed = 0;
  int get totalTasksFailed => _totalTasksFailed;

  int _longestStreak = 0;
  int get longestStreak => _longestStreak;

  int _coin = 0;
  int get coin => _coin;

  int _hp = 100;
  int get hp => _hp;

  int _maxHp = 100;
  int get maxHp => _maxHp;

  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  Map<String, String> _equippedItems = {
    'head': 'none',
    'clothes': 'none',
    'pants': 'none',
    'pet': 'none',
    'background': 'default',
  };
  Map<String, String> get equippedItems => _equippedItems;

  Map<String, int> _inventory = {};
  Map<String, int> get inventory => _inventory;

  List<String> _unlockedItems = ['none', 'default'];
  List<String> get unlockedItems => _unlockedItems;

  Map<String, int> _categoryXp = {};
  Map<String, int> get categoryXp => _categoryXp;

  List<String> _claimedBadges = [];
  List<String> get claimedBadges => _claimedBadges;

  List<String> _equippedBadges = [];
  List<String> get equippedBadges => _equippedBadges;

  String? _baseBody;
  String? get baseBody => _baseBody;

  Timestamp? _xpBonusUntil;
  Timestamp? get xpBonusUntil => _xpBonusUntil;

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  ProfileViewModel() {
    _initData();
  }

  void _initData() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _userSubscription = _db.collection('users').doc(uid).snapshots().listen((doc) {
      if (!doc.exists) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      final d = doc.data()!;
      
      _userName = d[UserSchema.name] ?? 'User';
      _username = d[UserSchema.username] ?? '';
      _email = d[UserSchema.email] ?? '';
      _level = d[UserSchema.level] ?? 1;
      _xp = d[UserSchema.xp] ?? 0;
      _streak = d[UserSchema.streak] ?? 0;
      _longestStreak = d[UserSchema.longestStreak] ?? 0;
      _totalTasksDone = d[UserSchema.totalTasksDone] ?? 0;
      _totalTasksFailed = d[UserSchema.totalTasksFailed] ?? 0;
      _coin = d[UserSchema.gold] ?? d['coin'] ?? 0;
      _hp = d[UserSchema.hp] ?? 100;
      _maxHp = d[UserSchema.maxHp] ?? 100;
      _soundEnabled = d[UserSchema.soundEnabled] ?? true;
      _xpBonusUntil = d[UserSchema.xpBonusUntil] as Timestamp?;
      AudioService.isEnabled = _soundEnabled;

      if (d[UserSchema.equippedItems] != null) {
        _equippedItems = Map<String, String>.from(d[UserSchema.equippedItems]);
      }
      if (d[UserSchema.unlockedItems] != null) {
        _unlockedItems = List<String>.from(d[UserSchema.unlockedItems]);
        if (!_unlockedItems.contains('none')) _unlockedItems.add('none');
        if (!_unlockedItems.contains('default')) _unlockedItems.add('default');
      }
      if (d[UserSchema.inventory] != null && d[UserSchema.inventory] is Map) {
        _inventory = Map<String, int>.from(d[UserSchema.inventory]);
      }
      if (d[UserSchema.claimedBadges] != null) {
        _claimedBadges = List<String>.from(d[UserSchema.claimedBadges]);
      }
      if (d[UserSchema.equippedBadges] != null) {
        _equippedBadges = List<String>.from(d[UserSchema.equippedBadges]);
      }
      _categoryXp = {
        'Strength': d[UserSchema.strengthXp] ?? 0,
        'Agility': d[UserSchema.agilityXp] ?? 0,
        'Intelligence': d[UserSchema.intelligenceXp] ?? 0,
        'Defense': d[UserSchema.defenseXp] ?? 0,
        'Vitality': d[UserSchema.vitalityXp] ?? 0,
      };
      _baseBody = d[UserSchema.baseBody] as String?;

      _isLoading = false;
      notifyListeners();
    });
  }

  // --- FUNGSI: Mengklaim Hadiah Badge ---
  // Dipanggil ketika pengguna menekan tombol "Klaim" pada Badge yang sudah terbuka.
  Future<void> claimBadgeReward(AppBadge badge) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (_claimedBadges.contains(badge.id)) return; // Sudah diklaim

    try {
      AudioService.playClick();
      // Tambahkan Gold & XP
      final int newGold = _coin + badge.rewardGold;
      final int newXp = _xp + badge.rewardXp;
      final List<String> newClaimed = List.from(_claimedBadges)..add(badge.id);

      await _db.collection('users').doc(uid).update({
        UserSchema.gold: newGold,
        UserSchema.xp: newXp,
        UserSchema.claimedBadges: newClaimed,
      });

      // Update state local sebelum sinkronisasi stream agar terasa cepat
      _coin = newGold;
      _xp = newXp;
      _claimedBadges = newClaimed;
      notifyListeners();

      // Anda dapat menampilkan UI overlay di Widget setelah memanggil fungsi ini
    } catch (e) {
      debugPrint("Error claim badge: $e");
    }
  }

  // --- FUNGSI: Menggunakan Badge (Equip) ---
  Future<void> equipBadge(String badgeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (!_claimedBadges.contains(badgeId)) return; // Belum diklaim
    if (_equippedBadges.contains(badgeId)) return; // Sudah di-equip

    final List<String> newEquipped = List.from(_equippedBadges);
    if (newEquipped.length >= 3) {
      newEquipped.removeAt(0); // Buang yang paling lama jika sudah 3
    }
    newEquipped.add(badgeId);

    try {
      await _db.collection('users').doc(uid).update({
        UserSchema.equippedBadges: newEquipped,
      });
      AudioService.playClick();
    } catch (e) {
      debugPrint("Error equip badge: $e");
    }
  }

  // --- FUNGSI: Melepas Badge (Unequip) ---
  Future<void> unequipBadge(String badgeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (!_equippedBadges.contains(badgeId)) return;

    final List<String> newEquipped = List.from(_equippedBadges)..remove(badgeId);

    try {
      await _db.collection('users').doc(uid).update({
        UserSchema.equippedBadges: newEquipped,
      });
      AudioService.playClick();
    } catch (e) {
      debugPrint("Error unequip badge: $e");
    }
  }

  // --- FUNGSI: Mengubah Avatar ---Membeli Item (Avatar) ---
  // Dipanggil saat user menekan item di Toko.
  // Akan mengecek apakah item sudah dimiliki. Jika belum, cek saldo koin (Gold).
  Future<String?> handleEquip(String category, String itemId) async {
    String dbKey = _getDbKeyFromCategory(category);

    if (category == 'Body 1 item' || category == 'Body 1 Set') {
      _equippedItems['pants'] = 'none';
    } else if (category == 'Pants') {
      final currentClothesId = _equippedItems['clothes'];
      if (currentClothesId != null) {
        final currentItem = AvatarData.allItems.firstWhere((e) => e.id == currentClothesId, orElse: () => AvatarData.allItems[0]);
        if (currentItem.category == 'Body 1 Set') _equippedItems['clothes'] = 'none';
      }
    }

    if (!_unlockedItems.contains(itemId)) {
      final item = AvatarData.allItems.firstWhere((e) => e.id == itemId);
      if (_coin >= item.price) {
        return await _processPurchase(item, dbKey);
      } else {
        AudioService.playClick();
        return 'INSUFFICIENT_COINS:${item.price}'; // Return error code
      }
    } else {
      AudioService.playClick();
      await _updateEquippedItem(dbKey, itemId);
      return null; // Success
    }
  }

  Future<void> saveInitialCharacter(String gender, String bodyId, String headId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    await _db.collection('users').doc(uid).update({
      UserSchema.gender: gender,
      UserSchema.baseBody: bodyId,
      UserSchema.defaultHead: headId,
      '${UserSchema.equippedItems}.head': headId,
      '${UserSchema.equippedItems}.clothes': bodyId,
    });
  }

  Future<void> completeInteractiveTutorial() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update({
      UserSchema.xp: FieldValue.increment(50),
      UserSchema.gold: FieldValue.increment(100),
      UserSchema.onboardingDone: true,
    });
  }

  String _getDbKeyFromCategory(String category) {
    switch (category) {
      case 'Head': return 'head';
      case 'Pants': return 'pants';
      case 'Pet': return 'pet';
      case 'Wallpaper': return 'background';
      default: return 'clothes';
    }
  }

  Future<String?> _processPurchase(AvatarItem item, String dbKey) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'NOT_LOGGED_IN';

    _coin -= item.price;
    if (!_unlockedItems.contains(item.id)) _unlockedItems.add(item.id);
    _equippedItems[dbKey] = item.id;

    AudioService.playCoin();
    final stats = AvatarData.getEquippedStats(_equippedItems);
    final newMaxHp = 100 + (stats['maxHp'] ?? 0.0).toInt();

    await _db.collection('users').doc(uid).update({
      UserSchema.gold: _coin,
      UserSchema.unlockedItems: _unlockedItems,
      UserSchema.equippedItems: _equippedItems,
      UserSchema.maxHp: newMaxHp,
    });
    return null;
  }

  Future<void> _updateEquippedItem(String dbKey, String itemId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _equippedItems[dbKey] = itemId;
    final stats = AvatarData.getEquippedStats(_equippedItems);
    final newMaxHp = 100 + (stats['maxHp'] ?? 0.0).toInt();

    await _db.collection('users').doc(uid).update({
      UserSchema.equippedItems: _equippedItems,
      UserSchema.maxHp: newMaxHp,
    });
  }

  // --- FUNGSI: Membeli Barang Sekali Pakai (Potion) ---
  Future<bool> buyConsumable(String itemId, int price) async {
    if (_coin < price) return false;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    AudioService.playCoin();
    await _db.collection('users').doc(uid).update({
      UserSchema.gold: FieldValue.increment(-price),
      '${UserSchema.inventory}.$itemId': FieldValue.increment(1),
    });
    return true;
  }

  // --- FUNGSI: Menggunakan Barang (Potion) ---
  // Menerapkan efek barang ke database (contoh: Red Potion menambah 30 HP).
  Future<String?> useConsumable(String itemId) async {
    final count = _inventory[itemId] ?? 0;
    if (count <= 0) return null;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    AudioService.playClick();
    
    Map<String, dynamic> updates = {
      '${UserSchema.inventory}.$itemId': FieldValue.increment(-1)
    };
    
    if (itemId == 'red_potion') {
      updates[UserSchema.hp] = (_hp + 30).clamp(0, _maxHp);
    } else if (itemId == 'blue_potion') {
      updates[UserSchema.hp] = (_hp + 60).clamp(0, _maxHp);
    } else if (itemId == 'green_potion') {
      updates[UserSchema.hp] = (_hp + 100).clamp(0, _maxHp);
    } else if (itemId == 'strength_potion') {
      updates[UserSchema.strengthXp] = FieldValue.increment(50);
    } else if (itemId == 'agility_potion') {
      updates[UserSchema.agilityXp] = FieldValue.increment(50);
    } else if (itemId == 'intelligence_potion') {
      updates[UserSchema.intelligenceXp] = FieldValue.increment(50);
    } else if (itemId == 'xp_scroll') {
      updates[UserSchema.xpBonusUntil] = Timestamp.fromDate(DateTime.now().add(const Duration(hours: 1)));
    }

    await _db.collection('users').doc(uid).update(updates);
    return itemId;
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
