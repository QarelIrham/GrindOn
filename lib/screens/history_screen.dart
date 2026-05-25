import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

import '../models/app_schema.dart';
import '../l10n/app_locale.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../widget/theme_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Color get bgDark => AppColors.background;
  Color get cardDark => AppColors.cardBackground;

  // ── Layar Utama History ───────────────────────────────────────────
  // Menampilkan daftar misi yang sudah Selesai (done: true).
  @override
  Widget build(BuildContext context) {
    final l = context.lw;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: Text(
          l.historyReviewTitle,
          style: GoogleFonts.nunito(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: uid == null
          ? Center(
              child: Text(
                l.msgNotLoggedIn,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('tasks')
                  .where(TaskSchema.done, isEqualTo: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  );
                }

                final rawDocs = snap.data?.docs ?? [];
                // Sort secara lokal untuk bypass error missing index di Firestore
                final docs = List<QueryDocumentSnapshot>.from(rawDocs);
                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final tA = dataA[TaskSchema.completedAt] as Timestamp?;
                  final tB = dataB[TaskSchema.completedAt] as Timestamp?;
                  if (tA == null && tB == null) return 0;
                  if (tA == null) return 1;
                  if (tB == null) return -1;
                  return tB.compareTo(tA);
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: AppColors.textDisabled,
                        ),
                        SizedBox(height: 16),
                        Text(
                          l.historyEmptyTasks,
                          style: GoogleFonts.nunito(
                            color: AppColors.textPrimary.withValues(alpha: 0.54),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildHistoryCardWrapper(data, l);
                  },
                );
              },
            ),
    );
  }

  // ── Pembungkus Kartu History ──────────────────────────────────────
  // Berguna untuk mengontrol state "isExpanded" (kartu sedang mekar atau kuncup)
  Widget _buildHistoryCardWrapper(Map<String, dynamic> data, L l) {
    bool isExpanded = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: _buildHistoryCard(data, isExpanded, l),
        );
      },
    );
  }

  // ── Desain Kartu History ──────────────────────────────────────────
  // Menampilkan judul, waktu selesai, XP & Gold yang didapat, serta bukti (foto/teks)
  Widget _buildHistoryCard(Map<String, dynamic> data, bool isExpanded, L l) {
    final title = data['title'] ?? 'Task';
    final notes = data['notes'] as String?;
    final cat = data['category'] ?? 'Strength';
    final diff = data['difficulty'] as int? ?? 1;
    final xp = data[TaskSchema.xp] ?? 0;
    final gold = data[TaskSchema.goldReward] ?? 0;
    final proofUrl = data[TaskSchema.proofUrl] as String?;
    final proofText = data[TaskSchema.proofText] as String?;
    final ts = data[TaskSchema.completedAt] as Timestamp?;
    final timeStr = ts != null ? _fmtDate(ts.toDate(), l) : l.historyDone;

    final diffIndex = (diff - 1).clamp(0, 3);
    final diffStr = l.diffLabel(diffIndex);
    Color diffColor = const Color(0xFF10B981);
    if (diff == 2) diffColor = const Color(0xFF3B82F6);
    else if (diff == 3) diffColor = const Color(0xFFF59E0B);
    else if (diff == 4) diffColor = const Color(0xFFEF4444);

    return ThemeCard(
      backgroundColor: cardDark,
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.textPrimary.withValues(alpha: 0.10),
      borderWidth: 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (notes != null && notes.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          notes,
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: AppColors.textPrimary.withValues(alpha: 0.54),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: diffColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: diffColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              diffStr,
                              style: GoogleFonts.nunito(
                                color: diffColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '$timeStr • ${l.catName(cat)}',
                            style: GoogleFonts.nunito(
                              color: AppColors.textPrimary.withValues(alpha: 0.54),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+$xp XP',
                      style: GoogleFonts.nunito(
                        color: Color(0xFFF59E0B),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '+$gold Gold',
                      style: GoogleFonts.nunito(
                        color: Color(0xFFFFD700),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Image Proof
          if (isExpanded && proofUrl != null && proofUrl.isNotEmpty) ...[
            Divider(color: AppColors.textPrimary.withValues(alpha: 0.10), height: 1),
            _buildProofImage(proofUrl, l),
          ],

          // Text Proof
          if (isExpanded && proofText != null && proofText.isNotEmpty) ...[
            Divider(color: AppColors.textPrimary.withValues(alpha: 0.10), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.historyNotesLabel,
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary.withValues(alpha: 0.38),
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    proofText,
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Menampilkan gambar bukti penyelesaian misi (jika ada)
  Widget _buildProofImage(String url, L l) {
    if (url == 'local_path_fallback') {
      return Container(
        width: double.infinity,
        height: 150,
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_rounded,
              color: AppColors.textDisabled,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              l.historyPhotoUnavailable,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38), fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        final bytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
          child: Image.memory(
            bytes,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _errorImage(),
          ),
        );
      } catch (e) {
        return _errorImage();
      }
    }

    if (url.startsWith('http')) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        child: Image.network(
          url,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _errorImage(),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _errorImage() => Container(
    width: double.infinity,
    height: 150,
    color: AppColors.textPrimary.withValues(alpha: 0.05),
    alignment: Alignment.center,
    child: Icon(
      Icons.broken_image_rounded,
      color: AppColors.textDisabled,
      size: 40,
    ),
  );

  String _fmtDate(DateTime dt, L l) {
    final m = l.monthShort;
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
