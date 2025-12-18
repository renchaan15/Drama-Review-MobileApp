// lib/core/models/video_trailer_model.dart

class VideoTrailer {
  final String key; // Ini adalah ID video YouTube
  final String site;
  final String type;

  VideoTrailer({required this.key, required this.site, required this.type});

  factory VideoTrailer.fromJson(Map<String, dynamic> json) {
    return VideoTrailer(
      key: json['key'],
      site: json['site'],
      type: json['type'],
    );
  }

  // --- TAMBAHAN BARU: Getter untuk Thumbnail ---
  String get youtubeThumbnailUrl {
    // Menggunakan 'maxresdefault' untuk kualitas gambar thumbnail tertinggi
    return 'https://img.youtube.com/vi/$key/maxresdefault.jpg';
  }
}