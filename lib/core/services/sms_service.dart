import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  /// 1. 🟢 100% FREE WhatsApp Message Launcher (No API Key Required!)
  Future<void> launchFreeWhatsAppMessage(String phoneNumber, String message) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri waUri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
        debugPrint('🟢 [FREE WHATSAPP] Opened WhatsApp for $phoneNumber');
      } else {
        debugPrint('🟢 [FREE WHATSAPP] Could not launch WhatsApp');
      }
    } catch (e) {
      debugPrint('🟢 [FREE WHATSAPP] Error launching WhatsApp: $e');
    }
  }

  /// 2. 📱 100% FREE Native Device SMS Launcher (Uses device's own mobile plan - 0 Millimes Extra!)
  Future<void> launchFreeNativeSms(String phoneNumber, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        debugPrint('📱 [FREE NATIVE SMS] Launched native SMS app for $phoneNumber');
      } else {
        debugPrint('📱 [FREE NATIVE SMS] Could not launch native SMS app');
      }
    } catch (e) {
      debugPrint('📱 [FREE NATIVE SMS] Error: $e');
    }
  }

  /// Send SMS OTP verification code
  Future<bool> sendOtpSms(String phoneNumber, String otpCode) async {
    final message = 'PharmaGuide TN: Votre code de vérification est: $otpCode. Valable 10 minutes.';
    return _dispatchSms(phoneNumber, message);
  }

  /// Send SMS notification when pharmacy accepts a 2h hold reservation
  Future<bool> sendReservationConfirmedSms({
    required String phoneNumber,
    required String pharmacyName,
    required String drugName,
    required String counterCode,
  }) async {
    final message = 'PharmaGuide TN: Votre réservation pour $drugName chez $pharmacyName est CONFIRMÉE (Valable 2h). Code Guichet: $counterCode.';
    
    // Auto-launch free WhatsApp or native SMS if available
    await launchFreeWhatsAppMessage(phoneNumber, message);
    return _dispatchSms(phoneNumber, message);
  }

  /// Send SMS notification when an out-of-stock medication becomes available
  Future<bool> sendAvailabilityAlertSms({
    required String phoneNumber,
    required String drugName,
    required String pharmacyName,
  }) async {
    final message = 'PharmaGuide TN: Le médicament $drugName est désormais DISPONIBLE à la $pharmacyName. Réservez-le maintenant !';
    return _dispatchSms(phoneNumber, message);
  }

  /// Send SMS notification when a pharmacy responds to an emergency broadcast request
  Future<bool> sendEmergencyBroadcastSms({
    required String phoneNumber,
    required String drugName,
    required String pharmacyName,
    required String phoneLandline,
  }) async {
    final message = 'PharmaGuide TN URGENCE: La $pharmacyName (Tél: $phoneLandline) confirme avoir en stock votre produit "$drugName". Contactez-les rapidement !';
    await launchFreeWhatsAppMessage(phoneNumber, message);
    return _dispatchSms(phoneNumber, message);
  }

  /// Internal simulation logger
  Future<bool> _dispatchSms(String phoneNumber, String message) async {
    debugPrint('📲 [SMS GATEWAY LOG] $phoneNumber: "$message"');
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
