// lib/core/models/forum_thread_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ForumThread {
  final String id;
  final String title;
  final String content;
  final String userId;
  final String username;
  final String userPhotoUrl;
  final Timestamp createdAt;
  final Timestamp latestReplyAt;
  final int replyCount;
  
  // Field Lampiran (Nullable)
  final int? attachedTmdbId;
  final String? attachedDramaTitle;
  final String? attachedPosterPath;

  ForumThread({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.username,
    required this.userPhotoUrl,
    required this.createdAt,
    required this.latestReplyAt,
    required this.replyCount,
    this.attachedTmdbId,
    this.attachedDramaTitle,
    this.attachedPosterPath,
  });

  factory ForumThread.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ForumThread(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      latestReplyAt: data['latestReplyAt'] ?? Timestamp.now(),
      replyCount: data['replyCount'] ?? 0,
      attachedTmdbId: data['attachedTmdbId'],
      attachedDramaTitle: data['attachedDramaTitle'],
      attachedPosterPath: data['attachedPosterPath'],
    );
  }

  // Helper untuk mendapatkan full poster URL
  String? get attachedFullPosterPath {
    if (attachedPosterPath != null) {
      return 'https://image.tmdb.org/t/p/w200$attachedPosterPath'; // Ukuran kecil cukup
    }
    return null;
  }
}