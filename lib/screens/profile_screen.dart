import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/audio_service.dart';
import '../models/app_schema.dart';
import '../models/avatar_data.dart';
import '../widget/avatar_shop_view.dart';
import '../widget/badge_gallery_view.dart';
import '../widget/item_shop_view.dart';
import '../widget/theme_card.dart';
import '../widget/settings_sheet.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../widget/screen_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State Variables
  int _selectedTabIndex = 1; // 0 = Badges, 1 = Avatar, 2 = Items
  
  // User Data
  String _userName = 'User';
  String _username = '';
  String _email = '';
  int _level = 1;
  int _streak = 0;
  int _totalTasksDone = 0;
  int _coin = 0;
  int _hp = 100;
  int _maxHp = 100;
  bool _soundEnabled = true;
  bool _musicEnabled = true;

  Map<String, String> _equippedItems = {
    'head': 'none',
    'clothes': 'none',
    'pants': 'none',
    'pet': 'none',
    'background': 'default',
  };
  Map<String, int> _inventory = {};
  List<String> _unlockedItems = ['none', 'default'];
  Map<String, int> _categoryXp = {};
  List<String> _claimedBadges = [];
  List<String> _equippedBadges = [];
  String? _baseBody;
  StreamSubscription<DocumentSnapshot>? _userSub;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _userSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
      if (!mounted || !doc.exists) return;

    final d = doc.data()!;
    setState(() {
      _userName = d[UserSchema.name] ?? 'User';
      _username = d[UserSchema.username] ?? '';
      _email = d[UserSchema.email] ?? '';
      _level = d[UserSchema.level] ?? 1;
      _streak = d[UserSchema.streak] ?? 0;
      _totalTasksDone = d[UserSchema.totalTasksDone] ?? 0;
      _coin = d[UserSchema.gold] ?? d['coin'] ?? 0;
      _hp = d[UserSchema.hp] ?? 100;
      _maxHp = d[UserSchema.maxHp] ?? 100;
      _soundEnabled = d[UserSchema.soundEnabled] ?? true;
      _musicEnabled = d[UserSchema.musicEnabled] ?? true;
      AudioService.isEnabled = _soundEnabled;
      AudioService.isMusicEnabled = _musicEnabled;
      if (_musicEnabled) {
        AudioService.playBgm();
      }

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
      _categoryXp = {
        'Strength': d[UserSchema.strengthXp] ?? 0,
        'Agility': d[UserSchema.agilityXp] ?? 0,
        'Intelligence': d[UserSchema.intelligenceXp] ?? 0,
        'Defense': d[UserSchema.defenseXp] ?? 0,
        'Vitality': d[UserSchema.vitalityXp] ?? 0,
      };
      if (d[UserSchema.claimedBadges] != null) {
        _claimedBadges = List<String>.from(d[UserSchema.claimedBadges]);
      }
      if (d[UserSchema.equippedBadges] != null) {
        _equippedBadges = List<String>.from(d[UserSchema.equippedBadges]);
      }
      _baseBody = d[UserSchema.baseBody] as String?;
    });
  });
  }

  // --- Logic Methods (Logika Bisnis) ---

  // FUNGSI CLAIM & EQUIP BADGE
  Future<void> _claimBadge(AppBadge badge) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _claimedBadges.add(badge.id));
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      UserSchema.claimedBadges: FieldValue.arrayUnion([badge.id])
    });
    // AudioService.playSuccess(); // User requested no sound
  }

  Future<void> _equipBadge(AppBadge badge) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      if (_equippedBadges.contains(badge.id)) {
        _equippedBadges.remove(badge.id);
      } else {
        if (_equippedBadges.length >= 3) {
          _equippedBadges.removeAt(0); // Max 3 badges
        }
        _equippedBadges.add(badge.id);
      }
    });
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      UserSchema.equippedBadges: _equippedBadges,
    });
    // AudioService.playClick(); // User requested no sound
  }

  // FUNGSI MEMAKAI / MEMBELI BAJU AVATAR
  Future<void> _handleEquip(String category, String itemId) async {
    AudioService.playClick();
    String dbKey = _getDbKeyFromCategory(category); // Ubah nama kategori UI jadi key Database (misal 'Pants' jadi 'pants')

    // Aturan Khusus Avatar (Special Logic)
    // Jika user pakai baju terusan (Body 1 Set), maka celana harus dilepas paksa ('none') agar grafisnya tidak tumpang tindih.
    if (category == 'Body 1 item' || category == 'Body 1 Set') {
      _equippedItems['pants'] = 'none';
    } else if (category == 'Pants') {
      // Sebaliknya, jika user mencoba pakai celana padahal sedang pakai setelan terusan, bajunya dilepas
      final currentClothesId = _equippedItems['clothes'];
      if (currentClothesId != null) {
        final currentItem = AvatarData.allItems.firstWhere((e) => e.id == currentClothesId, orElse: () => AvatarData.allItems[0]);
        if (currentItem.category == 'Body 1 Set') _equippedItems['clothes'] = 'none';
      }
    }

    // Cek apakah item ini sudah dibeli (unlocked)
    if (!_unlockedItems.contains(itemId)) {
      // Jika BELUM dibeli, cari harga item tersebut
      final item = AvatarData.allItems.firstWhere((e) => e.id == itemId);
      if (_coin >= item.price) {
        // Jika koin cukup, jalankan fungsi pemotongan koin
        await _processPurchase(item, dbKey);
      } else {
        // Jika koin kurang, munculkan pesan error merah
        _showInadequateGoldSnackBar(item.price);
      }
    } else {
      // Jika SUDAH dibeli, langsung pasang ke badan
      await _updateEquippedItem(dbKey, itemId);
    }
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

  // FUNGSI MEMBELI ITEM AVATAR (Hanya dipanggil dari _handleEquip)
  Future<void> _processPurchase(AvatarItem item, String dbKey) async {
    setState(() {
      _coin -= item.price; // Potong koin lokal
      if (!_unlockedItems.contains(item.id)) _unlockedItems.add(item.id); // Masukkan ke daftar barang yang dimiliki
      _equippedItems[dbKey] = item.id; // Langsung pakai bajunya
    });

    AudioService.playCoin();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Ambil status pasif (Passive Stats) dari semua baju yang sedang dipakai
      // Catatan Sidang: Max HP user bisa bertambah jika memakai baju/pet yang ada status penambah HP
      final stats = AvatarData.getEquippedStats(_equippedItems);
      final newMaxHp = 100 + (stats['maxHp'] ?? 0.0).toInt();

      // Update semuanya secara bersamaan ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        UserSchema.gold: _coin,
        UserSchema.unlockedItems: _unlockedItems,
        UserSchema.equippedItems: _equippedItems,
        UserSchema.maxHp: newMaxHp,
      });
      setState(() => _maxHp = newMaxHp);
    }
  }

  // FUNGSI MEMAKAI ITEM YANG SUDAH DIBELI
  Future<void> _updateEquippedItem(String dbKey, String itemId) async {
    setState(() => _equippedItems[dbKey] = itemId);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Setiap ganti baju, kita harus hitung ulang Max HP-nya siapa tahu baju yang dicopot ngurangin bonus HP
      final stats = AvatarData.getEquippedStats(_equippedItems);
      final newMaxHp = 100 + (stats['maxHp'] ?? 0.0).toInt();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        UserSchema.equippedItems: _equippedItems,
        UserSchema.maxHp: newMaxHp,
      });
      setState(() => _maxHp = newMaxHp);
    }
  }

  void _showInadequateGoldSnackBar(int price) {
    if (!mounted) return;
    final l = context.l;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.profileInsufficientCoins(price), style: GoogleFonts.nunito()),
        backgroundColor: Colors.red,
      ),
    );
  }

  // FUNGSI MEMBELI BARANG HABIS PAKAI (POTION / XP SCROLL)
  Future<void> _buyConsumable(String itemId, int price) async {
    if (_coin < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.profileInsufficientGold)),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    AudioService.playCoin();
    final newInventory = Map<String, int>.from(_inventory);
    newInventory[itemId] = (newInventory[itemId] ?? 0) + 1; // Tambah jumlah barang +1

    // FieldValue.increment(-price) memastikan pemotongan koin aman dari Race Condition
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      UserSchema.gold: FieldValue.increment(-price),
      UserSchema.inventory: newInventory,
    });
    _loadUserData(); // Reload UI
  }

  // FUNGSI MENGGUNAKAN BARANG HABIS PAKAI (POTION / XP SCROLL)
  Future<void> _useConsumable(String itemId) async {
    final count = _inventory[itemId] ?? 0;
    if (count <= 0) return; // Validasi anti minus

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    AudioService.playClick();
    final newInventory = Map<String, int>.from(_inventory);
    newInventory[itemId] = count - 1; // Kurangi jumlah di ransel

    // Siapkan wadah update untuk dikirim massal ke Firebase
    Map<String, dynamic> updates = {UserSchema.inventory: newInventory};
    
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
    } else if (itemId == 'vitality_potion') {
      updates[UserSchema.vitalityXp] = FieldValue.increment(50);
    } else if (itemId == 'defense_potion') {
      updates[UserSchema.defenseXp] = FieldValue.increment(50);
    } else if (itemId == 'xp_scroll') {
      updates[UserSchema.xpBonusUntil] = Timestamp.fromDate(DateTime.now().add(const Duration(hours: 1)));
    } else if (itemId == 'gold_scroll') {
      updates[UserSchema.goldBonusUntil] = Timestamp.fromDate(DateTime.now().add(const Duration(hours: 1)));
    } else if (itemId == 'revive_token') {
      updates[UserSchema.hp] = _maxHp;
      updates[UserSchema.isBurntOut] = false;
    } else if (itemId == 'mystery_box') {
      // Logic gacha sederhana — 3 kemungkinan hadiah
      final random = DateTime.now().millisecondsSinceEpoch % 3;
      if (random == 0) {
        updates[UserSchema.gold] = FieldValue.increment(150);
      } else if (random == 1) {
        updates[UserSchema.strengthXp] = FieldValue.increment(100);
        updates[UserSchema.agilityXp] = FieldValue.increment(100);
        updates[UserSchema.intelligenceXp] = FieldValue.increment(100);
        updates[UserSchema.vitalityXp] = FieldValue.increment(100);
        updates[UserSchema.defenseXp] = FieldValue.increment(100);
      } else {
        updates[UserSchema.hp] = _maxHp;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update(updates);
      _loadUserData();
      // Tampilkan popup reveal hadiah Mystery Box
      _showMysteryBoxReveal(random);
      return; // Early return agar tidak memanggil _showItemUsedSnackBar
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).update(updates);
    _loadUserData();
    _showItemUsedSnackBar(itemId);
  }

  // Menampilkan notifikasi kecil di bawah layar saat item (potion/scroll) berhasil dipakai
  void _showItemUsedSnackBar(String itemId) {
    if (!mounted) return;
    final l = context.l;
    String msg = l.profileHpRestored; // default fallback
    if (itemId == 'red_potion' || itemId == 'blue_potion' || itemId == 'green_potion') {
      msg = l.profileHpRestored;
    } else if (itemId == 'xp_scroll') {
      msg = l.profileXpBonusActive;
    } else if (itemId == 'gold_scroll') {
      msg = 'Double Gold aktif selama 1 Jam!';
    } else if (itemId == 'revive_token') {
      msg = 'Sembuh dari Burnout! HP penuh kembali.';
    } else if (itemId == 'mystery_box') {
      msg = 'Mystery Box dibuka! Mendapatkan hadiah acak!';
    } else if (itemId.contains('_potion')) {
      msg = 'Mendapatkan 50 XP tambahan!';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
    );
  }

  // Popup reveal khusus untuk Mystery Box — menampilkan hadiah yang didapat secara dramatis
  void _showMysteryBoxReveal(int result) {
    if (!mounted) return;
    AudioService.playSuccess();

    // Tentukan isi hadiah berdasarkan hasil random
    String prizeTitle;
    String prizeDesc;
    IconData prizeIcon;
    Color prizeColor;

    if (result == 0) {
      prizeTitle = '150 Gold!';
      prizeDesc = 'Kamu mendapatkan koin emas sebanyak 150!';
      prizeIcon = Icons.monetization_on_rounded;
      prizeColor = const Color(0xFFFFD700);
    } else if (result == 1) {
      prizeTitle = 'All Stats +100 XP!';
      prizeDesc = 'Semua atribut (Str, Agi, Int, Vit, Def) bertambah 100 XP!';
      prizeIcon = Icons.auto_awesome_rounded;
      prizeColor = const Color(0xFF8B5CF6);
    } else {
      prizeTitle = 'HP Full Restore!';
      prizeDesc = 'HP kamu dipulihkan sepenuhnya!';
      prizeIcon = Icons.favorite_rounded;
      prizeColor = const Color(0xFFEF4444);
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: prizeColor.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(color: prizeColor.withValues(alpha: 0.25), blurRadius: 30, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label Mystery Box
              Text(
                'MYSTERY BOX',
                style: GoogleFonts.cinzel(
                  color: prizeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kamu mendapatkan...',
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary.withValues(alpha: 0.54),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              // Ikon hadiah
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: prizeColor.withValues(alpha: 0.15),
                  border: Border.all(color: prizeColor.withValues(alpha: 0.4), width: 2),
                  boxShadow: [
                    BoxShadow(color: prizeColor.withValues(alpha: 0.3), blurRadius: 16),
                  ],
                ),
                child: Icon(prizeIcon, color: prizeColor, size: 40),
              ),
              const SizedBox(height: 20),
              // Nama hadiah
              Text(
                prizeTitle,
                style: GoogleFonts.nunito(
                  color: prizeColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              // Deskripsi hadiah
              Text(
                prizeDesc,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary.withValues(alpha: 0.70),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 28),
              // Tombol tutup
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: prizeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mantap!',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Membuka lembaran bawah (Bottom Sheet) untuk menu Pengaturan (Ganti Nama, Suara, Logout)
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsSheet(
        currentName: _userName,
        currentUsername: _username,
        currentEmail: _email,
        soundEnabled: _soundEnabled,
        musicEnabled: _musicEnabled,
        onProfileUpdated: _loadUserData,
      ),
    );
  }

  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          _buildSegmentedControl(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  // ── Bagian Atas Layar (Header Profil) ───────────────────────────
  // Menampilkan tulisan "Character", Jumlah Koin, dan Tombol Settings
  Widget _buildTopBar() {
    final l = context.lw;
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 0.0),
      child: ScreenHeader(
        title: l.profileCharacter,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCoinDisplay(),
            const SizedBox(width: 12),
            _buildSettingsButton(),
          ],
        ),
      ),
    );
  }

  // Kotak kecil di pojok kanan atas untuk menampilkan sisa koin pemain
  Widget _buildCoinDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 16),
          SizedBox(width: 6),
          Text('$_coin', style: GoogleFonts.nunito(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  // Tombol roda gigi untuk membuka menu pengaturan (Settings)
  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: _showSettings,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.cardBackground, shape: BoxShape.circle, border: Border.all(color: AppColors.cardBorder)),
        child: Icon(Icons.settings, color: AppColors.textSecondary, size: 20),
      ),
    );
  }

  // ── Tab Navigasi (Pilihan Menu) ─────────────────────────────────
  // Menampilkan tombol "Badges", "Avatar", dan "Items" untuk pindah-pindah layar
  Widget _buildSegmentedControl() {
    final l = context.lw;
    // Menggunakan ThemeCard untuk background tab navigasi //
    return ThemeCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      backgroundColor: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
      borderColor: AppColors.cardBorder,
      borderWidth: AppColors.borderWidth,
      child: Row(
        children: [
          _buildSegmentItem(l.profileTabBadges, 0),
          _buildSegmentItem(l.profileTabAvatar, 1),
          _buildSegmentItem(l.profileTabItems, 2),
        ],
      ),
    );
  }

  // Fungsi kecil untuk membuat satu buah tombol Tab (contoh: tab "Avatar" saja)
  Widget _buildSegmentItem(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.nunito(color: isSelected ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.54), fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }

  // ── Layar Utama Sesuai Tab yang Dipilih ────────────────────────
  // Akan merender layar yang berbeda tergantung tab mana yang sedang aktif
  Widget _buildMainContent() {
    switch (_selectedTabIndex) {
      case 0:
        return BadgeGalleryView(
          level: _level, 
          totalTasksDone: _totalTasksDone, 
          coin: _coin, 
          streak: _streak, 
          categoryXp: _categoryXp, 
          claimedBadges: _claimedBadges, 
          equippedBadges: _equippedBadges,
          onClaimBadge: _claimBadge,
          onEquipBadge: _equipBadge,
          accentColor: AppColors.primary
        );
      case 1:
        return AvatarShopView(equippedItems: _equippedItems, unlockedItems: _unlockedItems, onEquip: _handleEquip, accentColor: AppColors.primary, cardDark: AppColors.cardBackground, cardBorder: AppColors.cardBorder, baseBody: _baseBody);
      case 2:
        return ItemShopView(equippedItems: _equippedItems, inventory: _inventory, onBuy: _buyConsumable, onUse: _useConsumable, cardDark: AppColors.cardBackground, cardBorder: AppColors.cardBorder, accentColor: AppColors.primary);
      default:
        return Container();
    }
  }
}

