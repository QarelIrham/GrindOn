import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/audio_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

// ──────────────────────────────────────────────────────────
//  CUSTOM RPG NAVBAR  ·  Zero continuous animations
//  Desain: Flat glass bar + sliding gradient indicator
// ──────────────────────────────────────────────────────────
class CustomNavbar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onTaskAdded;
  final VoidCallback? onAddPressed;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onTaskAdded,
    this.onAddPressed,
  });

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();
}

class _CustomNavbarState extends State<CustomNavbar>
    with SingleTickerProviderStateMixin {
  // Satu controller — hanya berjalan saat ganti tab, bukan looping
  AnimationController? _slideCtrl;
  int _fromIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(CustomNavbar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _fromIndex = old.currentIndex;
      _slideCtrl?.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _slideCtrl?.dispose();
    super.dispose();
  }

  // Data tab: (ikon kosong, ikon penuh, label-getter)
  List<(IconData, IconData)> get _tabs => [
        (Icons.home_outlined, Icons.home_rounded),
        (Icons.checklist_outlined, Icons.checklist_rounded),
        (Icons.show_chart_rounded, Icons.show_chart_rounded),
        (Icons.person_outline_rounded, Icons.person_rounded),
      ];

  @override
  Widget build(BuildContext context) {
    final l = context.lw;
    final labels = [l.navHome, l.navDaily, l.navStats, l.navProfile];
    final mq = MediaQuery.of(context);
    // Lebar satu slot (5 slot: tab0, tab1, [add], tab2, tab3)
    final double slotW = mq.size.width / 5;

    // Guard: jika controller belum siap, tampilkan placeholder
    final ctrl = _slideCtrl;
    if (ctrl == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Container(
        height: 72 + mq.padding.bottom,
        decoration: BoxDecoration(
          // Theme adaptive background
          color: AppColors.cardBackground.withValues(alpha: 0.97),
          border: Border(
            top: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Sliding Top Indicator ───────────────────
            AnimatedBuilder(
              animation: ctrl,
              builder: (_, __) {
                final t = Curves.easeOutCubic.transform(ctrl.value);
                final fromX = _slotLeft(_fromIndex, slotW);
                final toX   = _slotLeft(widget.currentIndex, slotW);
                final x     = fromX + (toX - fromX) * t;

                return Positioned(
                  top: 0,
                  left: x + slotW * 0.15,
                  child: Container(
                    width: slotW * 0.70,
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── Tab Row ─────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 72,
              child: Row(
                children: [
                  // Tab 0 & 1
                  for (int i = 0; i < 2; i++)
                    _NavTab(
                      index: i,
                      activeIndex: widget.currentIndex,
                      inactiveIcon: _tabs[i].$1,
                      activeIcon: _tabs[i].$2,
                      label: labels[i],
                      width: slotW,
                      onTap: _onTabTap,
                    ),

                  // ── Add Button (tengah) ───────────────
                  SizedBox(
                    width: slotW,
                    height: 72,
                    child: Align(
                      alignment: const Alignment(0, -0.1),
                      child: _AddButton(onPressed: widget.onAddPressed),
                    ),
                  ),

                  // Tab 2 & 3
                  for (int i = 2; i < 4; i++)
                    _NavTab(
                      index: i,
                      activeIndex: widget.currentIndex,
                      inactiveIcon: _tabs[i].$1,
                      activeIcon: _tabs[i].$2,
                      label: labels[i],
                      width: slotW,
                      onTap: _onTabTap,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Posisi kiri dari slot (0-based, slot tengah dilewati)
  double _slotLeft(int tabIndex, double slotW) {
    final pos = tabIndex < 2 ? tabIndex : tabIndex + 1;
    return pos * slotW;
  }

  void _onTabTap(int index) {
    if (index == widget.currentIndex) return;
    HapticFeedback.lightImpact();
    AudioService.playClick();
    widget.onTap(index);
  }
}

// ──────────────────────────────────────────────────────────
//  Satu item tab (ikon + label)
// ──────────────────────────────────────────────────────────
class _NavTab extends StatelessWidget {
  final int index;
  final int activeIndex;
  final IconData inactiveIcon;
  final IconData activeIcon;
  final String label;
  final double width;
  final void Function(int) onTap;

  const _NavTab({
    required this.index,
    required this.activeIndex,
    required this.inactiveIcon,
    required this.activeIcon,
    required this.label,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == activeIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Ikon dengan background pill ───────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 40,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: active
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
                // Border tipis saat aktif
                border: active
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 1.0,
                      )
                    : null,
              ),
              child: Icon(
                active ? activeIcon : inactiveIcon,
                size: active ? 22 : 20,
                color: active
                    ? AppColors.primaryLight
                    : AppColors.textPrimary.withValues(alpha: 0.30),
              ),
            ),
            const SizedBox(height: 3),
            // ── Label ──────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.nunito(
                color: active
                    ? AppColors.primaryLight
                    : AppColors.textPrimary.withValues(alpha: 0.28),
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: active ? 0.3 : 0.0,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Tombol Add — Crystal/Gem RPG style
//  TIDAK ada animasi looping, hanya efek tap (scale turun saat ditekan)
// ──────────────────────────────────────────────────────────
class _AddButton extends StatefulWidget {
  final VoidCallback? onPressed;
  const _AddButton({this.onPressed});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.mediumImpact();
        AudioService.playClick();
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            // Cincin tipis putih
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.50),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              // Inner shimmer (tidak bergerak = tidak lag)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
