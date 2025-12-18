// lib/features/forum/presentation/screens/forum_thread_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drama_review_app/core/models/drama_model.dart'; // Import Drama
import 'package:drama_review_app/core/models/forum_post_model.dart';
import 'package:drama_review_app/core/providers/firebase_providers.dart';
import 'package:drama_review_app/core/models/forum_thread_model.dart';
import 'package:drama_review_app/core/providers/database_providers.dart';
import 'package:drama_review_app/features/drama_details/presentation/screens/drama_details_screen.dart';
import 'package:drama_review_app/features/forum/presentation/screens/drama_picker_screen.dart'; // Import Picker
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForumThreadScreen extends ConsumerStatefulWidget {
  final ForumThread thread;
  const ForumThreadScreen({super.key, required this.thread});

  @override
  ConsumerState<ForumThreadScreen> createState() => _ForumThreadScreenState();
}

class _ForumThreadScreenState extends ConsumerState<ForumThreadScreen> {
  final _postController = TextEditingController();
  bool _isPosting = false;
  Drama? _attachedDrama;

  void _postReply() async {
    if (_postController.text.trim().isEmpty) return;
    setState(() { _isPosting = true; });

    try {
      await ref.read(databaseServiceProvider).postReplyToThread(
        widget.thread.id, 
        _postController.text.trim(),
        attachedDrama: _attachedDrama,
      );
      _postController.clear();
      setState(() { _attachedDrama = null; });
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() { _isPosting = false; });
      }
    }
  }

  void _pickDrama() async {
    final Drama? selected = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const DramaPickerScreen())
    );
    if (selected != null) {
      setState(() {
        _attachedDrama = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(threadPostsProvider(widget.thread.id));
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid; // <-- Ambil ID User

    return Scaffold(
      appBar: AppBar(title: Text(widget.thread.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _ThreadHeader(thread: widget.thread),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      const Icon(EvaIcons.messageCircleOutline, size: 20),
                      const SizedBox(width: 8),
                      Text('Balasan', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                postsAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Belum ada balasan. Jadilah yang pertama!'),
                      ));
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return _PostTile(
                          post: posts[index],
                          currentUserId: currentUserId, // <-- Pass ID user
                          threadId: widget.thread.id,   // <-- Pass thread ID untuk hapus
                        );
                      },
                    );
                  },
                  error: (e, s) => const Center(child: Text('Tidak bisa memuat balasan.')),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _ReplyInputField(
            controller: _postController,
            isPosting: _isPosting,
            attachedDrama: _attachedDrama,
            onPost: _postReply,
            onAttach: _pickDrama,
            onRemoveAttachment: () => setState(() => _attachedDrama = null),
          ),
        ],
      ),
    );
  }
}

class _PostTile extends ConsumerWidget {
  final ForumPost post;
  final String? currentUserId; // <-- ID User
  final String threadId;       // <-- ID Thread
  const _PostTile({required this.post, required this.currentUserId, required this.threadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = currentUserId == post.userId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: post.userPhotoUrl.isNotEmpty ? CachedNetworkImageProvider(post.userPhotoUrl) : null,
            child: post.userPhotoUrl.isEmpty ? const Icon(EvaIcons.personOutline, size: 18) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(post.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    // --- TOMBOL HAPUS BALASAN ---
                    if (isOwner)
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Hapus Balasan?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await ref.read(databaseServiceProvider).deleteForumPost(threadId, post.id);
                                  }, 
                                  child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Icon(EvaIcons.trash2Outline, size: 16, color: Colors.grey),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(post.postText, style: TextStyle(color: Colors.grey[300], height: 1.4)),
                
                if (post.attachedTmdbId != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => DramaDetailScreen(dramaId: post.attachedTmdbId!)
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: post.attachedFullPosterPath != null
                                ? CachedNetworkImage(imageUrl: post.attachedFullPosterPath!, width: 40, height: 60, fit: BoxFit.cover)
                                : Container(width: 40, height: 60, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.attachedDramaTitle ?? 'Drama', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text('Lihat Info', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10)),
                                    Icon(Icons.arrow_forward_ios, size: 8, color: Theme.of(context).colorScheme.primary),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- INPUT FIELD YANG DIPERBARUI DENGAN TOMBOL LAMPIRAN & PREVIEW ---
class _ReplyInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isPosting;
  final VoidCallback onPost;
  final VoidCallback onAttach;
  final VoidCallback onRemoveAttachment;
  final Drama? attachedDrama;

  const _ReplyInputField({
    required this.controller,
    required this.isPosting,
    required this.onPost,
    required this.onAttach,
    required this.onRemoveAttachment,
    this.attachedDrama,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(top: BorderSide(color: Colors.grey[850]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PREVIEW LAMPIRAN SEMENTARA (SEBELUM DIKIRIM)
          if (attachedDrama != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.movie, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Melampirkan: ${attachedDrama!.name}",
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onRemoveAttachment,
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              // TOMBOL LAMPIRKAN
              IconButton(
                onPressed: onAttach,
                icon: Icon(
                  attachedDrama != null ? Icons.check_circle : Icons.add_link, 
                  color: attachedDrama != null ? Theme.of(context).colorScheme.primary : Colors.grey
                ),
                tooltip: 'Lampirkan Drama',
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Tulis balasan...',
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              isPosting
                  ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                  : IconButton(
                      icon: Icon(EvaIcons.paperPlane, color: Theme.of(context).colorScheme.primary),
                      onPressed: onPost,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  final ForumThread thread;
  const _ThreadHeader({required this.thread});

  @override
  Widget build(BuildContext context) {
    // (Kode header thread tetap sama, hanya menampilkan konten utama thread)
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: thread.userPhotoUrl.isNotEmpty ? CachedNetworkImageProvider(thread.userPhotoUrl) : null,
                child: thread.userPhotoUrl.isEmpty ? const Icon(EvaIcons.personOutline) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(thread.username, style: Theme.of(context).textTheme.titleMedium),
                  Text('Original Poster', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(thread.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(thread.content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[300], height: 1.5)),
        ],
      ),
    );
  }
}