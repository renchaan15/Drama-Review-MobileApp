// lib/core/models/genre_with_image_model.dart

import 'package:drama_review_app/core/models/drama_detail_model.dart';

class GenreWithImage {
  final Genre genre;
  final String imageUrl;

  GenreWithImage({required this.genre, required this.imageUrl});
}