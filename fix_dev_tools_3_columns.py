import sys
import re

with open('lib/widget/dev_tools_sheet.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove Quick Cheats section
# Finding QUICK CHEATS text
start_idx = content.find(r"// QUICK CHEATS")
end_idx = content.find(r"// QUICK QUEST")

if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + content[end_idx:]

# 2. Make sure _loadFromData successfully updates all controllers
# Sometimes data is nested or has different type. Let's make it robust.
load_from_data_old = r'''  void _loadFromData(Map<String, dynamic> data, String uid) {
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
  }'''

load_from_data_new = r'''  void _loadFromData(Map<String, dynamic> data, String uid) {
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
  }'''

content = content.replace(load_from_data_old, load_from_data_new)

# 3. Enhance _syncTargetUser
sync_old = r'''  Future<void> _syncTargetUser() async {
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
  }'''

sync_new = r'''  Future<void> _syncTargetUser() async {
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
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data  Berhasil Dimuat!')));
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User  tidak ditemukan!')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }'''

content = content.replace(sync_old, sync_new)

with open('lib/widget/dev_tools_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("dev_tools updated!")
