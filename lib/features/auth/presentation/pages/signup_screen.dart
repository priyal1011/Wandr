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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = credential.user;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          getIt<InMemoryStore>().currentUser = UserModel(
            id: user.uid,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: '', 
          );
          getIt<InMemoryStore>().hasSeenOnboarding = true;
          await getIt<InMemoryStore>().loadFromDisk();

          await getIt<AuthCubit>().setAuthenticated();

          if (mounted) context.go('/');
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'Signup failed'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
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
          constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
          decoration: const BoxDecoration(
            gradient: AppTheme.brandGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Gap(40),
                  // Logo Container
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Center(
                      child: ClipOval(
                        child: Image.asset(
                          isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 50),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9)),
                  const Gap(24),
                  Text(
                    'Your Journey\nStarts Here.',
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
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),        
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),        
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.name,
                          magnifierConfiguration: TextMagnifierConfiguration.disabled,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your travel name.' : null,
                        ),
                        const Gap(12),
                        TextFormField(
                          stylusHandwritingEnabled: false,
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),        
                          decoration: InputDecoration(
                            labelText: 'Wandr Email',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),        
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          magnifierConfiguration: TextMagnifierConfiguration.disabled,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your travel email.' : null,
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
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white70),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),        
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.visiblePassword,
                          magnifierConfiguration: TextMagnifierConfiguration.disabled,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters required.' : null,
                        ),
                        const Gap(24),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () {
                              HapticHelper.medium();
                              _signup();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('CREATE ADVENTURE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ),
                        ).animate().scale(delay: 300.ms),
                        const Gap(8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already wandering?", style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Log In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
