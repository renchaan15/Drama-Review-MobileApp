// lib/core/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drama_review_app/core/models/drama_detail_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drama_review_app/core/models/review_model.dart';
import 'package:drama_review_app/core/models/user_profile_model.dart';
import 'package:drama_review_app/core/models/watchlist_item_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:drama_review_app/core/models/comment_model.dart';
import 'package:drama_review_app/core/models/forum_post_model.dart'; // <-- IMPORT BARU
import 'package:drama_review_app/core/models/forum_thread_model.dart';
import 'package:drama_review_app/core/models/drama_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DatabaseService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  DatabaseService(this._db, this._auth);

  String? get _userId => _auth.currentUser?.uid;

  // --- WATCHLIST METHODS ---

  Future<void> addToWatchlist(DramaDetail drama) async {
    if (_userId == null) throw Exception("User not logged in");
    await _db.collection('users').doc(_userId).collection('watchlist').doc(drama.id.toString()).set({
      'addedAt': Timestamp.now(),
      'dramaTitle': drama.name, // Denormalized data
      'posterPath': drama.posterPath, // Denormalized data
    });
  }

  Future<void> removeFromWatchlist(int dramaId) async {
    if (_userId == null) throw Exception("User not logged in");
    await _db.collection('users').doc(_userId).collection('watchlist').doc(dramaId.toString()).delete();
  }

  Stream<bool> isDramaInWatchlist(int dramaId) {
    if (_userId == null) return Stream.value(false);
    return _db
        .collection('users')
        .doc(_userId)
        .collection('watchlist')
        .doc(dramaId.toString())
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // --- REVIEW METHODS (DIPERBARUI) ---
  Stream<List<Review>> getDramaReviews(int dramaId) {
    return _db
        .collection('reviews')
        .where('tmdbId', isEqualTo: dramaId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }

  Future<void> postReview({
    required int tmdbId,
    required double rating,
    required String reviewText,
  }) async {
    if (_userId == null) throw Exception("User not logged in");
    final userDoc = await _db.collection('users').doc(_userId).get();
    if (!userDoc.exists || userDoc.data() == null) {
      throw Exception("User profile not found.");
    }
    final username = userDoc.data()!['username'] as String;
    final photoUrl = userDoc.data()!['photoUrl'] as String?;

    await _db.collection('reviews').add({
      'userId': _userId,
      'username': username,
      'photoUrl': photoUrl,
      'tmdbId': tmdbId,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': Timestamp.now(),
      'likedBy': [], // <-- 2. TAMBAHKAN FIELD BARU
      'commentCount': 0, // <-- 2. TAMBAHKAN FIELD BARU
    });
  }

  Future<void> deleteReview(String reviewId) async {
    // Kita juga harus menghapus semua sub-koleksi komentar
    final comments = await _db.collection('reviews').doc(reviewId).collection('comments').get();
    for (var doc in comments.docs) {
      doc.reference.delete();
    }
    await _db.collection('reviews').doc(reviewId).delete();
  }

  // --- 3. METODE "LIKE" BARU ---
  Future<void> toggleLikeReview(String reviewId) async {
    if (_userId == null) throw Exception("User not logged in");
    final reviewRef = _db.collection('reviews').doc(reviewId);

    final doc = await reviewRef.get();
    if (!doc.exists) return;

    final review = Review.fromFirestore(doc);
    if (review.isLikedBy(_userId!)) {
      // Jika sudah suka (unlike)
      await reviewRef.update({
        'likedBy': FieldValue.arrayRemove([_userId])
      });
    } else {
      // Jika belum suka (like)
      await reviewRef.update({
        'likedBy': FieldValue.arrayUnion([_userId])
      });
    }
  }

  // --- 4. METODE "COMMENT" BARU ---
  Stream<List<Comment>> getCommentsForReview(String reviewId) {
    return _db
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .orderBy('createdAt', descending: false) // Komentar diurutkan dari lama ke baru
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList());
  }

  Future<void> addCommentToReview(String reviewId, String commentText) async {
    if (_userId == null) throw Exception("User not logged in");

    // Ambil info pengguna saat ini
    final userDoc = await _db.collection('users').doc(_userId).get();
    if (!userDoc.exists || userDoc.data() == null) throw Exception("User profile not found.");
    final username = userDoc.data()!['username'] as String;
    final photoUrl = userDoc.data()!['photoUrl'] as String?;

    // Referensi ke dokumen komentar baru dan review
    final commentRef = _db.collection('reviews').doc(reviewId).collection('comments').doc();
    final reviewRef = _db.collection('reviews').doc(reviewId);

    // Gunakan batch write untuk operasi atomik
    WriteBatch batch = _db.batch();

    // 1. Buat dokumen komentar baru
    batch.set(commentRef, {
      'userId': _userId,
      'username': username,
      'photoUrl': photoUrl,
      'commentText': commentText,
      'createdAt': Timestamp.now(),
    });

    // 2. Tambah jumlah commentCount di dokumen review
    batch.update(reviewRef, {
      'commentCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> deleteComment(String reviewId, String commentId) async {
    if (_userId == null) throw Exception("User not logged in");

    // (Opsional: Tambahkan logika untuk mengecek apakah user adalah pemilik komentar)
    final commentRef = _db.collection('reviews').doc(reviewId).collection('comments').doc(commentId);
    final reviewRef = _db.collection('reviews').doc(reviewId);

    WriteBatch batch = _db.batch();
    batch.delete(commentRef);
    batch.update(reviewRef, {'commentCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<UserProfile> getUserProfile() async {
    if (_userId == null) throw Exception("User not logged in");
    final userDoc = await _db.collection('users').doc(_userId).get();
    if (!userDoc.exists) throw Exception("User profile not found");
    // Email diambil dari Auth karena lebih terjamin
    return UserProfile.fromFirestore(userDoc, _auth.currentUser!.email!);
  }

  Stream<List<Review>> getMyReviews() {
    if (_userId == null) return Stream.value([]);
    return _db
        .collection('reviews')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }

  Stream<List<WatchlistItem>> getMyWatchlist() {
    if (_userId == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_userId)
        .collection('watchlist')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WatchlistItem.fromFirestore(doc)).toList());
  }

  // --- REVIEW METHODS (Lanjutan) ---
  
    // --- PROFILE METHODS (Lanjutan) ---
  Future<void> uploadProfilePicture(File imageFile) async {
    if (_userId == null) throw Exception("User not logged in");
    try {
      // 1. Tentukan path di Firebase Storage
      final ref = _storage.ref().child('profile_pictures').child(_userId!);
      
      // 2. Unggah file
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => {});
      
      // 3. Dapatkan URL download
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // 4. Perbarui dokumen pengguna di Firestore
      await _db.collection('users').doc(_userId).update({'photoUrl': downloadUrl});
    } catch (e) {
      throw Exception("Error uploading profile picture: $e");
    }
  }

  // --- METODE BARU YANG MEGAH UNTUK PENGATURAN ---
  Future<void> updateUsername(String newUsername) async {
    if (_userId == null) throw Exception("User not logged in");
    
    // Kita gunakan batch write untuk operasi atomik
    final batch = _db.batch();
    
    // 1. Perbarui dokumen user utama
    final userRef = _db.collection('users').doc(_userId);
    batch.update(userRef, {'username': newUsername});

    // 2. Perbarui semua 'review' yang ditulis oleh user ini
    // Ini adalah denormalisasi yang kuat, memastikan review lama ikut terupdate
    final reviewsQuery = await _db.collection('reviews').where('userId', isEqualTo: _userId).get();
    for (final doc in reviewsQuery.docs) {
      batch.update(doc.reference, {'username': newUsername});
    }

    // 3. Perbarui semua 'komentar' yang ditulis oleh user ini
    // Ini adalah query yang mahal, tapi penting untuk konsistensi
    final allReviews = await _db.collection('reviews').get();
    for (final reviewDoc in allReviews.docs) {
      final commentsQuery = await reviewDoc.reference.collection('comments').where('userId', isEqualTo: _userId).get();
      for (final commentDoc in commentsQuery.docs) {
        batch.update(commentDoc.reference, {'username': newUsername});
      }
    }
    
    // Jalankan semua pembaruan sekaligus
    await batch.commit();
  }

  // --- METODE BARU YANG MEGAH: FORUM ---

// Update metode ini:
  Future<void> createNewThread(String title, String content, {Drama? attachedDrama}) async {
    if (_userId == null) throw Exception("User not logged in");
    
    final userDoc = await _db.collection('users').doc(_userId).get();
    if (!userDoc.exists || userDoc.data() == null) throw Exception("User profile not found.");
    final username = userDoc.data()!['username'] as String;
    final photoUrl = userDoc.data()!['photoUrl'] as String?;
    
    final now = Timestamp.now();

    // Siapkan data dasar
    final Map<String, dynamic> threadData = {
      'title': title,
      'content': content,
      'userId': _userId,
      'username': username,
      'userPhotoUrl': photoUrl,
      'createdAt': now,
      'latestReplyAt': now,
      'replyCount': 0,
    };

    // Jika ada lampiran, tambahkan ke data
    if (attachedDrama != null) {
      threadData['attachedTmdbId'] = attachedDrama.id;
      threadData['attachedDramaTitle'] = attachedDrama.name;
      threadData['attachedPosterPath'] = attachedDrama.posterPath;
    }

    await _db.collection('forum_threads').add(threadData);
  }

  // Mengambil Semua Topik Diskusi
  Stream<List<ForumThread>> getAllThreads() {
    return _db
        .collection('forum_threads')
        .orderBy('latestReplyAt', descending: true) // Urutkan berdasarkan aktivitas terakhir
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ForumThread.fromFirestore(doc)).toList());
  }

  // Mengambil Semua Balasan untuk Satu Topik
  Stream<List<ForumPost>> getPostsForThread(String threadId) {
    return _db
        .collection('forum_threads')
        .doc(threadId)
        .collection('posts')
        .orderBy('createdAt', descending: false) // Balasan diurutkan dari lama ke baru
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ForumPost.fromFirestore(doc)).toList());
  }

