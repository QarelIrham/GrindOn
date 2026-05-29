import sys

content = r'''import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_schema.dart';
import '../models/title_system.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../screens/onboarding_screen.dart';
import '../theme/app_theme.dart';
import 'dart:math';

// --- Premium Colors for Neumorphism ---
const Color _bgCharcoal = Color(0xFF18181E);
const Color _cardBg = Color(0xFF22222A);
const Color _accentPurple = Color(0xFF8B5CF6);
const Color _accentPurpleDark = Color(0xFF5B21B6);
const Color _accentTeal = Color(0xFF14B8A6);
const Color _textOffWhite = Color(0xFFF3F4F6);
const Color _textMuted = Color(0xFF9CA3AF);
const Color _terracottaRed = Color(0xFFE27D60);
const Color _deepBlue = Color(0xFF3B82F6);
const Color _goldWarning = Color(0xFFF59E0B);

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
  // Target Selection
  final TextEditingController _targetUsernameCtrl = TextEditingController();
  String _targetUid = '';
  
  // Data Utama
  double _gold = 0;
  double _level = 1;
  double _xp = 0;
  int _hp = 100;

  // Stat Kualifikasi
  double _str = 0;
  double _int = 0;
  double _agi = 0;
  double _vit = 0;
  double _def = 0;
  
  bool _isLoading = false;
  String _rankName = 'Novice';

  final List<String> _rankOptions = ['Novice', 'Veteran', 'Elite', 'Mythic'];

  @override
  void initState() {
    super.initState();
    _loadFromData(widget.userData, FirebaseAuth.instance.currentUser?.uid ?? '');
  }

  void _loadFromData(Map<String, dynamic> data, String uid) {
    _targetUid = uid;
    setState(() {
      _gold = (data[UserSchema.gold] as num?)?.toDouble() ?? 0;
      _level = (data[UserSchema.level] as num?)?.toDouble() ?? 1;
      _xp = (data[UserSchema.xp] as num?)?.toDouble() ?? 0;
      _hp = (data[UserSchema.hp] as num?)?.toInt() ?? 100;

      _str = (data[UserSchema.strengthXp] as num?)?.toDouble() ?? 0;
      _int = (data[UserSchema.intelligenceXp] as num?)?.toDouble() ?? 0;
      _agi = (data[UserSchema.agilityXp] as num?)?.toDouble() ?? 0;
      _vit = (data[UserSchema.vitalityXp] as num?)?.toDouble() ?? 0;
      _def = (data[UserSchema.defenseXp] as num?)?.toDouble() ?? 0;
      
      _syncRankFromLevel(_level.toInt());
    });
  }

  @override
  void dispose() {
    _targetUsernameCtrl.dispose();
    super.dispose();
  }

  void _syncRankFromLevel(int lvl) {
    if (lvl >= 151) {
      _rankName = 'Mythic';
    } else if (lvl >= 71) {
      _rankName = 'Elite';
    } else if (lvl >= 31) {
      _rankName = 'Veteran';
    } else {
      _rankName = 'Novice';
    }
  }

  void _onRankChanged(String? newRank) {
    if (newRank == null) return;
    setState(() {
      _rankName = newRank;
      if (newRank == 'Mythic') _level = 151;
      else if (newRank == 'Elite') _level = 71;
      else if (newRank == 'Veteran') _level = 31;
      else if (newRank == 'Novice') _level = 1;
    });
  }

  Future<void> _syncTargetUser() async {
    final username = _targetUsernameCtrl.text.trim();
    setState(() => _isLoading = true);
    try {
      if (username.isEmpty) {
        // Fallback to current user
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists) {
            _loadFromData(doc.data() as Map<String, dynamic>, uid);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Synced to Self')));
          }
        }
      } else {
        // Query by username
        final snapshot = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: username).limit(1).get();
        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          _loadFromData(doc.data(), doc.id);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Synced to ')));
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User  not found')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStats() async {
    if (_targetUid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_targetUid).update({
        UserSchema.gold: _gold.toInt(),
        UserSchema.level: _level.toInt(),
        UserSchema.xp: _xp.toInt(),
        UserSchema.hp: _hp,
      });

      widget.onUpdated();
      if (mounted) {
        Navigator.pop(context); // Close panel on success
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateKualifikasi() async {
    if (_targetUid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_targetUid).update({
        UserSchema.strengthXp: _str.toInt(),
        UserSchema.intelligenceXp: _int.toInt(),
        UserSchema.agilityXp: _agi.toInt(),
        UserSchema.vitalityXp: _vit.toInt(),
        UserSchema.defenseXp: _def.toInt(),
      });

      widget.onUpdated();
      if (mounted) {
        Navigator.pop(context); // Close panel on success
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _maxAllStats() async {
    setState(() {
      _level = 999;
      _gold = 999999;
      _xp = 99999;
      _hp = 100;
      _str = 99999;
      _int = 99999;
      _agi = 99999;
      _vit = 99999;
      _def = 99999;
      _syncRankFromLevel(_level.toInt());
    });
    await _updateStats(); // Also saves directly and closes
  }

  Future<void> _resetField(String field, dynamic val) async {
    if (_targetUid.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(_targetUid).update({
      field: val,
    });
    widget.onUpdated();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reset  Success!')));
    }
  }

  String get _currentGelar {
    return TitleSystem.determineTitle(
      strXp: _str.toInt(),
      defXp: _def.toInt(),
      intXp: _int.toInt(),
      agiXp: _agi.toInt(),
      vitXp: _vit.toInt(),
    ).name;
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              color: _accentPurple,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderData(String label, double val, double maxVal, ValueChanged<double> onChanged, {bool isInt = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.nunito(color: _textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
            Text(isInt ? val.toInt().toString() : val.toStringAsFixed(1), style: GoogleFonts.nunito(color: _textOffWhite, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _accentPurple,
            inactiveTrackColor: _bgCharcoal,
            thumbColor: _textOffWhite,
            overlayColor: _accentPurple.withOpacity(0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: min(val, maxVal),
            min: 0,
            max: maxVal,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildApplyBtn(String label, VoidCallback onPressed) {
    return Center(
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [_accentPurple, _accentPurpleDark]),
          boxShadow: [
            BoxShadow(color: _accentPurple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Text(label, style: GoogleFonts.nunito(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        ),
      ),
    );
  }

  void _testNotificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Test Notifikasi', style: GoogleFonts.nunito(color: _textOffWhite, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications, color: _deepBlue),
              title: Text('System Alert', style: GoogleFonts.nunito(color: _textOffWhite)),
              subtitle: Text('Ini adalah notifikasi test', style: GoogleFonts.nunito(color: _textMuted)),
              onTap: () {
                NotificationService().showNotification(id: 0, title: 'SYSTEM ALERT', body: 'Ini adalah notifikasi simulasi dari God Mode');
                Navigator.pop(ctx);
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: _bgCharcoal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32), // Balance spacing
                Text(
                  'GOD MODE PANEL',
                  style: GoogleFonts.nunito(
                    color: _textOffWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, color: _accentTeal, size: 20),
                  onPressed: () {
                    // Toggle volume demo
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Volume toggled')));
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                // CARD 1: TARGET & DATA UTAMA
                _buildCard('1. TARGET & DATA UTAMA', [
                  // Sync Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: _bgCharcoal,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: TextField(
                            controller: _targetUsernameCtrl,
                            style: GoogleFonts.nunito(color: _textOffWhite, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Username (kosong = diri sendiri)',
                              hintStyle: GoogleFonts.nunito(color: _textMuted, fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: _accentTeal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.sync, color: _accentTeal),
                          onPressed: _syncTargetUser,
                          tooltip: 'Sync Realtime',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Rank & Max
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: _bgCharcoal,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _rankName,
                            dropdownColor: _cardBg,
                            icon: const Icon(Icons.keyboard_arrow_down, color: _textMuted),
                            style: GoogleFonts.nunito(color: _textOffWhite, fontWeight: FontWeight.bold, fontSize: 15),
                            items: _rankOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                            onChanged: _onRankChanged,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.bolt, size: 16, color: Colors.white),
                        label: const Text('MAX ALL'),
                        onPressed: _maxAllStats,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _goldWarning,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Gold, Level, XP Sliders
                  _buildSliderData('Level', _level, 999, (v) {
                    setState(() {
                      _level = v;
                      _syncRankFromLevel(_level.toInt());
                    });
                  }),
                  _buildSliderData('Total XP', _xp, 99999, (v) => setState(() => _xp = v)),
                  _buildSliderData('Gold', _gold, 999999, (v) => setState(() => _gold = v)),
                  
                  const SizedBox(height: 16),
                  
                  // HP Segmented
                  Text('Ubah HP', style: GoogleFonts.nunito(color: _textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: _bgCharcoal, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => _hp = max(0, _hp - 20)),
                            child: Text('-20', style: GoogleFonts.nunito(color: _terracottaRed, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Container(width: 1, height: 24, color: Colors.white10),
                        Expanded(
                          child: Center(child: Text(' / 100', style: GoogleFonts.nunito(color: _textOffWhite, fontWeight: FontWeight.w900))),
                        ),
                        Container(width: 1, height: 24, color: Colors.white10),
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => _hp = min(100, _hp + 20)),
                            child: Text('+20', style: GoogleFonts.nunito(color: _accentTeal, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildApplyBtn('APPLY CHANGES', _updateStats),
                ]),

                // CARD 2: QUICK CHEATS
                _buildCard('2. QUICK CHEATS & DEMO', [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: [
                      _buildQuickBtn('Reset Shop', Icons.shopping_cart_outlined, _terracottaRed, () => _resetField(UserSchema.unlockedItems, [])),
                      _buildQuickBtn('Reset Badge', Icons.shield_outlined, _terracottaRed, () => _resetField(UserSchema.unlockedBadges, [])),
                      _buildQuickBtn('Test Notif', Icons.notifications_none_rounded, _deepBlue, _testNotificationDialog),
                      _buildQuickBtn('Tutorial', Icons.book_outlined, _deepBlue, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()))),
                      _buildQuickBtn('Demo Badge', Icons.medal_outlined, _deepBlue, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Badge demo dipanggil')))),
                      _buildQuickBtn('Dummy', Icons.flight_takeoff, _deepBlue, () {}),
                    ],
                  ),
                ]),

                // CARD 3: KUALIFIKASI & GELAR
                _buildCard('3. KUALIFIKASI & GELAR', [
                  _buildSliderData('Strength (STR)', _str, 99999, (v) => setState(() => _str = v)),
                  _buildSliderData('Defense (DEF)', _def, 99999, (v) => setState(() => _def = v)),
                  _buildSliderData('Intelligence (INT)', _int, 99999, (v) => setState(() => _int = v)),
                  _buildSliderData('Vitality (VIT)', _vit, 99999, (v) => setState(() => _vit = v)),
                  _buildSliderData('Agility (AGI)', _agi, 99999, (v) => setState(() => _agi = v)),
                  
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _accentPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _accentPurple.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text('Preview Gelar', style: GoogleFonts.nunito(color: _textMuted, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(_currentGelar, style: GoogleFonts.cinzel(color: _accentPurple, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildApplyBtn('APPLY KUALIFIKASI', _updateKualifikasi),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.nunito(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
'''

with open('lib/widget/dev_tools_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("dev_tools_sheet.dart updated successfully.")
