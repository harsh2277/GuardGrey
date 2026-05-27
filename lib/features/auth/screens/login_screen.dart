import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/theme/app_theme.dart';
import 'package:guardgrey/data/sources/firebase/guard_grey_firestore_seed_source.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isSeedingDatabase = false;
  String? _errorMessage;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (error) {
      debugPrint('Login error: ${error.code} ${error.message}');
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _messageForAuthError(error);
      });
    } catch (error) {
      debugPrint('Login error: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to login right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _seedDatabase() async {
    if (_isSeedingDatabase || _isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSeedingDatabase = true;
      _errorMessage = null;
    });

    try {
      await seedDatabase(
        clearExisting: true,
        includeReports: true,
        includeVisits: true,
        includeLiveTracking: true,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Database seeded successfully.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      debugPrint('Seed database error: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            'Unable to seed the database right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSeedingDatabase = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Header background dynamically changes (primary900 in light mode, scaffold background in dark mode)
    final darkHeaderBg = isDark ? theme.scaffoldBackgroundColor : AppColors.primary900;
    final topPadding = MediaQuery.of(context).padding.top;

    // Dynamic linear gradient to create beautiful background depth
    final bgGradient = isDark
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              AppColors.neutral900,
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary800, // Rich darker blue
              AppColors.primary900, // Deepest navy blue
            ],
          );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Light icons for the dark header background
        statusBarBrightness: Brightness.dark, // For iOS devices
      ),
      child: Scaffold(
        body: Container(
        decoration: BoxDecoration(
          gradient: bgGradient,
        ),
        child: Stack(
          children: [
            // 🎨 Ambient Glow Spheres and abstract geometric cyber-security patterns in background
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: -120,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? theme.colorScheme.primary : AppColors.primary400)
                          .withValues(alpha: 0.12),
                      (isDark ? theme.colorScheme.primary : AppColors.primary400)
                          .withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // 🌊 Custom Fluid Liquid Wave Pattern that fully fills the background
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPatternPainter(context, isDark),
              ),
            ),

            // Actual form contents scrolling elegantly above the background elements
            CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Spacer to push the heading and subheading down right above the bottom card
                        const Spacer(),

                        // 1. Dark Header Section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(24, 24 + topPadding, 24, 0),
                          color: Colors.transparent, // transparent to let the gradient and pattern show through!
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login to GuardGrey',
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use your email and password to continue.',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              // Exactly 24px gap between subtitle and the bottom sheet card
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),

                        // 2. White Sheet Card Section
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? theme.cardTheme.color ?? AppColors.surfaceDark : Colors.white,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_errorMessage != null) ...[
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.errorDark.withValues(alpha: 0.2)
                                        : AppColors.errorLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.error.withValues(alpha: 0.3)
                                          : const Color(0xFFFECACA),
                                    ),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isDark ? AppColors.errorLight : AppColors.errorDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],

                              // Email Field
                              Text(
                                'Email',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppColors.neutral300 : AppColors.neutral800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                enabled: !_isSubmitting,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Enter your email',
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!email.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              Text(
                                'Password',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppColors.neutral300 : AppColors.neutral800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                enabled: !_isSubmitting,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                                      ),
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  final password = value ?? '';
                                  if (password.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (password.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submitLogin(),
                              ),
                              const SizedBox(height: 32),

                              // Login Action Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting || _isSeedingDatabase
                                      ? null
                                      : _submitLogin,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Login'),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Seed Database Action Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isSubmitting || _isSeedingDatabase
                                      ? null
                                      : _seedDatabase,
                                  icon: _isSeedingDatabase
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: theme.colorScheme.primary,
                                          ),
                                        )
                                      : const Icon(Icons.cloud_upload_outlined),
                                  label: const Text('Seed Database'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  String _messageForAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return error.message ?? 'Unable to login right now.';
    }
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final BuildContext context;
  final bool isDark;

  BackgroundPatternPainter(this.context, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Wave 1: Large smooth wave flowing from top-right to middle-left
    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(size.width, 0);
    path1.lineTo(size.width, size.height * 0.48);
    path1.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.60,
      0,
      size.height * 0.45,
    );
    path1.close();
    
    final gradient1 = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        AppColors.primary600.withValues(alpha: 0.40),
        AppColors.primary900.withValues(alpha: 0.05),
      ],
    );
    paint.shader = gradient1.createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.65));
    canvas.drawPath(path1, paint);
    
    // Wave 1 Border Stroke for crystal-clear boundary visibility
    final borderPaint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppColors.primary300.withValues(alpha: 0.35);
    final borderPath1 = Path();
    borderPath1.moveTo(0, size.height * 0.45);
    borderPath1.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.60,
      size.width,
      size.height * 0.48,
    );
    canvas.drawPath(borderPath1, borderPaint1);
    
    // Wave 2: Overlapping wave curving from middle-right to upper-left
    final path2 = Path();
    path2.moveTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.lineTo(0, size.height * 0.38);
    path2.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.32,
      size.width,
      size.height * 0.52,
    );
    path2.close();
    
    final gradient2 = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primary500.withValues(alpha: 0.30),
        AppColors.primary800.withValues(alpha: 0.0),
      ],
    );
    paint.shader = gradient2.createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));
    canvas.drawPath(path2, paint);
    
    // Wave 2 Border Stroke for gorgeous layered depth definition
    final borderPaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.primary200.withValues(alpha: 0.28);
    final borderPath2 = Path();
    borderPath2.moveTo(0, size.height * 0.38);
    borderPath2.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.32,
      size.width,
      size.height * 0.52,
    );
    canvas.drawPath(borderPath2, borderPaint2);
    
    // Wave 3: Bottom organic highlight band to add layered depth
    final path3 = Path();
    path3.moveTo(0, size.height * 0.22);
    path3.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.42,
      size.width,
      size.height * 0.28,
    );
    path3.lineTo(size.width, size.height * 0.58);
    path3.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.68,
      0,
      size.height * 0.52,
    );
    path3.close();
    
    final gradient3 = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        AppColors.primary400.withValues(alpha: 0.18),
        AppColors.primary700.withValues(alpha: 0.0),
      ],
    );
    paint.shader = gradient3.createShader(Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.58));
    canvas.drawPath(path3, paint);
    
    // Wave 3 Border Stroke for subtle flowing structural highlighting
    final borderPaint3 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.primary200.withValues(alpha: 0.18);
    final borderPath3 = Path();
    borderPath3.moveTo(0, size.height * 0.22);
    borderPath3.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.42,
      size.width,
      size.height * 0.28,
    );
    canvas.drawPath(borderPath3, borderPaint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
