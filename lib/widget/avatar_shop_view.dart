import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/avatar_data.dart';
import '../widget/avatar_preview.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';


// ── Tampilan Toko Avatar (Avatar Shop View) ───────────────────────
// Bagian dari Profile Screen yang menampilkan karakter dan daftar pakaian (inventory).
// Mengatur logika kategori tab (Head, Body, Pants, dll) dan merender item.
class AvatarShopView extends StatefulWidget {
  final Map<String, String> equippedItems;
  final List<String> unlockedItems;
  final Function(String category, String itemId) onEquip;
  final Color accentColor;
  final Color cardDark;
  final Color cardBorder;
  final String? baseBody;

  const AvatarShopView({
    super.key,
    required this.equippedItems,
    required this.unlockedItems,
    required this.onEquip,
    required this.accentColor,
    required this.cardDark,
    required this.cardBorder,
    this.baseBody,
  });

  @override
  State<AvatarShopView> createState() => _AvatarShopViewState();
}

class _AvatarShopViewState extends State<AvatarShopView> {
  String _selectedAvatarCategory = 'Body';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCharacterPreview(),
        const SizedBox(height: 16),
        _buildAvatarCategoryTabs(),
        Expanded(child: _buildAvatarInventory()),
      ],
    );
  }

  Widget _buildCharacterPreview() {
    return AvatarPreview(
      equippedItems: widget.equippedItems,
      size: 180,
      baseBody: widget.baseBody,
    );
  }

  Widget _buildAvatarCategoryTabs() {
    final l = context.l;
    final categories = ['Head', 'Body', 'Pants', 'Body 1 Set', 'Pet', 'Wallpaper'];
    
    final categoryIcons = {
      'Head': Icons.face_retouching_natural_rounded,
      'Body': Icons.checkroom_rounded,
      'Pants': Icons.accessibility_new_rounded,
      'Body 1 Set': Icons.star_rounded,
      'Pet': Icons.pets_rounded,
      'Wallpaper': Icons.image_rounded,
    };

    final labels = categories.map((cat) {
      if (cat == 'Body 1 Set') return l.isEn ? '1 Set' : '1 Set';
      if (cat == 'Wallpaper') return l.isEn ? 'Wall' : 'Latar';
      return l.shopCategoryLabel(cat);
    }).toList();

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedAvatarCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedAvatarCategory = cat),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? widget.accentColor.withValues(alpha: 0.2) : widget.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? widget.accentColor : widget.cardBorder),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    categoryIcons[cat] ?? Icons.category_rounded,
                    size: 14,
                    color: isSelected ? widget.accentColor : AppColors.textPrimary.withValues(alpha: 0.40),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    labels[index],
                    style: GoogleFonts.nunito(
                      color: isSelected ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.60),
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarInventory() {
    final items = AvatarData.allItems.where((e) => e.category == _selectedAvatarCategory).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.76,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final l = context.l;
        final item = items[index];
        final isUnlocked = widget.unlockedItems.contains(item.id);
        
        String dbKey = 'clothes';
        if (item.category == 'Head') {
          dbKey = 'head';
        } else if (item.category == 'Pants') {
          dbKey = 'pants';
        } else if (item.category == 'Pet') {
          dbKey = 'pet';
        } else if (item.category == 'Wallpaper') {
          dbKey = 'background';
        }

        final isEquipped = widget.equippedItems[dbKey] == item.id;

        // Tier Aesthetics
        Color tierColor = const Color(0xFF94A3B8);
        List<BoxShadow> shadows = [];
        double borderWidth = 1.0;

        if (item.tier == AvatarTier.veteran) {
          tierColor = const Color(0xFF3B82F6);
        } else if (item.tier == AvatarTier.elite) {
          tierColor = const Color(0xFF8B5CF6);
          shadows = [BoxShadow(color: tierColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)];
          borderWidth = 1.5;
        } else if (item.tier == AvatarTier.mythic) {
          tierColor = const Color(0xFFF59E0B);
          shadows = [
            BoxShadow(color: tierColor.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2),
            BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.2), blurRadius: 4, spreadRadius: 0),
          ];
          borderWidth = 2.0;
        }

        double scale = 1.0;
        if (item.category == 'Body') scale = 1.8;
        if (item.category == 'Body 1 Set') scale = 1.6;
        if (item.category == 'Pants') scale = 1.2;
        if (item.category == 'Pet') scale = 1.4;
        if (item.category == 'Head') scale = 1.3;

        return GestureDetector(
          onTap: () => widget.onEquip(item.category, item.id),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isEquipped ? tierColor.withValues(alpha: 0.1) : widget.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEquipped ? tierColor : (isUnlocked ? tierColor.withValues(alpha: 0.4) : AppColors.textPrimary.withValues(alpha: 0.10)),
                width: isEquipped ? borderWidth + 1 : borderWidth,
              ),
              boxShadow: isEquipped ? shadows : [],
            ),
            child: Stack(
              children: [
                if (item.category == 'Wallpaper' && item.imagePath != null)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(item.imagePath!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                if (item.tier == AvatarTier.mythic)
                  Positioned(top: 8, right: 8, child: Icon(Icons.auto_awesome, color: Colors.amber, size: 14)),
                
                Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Transform.scale(
                          scale: scale,
                          child: item.imagePath != null && !item.id.startsWith('none')
                              ? Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Image.asset(item.imagePath!, fit: BoxFit.contain, color: isUnlocked ? null : AppColors.textPrimary.withValues(alpha: 0.54), colorBlendMode: isUnlocked ? null : BlendMode.srcIn),
                                )
                              : Icon(item.icon, size: 40, color: isUnlocked ? item.color : AppColors.textPrimary.withValues(alpha: 0.24)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45), 
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19))
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l.itemName(item.id, item.name), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: isUnlocked ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.60))),
                            if ((item.passiveStats['goldBoost'] ?? 0.0) > 0 || (item.passiveStats['xpBoost'] ?? 0.0) > 0 || (item.passiveStats['maxHp'] ?? 0.0) > 0) ...[
                              SizedBox(height: 2),
                              Text(
                                l.passiveDesc(
                                  item.passiveStats['goldBoost'] ?? 0.0,
                                  item.passiveStats['xpBoost'] ?? 0.0,
                                  item.passiveStats['maxHp'] ?? 0.0,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            SizedBox(height: 2),
                            if (!isUnlocked)
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.gold), SizedBox(width: 4), Text('${item.price}', style: GoogleFonts.outfit(fontSize: 12, color: tierColor, fontWeight: FontWeight.bold))])
                            else
                              Text(isEquipped ? l.shopEquipped.toUpperCase() : (l.isEn ? 'OWNED' : 'DIMILIKI'), style: GoogleFonts.outfit(fontSize: 10, color: isEquipped ? tierColor : Colors.greenAccent, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isUnlocked)
                  Positioned.fill(child: Container(decoration: BoxDecoration(color: AppColors.textPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(19)), child: Center(child: Icon(Icons.lock_outline, color: AppColors.textDisabled, size: 30)))),
              ],
            ),
          ),
        );
      },
    );
  }
}
