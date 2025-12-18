// lib/core/services/tmdb_service.dart

import 'dart:convert';
import 'package:drama_review_app/core/models/drama_model.dart';
import 'package:drama_review_app/core/models/drama_detail_model.dart';
import 'package:http/http.dart' as http;
import 'package:drama_review_app/core/models/cast_member_model.dart';
import 'package:drama_review_app/core/models/video_trailer_model.dart';

class TmdbService {
  final String apiKey;
  final http.Client _client;

  final String _baseUrl = 'https://api.themoviedb.org/3';

  TmdbService({required this.apiKey, http.Client? client}) : _client = client ?? http.Client();

  Future<List<Drama>> getTopRatedDramas() async {
    // Endpoint untuk top rated TV shows (Korean dramas)
    final url = Uri.parse('$_baseUrl/tv/top_rated?api_key=$apiKey&with_original_language=ko&language=en-US');

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => Drama.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load top rated dramas');
    }
  }

  Future<List<Drama>> getOnAirDramas() async {
    // Endpoint untuk TV shows on the air (Korean dramas)
    final url = Uri.parse('$_baseUrl/tv/on_the_air?api_key=$apiKey&with_original_language=ko&language=en-US');

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => Drama.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load on the air dramas');
    }
  }

    Future<DramaDetail> getDramaDetails(int dramaId) async {
    final url = Uri.parse('$_baseUrl/tv/$dramaId?api_key=$apiKey&language=en-US');

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DramaDetail.fromJson(data);
    } else {
      throw Exception('Failed to load drama details');
    }
  }

    Future<List<Genre>> getGenres() async {
    final url = Uri.parse('$_baseUrl/genre/tv/list?api_key=$apiKey&language=en-US');
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['genres'];
      return results.map((e) => Genre.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load genres');
    }
  }

  Future<List<Drama>> getDramasByGenre(int genreId) async {
    final url = Uri.parse('$_baseUrl/discover/tv?api_key=$apiKey&with_genres=$genreId&with_original_language=ko');
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => Drama.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load dramas by genre');
    }
  }

    Future<List<Drama>> searchDramas(String query) async {
    final url = Uri.parse('$_baseUrl/search/tv?api_key=$apiKey&query=$query&include_adult=false&with_original_language=ko');
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => Drama.fromJson(e)).toList();
    } else {
      throw Exception('Failed to search dramas');
    }
  }

    Future<List<CastMember>> getDramaCast(int dramaId) async {
    final url = Uri.parse('$_baseUrl/tv/$dramaId/credits?api_key=$apiKey&language=en-US');
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['cast'];
      return results.map((e) => CastMember.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load cast');
    }
  }

  Future<List<Drama>> getPopularDramas() async {
    final url = Uri.parse('$_baseUrl/tv/popular?api_key=$apiKey&with_original_language=ko&language=en-US');
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => Drama.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load popular dramas');
    }
  }

  Future<VideoTrailer?> getDramaTrailer(int dramaId) async {
    final url = Uri.parse('$_baseUrl/tv/$dramaId/videos?api_key=$apiKey&language=en-US');
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      
      // Filter untuk menemukan video "Trailer" resmi di "YouTube"
      final trailers = results
          .map((e) => VideoTrailer.fromJson(e))
          .where((v) => v.type == 'Trailer' && v.site == 'YouTube')
          .toList();

      if (trailers.isNotEmpty) {
        return trailers.first; // Kembalikan trailer resmi pertama
      } else {
        return null; // Tidak ada trailer
      }
    } else {
      throw Exception('Failed to load videos');
    }
  }
}