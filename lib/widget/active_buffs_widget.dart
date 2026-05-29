import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/avatar_data.dart';
import '../theme/app_theme.dart';

class ActiveBuffsWidget extends StatefulWidget {
  final Map<String, dynamic> equippedItems;
  final dynamic xpBonusUntil;
  const ActiveBuffsWidget({super.key, required this.equippedItems, this.xpBonusUntil});

  @override
  State<ActiveBuffsWidget> createState() => _ActiveBuffsWidgetState();
}

class _ActiveBuffsWidgetState extends State<ActiveBuffsWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Rebuild every minute to update the potion countdown
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equippedItems = widget.equippedItems;
    final xpBonusUntil = widget.xpBonusUntil;
    final hasXpPotion = xpBonusUntil != null && xpBonusUntil!.toDate().isAfter(DateTime.now());
    
    // We determine what kind of buffs are active based on the equipped items
    // Pet usually gives goldBoost
    final hasPetBuff = equippedItems.values.any((id) {
      if (id.isEmpty || id.startsWith('none_')) return false;
      final item = AvatarData.allItems.firstWhere((e) => e.id == id, orElse: () => const AvatarItem(id: '', name: '', icon: Icons.error, color: Colors.transparent, category: ''));
      return item.category == 'Pet';
    });

    // Clothing (Head, Body, Pants) usually gives xpBoost or maxHp
    final hasClothingBuff = equippedItems.values.any((id) {
      if (id.isEmpty || id.startsWith('none_')) return false;
      final item = AvatarData.allItems.firstWhere((e) => e.id == id, orElse: () => const AvatarItem(id: '', name: '', icon: Icons.error, color: Colors.transparent, category: ''));
      return item.category != 'Pet' && item.category != 'Wallpaper' && item.passiveStats['xpBoost']! > 0 || item.passiveStats['maxHp']! > 0;
    });

    if (!hasXpPotion && !hasClothingBuff && !hasPetBuff) return const SizedBox.shrink();

    String potionTime = '';
    if (hasXpPotion) {
      final diff = xpBonusUntil!.toDate().difference(DateTime.now());
      if (diff.inHours > 0) {
        potionTime = '${diff.inHours}j ${diff.inMinutes.remainder(60)}m';
      } else if (diff.inMinutes > 0) {
        potionTime = '${diff.inMinutes}m';
      } else {
        potionTime = '<1m';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (hasXpPotion)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.science, color: Colors.purpleAccent, size: 12),
                  if (potionTime.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(potionTime.trim(), style: GoogleFonts.nunito(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          if (hasClothingBuff)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.checkroom, color: Colors.orangeAccent, size: 12),
            ),
          if (hasPetBuff)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.pets, color: Colors.greenAccent, size: 12),
            ),
        ],
      ),
    );
  }
}
