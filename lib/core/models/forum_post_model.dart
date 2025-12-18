// lib/core/models/forum_post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPost {
  final String id;
  final String userId;
  final String username;
  final String userPhotoUrl;
  final String postText;
  final Timestamp createdAt;
  
  // Field Lampiran Drama (Opsional)
  final int? attachedTmdbId;
  final String? attachedDramaTitle;
  final String? attachedPosterPath;

  ForumPost({
    required this.id,
    required this.userId,
    required this.username,
    required this.userPhotoUrl,
    required this.postText,
    required this.createdAt,
    this.attachedTmdbId,
    this.attachedDramaTitle,
    this.attachedPosterPath,
  });

  factory ForumPost.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ForumPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      postText: data['postText'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      attachedTmdbId: data['attachedTmdbId'],
      attachedDramaTitle: data['attachedDramaTitle'],
      attachedPosterPath: data['attachedPosterPath'],
    );
  }

  String? get attachedFullPosterPath {
    if (attachedPosterPath != null) {
      return 'https://image.tmdb.org/t/p/w200$attachedPosterPath';
    }
    return null;
  }
}