import sys

with open('lib/widget/dev_tools_sheet.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports if they don't exist
if "import '../services/notification_service.dart';" not in content:
    content = content.replace(
        "import '../models/title_system.dart';", 
        "import '../models/title_system.dart';\nimport '../services/notification_service.dart';\nimport '../screens/onboarding_screen.dart';"
    )

# 2. Add helper methods
helpers = r'''  Widget _buildQuickBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _bgCharcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _buildCard(List<Widget> children) {'''

if "_buildQuickBtn" not in content:
    content = content.replace("  Widget _buildCard(List<Widget> children) {", helpers)
    # also add _deepBlue to colors
    if "const Color _deepBlue =" not in content:
        content = content.replace(
            "const Color _goldWarning = Color(0xFFF59E0B);",
            "const Color _goldWarning = Color(0xFFF59E0B);\nconst Color _deepBlue = Color(0xFF3B82F6);"
        )
        content = content.replace(
            "const Color _accentPurple = Color(0xFF8B5CF6);",
            "const Color _accentPurple = Color(0xFF8B5CF6);\nconst Color _accentPurpleDark = Color(0xFF5B21B6);"
        )

# 3. Add QUICK CHEATS section
quick_cheats = r'''
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
                    _buildQuickBtn('MAX STATS', Icons.diamond_outlined, _accentPurple, () async {
                      setState(() {
                        _levelCtrl.text = '151';
                        _goldCtrl.text = '999999';
                        _xpCtrl.text = '999999';
                        _hp = 100;
                        _strCtrl.text = '99999';
                        _intCtrl.text = '99999';
                        _agiCtrl.text = '99999';
                        _vitCtrl.text = '99999';
                        _defCtrl.text = '99999';
                        _syncRankFromLevel(151);
                      });
                      await _updateStats();
                      await _updateKualifikasi();
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                
                // QUICK QUEST
'''

target_to_replace = r'''
                    ],
                  ),
                ]),
                
                // QUICK QUEST
'''

if "QUICK CHEATS" not in content:
    content = content.replace(target_to_replace, quick_cheats)

with open('lib/widget/dev_tools_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Quick Cheats injected successfully!")
