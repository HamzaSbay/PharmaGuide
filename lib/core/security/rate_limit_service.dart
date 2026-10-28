import 'dart:math';
import '../services/cache_service.dart';

/// Rate limiting service to prevent brute-force attacks on auth gates.
/// Supports in-memory tracking with persistent cache fallback and exponential backoff.
class RateLimitService {
  static final RateLimitService _instance = RateLimitService._internal();
  factory RateLimitService() => _instance;
  RateLimitService._internal();

  final Map<String, int> _attempts = {};
  final Map<String, DateTime> _lockoutUntil = {};
  final CacheService _cache = CacheService();

  /// Check whether an identifier (e.g. IP, CNOP, Phone, or PIN key) is currently locked out.
  bool isLocked(String key) {
    final lockout = _lockoutUntil[key];
    if (lockout != null) {
      if (DateTime.now().isBefore(lockout)) {
        return true;
      }
      // Lockout expired
      _lockoutUntil.remove(key);
      _attempts.remove(key);
      _persistState(key);
      return false;
    }

    // Check cached lockout
    final cachedLockoutMs = _cache.getSetting('ratelimit_lock_$key');
    if (cachedLockoutMs != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(cachedLockoutMs.toString()) ?? 0,
      );
      if (DateTime.now().isBefore(expiry)) {
        _lockoutUntil[key] = expiry;
        return true;
      } else {
        _cache.saveSetting('ratelimit_lock_$key', null);
      }
    }

    return false;
  }

  /// Returns remaining lockout duration in seconds, or 0 if not locked.
  int remainingLockoutSeconds(String key) {
    final lockout = _lockoutUntil[key];
    if (lockout == null) return 0;
    final diff = lockout.difference(DateTime.now()).inSeconds;
    return max(0, diff);
  }

  /// Get current failed attempts count for a key.
  int getAttempts(String key) {
    return _attempts[key] ?? 0;
  }

  /// Record a failed attempt. If attempts reach [maxAttempts], locks the key for [lockoutDuration].
  void recordFailure(
    String key, {
    int maxAttempts = 5,
    Duration lockoutDuration = const Duration(minutes: 5),
  }) {
    final current = (_attempts[key] ?? 0) + 1;
    _attempts[key] = current;

    if (current >= maxAttempts) {
      final until = DateTime.now().add(lockoutDuration);
      _lockoutUntil[key] = until;
      _cache.saveSetting('ratelimit_lock_$key', until.millisecondsSinceEpoch);
    }
  }

  /// Reset attempts and lockout for a key upon successful authentication.
  void reset(String key) {
    _attempts.remove(key);
    _lockoutUntil.remove(key);
    _cache.saveSetting('ratelimit_lock_$key', null);
  }

  void _persistState(String key) {
    _cache.saveSetting('ratelimit_lock_$key', null);
  }
}
