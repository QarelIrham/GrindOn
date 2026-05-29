import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_schema.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../screens/onboarding_screen.dart';
import '../theme/app_theme.dart';

// ── Panel God Mode (Dev Tools Sheet) ────────────────────────────
// Fitur khusus developer untuk memodifikasi stat akun secara instan.
// Bisa menambah/mengurangi Gold, XP, HP, reset inventory, dan demo notifikasi.
class DevToolsSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onUpdated;

  const DevToolsSheet({
    super.key,
    required this.userData,
    required this.onUpdated,
  });

  @override
  State<DevToolsSheet> createState() => _DevToolsSheetState();
}

class _DevToolsSheetState extends State<DevToolsSheet> {
  late TextEditingController _goldCtrl;
  late TextEditingController _levelCtrl;
  late TextEditingController _xpCtrl;
  bool _isLoading = false;
  String _selectedTier = 'E';

  final Map<String, int> _tierLevels = {
    'F': 1,
    'E': 6,
    'D': 11,
    'C': 21,
    'B': 36,
    'A': 51,
    'S': 71,
    'SS': 91,
    'SSS': 121,
  };

  @override
  void initState() {
    super.initState();
    _goldCtrl = TextEditingController(
      text: widget.userData[UserSchema.gold]?.toString() ?? '0',
    );
    _levelCtrl = TextEditingController(
      text: widget.userData[UserSchema.level]?.toString() ?? '1',
    );
    _xpCtrl = TextEditingController(
      text: widget.userData[UserSchema.xp]?.toString() ?? '0',
    );
    _selectedTier = RankSystem.rankFromLevel(
      widget.userData[UserSchema.level] ?? 1,
    );
  }

