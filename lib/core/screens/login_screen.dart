import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/services/auth_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _patientPhoneController = TextEditingController();
  final TextEditingController _pharmaPhoneController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _patientPhoneController.dispose();
    _pharmaPhoneController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handlePatientLogin() async {
    final phone = _patientPhoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await AuthService().loginWithPhone('+216$phone');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              phone: '+216$phone',
              onVerified: widget.onLoginSuccess,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _handlePharmaLogin() async {
    final phone = _pharmaPhoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await AuthService().loginWithPhone(phone);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              phone: phone,
              onVerified: widget.onLoginSuccess,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAdminLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await AuthService().loginAdmin(
      _adminPasswordController.text,
      email: _adminEmailController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (result.isSuccess) {
        widget.onLoginSuccess();
      } else {
        setState(() {
          _errorMessage = result.error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.health_and_safety,
                      color: AppTheme.pharmacyGreen,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PharmaGuide TN',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepBlack,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.pharmacyGreen,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppTheme.pharmacyGreen,
                      tabs: const [
                        Tab(text: 'Patient'),
                        Tab(text: 'Pharmacien'),
                        Tab(text: 'Admin'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPatientTab(),
                          _buildPharmacistTab(),
                          _buildAdminTab(),
                        ],
                      ),
                    ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: AppTheme.errorRed),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _patientPhoneController,
          decoration: InputDecoration(
            labelText: 'Numéro de téléphone',
            prefixText: '+216 ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handlePatientLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pharmacyGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Recevoir le code OTP'),
          ),
        ),
      ],
    );
  }

  Widget _buildPharmacistTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _pharmaPhoneController,
          decoration: InputDecoration(
            labelText: 'Numéro de téléphone pro',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.local_pharmacy),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handlePharmaLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pharmacyGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Connexion Pharmacien'),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _adminEmailController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminPasswordController,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.lock),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleAdminLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlack,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Connexion Admin'),
          ),
        ),
      ],
    );
  }
}
