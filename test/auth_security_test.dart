import 'package:flutter_test/flutter_test.dart';
import 'package:pharmaguide_tn/core/security/rate_limit_service.dart';
import 'package:pharmaguide_tn/core/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RateLimitService', () {
    final rateLimiter = RateLimitService();

    test('locks key after specified maximum failed attempts', () {
      const testKey = 'test_login_rate_limit';
      rateLimiter.reset(testKey);

      expect(rateLimiter.isLocked(testKey), isFalse);

      for (int i = 0; i < 5; i++) {
        rateLimiter.recordFailure(testKey, maxAttempts: 5, lockoutDuration: const Duration(seconds: 10));
      }

      expect(rateLimiter.isLocked(testKey), isTrue);
      expect(rateLimiter.remainingLockoutSeconds(testKey), greaterThan(0));

      // Resetting unlocks immediately
      rateLimiter.reset(testKey);
      expect(rateLimiter.isLocked(testKey), isFalse);
    });
  });

  group('AuthService Cryptography & Security', () {
    test('hashSecret generates deterministic SHA-256 with salt', () {
      final hash1 = AuthService.hashSecret('officine2026');
      final hash2 = AuthService.hashSecret('officine2026');
      final diffHash = AuthService.hashSecret('different_secret');

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(diffHash)));
      expect(AuthService.verifyHash('officine2026', hash1), isTrue);
      expect(AuthService.verifyHash('wrong_secret', hash1), isFalse);
    });

    test('Pharmacist authentication validates CNOP status and rejects unapproved', () async {
      final auth = AuthService();
      auth.isDevDemoMode = true;

      // Approved pharmacy login
      final result = await auth.loginPharmacist(
        cnopId: 'CNOP-TN-4012',
        password: 'officine2026',
        pharmacyId: 'ph-1',
        pharmacyName: 'Pharmacie Principale El Menzah',
        pharmacyStatus: 'APPROVED',
      );

      expect(result.isSuccess, isTrue);
      expect(auth.currentUser?.role, equals(UserRole.pharmacist));
      expect(auth.currentUser?.cnopId, equals('CNOP-TN-4012'));
      expect(auth.isAuthenticated, isTrue);

      // Unapproved pharmacy login should be rejected
      final unapprovedResult = await auth.loginPharmacist(
        cnopId: 'CNOP-TN-PENDING',
        password: 'officine2026',
        pharmacyId: 'ph-unapproved',
        pharmacyName: 'Pharmacie En Attente',
        pharmacyStatus: 'PENDING',
      );

      expect(unapprovedResult.isFailure, isTrue);
      expect(unapprovedResult.error, contains('attente de vérification CNOP'));
    });

    test('Admin authentication grants UserRole.admin with valid credentials', () async {
      final auth = AuthService();
      auth.isDevDemoMode = true;

      final res = await auth.loginAdmin('admin2026');
      expect(res.isSuccess, isTrue);
      expect(auth.currentUser?.role, equals(UserRole.admin));
      expect(auth.currentUser?.sessionToken, isNotNull);

      // Wrong pin fails
      final wrongRes = await auth.loginAdmin('wrong_pin_9999');
      expect(wrongRes.isFailure, isTrue);
    });
  });
}