// PERBARUI METHOD INI
  Future<void> postReplyToThread(String threadId, String postText, {Drama? attachedDrama}) async {
    if (_userId == null) throw Exception("User not logged in");
    
    final userDoc = await _db.collection('users').doc(_userId).get();
    if (!userDoc.exists || userDoc.data() == null) throw Exception("User profile not found.");
    final username = userDoc.data()!['username'] as String;
    final photoUrl = userDoc.data()!['photoUrl'] as String?;

    final threadRef = _db.collection('forum_threads').doc(threadId);
    final postRef = threadRef.collection('posts').doc();
    final now = Timestamp.now();

    WriteBatch batch = _db.batch();

    // Siapkan data post
    final Map<String, dynamic> postData = {
      'userId': _userId,
      'username': username,
      'userPhotoUrl': photoUrl,
      'postText': postText,
      'createdAt': now,
    };

    // Jika ada lampiran, tambahkan ke post
    if (attachedDrama != null) {
      postData['attachedTmdbId'] = attachedDrama.id;
      postData['attachedDramaTitle'] = attachedDrama.name;
      postData['attachedPosterPath'] = attachedDrama.posterPath;
    }

    batch.set(postRef, postData);

    batch.update(threadRef, {
      'replyCount': FieldValue.increment(1),
      'latestReplyAt': now,
    });

    await batch.commit();
  }

  // --- 5. METODE BARU: HAPUS THREAD ---
  Future<void> deleteThread(String threadId) async {
    if (_userId == null) throw Exception("User not logged in");
    // Untuk simplisitas, kita hanya menghapus dokumen thread utama.
    // Idealnya menggunakan Cloud Function untuk menghapus sub-koleksi 'posts' secara rekursif.
    await _db.collection('forum_threads').doc(threadId).delete();
  }

  // --- 6. METODE BARU: HAPUS BALASAN FORUM ---
  Future<void> deleteForumPost(String threadId, String postId) async {
    if (_userId == null) throw Exception("User not logged in");
    final threadRef = _db.collection('forum_threads').doc(threadId);
    final postRef = threadRef.collection('posts').doc(postId);

    WriteBatch batch = _db.batch();
    batch.delete(postRef);
    // Kurangi jumlah balasan
    batch.update(threadRef, {'replyCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  // Simpan FCM Token ke dokumen User
  Future<void> saveUserToken() async {
    if (_userId == null) return;

    // Dapatkan token
    String? token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    // Simpan ke Firestore dalam array 'fcmTokens' 
    // (Array digunakan jika user login di banyak HP)
    await _db.collection('users').doc(_userId).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }
  
  // Hapus token saat logout (Penting agar tidak kirim notif ke HP yang sudah logout)
  Future<void> removeUserToken() async {
    if (_userId == null) return;
    String? token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await _db.collection('users').doc(_userId).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }
}