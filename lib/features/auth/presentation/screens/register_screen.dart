// lib/features/auth/presentation/screens/register_screen.dart

import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:drama_review_app/core/providers/tmdb_providers.dart';
import 'package:drama_review_app/features/auth/providers/auth_providers.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _panelAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _panelAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required.')),
      );
      return;
    }
    setState(() { _isLoading = true; });
    final authService = ref.read(authServiceProvider);
    final error = await authService.registerUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _usernameController.text.trim(),
    );
    if (mounted) {
      setState(() { _isLoading = false; });
    }

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registrasi berhasil! Silakan login.'),
          backgroundColor: Colors.green[700],
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
      ),
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
                      Text('Create Account', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('Join the largest drama community!', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(EvaIcons.personOutline)),
                      ),
                      const SizedBox(height: 16),
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
                            : ElevatedButton(onPressed: _register, child: const Text('Register')),
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
                // Logo tidak ditampilkan di sini agar tidak terlalu ramai
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