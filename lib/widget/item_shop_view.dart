import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/avatar_preview.dart';
import '../theme/app_theme.dart';


// ── Tampilan Toko Item (Item Shop View) ─────────────────────────
// Bagian dari Profile Screen yang menampilkan item-item yang bisa dibeli dengan Gold.
// Contoh item: Red Potion (tambah HP) atau XP Scroll (tambah XP).
class ItemShopView extends StatelessWidget {
  final Map<String, String> equippedItems;
  final Map<String, int> inventory;
  final Function(String id, int price) onBuy;
  final Function(String id) onUse;
  final Color cardDark;
  final Color cardBorder;
  final Color accentColor;

  const ItemShopView({
    super.key,
    required this.equippedItems,
    required this.inventory,
    required this.onBuy,
    required this.onUse,
    required this.cardDark,
    required this.cardBorder,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AvatarPreview(equippedItems: equippedItems, size: 180),
        SizedBox(height: 16),
        Text('ITEM SHOP & INVENTORY', style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            children: [
              _buildItemRow(id: 'red_potion', name: 'Red Potion', desc: 'Instantly restore 30 HP.', price: 50, icon: Icons.local_hospital_rounded, color: Colors.redAccent),
              const SizedBox(height: 12),
              _buildItemRow(id: 'blue_potion', name: 'Blue Potion', desc: 'Instantly restore 60 HP.', price: 100, icon: Icons.water_drop, color: Colors.blue),
              const SizedBox(height: 12),
              _buildItemRow(id: 'green_potion', name: 'Green Potion', desc: 'Instantly restore 100 HP.', price: 150, icon: Icons.health_and_safety, color: Colors.green),
              const SizedBox(height: 12),
              _buildItemRow(id: 'xp_scroll', name: 'XP Scroll', desc: 'Double XP for 1 hour.', price: 100, icon: Icons.history_edu_rounded, color: Colors.amber),
              const SizedBox(height: 12),
              _buildItemRow(id: 'gold_scroll', name: 'Gold Scroll', desc: 'Double Gold for 1 hour.', price: 100, icon: Icons.request_quote_rounded, color: Colors.yellow),
              const SizedBox(height: 12),
              _buildItemRow(id: 'strength_potion', name: 'Strength Potion', desc: 'Add 50 Strength XP.', price: 120, icon: Icons.fitness_center, color: Colors.deepOrange),
              const SizedBox(height: 12),
              _buildItemRow(id: 'agility_potion', name: 'Agility Potion', desc: 'Add 50 Agility XP.', price: 120, icon: Icons.directions_run, color: Colors.teal),
              const SizedBox(height: 12),
              _buildItemRow(id: 'intelligence_potion', name: 'Intelligence Potion', desc: 'Add 50 Intelligence XP.', price: 120, icon: Icons.lightbulb, color: Colors.purple),
              const SizedBox(height: 12),
              _buildItemRow(id: 'vitality_potion', name: 'Vitality Potion', desc: 'Add 50 Vitality XP.', price: 120, icon: Icons.favorite, color: Colors.pink),
              const SizedBox(height: 12),
              _buildItemRow(id: 'defense_potion', name: 'Defense Potion', desc: 'Add 50 Defense XP.', price: 120, icon: Icons.shield, color: Colors.blueGrey),
              const SizedBox(height: 12),
              _buildItemRow(id: 'mystery_box', name: 'Mystery Box', desc: 'Open for a mysterious random reward!', price: 200, icon: Icons.card_giftcard_rounded, color: Colors.deepPurpleAccent),
              const SizedBox(height: 12),
              _buildItemRow(id: 'revive_token', name: 'Revive Token', desc: 'Cure Burnout & fully restore HP.', price: 500, icon: Icons.healing_rounded, color: Colors.cyan),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow({required String id, required String name, required String desc, required int price, required IconData icon, required Color color}) {
    final int count = inventory[id] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 28)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text(name, style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)), SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.textPrimary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(6)), child: Text('x$count', style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)))]),
                Text(desc, style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 11)),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold.withValues(alpha: 0.1), foregroundColor: AppColors.gold, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size(60, 30), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () => onBuy(id, price),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.monetization_on_rounded, size: 14), SizedBox(width: 4), Text('$price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]),
              ),
              SizedBox(height: 6),
              if (count > 0)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: AppColors.textPrimary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: const Size(60, 30), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => onUse(id),
                  child: const Text('USE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
