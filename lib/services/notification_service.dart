import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initialize() async {
    // Request permission for notifications
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
    
    // Get FCM token and save to user document
    await _saveFCMToken();
    
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }
  
  static Future<void> _saveFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await _messaging.getToken();
        if (token != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
            'lastTokenUpdate': DateTime.now(),
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (message.notification != null) {
      await showMessageNotification(
        message.notification!.title ?? 'New Message',
        message.notification!.body ?? 'You have a new message',
      );
    }
  }

  static Future<void> showMessageNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }
  
  static Future<void> showConnectionNotification(String userName) async {
    await showMessageNotification(
      'New Connection',
      '$userName wants to connect with you!',
    );
  }
  
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}