import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/mock_data_service.dart';
import 'pharmacist_dashboard.dart';

class PharmacyCnopAuthGate extends StatefulWidget {
  const PharmacyCnopAuthGate({super.key});

  @override
  State<PharmacyCnopAuthGate> createState() => _PharmacyCnopAuthGateState();
}

class _PharmacyCnopAuthGateState extends State<PharmacyCnopAuthGate> {
  final TextEditingController _cnopController = TextEditingController(text: 'CNOP-TN-4012');
  final TextEditingController _passwordController = TextEditingController(text: 'officine2026');
  final MockDataService _mockData = MockDataService();
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  String? _errorMessage;
  String? _authenticatedPharmacyId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (_authService.isAuthenticated &&
        user?.role == UserRole.pharmacist &&
        user?.pharmacyId != null) {
      _isLoggedIn = true;
      _authenticatedPharmacyId = user!.pharmacyId;
    }
  }

  Future<void> _verifyCnopLogin() async {
    final cnopInput = _cnopController.text.trim().toUpperCase();
    final passInput = _passwordController.text.trim();

    if (cnopInput.isEmpty || passInput.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir votre Code CNOP et mot de passe.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final matchIndex = _mockData.pharmacies.indexWhere(
      (p) => p.cnopId.toUpperCase() == cnopInput,
    );

    if (matchIndex == -1) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Code CNOP introuvable dans le répertoire national.';
      });
      return;
    }

    final matchedPharmacy = _mockData.pharmacies[matchIndex];

    final result = await _authService.loginPharmacist(
      cnopId: cnopInput,
      password: passInput,
      pharmacyId: matchedPharmacy.id,
      pharmacyName: matchedPharmacy.name,
      pharmacyStatus: matchedPharmacy.status,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _isLoggedIn = true;
        _authenticatedPharmacyId = matchedPharmacy.id;
        _errorMessage = null;
      } else {
        _errorMessage = result.error;
      }
    });
  }

  @override
  void dispose() {
    _cnopController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return PharmacistDashboard(pharmacyId: _authenticatedPharmacyId);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.pharmacyGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront, color: AppTheme.pharmacyGreen, size: 32),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESPACE OFFICINE',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepBlack,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Connexion Pharmacien Sécurisée CNOP',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'Code CNOP Officine Unique',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _cnopController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge, color: AppTheme.pharmacyGreen),
                    hintText: 'Ex: CNOP-TN-4012',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Mot de Passe Patente / CNOP',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: AppTheme.pharmacyGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _verifyCnopLogin,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isLoading ? 'Vérification CNOP en cours...' : 'Accéder au Portail Pharmacie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pharmacyGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    '🔒 Accès strictement réservé aux officines agréées Conseil National de l\'Ordre des Pharmaciens de Tunisie (CNOP).',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
