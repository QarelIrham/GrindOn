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
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() => _errorMsg = l.isEn ? 'All fields must be filled.' : 'Semua kolom tidak boleh kosong.');
      return;
    }
    if (password != confirm) { 
      setState(() => _errorMsg = l.isEn ? 'Passwords do not match.' : 'Password tidak cocok.'); 
      return; 
    }
    if (username.contains(' ')) { 
      setState(() => _errorMsg = l.isEn ? 'Username cannot contain spaces.' : 'Username tidak boleh mengandung spasi.'); 
      return; 
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final error = await _auth.register(
      name: name, username: username,
      email: email, password: password);
    if (!mounted) return;
    if (error != null) {
      setState(() { _errorMsg = error; _isLoading = false; });
    } else {
      // Firebase otomatis login user setelah register.
      // Langsung arahkan ke pembuatan karakter.
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => const CharacterCreationScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.lw;
    return Scaffold(
      body: Stack(
        children: [
          // 1. Wallpaper Gelap Full Screen
          Positioned.fill(
            child: Image.asset(
              'lib/assets/wallpaper/wallpaper castle dark.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Konten Utama
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Tombol Kembali melayang di kiri atas
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1525),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF4527A0), width: 2),
                                boxShadow: [BoxShadow(color: const Color(0xFF673AB7).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFE1BEE7), size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Title
                        Text(
                          l.isEn ? 'Create Account' : 'Buat Akun Baru',
                          style: GoogleFonts.nunito(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: const Color(0xFFF3E5F5),
                            shadows: [
                              const Shadow(color: Color(0xFF673AB7), blurRadius: 15, offset: Offset(0, 0)),
                              const Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 2)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.isEn ? 'Start your self-development journey!' : 'Mulai perjalanan pengembangan dirimu!',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFFCE93D8),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Papan Batu (Register Box)
                        _buildStoneBoard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              _label(l.authName),
                              const SizedBox(height: 6),
                              _inputField(controller: _nameCtrl, hint: l.isEn ? 'Your name' : 'Nama kamu', icon: Icons.badge_outlined),
                              const SizedBox(height: 14),
                              
                              // Username
                              _label(l.authUsername),
                              const SizedBox(height: 2),
                              Text(
                                l.isEn ? 'Used for login. Cannot be changed.' : 'Digunakan untuk login. Tidak bisa diganti.',
                                style: GoogleFonts.nunito(color: const Color(0xFF8D6E63), fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              _inputField(controller: _usernameCtrl, hint: l.isEn ? 'your_username' : 'username_kamu', icon: Icons.alternate_email_rounded),
                              const SizedBox(height: 14),
                              
                              // Email
                              _label(l.authEmail),
                              const SizedBox(height: 2),
                              Text(
                                l.isEn ? 'For verification & password reset only.' : 'Hanya untuk verifikasi & reset password.',
                                style: GoogleFonts.nunito(color: const Color(0xFF8D6E63), fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              _inputField(controller: _emailCtrl, hint: l.isEn ? 'your@email.com' : 'email@kamu.com', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
                              const SizedBox(height: 14),
                              
                              // Password
                              _label(l.authPassword),
                              const SizedBox(height: 6),
                              _inputField(
                                controller: _passCtrl,
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePass,
                                suffix: _eyeBtn(_obscurePass, () => setState(() => _obscurePass = !_obscurePass)),
                              ),
                              const SizedBox(height: 14),
                              
                              // Confirm Password
                              _label(l.isEn ? 'Confirm Password' : 'Konfirmasi Password'),
                              const SizedBox(height: 6),
                              _inputField(
                                controller: _confirmCtrl,
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscureConfirm,
                                suffix: _eyeBtn(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                              ),
                              
                              if (_errorMsg != null) ...[
                                const SizedBox(height: 16),
                                _errorBox(_errorMsg!),
                              ],
                              
                              const SizedBox(height: 24),
                              
                              // Register button
                              _buildCrystalButton(
                                text: l.authRegisterBtn,
                                onPressed: _isLoading ? null : _register,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l.authHaveAccount,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFFD7CCC8),
                                fontSize: 14,
                                shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                l.authLogin,
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFFE1BEE7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Elemen UI Kustom ───────────────────────

  Widget _buildStoneBoard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1525), Color(0xFF0F0C1B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF311B92), width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: const Color(0xFF673AB7).withValues(alpha: 0.15), blurRadius: 30, spreadRadius: -5),
        ],
      ),
      child: child,
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.nunito(
          color: const Color(0xFFE1BEE7),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _eyeBtn(bool vis, VoidCallback onTap) => IconButton(
        icon: Icon(
          vis ? Icons.visibility_off : Icons.visibility,
          color: const Color(0xFF7E57C2),
          size: 20,
        ),
        onPressed: onTap,
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0710),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.white12, offset: Offset(0, 1)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: GoogleFonts.nunito(color: const Color(0xFFF3E5F5), fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(color: const Color(0xFF7E57C2), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF7E57C2), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCrystalButton({required String text, required VoidCallback? onPressed, required bool isLoading}) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFD500F9), Color(0xFF6A1B9A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: const Color(0xFF311B92), width: 3),
        boxShadow: [
          BoxShadow(color: const Color(0xFFD500F9).withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                text,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _errorBox(String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1015),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7)),
          boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2), blurRadius: 10)],
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg, style: GoogleFonts.nunito(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
}
