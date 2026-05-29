import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_schema.dart';

// --- KELAS VIEWMODEL: Layar Misi Harian (Daily Screen) ---
// Bertugas mengatur penyaringan (Filter), pencarian, dan logika hukuman harian
// untuk daftar misi yang ditampilkan di layar DailyScreen.
class DailyViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _filterCat = 'Semua';
  String _filterStatus = 'Semua';
  String _filterFreq = 'Semua';
  String _searchQuery = '';

  String get filterCat => _filterCat;
  String get filterStatus => _filterStatus;
  String get filterFreq => _filterFreq;
  String get searchQuery => _searchQuery;

  void setFilterCat(String val) {
    _filterCat = val;
    notifyListeners();
  }

  void setFilterStatus(String val) {
    _filterStatus = val;
    notifyListeners();
  }

  void setFilterFreq(String val) {
    _filterFreq = val;
    notifyListeners();
  }

  void setSearchQuery(String val) {
    _searchQuery = val;
    notifyListeners();
  }

  // --- FUNGSI: Menyaring Daftar Tugas ---
  // Menerima seluruh tugas dari TaskViewModel, lalu memfilter (menyaring)
  // berdasarkan Kategori, Status (Belum/Selesai), Teks Pencarian, dan Frekuensi (Harian/Mingguan).
  List<Map<String, dynamic>> getFilteredTasks(List<Map<String, dynamic>> allTasks) {
    var docs = allTasks;

    if (_filterCat != 'Semua') {
      docs = docs.where((d) => d['category'] == _filterCat).toList();
    }
    
    if (_filterStatus == 'Belum') {
      docs = docs.where((d) => d['done'] != true).toList();
    } else if (_filterStatus == 'Selesai') {
      docs = docs.where((d) => d['done'] == true).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      docs = docs.where((d) {
        final t = (d['title'] ?? '').toString().toLowerCase();
        return t.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    if (_filterFreq != 'Semua') {
      docs = docs.where((d) {
        final freq = d[TaskSchema.frequency] ?? TaskSchema.freqDaily;
        return freq == _filterFreq;
      }).toList();
    }

    return docs;
  }

  // --- FUNGSI: Mengecek Misi Yang Mengutuk (Cursed Tasks) ---
  // Dipanggil setiap kali user masuk ke layar Daily.
  // Jika ada misi harian kemarin yang belum diselesaikan, maka misi tersebut menjadi 'Cursed' (Terkutuk).
  // Misi yang terkutuk durasi timernya ditambah 25% (Hukuman).
  Future<void> checkCursedTasks() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where(TaskSchema.done, isEqualTo: false)
        .where(TaskSchema.isCursed, isEqualTo: false)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final createdAt = data[TaskSchema.createdAt];
      if (createdAt == null) continue;

      final createdDate = (createdAt as Timestamp).toDate();
      
      if (createdDate.isBefore(todayStart)) {
        final currentDuration = (data[TaskSchema.duration] ?? 0) as int;
        final newDuration = currentDuration == 0 ? 0 : (currentDuration * 1.25).ceil();

        await doc.reference.update({
          TaskSchema.isCursed: true,
          TaskSchema.cursedMultiplier: 1.25,
          TaskSchema.duration: newDuration,
        });
      }
    }
  }
}
