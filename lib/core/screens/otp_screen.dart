import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final VoidCallback onVerified;

  const OtpScreen({super.key, required this.phone, required this.onVerified});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  int _timerSeconds = 60;
  Timer? _timer;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() => _timerSeconds = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Veuillez entrer les 6 chiffres');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await AuthService().verifyOtp(otp);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.isSuccess) {
        widget.onVerified();
      } else {
        setState(() => _errorMessage = result.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkSlate),
      ),
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
                      Icons.message_outlined,
                      color: AppTheme.pharmacyGreen,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Vérification OTP',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Code envoyé au ${widget.phone}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 40,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                            decoration: const InputDecoration(
                              counterText: '',
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: AppTheme.pharmacyGreen, width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage.isNotEmpty) ...[
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: AppTheme.errorRed),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.pharmacyGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Vérifier'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _timerSeconds == 0 ? _startTimer : null,
                      child: Text(
                        _timerSeconds > 0
                            ? 'Renvoyer le code dans $_timerSeconds s'
                            : 'Renvoyer le code',
                        style: TextStyle(
                          color: _timerSeconds > 0 ? Colors.grey : AppTheme.pharmacyGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
