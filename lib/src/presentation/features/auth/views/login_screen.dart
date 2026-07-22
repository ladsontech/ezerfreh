import 'dart:async';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _usePhoneAuth = true; // phone-first as primary
  bool _isLogin = true; // for email auth toggle
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isVerifyingOtp = false;
  String _verificationId = '';
  int _timerSeconds = 60;
  Timer? _timer;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        setState(() {
          _timer?.cancel();
        });
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String formattedPhone = phone;
      // Ugandan country prefix default if no + prefix
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+256${formattedPhone.substring(1)}';
        } else {
          formattedPhone = '+256$formattedPhone';
        }
      }

      await ref.read(authServiceProvider).verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _isVerifyingOtp = true;
                if (credential.smsCode != null && credential.smsCode!.isNotEmpty) {
                  _otpController.text = credential.smsCode!;
                }
              });
            }
            
            // On Android, credential passed by auto-retrieval / instant verification in verificationCompleted 
            // often has a null verificationId, causing firebase_auth pigeon platform interface to throw a channel-error.
            // We reconstruct credential using the stored _verificationId if missing.
            PhoneAuthCredential authCredential = credential;
            final code = credential.smsCode ?? _otpController.text.trim();
            if ((credential.verificationId == null || credential.verificationId!.isEmpty) &&
                _verificationId.isNotEmpty &&
                code.isNotEmpty) {
              authCredential = PhoneAuthProvider.credential(
                verificationId: _verificationId,
                smsCode: code,
              );
            }

            final userCredential = await ref.read(authServiceProvider).signInWithPhoneCredential(authCredential);
            
            // Create user profile if it's a new user (same as manual OTP verification flow)
            if (userCredential.user != null) {
              final firestoreService = ref.read(firestoreServiceProvider);
              final userDoc = await firestoreService.getUserProfileDoc(userCredential.user!.uid);
              
              if (!userDoc.exists) {
                await firestoreService.setUserProfile(userCredential.user!.uid, {
                  'uid': userCredential.user!.uid,
                  'name': 'Customer',
                  'contact': formattedPhone,
                  'role': 'customer',
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
            }
          } catch (e) {
            debugPrint('Auto-sign in failed: $e');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isVerifyingOtp = false;
              });
              // If auto-sign in fails but we have a valid 6-digit OTP code in the input box,
              // automatically attempt _verifyOtp() so sign-in succeeds seamlessly.
              if (_otpController.text.trim().length == 6) {
                _verifyOtp();
              }
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message ?? 'Verification failed')),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _otpSent = true;
              _verificationId = verificationId;
            });
            _startTimer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP sent to phone.')),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            _verificationId = verificationId;
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP.')),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      final userCredential = await ref.read(authServiceProvider).signInWithPhoneCredential(credential);
      
      if (userCredential.user != null) {
        final firestoreService = ref.read(firestoreServiceProvider);
        final userDoc = await firestoreService.getUserProfileDoc(userCredential.user!.uid);
        
        if (!userDoc.exists) {
          String formattedPhone = _phoneController.text.trim();
          if (!formattedPhone.startsWith('+')) {
            if (formattedPhone.startsWith('0')) {
              formattedPhone = '+256${formattedPhone.substring(1)}';
            } else {
              formattedPhone = '+256$formattedPhone';
            }
          }

          await firestoreService.setUserProfile(userCredential.user!.uid, {
            'uid': userCredential.user!.uid,
            'name': 'Customer',
            'contact': formattedPhone,
            'role': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Invalid OTP.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      if (_isLogin) {
        await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        final credential = await authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (credential != null && credential.user != null) {
          await firestoreService.setUserProfile(credential.user!.uid, {
            'uid': credential.user!.uid,
            'email': _emailController.text.trim(),
            'name': _nameController.text.trim(),
            'role': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Email already in use.'),
              action: SnackBarAction(
                label: 'Login',
                onPressed: () {
                  setState(() {
                    _isLogin = true;
                    _passwordController.clear();
                  });
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Authentication failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      final credential = await authService.signInWithGoogle();
      if (credential != null && credential.user != null) {
        final user = credential.user!;
        final userDoc = await firestoreService.getUserProfileDoc(user.uid);
        if (!userDoc.exists) {
          await firestoreService.setUserProfile(user.uid, {
            'uid': user.uid,
            'email': user.email ?? '',
            'name': user.displayName ?? 'Google User',
            'role': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Google sign-in failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skipAsGuest() async {
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -120,
            right: -100,
            child: CircleAvatar(
              radius: 160,
              backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.04),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/ezerlogo.png',
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Freshness at your doorstep',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        color: Colors.grey[600],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Auth Panel
                    if (_usePhoneAuth) _buildPhoneAuthPanel() else _buildEmailAuthPanel(),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[200])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[200])),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google Sign In Button
                    OutlinedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[200]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://developers.google.com/static/identity/images/g-logo.png',
                            height: 20,
                            width: 20,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.lato(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Toggle Phone / Email Auth Method
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _usePhoneAuth = !_usePhoneAuth;
                          _otpSent = false;
                        });
                      },
                      child: Text(
                        _usePhoneAuth ? 'Use Email & Password' : 'Use Phone Number',
                        style: GoogleFonts.lato(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Guest Button
                    Center(
                      child: TextButton.icon(
                        onPressed: _skipAsGuest,
                        icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                        label: Text(
                          'Browse as Guest',
                          style: GoogleFonts.lato(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneAuthPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _otpSent ? 'Enter verification code' : 'Sign in with Phone',
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (!_otpSent) ...[
          // Uganda Flag & prefix pre-field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '772 000 000',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇺🇬', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      '+256',
                      style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F7F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Send OTP Code', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ] else ...[
          // OTP code field
          Text(
            'We sent a 6-digit code to +256 ${_phoneController.text.trim()}',
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: GoogleFonts.lato(letterSpacing: 8, color: Colors.grey[300]),
              filled: true,
              fillColor: const Color(0xFFF5F7F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _otpSent = false;
                    _otpController.clear();
                  });
                },
                child: Text('Change number', style: GoogleFonts.lato(color: Colors.grey[600])),
              ),
              _timerSeconds > 0
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text('Resend in ${_timerSeconds}s', style: GoogleFonts.lato(color: Colors.grey)),
                    )
                  : TextButton(
                      onPressed: _sendOtp,
                      child: Text('Resend Code', style: GoogleFonts.lato(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isVerifyingOtp ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isVerifyingOtp
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Verify & Proceed', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildEmailAuthPanel() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isLogin ? 'Sign In' : 'Create Account',
            style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (!_isLogin) ...[
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => val == null || !val.contains('@') ? 'Please enter a valid email' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitEmailAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_isLogin ? 'Sign In' : 'Create Account', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_isLogin ? "Don't have an account?" : "Already have an account?", style: GoogleFonts.lato(color: Colors.grey[600])),
              TextButton(
                onPressed: _toggleAuthMode,
                child: Text(
                  _isLogin ? 'Sign Up' : 'Sign In',
                  style: GoogleFonts.lato(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFFF5F7F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        ),
        labelStyle: GoogleFonts.lato(color: Colors.grey[600]),
      ),
    );
  }
}
