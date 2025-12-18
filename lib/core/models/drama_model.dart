// lib/core/models/drama_model.dart

class Drama {
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final double voteAverage;

  Drama({
    required this.id,
    required this.name,
    required this.overview,
    this.posterPath,
    required this.voteAverage,
  });

  // Factory constructor untuk membuat instance Drama dari JSON map
  factory Drama.fromJson(Map<String, dynamic> json) {
    return Drama(
      id: json['id'],
      name: json['name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      voteAverage: json['vote_average'].toDouble(),
    );
  }

  // Helper getter untuk mendapatkan URL gambar poster lengkap
  String get fullPosterPath {
    if (posterPath != null) {
      return 'https://image.tmdb.org/t/p/w500$posterPath';
    }
    // Return placeholder image jika tidak ada poster
    return 'https://via.placeholder.com/500x750.png?text=No+Image';
  }

  // Helper getter untuk mendapatkan URL gambar backdrop lengkap
  String get fullBackdropPath {
    if (posterPath != null) {
      return 'https://image.tmdb.org/t/p/w780$posterPath';
    }
    // Return placeholder image jika tidak ada backdrop
    return 'https://via.placeholder.com/780x439.png?text=No+Image';
  }
}