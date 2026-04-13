import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../core/utils/haptic_feedback_helper.dart';
import '../../../../main.dart';
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

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = credential.user;
        if (user != null) {
          // Fetch Profile from Firestore
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          
          if (doc.exists) {
            final data = doc.data();
            getIt<InMemoryStore>().currentUser = UserModel(
              id: user.uid,
              name: data?['name']?.toString() ?? 'Explorer',
              email: data?['email']?.toString() ?? user.email ?? 'traveler@wandr.com',
              password: '', // Password handled by Firebase Auth
              photoUrl: data?['photoUrl']?.toString(),
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
          
          if (mounted) context.go('/home');
        }
      } on FirebaseAuthException catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
      } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An unexpected error occurred')));
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
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
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
                  // Logo with a premium blending glow
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: ClipOval(
                        child: Image.asset(
                          isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
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
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Wandr Email',
                            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your travel email.' : null,
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                        const Gap(12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Secure Password',
                            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white70),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your password.' : null,
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                        
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                            child: Text('Forgot Password?', style: TextStyle(color: AppTheme.accentCyan.withValues(alpha: 0.8), fontSize: 13)),
                          ),
                        ),
                        const Gap(16),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () {
                              HapticHelper.medium();
                              _login();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white) 
                                : const Text('LOG IN TO JOURNEY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ),
                        ).animate().scale(delay: 300.ms),
                        const Gap(16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("New to Wandr?", style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                            TextButton(
                              onPressed: () => context.push('/signup'),
                              child: const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
