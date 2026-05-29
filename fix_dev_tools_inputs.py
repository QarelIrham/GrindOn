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
  final TextEditingController _goldCtrl = TextEditingController();
  final TextEditingController _levelCtrl = TextEditingController();
  final TextEditingController _xpCtrl = TextEditingController();
  int _hp = 100;

  // Stat Kualifikasi
  final TextEditingController _strCtrl = TextEditingController();
  final TextEditingController _intCtrl = TextEditingController();
  final TextEditingController _agiCtrl = TextEditingController();
  final TextEditingController _vitCtrl = TextEditingController();
  final TextEditingController _defCtrl = TextEditingController();
  
  bool _isLoading = false;
  String _rankName = 'Novice';

  final List<String> _rankOptions = ['Novice', 'Veteran', 'Elite', 'Mythic', 'Legendary', 'SSS'];

  // Quick Quest
  final TextEditingController _questNameCtrl = TextEditingController();
  String _questDifficulty = 'easy';
  String _questCategory = 'Strength';

  @override
  void initState() {
    super.initState();
    _loadFromData(widget.userData, FirebaseAuth.instance.currentUser?.uid ?? '');
  }

  void _loadFromData(Map<String, dynamic> data, String uid) {
    _targetUid = uid;
    setState(() {
      _goldCtrl.text = (data[UserSchema.gold]?.toString()) ?? '0';
      _levelCtrl.text = (data[UserSchema.level]?.toString()) ?? '1';
      _xpCtrl.text = (data[UserSchema.xp]?.toString()) ?? '0';
      _hp = (data[UserSchema.hp] as num?)?.toInt() ?? 100;

      _strCtrl.text = (data[UserSchema.strengthXp]?.toString()) ?? '0';
      _intCtrl.text = (data[UserSchema.intelligenceXp]?.toString()) ?? '0';
      _agiCtrl.text = (data[UserSchema.agilityXp]?.toString()) ?? '0';
      _vitCtrl.text = (data[UserSchema.vitalityXp]?.toString()) ?? '0';
      _defCtrl.text = (data[UserSchema.defenseXp]?.toString()) ?? '0';
      
      _syncRankFromLevel(int.tryParse(_levelCtrl.text) ?? 1);
    });
  }

  @override
  void dispose() {
    _targetUsernameCtrl.dispose();
    _questNameCtrl.dispose();
    _goldCtrl.dispose();
    _levelCtrl.dispose();
    _xpCtrl.dispose();
    _strCtrl.dispose();
    _intCtrl.dispose();
    _agiCtrl.dispose();
    _vitCtrl.dispose();
    _defCtrl.dispose();
    super.dispose();
  }

  void _syncRankFromLevel(int lvl) {
    if (lvl >= 151) {
      _rankName = 'SSS';
    } else if (lvl >= 101) {
      _rankName = 'Legendary';
    } else if (lvl >= 71) {
      _rankName = 'Mythic';
    } else if (lvl >= 31) {
      _rankName = 'Elite';
    } else if (lvl >= 11) {
      _rankName = 'Veteran';
    } else {
      _rankName = 'Novice';
    }
  }

  void _onRankChanged(String? newRank) {
    if (newRank == null) return;
    setState(() {
      _rankName = newRank;
      if (newRank == 'SSS') _levelCtrl.text = '151';
      else if (newRank == 'Legendary') _levelCtrl.text = '101';
      else if (newRank == 'Mythic') _levelCtrl.text = '71';
      else if (newRank == 'Elite') _levelCtrl.text = '31';
      else if (newRank == 'Veteran') _levelCtrl.text = '11';
      else if (newRank == 'Novice') _levelCtrl.text = '1';
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
        UserSchema.gold: int.tryParse(_goldCtrl.text) ?? 0,
        UserSchema.level: int.tryParse(_levelCtrl.text) ?? 1,
        UserSchema.xp: int.tryParse(_xpCtrl.text) ?? 0,
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
        UserSchema.strengthXp: int.tryParse(_strCtrl.text) ?? 0,
        UserSchema.intelligenceXp: int.tryParse(_intCtrl.text) ?? 0,
        UserSchema.agilityXp: int.tryParse(_agiCtrl.text) ?? 0,
        UserSchema.vitalityXp: int.tryParse(_vitCtrl.text) ?? 0,
        UserSchema.defenseXp: int.tryParse(_defCtrl.text) ?? 0,
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
      _levelCtrl.text = '999';
      _goldCtrl.text = '999999';
      _xpCtrl.text = '999999';
      _hp = 100;
      _strCtrl.text = '99999';
      _intCtrl.text = '99999';
      _agiCtrl.text = '99999';
      _vitCtrl.text = '99999';
      _defCtrl.text = '99999';
      _syncRankFromLevel(999);
    });
    await _updateStats(); 
    await _updateKualifikasi();
  }

  Future<void> _createQuickQuest() async {
    final name = _questNameCtrl.text.trim();
    if (name.isEmpty || _targetUid.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        'userId': _targetUid,
        'title': name,
        'difficulty': _questDifficulty,
        'category': _questCategory,
        'proofType': 'none',
        'isCompleted': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quick Quest Created!')));
      _questNameCtrl.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    return TitleSystem.getPlayerTitle(
      rank: _rankName,
      categoryXp: {
        'Strength': int.tryParse(_strCtrl.text) ?? 0,
        'Defense': int.tryParse(_defCtrl.text) ?? 0,
        'Intelligence': int.tryParse(_intCtrl.text) ?? 0,
        'Vitality': int.tryParse(_vitCtrl.text) ?? 0,
        'Agility': int.tryParse(_agiCtrl.text) ?? 0,
      },
      level: int.tryParse(_levelCtrl.text) ?? 1,
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

  Widget _buildCard(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInputRow(String label, TextEditingController ctrl, {int step = 1, bool showButtons = true, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.nunito(color: _textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (showButtons)
                InkWell(
                  onTap: () {
                    int val = int.tryParse(ctrl.text) ?? 0;
                    ctrl.text = max(0, val - step).toString();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _terracottaRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _terracottaRed.withOpacity(0.3)),
                    ),
                    child: Text('-', style: GoogleFonts.nunito(color: _terracottaRed, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (showButtons) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: _goldWarning, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.nunito(color: _textOffWhite, fontSize: 16, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(border: InputBorder.none),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showButtons) const SizedBox(width: 8),
              if (showButtons)
                InkWell(
                  onTap: () {
                    int val = int.tryParse(ctrl.text) ?? 0;
                    ctrl.text = (val + step).toString();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentTeal.withOpacity(0.3)),
                    ),
                    child: Text('+', style: GoogleFonts.nunito(color: _accentTeal, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _bgCharcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.nunito(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value, String groupValue, ValueChanged<String> onSelected) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _accentPurple.withOpacity(0.2) : _bgCharcoal,
          border: Border.all(color: isSelected ? _accentPurple : Colors.white10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: isSelected ? _accentPurple : _textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
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
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                
                // TARGET USER
                Text('TARGET USER (Kosong = Diri Sendiri)', style: GoogleFonts.nunito(color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _bgCharcoal,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accentTeal.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_search, color: _accentTeal, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _targetUsernameCtrl,
                                style: GoogleFonts.nunito(color: _textOffWhite, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Ketik username tanpa @ (opsional)',
                                  hintStyle: GoogleFonts.nunito(color: _textMuted, fontSize: 13),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _syncTargetUser,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _bgCharcoal,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accentTeal.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.sync, color: _accentTeal, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // DATA UTAMA
                _buildCard([
                  Text('Select Tier / Rank', style: GoogleFonts.nunito(color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _rankName,
                        dropdownColor: _bgCharcoal,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: _textMuted),
                        style: GoogleFonts.nunito(color: _textOffWhite, fontWeight: FontWeight.bold, fontSize: 15),
                        items: _rankOptions.map((r) => DropdownMenuItem(value: r, child: Row(
                          children: [
                            const Icon(Icons.military_tech, color: _goldWarning, size: 20),
                            const SizedBox(width: 8),
                            Text('Rank '),
                          ],
                        ))).toList(),
                        onChanged: _onRankChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInputRow('Set Gold', _goldCtrl, showButtons: false, icon: Icons.monetization_on),
                  _buildInputRow('Level', _levelCtrl, step: 1, icon: Icons.trending_up),
                  _buildInputRow('Total XP', _xpCtrl, step: 1000, icon: Icons.star),
                  
                  const SizedBox(height: 16),
                  Text('HP', style: GoogleFonts.nunito(color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _hp = max(0, _hp - 20)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _terracottaRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _terracottaRed.withOpacity(0.3)),
                          ),
                          child: Text('-20', style: GoogleFonts.nunito(color: _terracottaRed, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: _accentTeal,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(' / 100 HP', style: GoogleFonts.nunito(color: _textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _hp = min(100, _hp + 20)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _accentTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _accentTeal.withOpacity(0.3)),
                          ),
                          child: Text('+20', style: GoogleFonts.nunito(color: _accentTeal, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ]),
                
                // QUICK CHEATS
                Text('QUICK CHEATS', style: GoogleFonts.nunito(color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _buildQuickBtn('DEMO ONBOARDING', Icons.play_circle_outline, _accentTeal, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()))),
                    _buildQuickBtn('DEMO TUTORIAL', Icons.help_outline, _goldWarning, () {}),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildQuickBtn('TEST NOTIF', Icons.notifications_none, _accentTeal, _testNotificationDialog),
                    _buildQuickBtn('DEMO BADGE', Icons.emoji_events_outlined, _goldWarning, () {}),
                    _buildQuickBtn('MAX STATS', Icons.diamond_outlined, _accentPurple, _maxAllStats),
                  ],
                ),
                const SizedBox(height: 24),
                
                // QUICK QUEST
                Text('QUICK QUEST', style: GoogleFonts.nunito(color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _questNameCtrl,
                    style: GoogleFonts.nunito(color: _textOffWhite, fontSize: 15),
                    decoration: InputDecoration(
                      icon: const Icon(Icons.edit, color: _goldWarning, size: 20),
                      hintText: 'Nama Quest',
                      hintStyle: GoogleFonts.nunito(color: _textMuted, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Difficulty', style: GoogleFonts.nunito(color: _textOffWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildChip('Easy', 'easy', _questDifficulty, (v) => setState(() => _questDifficulty = v)),
                    _buildChip('Med', 'medium', _questDifficulty, (v) => setState(() => _questDifficulty = v)),
                    _buildChip('Hard', 'hard', _questDifficulty, (v) => setState(() => _questDifficulty = v)),
                    _buildChip('Extreme', 'epic', _questDifficulty, (v) => setState(() => _questDifficulty = v)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Kategori', style: GoogleFonts.nunito(color: _textOffWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip('Strength', 'Strength', _questCategory, (v) => setState(() => _questCategory = v)),
                    _buildChip('Defense', 'Defense', _questCategory, (v) => setState(() => _questCategory = v)),
                    _buildChip('Intelligence', 'Intelligence', _questCategory, (v) => setState(() => _questCategory = v)),
                    _buildChip('Vitality', 'Vitality', _questCategory, (v) => setState(() => _questCategory = v)),
                    _buildChip('Agility', 'Agility', _questCategory, (v) => setState(() => _questCategory = v)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createQuickQuest,
                  icon: const Icon(Icons.add_task, color: Colors.white),
                  label: Text('CREATE QUEST', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentPurple,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),

                // KUALIFIKASI & GELAR
                Text('KUALIFIKASI & GELAR', style: GoogleFonts.nunito(color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rank', style: GoogleFonts.nunito(color: _textMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _terracottaRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _terracottaRed.withOpacity(0.3)),
                            ),
                            child: Text('Rank ', style: GoogleFonts.nunito(color: _terracottaRed, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rank ', style: GoogleFonts.nunito(color: _goldWarning, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(_currentGelar, style: GoogleFonts.nunito(color: _textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Atribut XP (tentukan gelar)', style: GoogleFonts.nunito(color: _textMuted, fontSize: 12)),
                      const SizedBox(height: 12),
                      _buildInputRow('STR', _strCtrl, step: 100),
                      _buildInputRow('DEF', _defCtrl, step: 100),
                      _buildInputRow('INT', _intCtrl, step: 100),
                      _buildInputRow('VIT', _vitCtrl, step: 100),
                      _buildInputRow('AGI', _agiCtrl, step: 100),
                      
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          await _updateStats();
                          await _updateKualifikasi();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentTeal,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('APPLY CHANGES', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
'''

with open('lib/widget/dev_tools_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("dev_tools_sheet.dart updated successfully.")
