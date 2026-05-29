import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppAuth {
  static String? _impersonatedUid;
  
  // Digunakan untuk memaksa rebuild seluruh aplikasi ketika akun di-sync
  static final ValueNotifier<int> appKeyNotifier = ValueNotifier(0);

  static void setImpersonatedUid(String? uid) {
    if (_impersonatedUid != uid) {
      _impersonatedUid = uid;
      appKeyNotifier.value++; // Trigger rebuild
    }
  }

  static String? getUid() {
    return _impersonatedUid ?? FirebaseAuth.instance.currentUser?.uid;
  }
}
