import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService extends ChangeNotifier {
  // Singleton pattern matching existing services (e.g., CacheService)
  NotificationService._privateConstructor();
  static final NotificationService _instance = NotificationService._privateConstructor();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;

  bool _isInitialized = false;
  String? _fcmToken;
  int _unreadCount = 0;

  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;
  int get unreadCount => _unreadCount;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      if (!kIsWeb) {
        // Initialize local notifications
        const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
        const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
        await _localNotificationsPlugin.initialize(initializationSettings);

        // Get FCM Token
        _fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('🔔 [NOTIF] Notification service initialized with FCM token: $_fcmToken');

        // Listen for foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (message.notification != null) {
            sendLocalNotification(
              title: message.notification!.title ?? 'Notification',
              body: message.notification!.body ?? '',
            );
          }
        });
      } else {
        debugPrint('🔔 [NOTIF] Web platform detected, skipping Firebase Notifications initialization');
      }
    } catch (e) {
      debugPrint('🔔 [NOTIF] Error initializing notification service: $e');
    }
    
    _isInitialized = true;
  }

  Future<void> requestPermission() async {
    try {
      if (!kIsWeb) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        debugPrint('🔔 [NOTIF] Notification permissions requested, status: ${settings.authorizationStatus}');
      }
    } catch (e) {
      debugPrint('🔔 [NOTIF] Error requesting permission: $e');
    }
  }

  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('🔔 [NOTIF] Local: $title — $body');
    _unreadCount++;
    notifyListeners();

    try {
      if (!kIsWeb) {
        const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'pharmaguide_notifications',
          'PharmaGuide Notifications',
          importance: Importance.high,
          priority: Priority.high,
        );
        const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
        
        await _localNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title,
          body,
          platformChannelSpecifics,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('🔔 [NOTIF] Error sending local notification: $e');
    }
  }

  void notifyReservationConfirmed(String pharmacyName, String drugName) {
    sendLocalNotification(
      title: '✅ Réservation Confirmée',
      body: '$drugName est prêt au guichet chez $pharmacyName',
    );
  }

  void notifyReservationDeclined(String pharmacyName) {
    sendLocalNotification(
      title: '❌ Réservation Refusée',
      body: '$pharmacyName n\'a pas pu honorer votre réservation',
    );
  }

  void notifyReservationExpiring(String drugName, int minutesLeft) {
    sendLocalNotification(
      title: '⏰ Réservation Expire Bientôt',
      body: '$drugName — plus que $minutesLeft minutes pour récupérer',
    );
  }

  void notifyChronicReminderDue(String medicationName, int daysUntilRenewal) {
    sendLocalNotification(
      title: '💊 Renouvellement Ordonnance',
      body: '$medicationName — renouvellement dans $daysUntilRenewal jours',
    );
  }

  void notifyEmergencyBroadcastReply(String pharmacyName, String drugName) {
    sendLocalNotification(
      title: '🔔 Alerte Médicament Trouvé',
      body: '$pharmacyName dispose de $drugName',
    );
  }

  void clearUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  void disposeService() {
    // Cleanup if needed
  }
}
