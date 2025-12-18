// lib/core/models/drama_detail_model.dart

import 'package:drama_review_app/core/models/drama_model.dart';

// Model kecil untuk genre
class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: json['id'], name: json['name']);
  }
}

// Model utama untuk detail drama
class DramaDetail extends Drama {
  final String? backdropPath;
  final List<Genre> genres;
  final int numberOfEpisodes;
  final int numberOfSeasons;

  DramaDetail({
    required super.id,
    required super.name,
    required super.overview,
    required super.posterPath,
    required super.voteAverage,
    this.backdropPath,
    required this.genres,
    required this.numberOfEpisodes,
    required this.numberOfSeasons,
  });

  factory DramaDetail.fromJson(Map<String, dynamic> json) {
    return DramaDetail(
      id: json['id'],
      name: json['name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      voteAverage: json['vote_average'].toDouble(),
      backdropPath: json['backdrop_path'],
      genres: (json['genres'] as List).map((g) => Genre.fromJson(g)).toList(),
      numberOfEpisodes: json['number_of_episodes'],
      numberOfSeasons: json['number_of_seasons'],
    );
  }

  String get fullBackdropPath {
    if (backdropPath != null) {
      return 'https://image.tmdb.org/t/p/w1280$backdropPath';
    }
    // Jika tidak ada backdrop, gunakan poster sebagai fallback
    return fullPosterPath;
  }
}