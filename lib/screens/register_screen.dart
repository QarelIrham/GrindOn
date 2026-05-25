import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import 'character_creation_screen.dart';
import '../theme/app_theme.dart';


// ── Layar Daftar (Register Screen) ──────────────────────────────
// Layar untuk membuat akun baru jika user belum memiliki akun.
// Meminta nama, username, email, dan password.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _errorMsg;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color purple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _usernameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose(); _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l = context.l;
    if (_passCtrl.text != _confirmCtrl.text) { 
      setState(() => _errorMsg = l.isEn ? 'Passwords do not match.' : 'Password tidak cocok.'); 
      return; 
    }
    if (_nameCtrl.text.trim().isEmpty) { 
      setState(() => _errorMsg = l.isEn ? 'Name cannot be empty.' : 'Nama tidak boleh kosong.'); 
      return; 
    }
    if (_usernameCtrl.text.trim().isEmpty) { 
      setState(() => _errorMsg = l.isEn ? 'Username cannot be empty.' : 'Username tidak boleh kosong.'); 
      return; 
    }
    if (_usernameCtrl.text.trim().contains(' ')) { 
      setState(() => _errorMsg = l.isEn ? 'Username cannot contain spaces.' : 'Username tidak boleh mengandung spasi.'); 
      return; 
    }

    setState(() { _isLoading = true; _errorMsg = null; });
    final error = await _auth.register(
      name: _nameCtrl.text.trim(), username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
    if (!mounted) return;
    if (error != null) {
      setState(() { _errorMsg = error; _isLoading = false; });
    } else {
      // Navigate to character creation instead of home
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => const CharacterCreationScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.lw;
    return Scaffold(
      body: Stack(children: [
        // BG gradient
        Container(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF4C1D95), Color(0xFF2E1065), Color(0xFF1E1B4B)],
        ))),
        // Stars
        ..._buildStars(),
        // Wallpaper bottom
        Positioned(bottom: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.25,
          child: Image.asset('lib/assets/wallpaper/wallpaper hutan.png', fit: BoxFit.cover,
            color: AppColors.textPrimary.withValues(alpha: 0.6), colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) => SizedBox()),
        ),
        Positioned(bottom: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.3,
          child: Container(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1B4B), Colors.transparent], stops: [0.0, 0.4],
          ))),
        ),
        // Content
        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(opacity: _fadeAnim, child: SlideTransition(
            position: _slideAnim,
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(height: 20),
              // Back button
              Align(alignment: Alignment.centerLeft, child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.15)),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 18),
                ),
              )),
              SizedBox(height: 16),
              // Title
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [Color(0xFFA78BFA), Color(0xFFE879F9)]).createShader(b),
                child: Text(l.isEn ? 'Create New Account' : 'Buat Akun Baru', style: GoogleFonts.nunito(
                  color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w900)),
              ),
              SizedBox(height: 6),
              Text(l.isEn ? 'Start your self-development journey!' : 'Mulai perjalanan pengembangan dirimu!', style: GoogleFonts.nunito(
                color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 14)),
              SizedBox(height: 24),
              // Form card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08)),
                  boxShadow: [BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.3), blurRadius: 20)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Name
                  _label(l.authName),
                  SizedBox(height: 8),
                  _inputField(controller: _nameCtrl, hint: l.isEn ? 'Your name' : 'Nama kamu', icon: Icons.badge_outlined),
                  SizedBox(height: 14),
                  // Username
                  _label(l.authUsername),
                  SizedBox(height: 4),
                  Text(l.isEn ? 'Used for login. Cannot be changed.' : 'Digunakan untuk login. Tidak bisa diganti.', style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38), fontSize: 11)),
                  SizedBox(height: 6),
                  _inputField(controller: _usernameCtrl, hint: l.isEn ? 'your_username' : 'username_kamu', icon: Icons.alternate_email_rounded),
                  SizedBox(height: 14),
                  // Email
                  _label(l.authEmail),
                  SizedBox(height: 4),
                  Text(l.isEn ? 'For verification & password reset only.' : 'Hanya untuk verifikasi & reset password.', style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38), fontSize: 11)),
                  SizedBox(height: 6),
                  _inputField(controller: _emailCtrl, hint: l.isEn ? 'your@email.com' : 'email@kamu.com', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
                  SizedBox(height: 14),
                  // Password
                  _label(l.authPassword),
                  SizedBox(height: 8),
                  _inputField(controller: _passCtrl, hint: '••••••••', icon: Icons.lock_outline_rounded,
                    obscure: _obscurePass, suffix: _eyeBtn(_obscurePass, () => setState(() => _obscurePass = !_obscurePass))),
                  SizedBox(height: 14),
                  // Confirm
                  _label(l.isEn ? 'Confirm Password' : 'Konfirmasi Password'),
                  SizedBox(height: 8),
                  _inputField(controller: _confirmCtrl, hint: '••••••••', icon: Icons.lock_outline_rounded,
                    obscure: _obscureConfirm, suffix: _eyeBtn(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm))),
                  SizedBox(height: 12),
                  if (_errorMsg != null) _errorBox(_errorMsg!),
                  if (_errorMsg != null) SizedBox(height: 12),
                  // Register button
                  SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      disabledBackgroundColor: purple.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.textOnPrimary, strokeWidth: 2))
                      : Text(l.authRegisterBtn, style: GoogleFonts.nunito(color: AppColors.textOnPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  )),
                ]),
              ),
              SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(l.authHaveAccount, style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 14)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(l.authLogin, style: GoogleFonts.nunito(
                    color: const Color(0xFFA78BFA), fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 40),
            ]),
          )),
        )),
      ]),
    );
  }

  // ─── Helpers ───────────────────────
  Widget _label(String t) => Text(t, style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600));

  Widget _eyeBtn(bool vis, VoidCallback onTap) => IconButton(
    icon: Icon(vis ? Icons.visibility_off : Icons.visibility, color: AppColors.textPrimary.withValues(alpha: 0.38), size: 20), onPressed: onTap);

  Widget _inputField({
    required TextEditingController controller, required String hint, required IconData icon,
    bool obscure = false, Widget? suffix, TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller, obscureText: obscure, keyboardType: keyboard,
      style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38), fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textPrimary.withValues(alpha: 0.38), size: 20), suffixIcon: suffix,
        filled: true, fillColor: AppColors.textPrimary.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x1AEF4444), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0x4DEF4444)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: GoogleFonts.nunito(color: Colors.redAccent, fontSize: 13))),
    ]),
  );

  List<Widget> _buildStars() => [
    _star(30,90,3,0.3), _star(90,160,2,0.2), _star(160,50,4,0.4),
    _star(260,120,2,0.15), _star(310,260,3,0.25), _star(70,400,2,0.2),
    _star(330,460,4,0.35), _star(210,540,2,0.15),
  ];

  Widget _star(double x, double y, double s, double o) => Positioned(left: x, top: y, child: Container(
    width: s, height: s, decoration: BoxDecoration(
      color: AppColors.textPrimary.withValues(alpha: o), shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: AppColors.textPrimary.withValues(alpha: o * 0.5), blurRadius: s * 2)]),
  ));
}
