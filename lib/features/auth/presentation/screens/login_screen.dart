// lib/features/auth/presentation/screens/login_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:drama_review_app/core/providers/tmdb_providers.dart';
import 'package:drama_review_app/features/auth/presentation/screens/register_screen.dart';
import 'package:drama_review_app/features/auth/providers/auth_providers.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _panelAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _panelAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email and password cannot be empty.')));
      return;
    }
    setState(() { _isLoading = true; });
    final authService = ref.read(authServiceProvider);
    final error = await authService.loginUser(email: _emailController.text.trim(), password: _passwordController.text.trim());
    if (mounted) {
      setState(() { _isLoading = false; });
    }
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _signInWithGoogle() async {
    setState(() { _isLoading = true; });
    final authService = ref.read(authServiceProvider);
    try {
      final error = await authService.signInWithGoogle();
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BackgroundCarousel(),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizeTransition(
              sizeFactor: _panelAnimation,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome Back!', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('Login to continue your journey.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(EvaIcons.emailOutline)),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(EvaIcons.lockOutline)),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(onPressed: _isLoading ? null : _login, child: const Text('Login')),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[800])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Or', style: TextStyle(color: Colors.grey[600])),
                          ),
                          Expanded(child: Divider(color: Colors.grey[800])),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                          label: const Text('Continue with Google'),
                          style: Theme.of(context).filledButtonTheme.style?.copyWith(
                            backgroundColor: WidgetStateProperty.all(Colors.white),
                            foregroundColor: WidgetStateProperty.all(Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: _isLoading ? null : () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
                            },
                            child: const Text('Register Now'),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundCarousel extends ConsumerWidget {
  const _BackgroundCarousel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MENGGUNAKAN PROVIDER LAMA YANG SUDAH DIKEMBALIKAN
    final popularAsync = ref.watch(popularDramasProvider);

    return popularAsync.when(
      data: (dramas) { // 'dramas' adalah List<Drama>
        if (dramas.isEmpty) return Container(color: Colors.black);
        return CarouselSlider.builder(
          itemCount: dramas.take(5).length,
          itemBuilder: (context, index, realIndex) {
            final drama = dramas[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: drama.fullBackdropPath,
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Container(color: Colors.black.withValues(alpha: 0.4)),
                ),
                Center(
                  child: CachedNetworkImage(
                    imageUrl: drama.fullBackdropPath,
                    fit: BoxFit.contain,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Theme.of(context).colorScheme.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/images/splash_logo.png',
                      width: 100,
                    ),
                  ),
                ),
              ],
            );
          },
          options: CarouselOptions(
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 6),
            viewportFraction: 1.0,
            height: MediaQuery.of(context).size.height,
            scrollPhysics: const NeverScrollableScrollPhysics(),
            enlargeCenterPage: false,
            pauseAutoPlayOnTouch: false,
            autoPlayAnimationDuration: const Duration(seconds: 1),
            autoPlayCurve: Curves.easeInOut,
          ),
        );
      },
      error: (e, s) => Container(color: Colors.black),
      loading: () => Container(color: Colors.black),
    );
  }
}