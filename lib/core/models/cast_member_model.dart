// lib/core/models/cast_member_model.dart

class CastMember {
  final String name;
  final String character;
  final String? profilePath;

  CastMember({
    required this.name,
    required this.character,
    this.profilePath,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      name: json['name'],
      character: json['character'],
      profilePath: json['profile_path'],
    );
  }

  String get fullProfilePath {
    if (profilePath != null) {
      return 'https://image.tmdb.org/t/p/w185$profilePath';
    }
    return 'https://via.placeholder.com/185x278.png?text=No+Image';
  }
}