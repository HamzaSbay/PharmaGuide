import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/services/auth_service.dart';
import 'admin_dashboard.dart';

class AdminPinAuthGate extends StatefulWidget {
  const AdminPinAuthGate({super.key});

  @override
  State<AdminPinAuthGate> createState() => _AdminPinAuthGateState();
}

class _AdminPinAuthGateState extends State<AdminPinAuthGate> {
  final TextEditingController _pinController = TextEditingController(text: 'admin2026');
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (_authService.isAuthenticated && user?.role == UserRole.admin) {
      _isLoggedIn = true;
    }
  }

  Future<void> _verifyAdminPin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir le code secret administrateur.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.loginAdmin(pin);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _isLoggedIn = true;
        _errorMessage = null;
      } else {
        _errorMessage = result.error;
        _pinController.clear();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return const AdminDashboard();
    }

    return Scaffold(
      backgroundColor: AppTheme.darkSlate,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
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
                        color: AppTheme.darkSlate.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: AppTheme.darkSlate, size: 32),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PORTAIL ADMIN',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepBlack,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Superviseur National PharmaGuide TN',
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
                  'Code Secret Administrateur',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.key, color: AppTheme.darkSlate),
                    hintText: 'Code Secret Admin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _verifyAdminPin,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.shield),
                    label: Text(_isLoading ? 'Vérification sécurisée...' : 'Déverrouiller Portail Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkSlate,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
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
