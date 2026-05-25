import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Static init method for main.dart
  static Future<void> init() async {
    await NotificationService().initialize();
  }

  // --- FUNGSI INISIALISASI (PERSIAPAN MESIN NOTIFIKASI) ---
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Pengaturan khusus Android: Kita memberitahu sistem Android logo/icon mana yang
    // dipakai saat notifikasi muncul di bar atas HP (@mipmap/ic_launcher).
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. Pengaturan khusus iOS (Apple): Meminta izin secara pop-up
    // untuk menampilkan Alert (Teks), Badge (Angka merah di icon aplikasi), dan Sound (Suara)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Gabungkan pengaturan kedua mesin (Android + Apple)
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Nyalakan mesin notifikasinya
    try {
      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      _initialized = false;
    }
  }

  // --- FUNGSI MEMINTA IZIN NOTIFIKASI (UNTUK ANDROID 13 KE ATAS) ---
  // Catatan Sidang: Mulai Android 13, Google mewajibkan aplikasi minta izin manual
  // ke user sebelum bisa mengirim notifikasi (seperti iOS).
  Future<bool> requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? true;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  // --- FUNGSI MEMUNCULKAN NOTIFIKASI KE LAYAR HP (POP-UP) ---
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    try {
      // Pembuatan "Channel" Khusus Android
      // Catatan Sidang: Android versi 8 (Oreo) ke atas mewajibkan notifikasi dikelompokkan
      // dalam sebuah "Channel" agar user bisa mengatur suaranya (dimatikan/dibunyikan khusus channel ini).
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'daily_dev_channel', // ID unik channel di sistem Android
        'GrindOn', // Nama channel yang terlihat di Pengaturan HP
        channelDescription: 'Notifications for GrindOn RPG Task',
        importance: Importance.high, // Set High agar muncul pop-up menjuntai dari atas layar
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF7C3AED), // Warna ungu aksen notifikasi
        enableVibration: true, // Izinkan getar
        playSound: true, // Izinkan bunyi
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Tembakkan notifikasinya!
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // ═══════════════════════════════════════════════════════════
  //  DEMO NOTIFICATIONS (for God Mode)
  // ═══════════════════════════════════════════════════════════

  /// Quest Reminder
  Future<void> showQuestReminder() async {
    await showNotification(
      id: 1,
      title: '🎯 Quest Reminder',
      body: 'You have 3 pending quests! Complete them to earn rewards.',
      payload: 'quest_reminder',
    );
  }

  /// Deadline Alert
  Future<void> showDeadlineAlert() async {
    await showNotification(
      id: 2,
      title: '⚠️ Deadline Alert',
      body: 'Task "Morning Workout" deadline in 1 hour!',
      payload: 'deadline_alert',
    );
  }

  /// Streak Alert
  Future<void> showStreakAlert() async {
    await showNotification(
      id: 3,
      title: '🔥 Streak Alert',
      body: 'Don\'t break your 7-day streak! Complete at least 1 task today.',
      payload: 'streak_alert',
    );
  }

  /// Level Up
  Future<void> showLevelUp() async {
    await showNotification(
      id: 4,
      title: '⭐ Level Up!',
      body: 'Congratulations! You reached Level 10!',
      payload: 'level_up',
    );
  }

  /// Gold Earned
  Future<void> showGoldEarned() async {
    await showNotification(
      id: 5,
      title: '💰 Gold Earned',
      body: 'You earned 50 Gold from completing "Study Flutter"!',
      payload: 'gold_earned',
    );
  }

  /// Achievement Unlocked
  Future<void> showAchievementUnlocked() async {
    await showNotification(
      id: 6,
      title: '🏆 Achievement Unlocked',
      body: 'New badge: "Warrior" - Complete 10 STR tasks!',
      payload: 'achievement_unlocked',
    );
  }

  /// Show all demo notifications (with delay)
  Future<void> showAllDemoNotifications() async {
    await showQuestReminder();
    await Future.delayed(const Duration(seconds: 2));
    
    await showDeadlineAlert();
    await Future.delayed(const Duration(seconds: 2));
    
    await showStreakAlert();
    await Future.delayed(const Duration(seconds: 2));
    
    await showLevelUp();
    await Future.delayed(const Duration(seconds: 2));
    
    await showGoldEarned();
    await Future.delayed(const Duration(seconds: 2));
    
    await showAchievementUnlocked();
  }
}
