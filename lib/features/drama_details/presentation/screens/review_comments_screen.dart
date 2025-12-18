// lib/features/drama_details/presentation/screens/review_comments_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drama_review_app/core/models/review_model.dart';
import 'package:drama_review_app/core/providers/database_providers.dart';
import 'package:drama_review_app/core/providers/firebase_providers.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:drama_review_app/core/models/comment_model.dart';

class ReviewCommentsScreen extends ConsumerStatefulWidget {
  final Review review;
  const ReviewCommentsScreen({super.key, required this.review});

  @override
  ConsumerState<ReviewCommentsScreen> createState() => _ReviewCommentsScreenState();
}

class _ReviewCommentsScreenState extends ConsumerState<ReviewCommentsScreen> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  void _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() { _isPosting = true; });

    try {
      await ref.read(databaseServiceProvider).addCommentToReview(widget.review.id, _commentController.text.trim());
      _commentController.clear();
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

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(reviewCommentsProvider(widget.review.id));
    
    return Scaffold(
      appBar: AppBar(title: Text("Review by ${widget.review.username}")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Tampilkan review utama di bagian atas
                _ReviewCard(review: widget.review),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Comments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                // Tampilkan daftar komentar
                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No comments yet. Be the first!'),
                      ));
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return _CommentTile(comment: comment);
                      },
                    );
                  },
                  error: (e, s) => const Center(child: Text('Could not load comments.')),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
          // Bagian untuk menambah komentar
          _CommentInputField(
            controller: _commentController,
            isPosting: _isPosting,
            onPost: _postComment,
          ),
        ],
      ),
    );
  }
}

// Widget untuk menampilkan review utama
class _ReviewCard extends ConsumerWidget {
  final Review review;
  const _ReviewCard({required this.review});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(EvaIcons.personOutline)),
                const SizedBox(width: 12),
                Text(review.username, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            RatingBarIndicator(
              rating: review.rating,
              itemBuilder: (context, index) => Icon(EvaIcons.star, color: Theme.of(context).colorScheme.primary),
              itemCount: 5,
              itemSize: 16.0,
            ),
            const SizedBox(height: 12),
            Text(review.reviewText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[300], height: 1.5)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Suka
                TextButton.icon(
                  onPressed: () {
                    if (currentUserId != null) {
                      ref.read(databaseServiceProvider).toggleLikeReview(review.id);
                    }
                  },
                  icon: Icon(
                    review.isLikedBy(currentUserId ?? '') ? EvaIcons.heart : EvaIcons.heartOutline,
                    color: review.isLikedBy(currentUserId ?? '') ? Colors.red : Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(review.likeCount.toString(), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
                // Tombol Komentar (hanya tampilan)
                Row(
                  children: [
                    Icon(EvaIcons.messageSquareOutline, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(review.commentCount.toString(), style: TextStyle(color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget untuk menampilkan satu komentar
class _CommentTile extends StatelessWidget {
  final Comment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: comment.photoUrl.isNotEmpty ? CachedNetworkImageProvider(comment.photoUrl) : null,
        child: comment.photoUrl.isEmpty ? const Icon(EvaIcons.personOutline) : null,
      ),
      title: Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(comment.commentText),
    );
  }
}

// Widget untuk input field komentar
class _CommentInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isPosting;
  final VoidCallback onPost;

  const _CommentInputField({
    required this.controller,
    required this.isPosting,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(top: BorderSide(color: Colors.grey[850]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
                filled: false,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          isPosting
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              : IconButton(
                  icon: Icon(EvaIcons.paperPlane, color: Theme.of(context).colorScheme.primary),
                  onPressed: onPost,
                ),
        ],
      ),
    );
  }
}