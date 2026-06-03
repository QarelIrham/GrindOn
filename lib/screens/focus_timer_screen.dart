import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_schema.dart';
import '../services/audio_service.dart';
import 'proof_screen.dart';
import '../theme/rpg_theme.dart';
import '../l10n/app_locale.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';


// ── Layar Penghitung Waktu Fokus (Focus Timer Screen) ─────────────
// Layar ini muncul saat user mulai mengerjakan tugas yang ada batas waktunya.
// Menampilkan animasi lingkaran yang terus berjalan mundur (countdown).
class FocusTimerScreen extends StatefulWidget {
  final String taskId;
  final String uid;
  final String title;
  final String category;
  final int difficulty;
  final int durationMinutes; // 0 = no timer
  final String proofType;
  final int xpReward;
  final int goldReward;

  const FocusTimerScreen({
    super.key,
    required this.taskId,
    required this.uid,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.proofType,
    required this.xpReward,
    required this.goldReward,
  });

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with TickerProviderStateMixin {
  static Map<String, Color> get catColors => RPGColors.catColors;
  static Map<String, IconData> get catIcons => RPGIcons.catIcons;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  Timer? _ticker;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  bool _isPaused = false;

  Color get _color => catColors[widget.category] ?? const Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    if (widget.durationMinutes == 0) {
      // No timer mode — langsung siap selesai
      setState(() => _isRunning = false);
    } else {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // --- LOGIKA MESIN PENGHITUNG WAKTU (TIMER ENGINE) ---
  Future<void> _startTimer() async {
    // 1. Simpan stempel waktu (timestamp) kapan timer dimulai ke database server
    // Ini berguna jika user curang dengan menutup aplikasi paksa (Force Close), 
    // server masih tahu kapan dia sebenarnya mulai.
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('tasks')
        .doc(widget.taskId)
        .update({
      TaskSchema.timerStatus: TaskSchema.timerRunning,
      TaskSchema.timerStartAt: FieldValue.serverTimestamp(),
    });

    // AudioService.playClick();
    setState(() => _isRunning = true);

    // 2. Menyalakan Detak Jantung Timer (Ticker)
    // Timer.periodic akan mengeksekusi kode di dalamnya secara berulang-ulang setiap 1 detik
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return; // Cegah error jika layar sudah ditutup user
      if (_isPaused) return; // Jika tombol Pause ditekan, lewati pengurangan detik
      
      // Jika waktu masih ada, kurangi 1 detik dan perbarui layar (setState)
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        // Jika waktu habis (0 detik), HENTIKAN detak jantung timer agar RAM tidak bocor
        _ticker?.cancel();
        
        // Panggil fungsi penyelesaian (menuju layar pengiriman bukti)
        _onTimerComplete();
      }
    });
  }

  // Fungsi untuk jeda (pause) atau melanjutkan (resume) timer
  void _togglePause() {
    // AudioService.playClick();
    HapticFeedback.lightImpact();
    setState(() => _isPaused = !_isPaused);
  }

  // Dipanggil otomatis ketika detik timer mencapai angka 0
  Future<void> _onTimerComplete() async {
    AudioService.playSuccess();
    HapticFeedback.heavyImpact();
    setState(() {
      _isCompleted = true;
      _isRunning = false;
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('tasks')
        .doc(widget.taskId)
        .update({TaskSchema.timerStatus: TaskSchema.timerCompleted});

    if (!mounted) return;
    _goToProof();
  }

  // Dipanggil ketika user selesai mengerjakan tugas yang "Tanpa Timer"
  Future<void> _onNoTimerComplete() async {
    AudioService.playSuccess();
    HapticFeedback.mediumImpact();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('tasks')
        .doc(widget.taskId)
        .update({TaskSchema.timerStatus: TaskSchema.timerCompleted});

    if (!mounted) return;
    _goToProof();
  }

  // Berpindah ke layar pengumpulan bukti foto/catatan (Proof Screen)
  void _goToProof() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProofScreen(
          taskId: widget.taskId,
          uid: widget.uid,
          title: widget.title,
          category: widget.category,
          proofType: widget.proofType,
          xpReward: widget.xpReward,
          goldReward: widget.goldReward,
        ),
      ),
    );
  }

  // Fitur Rahasia / Tool Kecil: Mengatur sisa waktu secara manual jika user menyentuh tombol jam pasir
  Future<void> _manualSetTime() async {
    final l = context.l;
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (ctx) {
        int m = minutes;
        int s = seconds;
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(l.timerSetManual, style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNumberInput(l.timerMinutes, m, (v) => m = v),
              Text(' : ', style: TextStyle(color: AppColors.textPrimary, fontSize: 24)),
              _buildNumberInput(l.timerSeconds, s, (v) => s = v),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.btnCancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {'m': m, 's': s}),
              child: Text(l.btnSave),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _remainingSeconds = (result['m']! * 60) + result['s']!;
        if (_remainingSeconds > _totalSeconds) _totalSeconds = _remainingSeconds;
      });
    }
  }

  Widget _buildNumberInput(String label, int initial, Function(int) onChange) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 10)),
        SizedBox(
          width: 60,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none),
            controller: TextEditingController(text: initial.toString()),
            onChanged: (v) => onChange(int.tryParse(v) ?? 0),
          ),
        ),
      ],
    );
  }

  // Tombol Nyerah (Give Up) - Dipanggil saat user tidak sanggup menyelesaikan tugas
  // Memberikan hukuman (penalti) berupa pengurangan HP, Koin, XP, dan Reset Streak!
  Future<void> _giveUp() async {
    final l = context.l;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.timerGiveUpTitle,
          style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l.timerGiveUpMsg,
          style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.timerContinue, style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.timerYesGiveUp,
              style: GoogleFonts.nunito(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _ticker?.cancel();
    AudioService.playFail();
    HapticFeedback.heavyImpact();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('tasks')
        .doc(widget.taskId)
        .update({
      TaskSchema.timerStatus: TaskSchema.timerFailed,
      TaskSchema.failedAt: FieldValue.serverTimestamp(),
      TaskSchema.done: false,
    });

    // Penalti: kurangi HP, Gold, XP, dan reset streak (RBS Rule)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .update({
      UserSchema.hp: FieldValue.increment(-RankSystem.hpLossOnTaskFail),
      UserSchema.gold: FieldValue.increment(-15),
      UserSchema.xp: FieldValue.increment(-10), // Penalti XP
      UserSchema.totalTasksFailed: FieldValue.increment(1),
      UserSchema.streak: 0, // Streak reset
    });

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l.timerFailedSnack)),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Menghitung persentase sisa waktu untuk menggambar garis lingkaran
  double get _progress =>
      _totalSeconds == 0 ? 1.0 : 1.0 - (_remainingSeconds / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    final l = context.lw;
    return Scaffold(
      backgroundColor: Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isRunning ? _giveUp : () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.textDisabled),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    widget.durationMinutes == 0 ? l.timerFreeMode : l.timerFocusMode,
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary.withValues(alpha: 0.54),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.durationMinutes > 0) ...[
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: _manualSetTime,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.textPrimary.withValues(alpha: 0.05), shape: BoxShape.circle),
                        child: Icon(Icons.timer_outlined, color: Colors.amber, size: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 24),

            // ── Task Info Card ────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(catIcons[widget.category] ?? Icons.star, color: _color, size: 22),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.nunito(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l.catName(widget.category),
                          style: GoogleFonts.nunito(color: _color, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${widget.xpReward} XP',
                        style: GoogleFonts.nunito(
                          color: const Color(0xFFF59E0B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '+${widget.goldReward} 🪙',
                        style: GoogleFonts.nunito(color: const Color(0xFFFFD700), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Timer / No Timer ──────────────────────────
            if (widget.durationMinutes > 0)
              _buildCircularTimer(l)
            else
              _buildNoTimerMode(l),

            const Spacer(),

            // ── Controls ──────────────────────────────────
            if (widget.durationMinutes > 0 && _isRunning && !_isCompleted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _giveUp,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              l.timerGiveUpBtn,
                              style: GoogleFonts.nunito(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _togglePause,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _color.withValues(alpha: 0.4)),
                          ),
                          child: Center(
                            child: Text(
                              _isPaused ? l.timerResume : l.timerPause,
                              style: GoogleFonts.nunito(
                                color: _color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularTimer(L l) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _isRunning && !_isPaused ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _TimerPainter(
                  progress: _progress,
                  color: _color,
                  isPaused: _isPaused,
                ),
              ),
            ),
            // Time text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(_remainingSeconds),
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  _isPaused
                      ? l.timerPaused
                      : _isCompleted
                          ? l.timerComplete
                          : l.timerRemaining,
                  style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38), fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTimerMode(L l) {
    return Column(
      children: [
        Icon(
          catIcons[widget.category] ?? Icons.star,
          color: _color.withValues(alpha: 0.4),
          size: 80,
        ),
        SizedBox(height: 16),
        Text(
          l.timerWorkTask,
          style: GoogleFonts.nunito(
            color: AppColors.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8),
        Text(
          l.timerPressDone,
          style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38), fontSize: 13),
        ),
        SizedBox(height: 32),
        GestureDetector(
          onTap: _onNoTimerComplete,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color, _color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              l.timerDoneBtn,
              style: GoogleFonts.nunito(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Custom Painter untuk lingkaran countdown ──────────────────
class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPaused;

  _TimerPainter({required this.progress, required this.color, required this.isPaused});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = isPaused ? Colors.grey : color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.isPaused != isPaused;
}
