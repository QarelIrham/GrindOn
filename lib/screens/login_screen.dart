import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/audio_service.dart';
import 'package:provider/provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../theme/app_theme.dart';
import '../l10n/app_locale.dart';


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
  bool _isMusicEnabled = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color purple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _isMusicEnabled = AudioService.isMusicEnabled;
    if (_isMusicEnabled) {
      AudioService.playBgm();
    }
    
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
    final username = _usernameCtrl.text.trim();
    final password = _passCtrl.text.trim();
    
    if (username.isEmpty || password.isEmpty) {
      final isEn = Provider.of<LocaleService>(context, listen: false).isEnglish;
      setState(() { _errorMsg = isEn ? 'Username and password cannot be empty' : 'Username dan password tidak boleh kosong'; });
      return;
    }

    // 1. Tampilkan animasi muter (Loading) dan hapus pesan error sebelumnya
    setState(() { _isLoading = true; _errorMsg = null; });
    
    // 2. Tembak ke AuthService (Firebase Authentication)
    // AuthService ini mengurus komunikasi langsung ke server Google/Firebase
    final error = await _auth.loginWithUsername(
      username: username, password: password);
    
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
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Tombol samping (Volume & List)
                        Positioned(
                          left: -24,
                          top: 40,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isMusicEnabled = !_isMusicEnabled;
                                  });
                                  AudioService.toggleBgm(_isMusicEnabled);
                                },
                                child: _buildSideButton(_isMusicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  final localeService = Provider.of<LocaleService>(context, listen: false);
                                  localeService.setLang(localeService.isEnglish ? AppLang.id : AppLang.en);
                                },
                                child: _buildSideButton(Icons.language_rounded),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            
                            // Crest Logo
                            _buildLogoCrest(),
                            const SizedBox(height: 16),
                            
                            // Title "GrindOn"
                            Text(
                              'GrindOn',
                              style: GoogleFonts.nunito(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: const Color(0xFFF3E5F5),
                                shadows: [
                                  const Shadow(color: Color(0xFF673AB7), blurRadius: 15, offset: Offset(0, 0)),
                                  const Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 2)),
                                ],
                              ),
                            ),
                            Text(
                              l.isEn ? 'Continue your adventure' : 'Lanjutkan petualanganmu',
                              style: GoogleFonts.nunito(
                                color: const Color(0xFFCE93D8),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Papan Batu / Metal (Login Box)
                            _buildStoneBoard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label(l.authUsername),
                                  const SizedBox(height: 6),
                                  _inputField(controller: _usernameCtrl, hint: l.isEn ? 'your_username' : 'username_kamu', icon: Icons.person_outline_rounded),
                                  const SizedBox(height: 16),
                                  
                                  _label(l.authPassword),
                                  const SizedBox(height: 6),
                                  _inputField(
                                    controller: _passCtrl,
                                    hint: '••••••••',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscurePass,
                                    suffix: _eyeBtn(_obscurePass, () => setState(() => _obscurePass = !_obscurePass)),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: _forgotPassword,
                                      child: Text(
                                        l.isEn ? 'Forgot password?' : 'Lupa password?',
                                        style: GoogleFonts.nunito(
                                          color: const Color(0xFFE1BEE7),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  if (_errorMsg != null) ...[
                                    const SizedBox(height: 16),
                                    _errorBox(_errorMsg!),
                                  ],
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Login button
                                  _buildCrystalButton(
                                    text: l.authLoginBtn,
                                    onPressed: _isLoading ? null : _login,
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
                                  l.authNoAccount,
                                  style: GoogleFonts.nunito(
                                    color: const Color(0xFFD7CCC8),
                                    fontSize: 14,
                                    shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                  child: Text(
                                    l.authRegister,
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

  Widget _buildSideButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1525),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
        border: Border.all(color: const Color(0xFF4527A0), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFF673AB7).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(2, 2))],
      ),
      child: Icon(icon, color: const Color(0xFFE1BEE7), size: 24),
    );
  }

  Widget _buildLogoCrest() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0F0C1B),
        border: Border.all(color: const Color(0xFF7E57C2), width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2, offset: Offset(0, 4)),
          BoxShadow(color: Color(0xFF673AB7), blurRadius: 20, spreadRadius: -5), // Inner glow
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset('lib/assets/logo/Logo_GrindOn.png', fit: BoxFit.contain),
      ),
    );
  }

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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0710), // Batu sangat gelap (cekung)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.5), width: 1.5), 
        boxShadow: const [
          BoxShadow(color: Colors.white12, offset: Offset(0, 1)), // Fake bottom highlight
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
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
