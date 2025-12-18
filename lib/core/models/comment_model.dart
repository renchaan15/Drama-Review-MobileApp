// lib/core/models/comment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String username;
  final String photoUrl;
  final String commentText;
  final Timestamp createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.photoUrl,
    required this.commentText,
    required this.createdAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      photoUrl: data['photoUrl'] ?? '', // Kita simpan photoUrl untuk tampilan
      commentText: data['commentText'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}