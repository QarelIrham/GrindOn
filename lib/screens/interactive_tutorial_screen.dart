import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_schema.dart';
import '../services/audio_service.dart';
import 'home_screen.dart';
import '../theme/app_theme.dart';
import '../services/locale_service.dart';

class InteractiveTutorialScreen extends StatefulWidget {
  const InteractiveTutorialScreen({super.key});

  @override
  State<InteractiveTutorialScreen> createState() => _InteractiveTutorialScreenState();
}

class _InteractiveTutorialScreenState extends State<InteractiveTutorialScreen>
    with TickerProviderStateMixin {
  bool _isTaskDone = false;
  bool _showReward = false;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeTutorial() async {
    if (_isTaskDone) return;
    setState(() {
      _isTaskDone = true;
    });

    AudioService.playCoin();
    
    // Tampilkan animasi reward sejenak
    setState(() {
      _showReward = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        UserSchema.xp: FieldValue.increment(50),
        UserSchema.gold: FieldValue.increment(100),
        UserSchema.onboardingDone: true,
      });
    }

    // Tunggu 2 detik biar user bisa lihat animasi hadiahnya, lalu pindah
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.lw;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Latar belakang gradasi
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
              ),
            ),
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeCtrl,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      l.isEn ? 'Your First Quest!' : 'Quest Pertamamu!',
                      style: GoogleFonts.outfit(
                        color: AppColors.gold,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.isEn 
                        ? 'Check off the task below to earn your first reward.'
                        : 'Centang tugas di bawah ini untuk mendapatkan hadiah pertamamu.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Kotak Task (Quest)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isTaskDone ? AppColors.primary.withValues(alpha: 0.2) : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isTaskDone ? AppColors.primary : AppColors.cardBorder,
                          width: 2,
                        ),
                        boxShadow: _isTaskDone
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15)]
                            : [],
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _completeTutorial,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _isTaskDone ? AppColors.primary : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isTaskDone ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: _isTaskDone
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.isEn ? 'Take 3 deep breaths' : 'Tarik napas dalam 3 kali',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    decoration: _isTaskDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.stars, color: AppColors.primary, size: 14),
                                    const SizedBox(width: 4),
                                    Text('+50 XP', style: GoogleFonts.nunito(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 12),
                                    Icon(Icons.monetization_on, color: AppColors.gold, size: 14),
                                    const SizedBox(width: 4),
                                    Text('+100 Gold', style: GoogleFonts.nunito(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Efek Popup Hadiah ketika selesai
          if (_showReward)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E293B).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.gold, width: 2),
                    boxShadow: [
                      BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.celebration, color: AppColors.gold, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        l.isEn ? 'Quest Complete!' : 'Quest Selesai!',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          Text('+50 XP', style: GoogleFonts.nunito(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on, color: AppColors.gold, size: 24),
                          const SizedBox(width: 8),
                          Text('+100 Gold', style: GoogleFonts.nunito(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
