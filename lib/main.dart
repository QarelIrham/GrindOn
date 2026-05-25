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
class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4C1D95), Color(0xFF2E1065), Color(0xFF1E1B4B)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/logo/Logo_GrindOn.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Color(0xFFA78BFA),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
