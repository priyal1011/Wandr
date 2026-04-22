import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../cubit/auth_cubit.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../core/utils/haptic_feedback_helper.dart';
import '../../../../main.dart';
import '../../../../models/user_model.dart';
import '../../../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        final user = credential.user;
        if (user != null) {
          // Fetch Profile from Firestore
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (doc.exists) {
            final data = doc.data();
            getIt<InMemoryStore>().currentUser = UserModel(
              id: user.uid,
              name: data?['name']?.toString() ?? 'Explorer',
              email:
                  data?['email']?.toString() ??
                  user.email ??
                  'traveler@wandr.com',
              password: '', // Password handled by Firebase Auth
              photoUrl: data?['photoUrl']?.toString(),
              fluttermojiCode: data?['fluttermojiCode']?.toString(),
            );
          } else {
            getIt<InMemoryStore>().currentUser = UserModel(
              id: user.uid,
              name: 'Explorer',
              email: user.email ?? 'traveler@wandr.com',
              password: '', // Password handled by Firebase Auth
            );
          }

          getIt<InMemoryStore>().hasSeenOnboarding = true;
          await getIt<InMemoryStore>().loadFromDisk();

          // Emit success to trigger router redirection
          await getIt<AuthCubit>().setAuthenticated();

          if (mounted) context.go('/');
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Login failed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An unexpected error occurred')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height,
          ),
          decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Gap(40),
                  // Logo with a solid, high-performance background
                  Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: Center(
                          child: ClipOval(
                            child: Image.asset(
                              isDark
                                  ? 'assets/images/logo_dark.png'
                                  : 'assets/images/logo.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.travel_explore,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                  const Gap(24),
                  Text(
                    'Welcome Back,\nExplorer.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: -1,
                    ),
                  ),
                  const Gap(32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          stylusHandwritingEnabled: false,
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Wandr Email',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: Color(
                              0xFF1E293B,
                            ), // Solid slate (no transparency/blending)
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          magnifierConfiguration:
                              TextMagnifierConfiguration.disabled,
                          textInputAction: TextInputAction.next,

                          autocorrect: false,
                          enableSuggestions: false,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter your travel email.'
                              : null,
                        ),
                        const Gap(12),
                        TextFormField(
                          stylusHandwritingEnabled: false,
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Secure Password',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white70,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white70,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            filled: true,
                            fillColor: Color(
                              0xFF1E293B,
                            ), // Solid slate (no transparency/blending)
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.visiblePassword,
                          magnifierConfiguration:
                              TextMagnifierConfiguration.disabled,
                          textInputAction: TextInputAction.done,

                          autocorrect: false,
                          enableSuggestions: false,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter your password.'
                              : null,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 30),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppTheme.accentCyan.withValues(
                                  alpha: 0.8,
                                ),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const Gap(16),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    HapticHelper.medium();
                                    _login();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'LOG IN TO JOURNEY',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ).animate().scale(delay: 300.ms),
                        const Gap(8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "New to Wandr?",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/signup'),
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
