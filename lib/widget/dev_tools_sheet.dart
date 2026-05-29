import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_schema.dart';
import '../models/title_system.dart';
import '../services/notification_service.dart';
import '../screens/onboarding_screen.dart';
import 'dart:math';

// Flat Minimalist Colors
const Color _bgDark = Color(0xFF0F0F1E);
const Color _cardBg = Color(0xFF1A1A2E);
const Color _accentPurple = Color(0xFF7C3AED); // Main app purple
const Color _accentCyan = Color(0xFF7C3AED);
const Color _textWhite = Color(0xFFFFFFFF);
const Color _textMuted = Color(0x8AFFFFFF);

const Color _flatRed = Color(0xFFEF4444);
const Color _flatAmber = Color(0xFF7C3AED);
const Color _flatGreen = Color(0xFF7C3AED);
const Color _flatBlue = Color(0xFF7C3AED);

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
  String _rankName = 'F';

  final List<String> _rankOptions = ['F', 'E', 'D', 'C', 'B', 'A', 'S', 'SS', 'SSS', 'SSR'];

  // Quick Quest
  final TextEditingController _questNameCtrl = TextEditingController();
  String _questDifficulty = 'easy';
  String _questCategory = 'Strength';

  @override
  void initState() {
    super.initState();
    _loadFromData(widget.userData, FirebaseAuth.instance.currentUser?.uid ?? '');
    
    _levelCtrl.addListener(() {
      final lvl = int.tryParse(_levelCtrl.text) ?? 1;
      final newRank = RankSystem.calculateRank(
        lvl,
        str: int.tryParse(_strCtrl.text) ?? 0,
        def: int.tryParse(_defCtrl.text) ?? 0,
        intl: int.tryParse(_intCtrl.text) ?? 0,
        vit: int.tryParse(_vitCtrl.text) ?? 0,
        agi: int.tryParse(_agiCtrl.text) ?? 0,
      );
      if (_rankName != newRank) {
        setState(() {
          _rankName = newRank;
        });
      }
    });
  }

  void _loadFromData(Map<String, dynamic> data, String uid) {
    _targetUid = uid;
    setState(() {
      _goldCtrl.text = (data[UserSchema.gold]?.toString()) ?? '0';
      _levelCtrl.text = (data[UserSchema.level]?.toString()) ?? '1';
      _xpCtrl.text = (data[UserSchema.xp]?.toString()) ?? '0';
      
      // Ensure HP parses safely
      var hpData = data[UserSchema.hp];
      if (hpData is int) _hp = hpData;
      else if (hpData is double) _hp = hpData.toInt();
      else if (hpData is String) _hp = int.tryParse(hpData) ?? 100;
      else _hp = 100;

      _strCtrl.text = (data[UserSchema.strengthXp]?.toString()) ?? '0';
      _intCtrl.text = (data[UserSchema.intelligenceXp]?.toString()) ?? '0';
      _agiCtrl.text = (data[UserSchema.agilityXp]?.toString()) ?? '0';
      _vitCtrl.text = (data[UserSchema.vitalityXp]?.toString()) ?? '0';
      _defCtrl.text = (data[UserSchema.defenseXp]?.toString()) ?? '0';
      
      // Automatically detect rank from the database rank, or derive from level
      String? savedRank = data[UserSchema.rank] as String?;
      if (savedRank != null && _rankOptions.contains(savedRank)) {
        _rankName = savedRank;
      } else {
        _syncRankFromLevel(int.tryParse(_levelCtrl.text) ?? 1);
      }
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
    _rankName = RankSystem.calculateRank(
      lvl,
      str: int.tryParse(_strCtrl.text) ?? 0,
      def: int.tryParse(_defCtrl.text) ?? 0,
      intl: int.tryParse(_intCtrl.text) ?? 0,
      vit: int.tryParse(_vitCtrl.text) ?? 0,
      agi: int.tryParse(_agiCtrl.text) ?? 0,
    );
  }

  void _onRankChanged(String? newRank) {
    if (newRank == null) return;
    setState(() {
      _rankName = newRank;
      if (newRank == 'SSR') _levelCtrl.text = '150';
      else if (newRank == 'SSS') _levelCtrl.text = '121';
      else if (newRank == 'SS') _levelCtrl.text = '91';
      else if (newRank == 'S') _levelCtrl.text = '71';
      else if (newRank == 'A') _levelCtrl.text = '51';
      else if (newRank == 'B') _levelCtrl.text = '36';
      else if (newRank == 'C') _levelCtrl.text = '21';
      else if (newRank == 'D') _levelCtrl.text = '11';
      else if (newRank == 'E') _levelCtrl.text = '6';
      else if (newRank == 'F') _levelCtrl.text = '1';
    });
  }

  Future<void> _syncTargetUser() async {
    String username = _targetUsernameCtrl.text.trim();
    setState(() => _isLoading = true);
    try {
      if (username.isEmpty) {
        // Fallback to current user
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists) {
            _loadFromData(doc.data() as Map<String, dynamic>, uid);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data Diri Sendiri Berhasil Dimuat!')));
          }
        }
      } else {
        // Query by username. Make case insensitive if possible by checking lowercase
        username = username.toLowerCase();
        var snapshot = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: username).limit(1).get();
        
        // If not found, try original case
        if (snapshot.docs.isEmpty) {
           snapshot = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: _targetUsernameCtrl.text.trim()).limit(1).get();
        }

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          _loadFromData(doc.data(), doc.id);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data Berhasil Dimuat!')));
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User tidak ditemukan!')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        UserSchema.rank: _rankName,
      });

      widget.onUpdated();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createQuickQuest() async {
    final name = _questNameCtrl.text.trim();
    if (name.isEmpty || _targetUid.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      int difficultyInt = 1;
      switch (_questDifficulty) {
        case 'easy': difficultyInt = 1; break;
        case 'medium': difficultyInt = 2; break;
        case 'hard': difficultyInt = 3; break;
        case 'epic': difficultyInt = 4; break;
      }

      await FirebaseFirestore.instance.collection('users').doc(_targetUid).collection('tasks').add({
        TaskSchema.uid: _targetUid,
        TaskSchema.title: name,
        TaskSchema.difficulty: difficultyInt,
        TaskSchema.category: _questCategory,
        TaskSchema.proofType: 'none',
        TaskSchema.done: false,
        TaskSchema.createdAt: FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quick Quest Created!')));
        Navigator.pop(context);
      }
      _questNameCtrl.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.nunito(color: _textWhite, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController ctrl, {int step = 1, bool showButtons = true, IconData? icon, Color iconColor = _textWhite}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.nunito(color: _textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
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
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bgDark,
                    ),
                    child: const Icon(Icons.remove, color: _flatRed, size: 20),
                  ),
                ),
              if (showButtons) const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _bgDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: iconColor, size: 20),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.nunito(color: _textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showButtons) const SizedBox(width: 12),
              if (showButtons)
                InkWell(
                  onTap: () {
                    int val = int.tryParse(ctrl.text) ?? 0;
                    ctrl.text = (val + step).toString();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bgDark,
                    ),
                    child: const Icon(Icons.add, color: _flatGreen, size: 20),
                  ),
                ),
            ],
          ),
        ],
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
          color: isSelected ? _accentPurple : _bgDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: isSelected ? _textWhite : _textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: _bgDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.nunito(color: _textWhite, fontWeight: FontWeight.w800, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _testNotificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Test Notifikasi', style: GoogleFonts.nunito(color: _textWhite, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications, color: _accentCyan),
              title: Text('System Alert', style: GoogleFonts.nunito(color: _textWhite)),
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
        color: _bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Top Bar Indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                
                // DATA UTAMA CARD
                _buildCard('PLAYER STATS', [
                  // TARGET USER
                  Text('Target User', style: GoogleFonts.nunito(color: _textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: _bgDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_search, color: _textMuted, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _targetUsernameCtrl,
                                  style: GoogleFonts.nunito(color: _textWhite, fontSize: 15, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    hintText: 'Ketik username tanpa @',
                                    hintStyle: GoogleFonts.nunito(color: _textMuted, fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _accentPurple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : const Icon(Icons.sync, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // TIER / RANK
                  Text('Rank & Tier', style: GoogleFonts.nunito(color: _textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _bgDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _rankName,
                        dropdownColor: _cardBg,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: _textMuted),
                        style: GoogleFonts.nunito(color: _textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                        items: _rankOptions.map((r) => DropdownMenuItem(value: r, child: Row(
                          children: [
                            const Icon(Icons.military_tech, color: _flatAmber, size: 20),
                            const SizedBox(width: 12),
                            Text('Rank $r'),
                          ],
                        ))).toList(),
                        onChanged: _onRankChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildInputRow('Gold', _goldCtrl, showButtons: false, icon: Icons.monetization_on, iconColor: _flatAmber),
                  _buildInputRow('Level', _levelCtrl, step: 1, icon: Icons.trending_up, iconColor: _accentCyan),
                  _buildInputRow('Total XP', _xpCtrl, step: 1000, icon: Icons.star, iconColor: _flatAmber),
                  
                  const SizedBox(height: 12),
                  Text('Health Pool', style: GoogleFonts.nunito(color: _textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _hp = max(0, _hp - 20)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _bgDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('-20', style: GoogleFonts.nunito(color: _flatRed, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: _bgDark,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _hp / 100.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _accentCyan,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('$_hp / 100 HP', style: GoogleFonts.nunito(color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _hp = min(100, _hp + 20)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _bgDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('+20', style: GoogleFonts.nunito(color: _flatGreen, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      await _updateStats();
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentCyan,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('APPLY STATS', style: GoogleFonts.nunito(color: _bgDark, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
                  ),
                ]),
                
                // QUICK CHEATS
                _buildCard('QUICK CHEATS', [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: [
                      _buildQuickBtn('DEMO ONBOARDING', Icons.play_circle_outline, _accentCyan, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()))),
                      _buildQuickBtn('DEMO TUTORIAL', Icons.help_outline, _flatAmber, () {}),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildQuickBtn('TEST NOTIF', Icons.notifications_none, _flatGreen, _testNotificationDialog),
                      _buildQuickBtn('DEMO BADGE', Icons.emoji_events_outlined, _flatAmber, () {}),
                      _buildQuickBtn('MAX STATS', Icons.diamond_outlined, _accentPurple, () async {
                        setState(() {
                          _levelCtrl.text = '150';
                          _goldCtrl.text = '999999';
                          _xpCtrl.text = '999999';
                          _hp = 100;
                          _strCtrl.text = '99999';
                          _intCtrl.text = '99999';
                          _agiCtrl.text = '99999';
                          _vitCtrl.text = '99999';
                          _defCtrl.text = '99999';
                          _syncRankFromLevel(150);
                        });
                        await _updateStats();
                        await _updateKualifikasi();
                        if (mounted) Navigator.pop(context);
                      }),
                    ],
                  ),
                ]),
                
                // QUICK QUEST
                _buildCard('QUICK QUEST', [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: _bgDark, borderRadius: BorderRadius.circular(8)),
                    child: TextField(
                      controller: _questNameCtrl,
                      style: GoogleFonts.nunito(color: _textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.edit, color: _textMuted, size: 20),
                        hintText: 'Nama Quest',
                        hintStyle: GoogleFonts.nunito(color: _textMuted, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Difficulty', style: GoogleFonts.nunito(color: _textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildChip('Easy', 'easy', _questDifficulty, (v) => setState(() => _questDifficulty = v)),
                      _buildChip('Med', 'medium', _questDifficulty, (v) => setState(() => _questDifficulty = v)),
                      _buildChip('Hard', 'hard', _questDifficulty, (v) => setState(() => _questDifficulty = v)),
                      _buildChip('Epic', 'epic', _questDifficulty, (v) => setState(() => _questDifficulty = v)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Kategori', style: GoogleFonts.nunito(color: _textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createQuickQuest,
                    icon: const Icon(Icons.auto_awesome, color: Colors.white),
                    label: Text('CREATE QUEST', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentPurple,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]),
                
                // KUALIFIKASI & GELAR
                _buildCard('KUALIFIKASI & GELAR', [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: _bgDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _accentPurple, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.military_tech, color: _accentPurple, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rank $_rankName', style: GoogleFonts.nunito(color: _textWhite, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(_currentGelar, style: GoogleFonts.nunito(color: _textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Atribut XP (Penentu Gelar)', style: GoogleFonts.nunito(color: _textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInputRow('STR', _strCtrl, step: 100),
                  _buildInputRow('DEF', _defCtrl, step: 100),
                  _buildInputRow('INT', _intCtrl, step: 100),
                  _buildInputRow('VIT', _vitCtrl, step: 100),
                  _buildInputRow('AGI', _agiCtrl, step: 100),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      await _updateStats();
                      await _updateKualifikasi();
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentCyan,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('APPLY CHANGES', style: GoogleFonts.nunito(color: _bgDark, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
                  ),
                ]),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
