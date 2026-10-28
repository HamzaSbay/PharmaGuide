import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../security/rate_limit_service.dart';
import '../utils/result.dart';
import 'cache_service.dart';

enum UserRole { patient, pharmacist, admin }

class UserProfile {
  final String id;
  final String? phone;
  final String? name;
  final UserRole role;
  final String? cnopId;
  final String? pharmacyId;
  final String? sessionToken;
  final bool isVerified;

  UserProfile({
    required this.id,
    this.phone,
    this.name,
    required this.role,
    this.cnopId,
    this.pharmacyId,
    this.sessionToken,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'role': role.name,
      'cnop_id': cnopId,
      'pharmacy_id': pharmacyId,
      'session_token': sessionToken,
      'is_verified': isVerified,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      phone: json['phone'],
      name: json['name'],
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.patient,
      ),
      cnopId: json['cnop_id'],
      pharmacyId: json['pharmacy_id'],
      sessionToken: json['session_token'],
      isVerified: json['is_verified'] ?? false,
    );
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final RateLimitService _rateLimiter = RateLimitService();
  final CacheService _cache = CacheService();

  UserProfile? _currentUser;
  bool _isAuthenticated = false;
  String? _pendingPhone;
  bool _isDevDemoMode = true;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  UserRole? get currentRole => _currentUser?.role;
  bool get isDevDemoMode => _isDevDemoMode;

  set isDevDemoMode(bool value) {
    _isDevDemoMode = value;
    notifyListeners();
  }

  SupabaseClient? get _supabase =>
      SupabaseConstants.isConfigured ? Supabase.instance.client : null;

  /// Cryptographic hash utility for passwords and PINs
  static String hashSecret(String secret, {String salt = 'PG_TN_SECURE_SALT_2026'}) {
    final bytes = utf8.encode('$salt$secret$salt');
    return sha256.convert(bytes).toString();
  }

  /// Verify secret against its cryptographic hash
  static bool verifyHash(String secret, String expectedHash, {String salt = 'PG_TN_SECURE_SALT_2026'}) {
    return hashSecret(secret, salt: salt) == expectedHash;
  }

  /// Restores active session from persistent Hive cache on app launch
  Future<void> restoreSession() async {
    try {
      final cachedJson = _cache.getSetting('auth_user_session');
      if (cachedJson != null) {
        final Map<String, dynamic> map = jsonDecode(cachedJson.toString());
        _currentUser = UserProfile.fromJson(map);
        _isAuthenticated = true;
        notifyListeners();
        debugPrint('🔐 [AUTH] Session restored for ${_currentUser?.role.name}: ${_currentUser?.name}');
      }
    } catch (e) {
      debugPrint('⚠️ [AUTH] Session restoration failed: $e');
    }
  }

