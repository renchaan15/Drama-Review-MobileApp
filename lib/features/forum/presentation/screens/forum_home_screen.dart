// lib/features/forum/presentation/screens/forum_home_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drama_review_app/core/models/forum_thread_model.dart';
import 'package:drama_review_app/core/providers/database_providers.dart';
import 'package:drama_review_app/core/providers/firebase_providers.dart'; // <-- Import Auth Provider
import 'package:drama_review_app/features/forum/presentation/screens/create_thread_screen.dart';
import 'package:drama_review_app/features/forum/presentation/screens/forum_thread_screen.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForumHomeScreen extends ConsumerWidget {
  const ForumHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(allThreadsProvider);
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid; // <-- Ambil ID user

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Diskusi'),
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(EvaIcons.messageCircleOutline, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  const Text('Belum ada diskusi.\nMulai topik baru sekarang!', textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _ThreadCard(
                thread: threads[index], 
                currentUserId: currentUserId, // <-- Pass ID user
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateThreadScreen()));
        },
        label: const Text('Topik Baru'),
        icon: const Icon(EvaIcons.plus),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
      ),
    );
  }
}

class _ThreadCard extends ConsumerWidget {
  final ForumThread thread;
  final String? currentUserId; // <-- Terima ID user
  const _ThreadCard({required this.thread, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = currentUserId == thread.userId; // Cek kepemilikan

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForumThreadScreen(thread: thread)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: thread.userPhotoUrl.isNotEmpty ? CachedNetworkImageProvider(thread.userPhotoUrl) : null,
                    child: thread.userPhotoUrl.isEmpty ? const Icon(EvaIcons.personOutline, size: 14) : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    thread.username,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                  ),
                  const Spacer(),
                  // --- TOMBOL HAPUS JIKA OWNER ---
                  if (isOwner)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(EvaIcons.trash2Outline, size: 16, color: Colors.redAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Hapus Topik?"),
                            content: const Text("Tindakan ini tidak bisa dibatalkan."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await ref.read(databaseServiceProvider).deleteThread(thread.id);
                                }, 
                                child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(width: 8),
                  // ------------------------------
                  Icon(EvaIcons.messageSquareOutline, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    thread.replyCount.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                thread.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (thread.attachedTmdbId != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.movie_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "Membahas: ${thread.attachedDramaTitle ?? 'Unknown Drama'}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}