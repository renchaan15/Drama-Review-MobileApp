// lib/core/models/watchlist_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class WatchlistItem {
  final int id;
  final String dramaTitle;
  final String? posterPath;
  final Timestamp addedAt;

  WatchlistItem({
    required this.id,
    required this.dramaTitle,
    this.posterPath,
    required this.addedAt,
  });

  factory WatchlistItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return WatchlistItem(
      id: int.parse(doc.id), // ID dokumen adalah tmdbId
      dramaTitle: data['dramaTitle'] ?? '',
      posterPath: data['posterPath'],
      addedAt: data['addedAt'] ?? Timestamp.now(),
    );
  }

  String get fullPosterPath {
    if (posterPath != null) {
      return 'https://image.tmdb.org/t/p/w500$posterPath';
    }
    return 'https://via.placeholder.com/500x750.png?text=No+Image';
  }
}