  @override
  void dispose() {
    _goldCtrl.dispose();
    _levelCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStats() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final oldLevel = widget.userData[UserSchema.level] ?? 1;
      final oldRank = RankSystem.rankFromLevel(oldLevel);
      final newLevel = int.tryParse(_levelCtrl.text) ?? 1;
      final newRank = RankSystem.rankFromLevel(newLevel);

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        UserSchema.gold: int.tryParse(_goldCtrl.text) ?? 0,
        UserSchema.level: newLevel,
        UserSchema.xp: int.tryParse(_xpCtrl.text) ?? 0,
        UserSchema.hp: 100,
      });

      widget.onUpdated();

      if (mounted) {
        if (newLevel > oldLevel || newRank != oldRank) {
          AudioService.playLevelUp();
          _showLevelUpPopup(oldLevel, newLevel, oldRank, newRank);
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLevelUpPopup(int oldLv, int newLv, String oldR, String newR) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.amber.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✨', style: TextStyle(fontSize: 40)),
            Text(
              newR != oldR ? 'RANK UP!' : 'LEVEL UP!',
              style: GoogleFonts.nunito(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _levelBadge(oldLv, oldR, AppColors.textPrimary.withValues(alpha: 0.24)),
                Icon(Icons.arrow_forward_rounded, color: AppColors.textPrimary.withValues(alpha: 0.38)),
                _levelBadge(newLv, newR, Colors.amber),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(
                'MANTAP!',
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelBadge(int lv, String rank, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            rank,
            style: GoogleFonts.nunito(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Lv.$lv',
            style: GoogleFonts.nunito(
              color: color.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addGold(int amount) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final currentGold = int.tryParse(_goldCtrl.text) ?? 0;
    final newGold = currentGold + amount;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      UserSchema.gold: newGold,
    });

    if (mounted) {
      setState(() {
        _goldCtrl.text = newGold.toString();
      });
      AudioService.playClick();
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $amount Gold! 💰'),
          duration: const Duration(milliseconds: 500),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  Future<void> _addXP(int amount) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final currentXP = int.tryParse(_xpCtrl.text) ?? 0;
    final newXP = currentXP + amount;
    final currentLv = int.tryParse(_levelCtrl.text) ?? 1;

    // Simple level up logic for God Mode:
    // Every 100 XP added via this button can trigger a level up check if desired,
    // but let's make it follow the _xpNext logic.
    int xpNeeded = 100 + (currentLv - 1) * 50;
    int newLv = currentLv;
    int tempXP = newXP;

    // Calculate new level based on cumulative XP logic
    // (Assuming level up happens when XP >= threshold for current level)
    if (tempXP >= xpNeeded) {
      newLv++;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      UserSchema.xp: newXP,
      UserSchema.level: newLv,
    });

    if (mounted) {
      setState(() {
        _xpCtrl.text = newXP.toString();
        _levelCtrl.text = newLv.toString();
      });

      if (newLv > currentLv) {
        AudioService.playLevelUp();
        final oldRank = RankSystem.rankFromLevel(currentLv);
        final newRank = RankSystem.rankFromLevel(newLv);
        _showLevelUpPopup(currentLv, newLv, oldRank, newRank);
      } else {
        AudioService.playClick();
      }

      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added $amount XP! ${newLv > currentLv ? 'LEVEL UP!' : ''}',
          ),
          duration: const Duration(milliseconds: 500),
          backgroundColor: Colors.blueAccent,
        ),
      );
    }
  }

  Future<void> _resetXP() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      UserSchema.xp: 0,
    });
    if (mounted) {
      setState(() {
        _xpCtrl.text = '0';
      });
      AudioService.playClick();
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('XP Reset to 0!'),
          duration: Duration(milliseconds: 800),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  Future<void> _forceLevelUp() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final currentLv = int.tryParse(_levelCtrl.text) ?? 1;
    final newLv = currentLv + 1;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      UserSchema.level: newLv,
      UserSchema.hp: 100,
    });

    if (mounted) {
      setState(() {
        _levelCtrl.text = newLv.toString();
      });
      AudioService.playLevelUp();
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Level UP! 🚀'),
          duration: Duration(milliseconds: 800),
          backgroundColor: Colors.purpleAccent,
        ),
      );
    }
  }

  Future<void> _resetLevel() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      UserSchema.level: 1,
      UserSchema.xp: 0,
      UserSchema.hp: 100,
    });

    if (mounted) {
      setState(() {
        _levelCtrl.text = '1';
        _xpCtrl.text = '0';
      });
      AudioService.playClick();
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Level & XP Reset!'),
          duration: Duration(milliseconds: 800),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _reduceHP(int amount) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      UserSchema.hp: FieldValue.increment(-amount),
    });
    AudioService.playFail();
    widget.onUpdated();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('HP Reduced by $amount! 💔'),
          duration: const Duration(milliseconds: 800),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _demoTutorial() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'tutorialsCompleted': {
        'home': false,
        'daily': false,
        'stats': false,
        'profile': false,
        'addTask': false,
        'leaderboard': false,
      }
    });

    if (mounted) {
      AudioService.playClick();
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Panduan xqvx The Creator siap diperagakan! 🎭'),
          duration: Duration(milliseconds: 1500),
          backgroundColor: Color(0xFFD4AF37),
        ),
      );
      Navigator.pop(context); // Close dev tools bottom sheet
    }
  }

  Future<void> _testNotification() async {
    if (!mounted) return;
    
    AudioService.playClick();
    
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Show notification selection dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.tealAccent.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.tealAccent),
            SizedBox(width: 12),
            Text(
              'Test Notifications',
              style: GoogleFonts.nunito(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih notifikasi untuk demo:\n(Akan muncul di notification bar HP)',
                style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildNotificationOption(
                ctx,
                '🎯 Quest Reminder',
                'You have 3 pending quests!',
                Colors.blueAccent,
                () async {
                  Navigator.pop(ctx);
                  await notificationService.showQuestReminder();
                  _showSuccessSnackbar('Quest Reminder sent! Check notification bar 🔔');
                },
              ),
              _buildNotificationOption(
                ctx,
                '⚠️ Deadline Alert',
                'Task deadline in 1 hour!',
                Colors.orangeAccent,
                () async {
                  Navigator.pop(ctx);
                  await notificationService.showDeadlineAlert();
                  _showSuccessSnackbar('Deadline Alert sent! Check notification bar 🔔');
                },
              ),
              _buildNotificationOption(
                ctx,
                '🔥 Streak Alert',
                'Don\'t break your streak!',
                Colors.redAccent,
                () async {
                  Navigator.pop(ctx);
                  await notificationService.showStreakAlert();
                  _showSuccessSnackbar('Streak Alert sent! Check notification bar 🔔');
                },
              ),
              _buildNotificationOption(
                ctx,
                '⭐ Level Up',
                'You reached Level 10!',
                Colors.purpleAccent,
                () async {
                  Navigator.pop(ctx);
                  await notificationService.showLevelUp();
                  _showSuccessSnackbar('Level Up sent! Check notification bar 🔔');
                },
              ),
              _buildNotificationOption(
                ctx,
                '💰 Gold Earned',
                'You earned 50 Gold!',
                Colors.amber,
                () async {
                  Navigator.pop(ctx);
                  await notificationService.showGoldEarned();
                  _showSuccessSnackbar('Gold Earned sent! Check notification bar 🔔');
                },
              ),
              _buildNotificationOption(
                ctx,
                '🏆 Achievement',
                'New badge unlocked!',
                Colors.greenAccent,
                () async {
                  Navigator.pop(ctx);
                  await notificationService.showAchievementUnlocked();
                  _showSuccessSnackbar('Achievement sent! Check notification bar 🔔');
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _showSuccessSnackbar('Sending all notifications... Check notification bar! 🔔');
                    await notificationService.showAllDemoNotifications();
                  },
                  icon: Icon(Icons.all_inclusive, size: 18),
                  label: Text(
                    'Send All (2s delay)',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationOption(
    BuildContext ctx,
    String title,
    String message,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications,
                color: color,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      message,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary.withValues(alpha: 0.60),
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.textPrimary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.tealAccent.withValues(alpha: 0.9),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _resetShop() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        UserSchema.unlockedItems: [
          'none',
          'default',
          'peasant_shirt',
          'peasant_pants',
        ],
        UserSchema.inventory: {},
        UserSchema.equippedItems: {
          'head': 'none',
          'clothes': 'peasant_shirt',
          'pants': 'peasant_pants',
          'pet': 'none',
          'background': 'default',
        },
      });

      if (mounted) {
        AudioService.playClick();
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop Reset! All items locked.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber, size: 28),
                SizedBox(width: 12),
                Text(
                  'GOD MODE PANEL',
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildTierSelector(),
            SizedBox(height: 16),
            _buildInput('Set Gold', _goldCtrl, Icons.monetization_on),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInput('Level', _levelCtrl, Icons.trending_up),
                ),
                SizedBox(width: 16),
                Expanded(child: _buildInput('Total XP', _xpCtrl, Icons.star)),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'QUICK CHEATS',
              style: GoogleFonts.nunito(
                color: AppColors.textPrimary.withValues(alpha: 0.54),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCheatButton(
                    label: '+100 XP',
                    icon: Icons.add_circle_outline,
                    color: Colors.blueAccent,
                    onTap: () => _addXP(100),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCheatButton(
                    label: '+1000 Gold',
                    icon: Icons.monetization_on,
                    color: Colors.amber,
                    onTap: () => _addGold(1000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCheatButton(
                    label: 'RESET XP',
                    icon: Icons.refresh,
                    color: Colors.orangeAccent,
                    onTap: _resetXP,
                  ),
                ),
                const SizedBox(width: 12),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCheatButton(
                    label: 'LEVEL UP',
                    icon: Icons.upgrade,
                    color: Colors.purpleAccent,
                    onTap: _forceLevelUp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCheatButton(
                    label: 'RESET LEVEL',
                    icon: Icons.restart_alt,
                    color: Colors.redAccent,
                    onTap: _resetLevel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCheatButton(
                    label: '-20 HP',
                    icon: Icons.heart_broken,
                    color: Colors.red,
                    onTap: () => _reduceHP(20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCheatButton(
                    label: 'DEMO ONBOARDING',
                    icon: Icons.slideshow,
                    color: Colors.cyanAccent,
                    onTap: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCheatButton(
                    label: 'DEMO TUTORIAL',
                    icon: Icons.help_outline_rounded,
                    color: Color(0xFFD4AF37),
                    onTap: _demoTutorial,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildCheatButton(
                    label: 'TEST NOTIF',
                    icon: Icons.notifications_active,
                    color: Colors.tealAccent,
                    onTap: _testNotification,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateStats,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'APPLY CHANGES',
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _resetShop,
                icon: const Icon(Icons.refresh, color: Colors.redAccent),
                label: Text(
                  'RESET SHOP (Lock All Items)',
                  style: GoogleFonts.nunito(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildCheatButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.54)),
        prefixIcon: Icon(icon, color: Colors.amber, size: 20),
        filled: true,
        fillColor: AppColors.textPrimary.withValues(alpha: 0.26),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTierSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedTier,
      dropdownColor: AppColors.cardBackground,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Select Tier / Rank',
        labelStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.54)),
        prefixIcon: Icon(
          Icons.military_tech,
          color: Colors.amber,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.textPrimary.withValues(alpha: 0.26),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: _tierLevels.keys.map((String rank) {
        return DropdownMenuItem<String>(
          value: rank,
          child: Text(
            'Rank $rank',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedTier = newValue;
            _levelCtrl.text = _tierLevels[newValue].toString();
          });
        }
      },
    );
  }
}


