// lib/core/providers/database_providers.dart

import 'package:drama_review_app/core/providers/firebase_providers.dart';
import 'package:drama_review_app/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drama_review_app/core/models/review_model.dart';
import 'package:drama_review_app/core/models/user_profile_model.dart';
import 'package:drama_review_app/core/models/watchlist_item_model.dart';
import 'package:drama_review_app/core/models/comment_model.dart';
import 'package:drama_review_app/core/models/forum_post_model.dart'; // <-- IMPORT BARU
import 'package:drama_review_app/core/models/forum_thread_model.dart';

// Provider untuk DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final firestore = ref.watch(firestoreProvider); // Asumsi firestoreProvider sudah ada
  final auth = ref.watch(firebaseAuthProvider);
  return DatabaseService(firestore, auth);
});

// StreamProvider 'family' untuk status watchlist
// Ini akan secara reaktif memberi tahu UI apakah sebuah drama ada di watchlist atau tidak
final watchlistStatusProvider = StreamProvider.autoDispose.family<bool, int>((ref, dramaId) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.isDramaInWatchlist(dramaId);
});

// StreamProvider 'family' untuk daftar review
final dramaReviewsProvider = StreamProvider.autoDispose.family<List<Review>, int>((ref, dramaId) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getDramaReviews(dramaId);
});

// Provider untuk profil pengguna
final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getUserProfile();
});

// Provider untuk daftar review pengguna
final myReviewsProvider = StreamProvider.autoDispose<List<Review>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getMyReviews();
});

// Provider untuk daftar watchlist pengguna
final myWatchlistProvider = StreamProvider.autoDispose<List<WatchlistItem>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getMyWatchlist();
});

// --- 2. PROVIDER BARU UNTUK KOMENTAR ---
final reviewCommentsProvider = StreamProvider.autoDispose.family<List<Comment>, String>((ref, reviewId) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getCommentsForReview(reviewId);
});

// Provider untuk mengambil semua topik diskusi
final allThreadsProvider = StreamProvider.autoDispose<List<ForumThread>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getAllThreads();
});

// Provider untuk mengambil semua balasan dari satu topik
final threadPostsProvider = StreamProvider.autoDispose.family<List<ForumPost>, String>((ref, threadId) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getPostsForThread(threadId);
});