import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/audio_service.dart';
import '../services/locale_service.dart';
import '../l10n/app_locale.dart';
import '../models/app_schema.dart';
import '../screens/login_screen.dart';
import '../screens/theme_selector_screen.dart';
import '../theme/app_theme.dart';
import '../screens/credits_screen.dart';

// ── Panel Pengaturan (Settings Sheet) ───────────────────────────
// Modal bawah (Bottom Sheet) untuk mengatur profil, password, tema, bahasa,
// serta melihat status verifikasi email dan tombol logout.
class SettingsSheet extends StatefulWidget {
  final String currentName;
  final String currentUsername;
  final String currentEmail;
  final bool soundEnabled;
  final bool musicEnabled;
  final VoidCallback onProfileUpdated;

  const SettingsSheet({
    super.key,
    required this.currentName,
    required this.currentUsername,
    required this.currentEmail,
    required this.soundEnabled,
    required this.musicEnabled,
    required this.onProfileUpdated,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  late bool _isEmailVerified;
  late bool _soundEnabled;
  late bool _musicEnabled;
  int _versionTapCount = 0; // Menghitung jumlah klik untuk easter egg

  @override
  void initState() {
    super.initState();
    _isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    _soundEnabled = widget.soundEnabled;
    _musicEnabled = widget.musicEnabled;
  }

  Future<void> _toggleSound(bool val) async {
    setState(() => _soundEnabled = val);
    AudioService.isEnabled = val;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        UserSchema.soundEnabled: val,
      });
    }
    widget.onProfileUpdated();
  }

  Future<void> _toggleMusic(bool val) async {
    setState(() => _musicEnabled = val);
    await AudioService.toggleBgm(val);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        UserSchema.musicEnabled: val,
      });
    }
    widget.onProfileUpdated();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.onProfileUpdated();
  }

  Future<void> _sendVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        _showSuccess('Link verifikasi telah dikirim ke email Anda!');
      } catch (e) {
        _showError('Gagal mengirim email: $e');
      }
    }
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: widget.currentName);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.10))),
          title: Text('Edit Profil', style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(controller: nameCtrl, label: 'Nama Lengkap', icon: Icons.person_outline),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.54)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                final err = await _auth.updateProfile(name: nameCtrl.text.trim());
                setState(() => _isLoading = false);
                if (err != null) {
                  _showError(err);
                } else {
                  _showSuccess('Profil diperbarui!');
                }
              },
              child: Text('Simpan', style: TextStyle(color: AppColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editUsername() async {
    final userCtrl = TextEditingController(text: widget.currentUsername);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.10))),
        title: Text('Ganti Username', style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: _buildField(controller: userCtrl, label: 'Username Baru', icon: Icons.alternate_email_rounded),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.54)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final val = userCtrl.text.trim();
              if (val.isEmpty || val.contains(' ')) {
                _showError('Username tidak valid.'); return;
              }
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final err = await _auth.changeUsername(widget.currentUsername, val);
              setState(() => _isLoading = false);
              if (err != null) {
                _showError(err);
              } else {
                _showSuccess('Username diganti!');
              }
            },
            child: Text('Simpan', style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _editPassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool isDialogLoading = false;
          String? errorMessage;
          
          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.10))),
            title: Text('Ganti Password', style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(errorMessage!, style: GoogleFonts.nunito(color: const Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ],
                _buildField(controller: oldCtrl, label: 'Password Lama', icon: Icons.lock_outline, obscure: true),
                SizedBox(height: 16),
                _buildField(controller: newCtrl, label: 'Password Baru', icon: Icons.vpn_key_outlined, obscure: true),
                if (isDialogLoading) ...[
                  SizedBox(height: 16),
                  LinearProgressIndicator(color: AppColors.primary, backgroundColor: Colors.transparent),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDialogLoading ? null : () => Navigator.pop(context), 
                child: Text('Batal', style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.54)))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: isDialogLoading ? null : () async {
                  if (newCtrl.text.length < 6) {
                    setStateDialog(() => errorMessage = 'Minimal 6 karakter.');
                    return;
                  }
                  
                  setStateDialog(() {
                    isDialogLoading = true;
                    errorMessage = null; // Reset error saat mencoba lagi
                  });
                  
                  final err = await _auth.changePassword(oldCtrl.text, newCtrl.text);
                  
                  setStateDialog(() {
                    isDialogLoading = false;
                    if (err != null) errorMessage = err;
                  });
                  
                  if (err == null) {
                    if (context.mounted) Navigator.pop(context);
                    _showSuccess('Password diganti!');
                  }
                },
                child: Text('Simpan', style: TextStyle(color: AppColors.textPrimary)),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _resetTutorial() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      setState(() => _isLoading = true);
      try {
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
          Navigator.pop(context); // Dismiss settings sheet
          _showSuccess('Panduan misi telah disetel ulang! xqvx The Creator akan membimbingmu kembali.');
        }
      } catch (e) {
        _showError('Gagal menyetel ulang panduan: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.10))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final isEn = localeService.isEnglish;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: AppColors.textSecondary, blurRadius: 20, spreadRadius: 5)],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            if (_isLoading) LinearProgressIndicator(color: AppColors.primary, backgroundColor: Colors.transparent),
            SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textDisabled, borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 20),
            Text(
              isEn ? 'ACCOUNT SETTINGS' : 'PENGATURAN AKUN',
              style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            SizedBox(height: 24),
            
            // Verification Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isEmailVerified ? Color(0xFF10B981).withValues(alpha: 0.1) : Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (_isEmailVerified ? Color(0xFF10B981) : Color(0xFFF59E0B)).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_isEmailVerified ? Icons.verified_user_rounded : Icons.warning_amber_rounded, color: _isEmailVerified ? Color(0xFF10B981) : Color(0xFFF59E0B), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEmailVerified
                                ? (isEn ? 'Account Verified' : 'Akun Terverifikasi')
                                : (isEn ? 'Account Not Verified' : 'Akun Belum Verifikasi'),
                            style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            _isEmailVerified
                                ? (isEn ? 'Your email is safe and validated.' : 'Email Anda sudah aman dan tervalidasi.')
                                : (isEn ? 'Verify your email for extra security.' : 'Verifikasi email Anda untuk keamanan ekstra.'),
                            style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (!_isEmailVerified)
                      TextButton(
                        onPressed: _sendVerification,
                        child: Text(isEn ? 'Verify' : 'Verifikasi', style: GoogleFonts.nunito(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            _buildSettingItem(Icons.person_rounded, isEn ? 'Profile' : 'Profil', widget.currentName, _editProfile),
            _buildSettingItem(Icons.alternate_email_rounded, 'Username', '@${widget.currentUsername}', _editUsername),
            _buildSettingItem(Icons.lock_outline_rounded, isEn ? 'Security' : 'Keamanan', isEn ? 'Change your password' : 'Ganti password Anda', _editPassword),
            _buildSettingItem(Icons.help_outline_rounded, isEn ? 'Reset Tutorial Guide' : 'Reset Panduan Misi', isEn ? 'Replay xqvx The Creator\'s guidance' : 'Tanya ulang panduan xqvx The Creator', _resetTutorial),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(_soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: AppColors.primary, size: 20),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isEn ? 'Sound Effects' : 'Efek Suara', style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            _soundEnabled ? (isEn ? 'Sound On' : 'Suara Aktif') : (isEn ? 'Sound Off' : 'Suara Dimatikan'),
                            style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _soundEnabled,
                      onChanged: _toggleSound,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(_musicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded, color: AppColors.primary, size: 20),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isEn ? 'Background Music' : 'Musik Latar', style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            _musicEnabled ? (isEn ? 'Music On' : 'Musik Aktif') : (isEn ? 'Music Off' : 'Musik Dimatikan'),
                            style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _musicEnabled,
                      onChanged: _toggleMusic,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            // ── Language Toggle ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.language_rounded, color: AppColors.primary, size: 20),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        isEn ? 'Language / Bahasa' : 'Bahasa / Language',
                        style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    _buildLangButton(AppLang.id, '🇮🇩 ID', localeService),
                    const SizedBox(width: 8),
                    _buildLangButton(AppLang.en, '🇬🇧 EN', localeService),
                  ],
                ),
              ),
            ),

            // ── Theme Selector ───────────────────────────────────
            _buildSettingItem(
              Icons.palette_outlined,
              isEn ? 'Theme' : 'Tema',
              isEn ? 'Customize your app appearance' : 'Sesuaikan tampilan aplikasi',
              () {
                Navigator.pop(context); // Close settings sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ThemeSelectorScreen(),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _auth.logout().then((_) {
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false);
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(isEn ? 'SIGN OUT' : 'KELUAR AKUN', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // ── Hidden Version Trigger (Easter Egg) ──────────────────
            // Area ini berisi versi aplikasi yang tidak mencolok. 
            // Jika diklik 7 kali, akan membuka layar rahasia (Credits).
            GestureDetector(
              behavior: HitTestBehavior.opaque, // Memastikan tap selalu terdeteksi
              onTap: () {
                _versionTapCount++;
                if (_versionTapCount >= 7) {
                  _versionTapCount = 0; // Reset hitungan
                  
                  // Mainkan efek suara naik level dan getaran (opsional)
                  AudioService.playLevelUp();
                  // Tutup pengaturan saat ini
                  Navigator.pop(context);
                  
                  // Transisi fade ke layar Credits (Rahasia)
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 800),
                      pageBuilder: (context, anim1, anim2) {
                        return FadeTransition(
                          opacity: anim1,
                          // Import secara dinamis agar tidak mengubah file terlalu banyak di atas
                          child: const _CreditsScreenWrapper(), 
                        );
                      },
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 30.0),
                child: Text(
                  'App Version 1.0.0',
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary.withValues(alpha: 0.15),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildLangButton(AppLang lang, String label, LocaleService service) {
    final active = service.lang == lang;
    return GestureDetector(
      onTap: () => service.setLang(lang),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.12),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: active ? AppColors.textOnPrimary : AppColors.textPrimary.withValues(alpha: 0.54),
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(subtitle, style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textDisabled, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Wrapper untuk mencegah error impor jika credits_screen diletakkan di file terpisah.
// Kita akan memanggil file credits_screen.dart di dalamnya.
class _CreditsScreenWrapper extends StatelessWidget {
  const _CreditsScreenWrapper();
  @override
  Widget build(BuildContext context) {
    return const CreditsScreen();
  }
}

