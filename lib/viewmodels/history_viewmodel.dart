import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_schema.dart';

// --- KELAS VIEWMODEL: Layar Riwayat (History Screen) ---
// Bertugas mengurus tampilan daftar misi yang SUDAH SELESAI.
class HistoryViewModel extends ChangeNotifier {
  // --- FUNGSI: Mengurutkan Riwayat ---
  // Mengambil daftar semua task, membuang task yang belum selesai,
  // lalu mengurutkannya dari yang paling baru selesai (descending).
  List<Map<String, dynamic>> getSortedHistoryTasks(List<Map<String, dynamic>> allTasks) {
    final docs = allTasks.where((d) {
      return d[TaskSchema.done] == true;
    }).toList();

    docs.sort((a, b) {
      final tA = a[TaskSchema.completedAt] as Timestamp?;
      final tB = b[TaskSchema.completedAt] as Timestamp?;
      if (tA == null && tB == null) return 0;
      if (tA == null) return 1;
      if (tB == null) return -1;
      return tB.compareTo(tA);
    });

    return docs;
  }
}
