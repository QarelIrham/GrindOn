import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/character_creation_screen.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/locale_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'models/app_schema.dart';

// --- TITIK AWAL APLIKASI (ENTRY POINT) ---
// void main() adalah fungsi pertama yang dieksekusi saat aplikasi dibuka.
void main() async {
  // 1. Memastikan kerangka dasar (bindings) Flutter sudah terpasang dengan OS (Android/iOS)
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Membuka koneksi awal ke server Google Firebase menggunakan setting default
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // 3. Menyalakan mesin pemutar efek suara (Background Audio)
  AudioService.init();
  
  // 4. Mempersiapkan sistem Notifikasi Lokal agar aplikasi bisa mengingatkan user
  await NotificationService.init();

  // 5. Menyiapkan sistem multibahasa (Indonesia/Inggris)
  final localeService = LocaleService();
  await localeService.init();

  // 6. Menyiapkan sistem warna/tema (Anime/Comic/Light/Dark)
  final themeService = ThemeService();

  // 7. Menjalankan Aplikasi Induk dengan MultiProvider
  // MultiProvider berfungsi agar status (Bahasa & Tema) bisa diakses dari seluruh file
  // tanpa harus mengoper datanya satu per satu (State Management).
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleService>.value(value: localeService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
      ],
      child: const MyApp(),
    ),
  );
}



// --- APLIKASI UTAMA ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Membaca status tema saat ini (misal: Apakah user sedang pakai tema Comic?)
    final themeService = Provider.of<ThemeService>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Menghilangkan tulisan "DEBUG" di pojok kanan atas
      title: 'GrindOn',
      theme: themeService.themeData,     // Mengaplikasikan tema ke seluruh elemen aplikasi
      home: const _AppGate(),            // Masuk ke Gerbang Pengecekan
    );
  }
}

// --- GERBANG PENGECEKAN SESI (ROUTER) ---
/// Fungsi ini menentukan apakah user harus pergi ke halaman Login atau langsung ke Home.
class _AppGate extends StatefulWidget {
  const _AppGate();
  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  @override
  Widget build(BuildContext context) {
    // StreamBuilder berfungsi sebagai 'Soket Pantau' yang terus mendengarkan status Login
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // Jika aplikasi masih loading mengecek internet, tampilkan layar loading ungu
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _SplashLoading();
        }

        // Jika user SUDAH LOGIN (token token auth ditemukan di memori HP)
        if (authSnap.hasData && authSnap.data != null) {
          // Lanjutkan cek apakah user sudah selesai membuat karakternya
          return _CharacterGate(uid: authSnap.data!.uid);
        }

        // Jika user BELUM LOGIN, arahkan ke layar LoginScreen
        return const LoginScreen();
      },
    );
  }
}

// --- GERBANG PENGECEKAN KARAKTER (ONBOARDING & CHARACTER CREATION) ---
/// Mengecek apakah user yang sudah login itu pengguna baru atau pengguna lama
class _CharacterGate extends StatefulWidget {
  final String uid; // Menyimpan ID Firebase milik user
  const _CharacterGate({required this.uid});

  @override
  State<_CharacterGate> createState() => _CharacterGateState();
}

class _CharacterGateState extends State<_CharacterGate> {
  bool? _seen; // Mengecek apakah user sudah pernah lihat Onboarding (Slider pengenalan)

  @override
  void initState() {
    super.initState();
    _check(); // Jalan pertama kali
  }

  // Fungsi mengecek ke memori HP (SharedPreferences)
  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _seen = prefs.getBool('onboarding_seen') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    // Selama status baca memori belum selesai (null), tahan di layar loading
    if (_seen == null) return const _SplashLoading();

    // Bertanya ke database Firestore: "Apakah user ini dokumennya sudah lengkap?"
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(widget.uid).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SplashLoading();
        }
        
        final data = snap.data?.data() as Map<String, dynamic>?;
        // Memeriksa status (onboardingDone) yang diset saat user bikin karakter
        final done = data?[UserSchema.onboardingDone] ?? false;
        
        // KONDISI 1: Jika sudah pernah bikin karakter (user lama) -> Langsung Masuk Halaman Utama (Home)
        if (done == true) return const HomeScreen();

        // KONDISI 2: Jika karakter BELUM dibuat, DAN dia BELUM pernah lihat animasi slider
        if (_seen == false) return const OnboardingScreen();
        
        // KONDISI 3: Jika karakter BELUM dibuat, TAPI dia SUDAH pernah lihat animasi slider
        return const CharacterCreationScreen();
      },
    );
  }
}

// --- LAYAR LOADING KUSTOM (SPLASH SCREEN) ---
/// Layar transisi ungu yang indah agar user tidak melihat layar putih/blank saat aplikasi loading
class _SplashLoading extends StatefulWidget {
  const _SplashLoading();

  @override
  State<_SplashLoading> createState() => _SplashLoadingState();
}

class _SplashLoadingState extends State<_SplashLoading> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Animasi durasi 1.5 detik berulang bolak-balik (naik-turun)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Ukuran scale dari 90% ke 105% untuk efek "bernafas" (breathing)
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C103F), // Ungu sangat gelap di atas
              Color(0xFF150A21), // Hampir hitam di tengah
              Color(0xFF0D0514), // Hitam pekat di bawah (Vibe Dungeon)
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Logo dengan efek detak (Pulse) & Cahaya Magis (Glow)
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA78BFA).withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'lib/assets/logo/Logo_GrindOn.png',
                    width: 150,
                    height: 150,
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // 2. Teks Loading gaya RPG (seperti masuk ke realm/dungeon)
              const Text(
                "MEMASUKI DUNIA...",
                style: TextStyle(
                  color: Color(0xFFD8B4FE),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 3. Bar Loading ala RPG (Mirip Mana/XP Bar)
              Container(
                width: 220,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6), // Latar belakang bar
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF6D28D9), // Border ungu terang
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6D28D9).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA78BFA)), // Isi bar
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
