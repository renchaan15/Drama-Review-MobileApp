// lib/features/profile/presentation/screens/settings_screen.dart

import 'package:drama_review_app/core/providers/database_providers.dart';
import 'package:drama_review_app/features/auth/providers/auth_providers.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _usernameController;
  bool _isSaving = false;
  bool _isSendingResetEmail = false;

  @override
  void initState() {
    super.initState();
    // Ambil username saat ini dan masukkan ke controller
    final username = ref.read(userProfileProvider).valueOrNull?.username ?? '';
    _usernameController = TextEditingController(text: username);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // Aksi untuk memperbarui username
  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty.')),
      );
      return;
    }

    setState(() { _isSaving = true; });

    try {
      await ref.read(databaseServiceProvider).updateUsername(newUsername);
      // Refresh data profil di seluruh aplikasi
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username updated successfully!'), backgroundColor: Colors.green[700]),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating username: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  // Aksi untuk mengirim email reset password
  Future<void> _resetPassword() async {
    final email = ref.read(userProfileProvider).valueOrNull?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find user email.')),
      );
      return;
    }

    setState(() { _isSendingResetEmail = true; });

    try {
      await ref.read(authServiceProvider).resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to $email'), backgroundColor: Colors.green[700]),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending email: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSendingResetEmail = false; });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Bagian Ubah Username ---
          _SettingsGroup(
            title: 'Profile',
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(EvaIcons.personOutline),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _updateUsername,
                        child: const Text('Save Changes'),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Bagian Keamanan ---
          _SettingsGroup(
            title: 'Security',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(EvaIcons.emailOutline),
                title: const Text('Reset Password'),
                subtitle: const Text('Send a password reset link to your email.'),
                trailing: _isSendingResetEmail
                    ? const CircularProgressIndicator()
                    : FilledButton.tonal(
                        onPressed: _resetPassword,
                        child: const Text('Send Link'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget helper untuk membuat grup pengaturan yang rapi
class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.grey[500],
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}