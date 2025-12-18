// lib/core/providers/tmdb_providers.dart

import 'package:drama_review_app/core/models/drama_model.dart';
import 'package:drama_review_app/core/services/tmdb_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drama_review_app/core/models/cast_member_model.dart';
import 'package:drama_review_app/core/models/genre_with_image_model.dart';
import 'package:drama_review_app/core/models/drama_detail_model.dart';
import 'package:drama_review_app/core/models/video_trailer_model.dart';

// 1. Provider untuk TmdbService
final tmdbServiceProvider = Provider<TmdbService>((ref) {
  final apiKey = dotenv.env['TMDB_API_KEY'];
  if (apiKey == null) {
    throw Exception('TMDB_API_KEY not found in .env file');
  }
  return TmdbService(apiKey: apiKey);
});

// 2. FutureProvider untuk mengambil data drama rating tertinggi
// FutureProvider sangat ideal untuk panggilan API satu kali.
// Ia menangani state loading, error, dan data secara otomatis, serta melakukan caching.
final topRatedDramasProvider = FutureProvider<List<Drama>>((ref) {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return tmdbService.getTopRatedDramas();
});

// 3. FutureProvider untuk mengambil data drama yang sedang tayang
final onAirDramasProvider = FutureProvider<List<Drama>>((ref) {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return tmdbService.getOnAirDramas();
});

// 4. Provider 'family' untuk detail drama
// .family memungkinkan kita untuk meneruskan parameter (dalam hal ini, int dramaId)
// .autoDispose akan secara otomatis menghapus state provider saat layarnya tidak lagi digunakan
final dramaDetailProvider = FutureProvider.autoDispose.family<DramaDetail, int>((ref, dramaId) {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return tmdbService.getDramaDetails(dramaId);
});

// Provider untuk daftar genre
final genreListProvider = FutureProvider.autoDispose<List<Genre>>((ref) {
  return ref.watch(tmdbServiceProvider).getGenres();
});

// Provider family untuk drama berdasarkan genre
final dramasByGenreProvider = FutureProvider.autoDispose.family<List<Drama>, int>((ref, genreId) {
  return ref.watch(tmdbServiceProvider).getDramasByGenre(genreId);
});

// Provider family untuk pencarian drama
final searchDramasProvider = FutureProvider.autoDispose.family<List<Drama>, String>((ref, query) {
  return ref.watch(tmdbServiceProvider).searchDramas(query);
});

// Provider family untuk cast drama
final dramaCastProvider = FutureProvider.autoDispose.family<List<CastMember>, int>((ref, dramaId) {
  return ref.watch(tmdbServiceProvider).getDramaCast(dramaId);
});

// Provider baru yang cerdas untuk genre dengan gambar
final genresWithImagesProvider = FutureProvider.autoDispose<List<GenreWithImage>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);

  // Langkah 1: Ambil semua genre
  final genres = await tmdbService.getGenres();

  // Langkah 2: Untuk setiap genre, siapkan permintaan untuk mengambil 1 drama populer
  final imageFutures = genres.map((genre) async {
    // Ambil daftar drama untuk genre ini
    final dramas = await tmdbService.getDramasByGenre(genre.id);
    // Ambil URL gambar dari drama pertama, atau gunakan placeholder jika tidak ada
    final imageUrl = dramas.isNotEmpty
    ? dramas.first.fullPosterPath
    : 'https://via.placeholder.com/300x169.png?text=Not+Found';
    return GenreWithImage(genre: genre, imageUrl: imageUrl);
  }).toList();

  // Langkah 3: Jalankan semua permintaan gambar secara paralel dan tunggu hasilnya
  final genresWithImages = await Future.wait(imageFutures);
  return genresWithImages;
});

// Provider untuk drama populer
final popularDramasProvider = FutureProvider.autoDispose<List<Drama>>((ref) {
  return ref.watch(tmdbServiceProvider).getPopularDramas();
});

// Provider kecil untuk mengambil info dasar sebuah drama berdasarkan ID
// Ini akan sangat berguna di banyak tempat.
final dramaInfoProvider = FutureProvider.autoDispose.family<Drama, int>((ref, dramaId) {
  // Kita bisa membuat metode baru di service, atau sederhananya seperti ini:
  final tmdbService = ref.watch(tmdbServiceProvider);
  // Kita pakai getDramaDetails dan ubah sedikit hasilnya agar cocok dengan model Drama
  return tmdbService.getDramaDetails(dramaId).then(
        (details) => Drama(
          id: details.id,
          name: details.name,
          overview: details.overview,
          posterPath: details.posterPath,
          voteAverage: details.voteAverage,
        ),
      );
});

// --- 2. TAMBAHKAN PROVIDER BARU INI ---
final dramaTrailerProvider = FutureProvider.autoDispose.family<VideoTrailer?, int>((ref, dramaId) {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return tmdbService.getDramaTrailer(dramaId);
});