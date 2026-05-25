import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_schema.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- FUNGSI MENDAFTARKAN AKUN BARU (REGISTER) ---
  // Catatan Sidang: Kenapa kita simpan data ke dua tempat? (Koleksi 'users' dan koleksi 'usernames')
  // Jawab: Karena bawaan asli Firebase Authentication hanya mendukung Login memakai Email.
  // Agar aplikasi kita bisa login memakai 'Username' layaknya game/sosmed modern,
  // kita harus membuat sistem "Kamus Indexing". Koleksi 'usernames' berfungsi sebagai kamus
  // yang menerjemahkan username menjadi email asli di belakang layar.
  Future<String?> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Cek ketersediaan username (Apakah sudah ada yang pakai di database?)
      final existing = await _db
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();
      if (existing.exists) return 'Username sudah digunakan.';

      // 2. Buat akun mesin utama di Firebase Auth memakai Email
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      // 3. Simpan Profil RPG User secara lengkap ke koleksi 'users'
      final userData = UserSchema.defaultUser(
        uid: uid,
        name: name,
        username: username,
        email: email,
      );
      userData['createdAt'] = FieldValue.serverTimestamp();
      await _db.collection('users').doc(uid).set(userData);

      // 4. Daftarkan username ke "Kamus Indexing" (Koleksi 'usernames')
      // Ini kunci agar nanti waktu Login, sistem bisa mencari email dari username ini
      await _db.collection('usernames').doc(username.toLowerCase()).set({
        'uid': uid,
        'email': email, // Email rahasia yang terhubung dengan username ini
      });

      return null; // Mengembalikan null berarti SUKSES tanpa error
    } on FirebaseAuthException catch (e) {
      // Penanganan Error Bawaan Firebase
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email sudah terdaftar.';
        case 'weak-password':
          return 'Password terlalu lemah (min. 6 karakter).';
        case 'invalid-email':
          return 'Format email tidak valid.';
        default:
          return 'Registrasi gagal: ${e.message}';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // ─── Login via username ─────────────────────────────────────
  Future<String?> loginWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      // Cari email dari username
      final doc = await _db
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();

      if (!doc.exists) return 'Username tidak ditemukan.';

      final email = doc.data()?['email'] as String?;
      if (email == null) return 'Akun bermasalah, hubungi admin.';

      // Login pakai email (internal)
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      return null; // sukses
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Password salah.';
        case 'user-disabled':
          return 'Akun dinonaktifkan.';
        default:
          return 'Login gagal: ${e.message}';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // ─── Forgot password (kirim ke email) ──────────────────────
  Future<String?> sendPasswordReset(String username) async {
    try {
      final doc = await _db
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();

      if (!doc.exists) return 'Username tidak ditemukan.';

      final email = doc.data()?['email'] as String?;
      if (email == null) return 'Akun bermasalah.';

      await _auth.sendPasswordResetEmail(email: email);
      return null; // sukses, email terkirim
    } catch (e) {
      return 'Gagal mengirim email: $e';
    }
  }

  // ─── Logout ────────────────────────────────────────────────
  Future<void> logout() async => await _auth.signOut();

  // ─── Update Profile ────────────────────────────────────────
  Future<String?> updateProfile({required String name}) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return 'Tidak ada user login.';

      await _db.collection('users').doc(uid).update({
        UserSchema.name: name,
      });
      return null;
    } catch (e) {
      return 'Gagal update profil: $e';
    }
  }

  // ─── Change Username ───────────────────────────────────────
  Future<String?> changeUsername(String oldUsername, String newUsername) async {
    try {
      final uid = currentUser?.uid;
      final email = currentUser?.email;
      if (uid == null || email == null) return 'Tidak ada user login.';

      final oldUserLower = oldUsername.toLowerCase();
      final newUserLower = newUsername.toLowerCase();

      if (oldUserLower == newUserLower) return null; // Tidak ada perubahan

      // Cek apakah username baru sudah dipakai
      final existing = await _db.collection('usernames').doc(newUserLower).get();
      if (existing.exists) return 'Username sudah digunakan.';

      // Buat data baru
      await _db.collection('usernames').doc(newUserLower).set({
        'uid': uid,
        'email': email,
      });

      // Update di user document
      await _db.collection('users').doc(uid).update({
        UserSchema.username: newUserLower,
      });

      // Hapus data lama
      await _db.collection('usernames').doc(oldUserLower).delete();

      return null;
    } catch (e) {
      return 'Gagal mengganti username: $e';
    }
  }

  // ─── Change Password ───────────────────────────────────────
  Future<String?> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) return 'Tidak ada user login.';

      // Re-authenticate
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Password lama salah.';
      } else if (e.code == 'weak-password') {
        return 'Password baru terlalu lemah.';
      }
      return 'Gagal mengganti password: ${e.message}';
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // ─── Current user ──────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
}
