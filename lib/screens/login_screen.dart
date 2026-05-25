import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../theme/app_theme.dart';


// ── Layar Masuk (Login Screen) ──────────────────────────────────
// Layar pertama yang dilihat pengguna (jika belum login).
// Menggunakan username dan password untuk masuk ke dalam aplikasi.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
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
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // --- FUNGSI LOGIN (MASUK AKUN) ---
  Future<void> _login() async {
    // 1. Tampilkan animasi muter (Loading) dan hapus pesan error sebelumnya
    setState(() { _isLoading = true; _errorMsg = null; });
    
    // 2. Tembak ke AuthService (Firebase Authentication)
    // AuthService ini mengurus komunikasi langsung ke server Google/Firebase
    final error = await _auth.loginWithUsername(
      username: _usernameCtrl.text.trim(), password: _passCtrl.text.trim());
    
    if (!mounted) return; // Cegah error jika layar sudah ditutup

    // 3. Cek hasil dari server
    if (error != null) {
      // Jika error (misal: password salah, user tidak ada), tampilkan kotak merah berisi pesan error
      setState(() { _errorMsg = error; _isLoading = false; });
    } else {
      // Jika sukses, hancurkan layar Login dan langsung pindah ke HomeScreen
      // pushReplacement dipakai agar user tidak bisa tekan tombol 'Back' kembali ke layar Login
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  // --- FUNGSI RESET PASSWORD (LUPA KATA SANDI) ---
  void _forgotPassword() async {
    final l = context.l;
    final username = _usernameCtrl.text.trim();
    
    // 1. Validasi: User harus mengetik username-nya terlebih dahulu
    if (username.isEmpty) { 
      setState(() => _errorMsg = l.isEn ? 'Enter username first to reset password.' : 'Isi username dulu untuk reset password.'); 
      return; 
    }
    
    setState(() => _isLoading = true); // Munculkan loading
    
    // 2. Minta AuthService untuk mengirimkan link Reset Password ke Email asli user (lewat Firebase)
    final error = await _auth.sendPasswordReset(username);
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    // 3. Cek hasil dari Firebase
    if (error != null) {
      // Tampilkan error jika username tidak ditemukan di database
      setState(() => _errorMsg = error);
    } else {
      // Tampilkan notifikasi hijau sukses
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.isEn ? 'Password reset email sent! Check your inbox.' : 'Email reset password sudah dikirim! Cek inbox kamu.'),
        backgroundColor: const Color(0xFF10B981)));
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
        Positioned(bottom: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.3,
          child: Image.asset('lib/assets/wallpaper/wallpaper hutan.png', fit: BoxFit.cover,
            color: AppColors.textPrimary.withValues(alpha: 0.6), colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) => SizedBox()),
        ),
        Positioned(bottom: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.35,
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
              SizedBox(height: 50),
              // Logo
              Container(
                padding: const EdgeInsets.all(8), // Kurangi padding agar logo lebih besar
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.15), shape: BoxShape.circle,
                  border: Border.all(color: purple.withValues(alpha: 0.4), width: 2),
                  boxShadow: [BoxShadow(color: purple.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 4)],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'lib/assets/logo/Logo_GrindOn.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 16),
              FittedBox(
                child: Text('GrindOn', style: GoogleFonts.nunito(
                  fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white,
                  letterSpacing: 1.2,
                )),
              ),
              Text(l.isEn ? 'Continue your adventure' : 'Lanjutkan petualanganmu', style: GoogleFonts.nunito(
                color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 14)),
              SizedBox(height: 36),
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
                  Text(l.authLogin, style: GoogleFonts.nunito(
                    color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                  SizedBox(height: 20),
                  _label(l.authUsername),
                  SizedBox(height: 8),
                  _inputField(controller: _usernameCtrl, hint: l.isEn ? 'your username' : 'username kamu', icon: Icons.person_outline_rounded),
                  SizedBox(height: 16),
                  _label(l.authPassword),
                  SizedBox(height: 8),
                  _inputField(
                    controller: _passCtrl, hint: '••••••••', icon: Icons.lock_outline_rounded,
                    obscure: _obscurePass,
                    suffix: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: AppColors.textPrimary.withValues(alpha: 0.38), size: 20),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass)),
                  ),
                  SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: GestureDetector(
                    onTap: _forgotPassword,
                    child: Text(l.isEn ? 'Forgot password?' : 'Lupa password?', style: GoogleFonts.nunito(
                      color: Color(0xFFA78BFA), fontSize: 13, fontWeight: FontWeight.w600)),
                  )),
                  SizedBox(height: 12),
                  if (_errorMsg != null) _errorBox(_errorMsg!),
                  if (_errorMsg != null) SizedBox(height: 12),
                  // Login button
                  SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      disabledBackgroundColor: purple.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.textOnPrimary, strokeWidth: 2))
                      : Text(l.authLoginBtn, style: GoogleFonts.nunito(color: AppColors.textOnPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  )),
                ]),
              ),
              SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(l.authNoAccount, style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 14)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text(l.authRegister, style: GoogleFonts.nunito(
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
  Widget _label(String text) => Text(text, style: GoogleFonts.nunito(
    color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600));

  Widget _inputField({
    required TextEditingController controller, required String hint,
    required IconData icon, bool obscure = false, Widget? suffix,
  }) {
    return TextField(
      controller: controller, obscureText: obscure,
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
    _star(30,100,3,0.3), _star(80,180,2,0.2), _star(150,60,4,0.4),
    _star(250,130,2,0.15), _star(300,280,3,0.25), _star(60,420,2,0.2),
    _star(320,480,4,0.35), _star(200,560,2,0.15),
  ];

  Widget _star(double x, double y, double s, double o) => Positioned(left: x, top: y, child: Container(
    width: s, height: s, decoration: BoxDecoration(
      color: AppColors.textPrimary.withValues(alpha: o), shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: AppColors.textPrimary.withValues(alpha: o * 0.5), blurRadius: s * 2)]),
  ));
}
