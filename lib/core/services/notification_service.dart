// lib/core/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Fungsi handler untuk background harus di luar class (top-level)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // 1. Inisialisasi Layanan
  Future<void> initNotifications() async {
    // Meminta izin notifikasi (Penting untuk iOS & Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
      return; // Jangan lanjut jika tidak diizinkan
    }

    // Dapatkan Token FCM (Alamat unik HP ini)
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken'); 
    // (Nanti kita akan simpan token ini ke Firestore via DatabaseService)

    // Set up handler untuk background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handler untuk pesan saat aplikasi dibuka (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Di sini kita bisa menampilkan dialog atau snackbar lokal
      }
    });
  }

  // Helper untuk mendapatkan token (akan dipanggil saat login)
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}