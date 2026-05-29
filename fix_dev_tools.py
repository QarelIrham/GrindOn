import sys

with open('lib/widget/dev_tools_sheet.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace withOpacity
content = content.replace('.withOpacity(', '.withValues(alpha: ')

# Add Quick Quest Section
quick_quest_ui = r'''
                // CARD 4: QUICK QUEST
                _buildCard('4. QUICK QUEST (TANPA BUKTI)', [
                  TextField(
                    controller: _questNameCtrl,
                    style: GoogleFonts.nunito(color: _textOffWhite, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Nama Quest',
                      hintStyle: GoogleFonts.nunito(color: _textMuted, fontSize: 13),
                      filled: true,
                      fillColor: _bgCharcoal,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: _bgCharcoal, borderRadius: BorderRadius.circular(16)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _questDifficulty,
                              dropdownColor: _cardBg,
                              icon: const Icon(Icons.keyboard_arrow_down, color: _textMuted),
                              style: GoogleFonts.nunito(color: _textOffWhite, fontWeight: FontWeight.bold, fontSize: 13),
                              items: ['easy', 'medium', 'hard', 'epic'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                              onChanged: (v) => setState(() => _questDifficulty = v!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: _bgCharcoal, borderRadius: BorderRadius.circular(16)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _questCategory,
                              dropdownColor: _cardBg,
                              icon: const Icon(Icons.keyboard_arrow_down, color: _textMuted),
                              style: GoogleFonts.nunito(color: _textOffWhite, fontWeight: FontWeight.bold, fontSize: 13),
                              items: ['Strength', 'Intelligence', 'Agility', 'Vitality', 'Defense'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                              onChanged: (v) => setState(() => _questCategory = v!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildApplyBtn('CREATE QUICK QUEST', _createQuickQuest),
                ]),
'''

# Find the end of children for ListView
target = r'''              ],
            ),
          ),'''

content = content.replace(target, quick_quest_ui + target)

# Add controllers and variables for Quick Quest
vars_target = r'''  final List<String> _rankOptions = ['Novice', 'Veteran', 'Elite', 'Mythic'];'''
vars_code = r'''  final List<String> _rankOptions = ['Novice', 'Veteran', 'Elite', 'Mythic'];

  // Quick Quest
  final TextEditingController _questNameCtrl = TextEditingController();
  String _questDifficulty = 'easy';
  String _questCategory = 'Strength';
'''
content = content.replace(vars_target, vars_code)

# Add dispose
dispose_target = r'''  @override
  void dispose() {
    _targetUsernameCtrl.dispose();
    super.dispose();
  }'''
dispose_code = r'''  @override
  void dispose() {
    _targetUsernameCtrl.dispose();
    _questNameCtrl.dispose();
    super.dispose();
  }'''
content = content.replace(dispose_target, dispose_code)

# Add Create Quick Quest function
create_target = r'''  Future<void> _resetField(String field, dynamic val) async {'''
create_code = r'''  Future<void> _createQuickQuest() async {
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

  Future<void> _resetField(String field, dynamic val) async {'''
content = content.replace(create_target, create_code)

with open('lib/widget/dev_tools_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated with Quick Quest")