  Future<void> _persistSession(UserProfile profile) async {
    try {
      await _cache.saveSetting('auth_user_session', jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('⚠️ [AUTH] Session cache error: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      await _cache.saveSetting('auth_user_session', null);
    } catch (e) {
      debugPrint('⚠️ [AUTH] Session clear error: $e');
    }
  }

  /// Authenticate Pharmacist via CNOP ID and password with persistent rate limiting
  Future<Result<UserProfile>> loginPharmacist({
    required String cnopId,
    required String password,
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyStatus,
  }) async {
    final rateKey = 'cnop_${cnopId.toUpperCase().trim()}';

    if (_rateLimiter.isLocked(rateKey)) {
      final remaining = _rateLimiter.remainingLockoutSeconds(rateKey);
      return Failure('Compte temporairement bloqué (trop de tentatives). Réessayez dans ${remaining}s.');
    }

    if (pharmacyStatus != 'APPROVED') {
      return const Failure('Officine en attente de vérification CNOP. Accès non autorisé.');
    }

    // Default hashed password for demo officine accounts
    final expectedHash = hashSecret('officine2026');
    final passwordMatches = verifyHash(password, expectedHash) ||
        (_isDevDemoMode && password == 'officine2026');

    if (!passwordMatches) {
      _rateLimiter.recordFailure(rateKey);
      final remainingAttempts = 5 - _rateLimiter.getAttempts(rateKey);
      if (remainingAttempts <= 0) {
        return const Failure('5 tentatives échouées. Compte verrouillé pour 5 minutes.');
      }
      return Failure('Mot de passe incorrect. Tentatives restantes: $remainingAttempts');
    }

    _rateLimiter.reset(rateKey);

    final sessionToken = 'tok_ph_${DateTime.now().millisecondsSinceEpoch}_${cnopId.hashCode.abs()}';
    final profile = UserProfile(
      id: 'usr_ph_$pharmacyId',
      name: pharmacyName,
      role: UserRole.pharmacist,
      cnopId: cnopId,
      pharmacyId: pharmacyId,
      sessionToken: sessionToken,
      isVerified: true,
    );

    _currentUser = profile;
    _isAuthenticated = true;
    await _persistSession(profile);
    notifyListeners();

    return Success(profile);
  }

  /// Authenticate Admin via PIN with persistent rate limiting
  Future<Result<UserProfile>> loginAdmin(String pin, {String? email}) async {
    const rateKey = 'admin_portal_pin';

    if (_rateLimiter.isLocked(rateKey)) {
      final remaining = _rateLimiter.remainingLockoutSeconds(rateKey);
      return Failure('Portail Admin bloqué. Réessayez dans ${remaining}s.');
    }

    final expectedHash = hashSecret('admin2026');
    final pinMatches = verifyHash(pin, expectedHash) ||
        (_isDevDemoMode && (pin == 'admin2026' || pin == '123456'));

    if (!pinMatches) {
      _rateLimiter.recordFailure(rateKey);
      final remainingAttempts = 5 - _rateLimiter.getAttempts(rateKey);
      if (remainingAttempts <= 0) {
        return const Failure('Accès bloqué pendant 5 minutes suite à 5 tentatives infructueuses.');
      }
      return Failure('Code secret administrateur incorrect. Tentatives restantes: $remainingAttempts');
    }

    _rateLimiter.reset(rateKey);

    final sessionToken = 'tok_admin_${DateTime.now().millisecondsSinceEpoch}';
    final profile = UserProfile(
      id: 'admin_root',
      name: 'Super Administrateur CNOP',
      phone: '+216 71 000 000',
      role: UserRole.admin,
      sessionToken: sessionToken,
      isVerified: true,
    );

    _currentUser = profile;
    _isAuthenticated = true;
    await _persistSession(profile);
    notifyListeners();

    return Success(profile);
  }

  /// Send SMS OTP code to Tunisian phone number
  Future<Result<void>> loginWithPhone(String phone) async {
    _pendingPhone = phone;

    if (_supabase != null) {
      try {
        await _supabase!.auth.signInWithOtp(phone: phone);
        debugPrint('📲 [AUTH] OTP sent via Supabase SMS Auth to $phone');
        return const Success(null);
      } catch (e) {
        debugPrint('⚠️ [AUTH] Supabase OTP send error: $e');
        if (!_isDevDemoMode) {
          return Failure('Erreur d\'envoi SMS: $e');
        }
      }
    }

    // Dev demo mode fallback
    await Future.delayed(const Duration(milliseconds: 600));
    return const Success(null);
  }

  /// Verify 6-digit OTP code
  Future<Result<UserProfile>> verifyOtp(String otp) async {
    if (_supabase != null && otp != '123456') {
      try {
        final res = await _supabase!.auth.verifyOTP(
          type: OtpType.sms,
          token: otp,
          phone: _pendingPhone,
        );

        if (res.user != null) {
          final profile = UserProfile(
            id: res.user!.id,
            phone: _pendingPhone,
            name: 'Patient Vérifié',
            role: UserRole.patient,
            sessionToken: res.session?.accessToken,
            isVerified: true,
          );
          _currentUser = profile;
          _isAuthenticated = true;
          await _persistSession(profile);
          notifyListeners();
          return Success(profile);
        }
      } catch (e) {
        debugPrint('⚠️ [AUTH] Supabase OTP verify error: $e');
        if (!_isDevDemoMode) {
          return Failure('Code SMS invalide ou expiré: $e');
        }
      }
    }

    // Dev test fallback: accept 123456
    await Future.delayed(const Duration(milliseconds: 500));
    if (_isDevDemoMode && (otp == '123456' || otp.length == 6)) {
      final profile = UserProfile(
        id: 'patient_session_${DateTime.now().millisecondsSinceEpoch}',
        phone: _pendingPhone ?? '+216 98 123 456',
        name: 'Patient PharmaGuide',
        role: UserRole.patient,
        sessionToken: 'tok_pat_${DateTime.now().millisecondsSinceEpoch}',
        isVerified: true,
      );
      _currentUser = profile;
      _isAuthenticated = true;
      await _persistSession(profile);
      notifyListeners();
      return Success(profile);
    }

    return const Failure('Code de vérification incorrect. Veuillez réessayer.');
  }

  /// Register new pharmacist with CNOP & patente details
  Future<void> registerPharmacist(
      String name, String cnopId, String phone, String patentProof) async {
    if (_supabase != null) {
      try {
        await _supabase!.from('pharmacies').insert({
          'cnop_id': cnopId,
          'name': name,
          'phone_landline': phone,
          'status': 'PENDING',
          'governorate': 'Tunis',
          'municipality': 'El Menzah',
          'address': 'Adresse Pro',
          'location': 'POINT(10.1815 36.8368)',
        });
      } catch (e) {
        debugPrint('⚠️ [AUTH] Supabase pharmacist register error: $e');
      }
    }

    await Future.delayed(const Duration(seconds: 1));
  }

  void logout() {
    if (_supabase != null) {
      try {
        _supabase!.auth.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    _isAuthenticated = false;
    _pendingPhone = null;
    _clearSession();
    notifyListeners();
  }
}
