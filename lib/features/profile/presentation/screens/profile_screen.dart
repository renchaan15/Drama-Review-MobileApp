// lib/features/profile/presentation/screens/profile_screen.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drama_review_app/core/models/review_model.dart';
import 'package:drama_review_app/core/providers/database_providers.dart';
import 'package:drama_review_app/core/providers/tmdb_providers.dart';
import 'package:drama_review_app/features/auth/providers/auth_providers.dart';
import 'package:drama_review_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:drama_review_app/features/drama_details/presentation/screens/drama_details_screen.dart';
import 'package:drama_review_app/features/drama_details/presentation/screens/review_comments_screen.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickAndUploadImage(WidgetRef ref, BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final file = File(image.path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading picture...'))
      );
      try {
        await ref.read(databaseServiceProvider).uploadProfilePicture(file);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!'))
        );
        ref.invalidate(userProfileProvider);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    return userProfileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              actions: [
                IconButton(
                  icon: const Icon(EvaIcons.settings2Outline),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(EvaIcons.logOutOutline),
                  tooltip: 'Logout',
                  onPressed: () => ref.read(authServiceProvider).logout(),
                ),
              ],
            ),
            body: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Theme.of(context).primaryColor.withValues(alpha : 0.1), Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: () => _pickAndUploadImage(ref, context),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: user.photoUrl != null 
                                ? CachedNetworkImageProvider(user.photoUrl!) 
                                : null,
                              child: user.photoUrl == null 
                                ? Icon(EvaIcons.personOutline, size: 60, color: Colors.grey[300]) 
                                : null,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(EvaIcons.camera, size: 18, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        user.username,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Stats
                      const _UserStats(),
                    ],
                  ),
                ),
                // TabBar
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: const TabBar(
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(text: 'Reviews'),
                      Tab(text: 'Watchlist'),
                    ],
                  ),
                ),
                // TabBarView
                const Expanded(
                  child: TabBarView(
                    children: [
                      _MyReviewsList(),
                      _MyWatchlistGrid(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserStats extends ConsumerWidget {
  const _UserStats();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsCount = ref.watch(myReviewsProvider).asData?.value.length ?? 0;
    final watchlistCount = ref.watch(myWatchlistProvider).asData?.value.length ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(count: reviewsCount, label: 'Reviews'),
          Container(width: 1, height: 40, color: Colors.grey[800]),
          _StatItem(count: watchlistCount, label: 'Watchlist'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  const _StatItem({required this.count, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

class _MyReviewsList extends ConsumerWidget {
  const _MyReviewsList();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReviewsAsync = ref.watch(myReviewsProvider);
    return myReviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Center(child: Text('Could not load reviews')),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(EvaIcons.edit2Outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No reviews yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your thoughts on dramas you\'ve watched',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _MyReviewCard(review: reviews[index]);
          },
        );
      },
    );
  }
}

class _MyReviewCard extends ConsumerWidget {
  final Review review;
  const _MyReviewCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dramaAsync = ref.watch(dramaInfoProvider(review.tmdbId));
    
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drama Info
          dramaAsync.when(
            data: (drama) => InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DramaDetailScreen(dramaId: drama.id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Poster
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: drama.fullPosterPath,
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          width: 60,
                          height: 80,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drama.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                review.rating.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Drama ID: ${review.tmdbId}'),
            ),
          ),
          const Divider(height: 1),
          // Review Text
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              review.reviewText,
              style: const TextStyle(height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(EvaIcons.heart, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(review.likeCount.toString()),
                const SizedBox(width: 16),
                Icon(EvaIcons.messageSquare, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(review.commentCount.toString()),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewCommentsScreen(review: review),
                      ),
                    );
                  },
                  child: const Text('View'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    // Delete logic
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyWatchlistGrid extends ConsumerWidget {
  const _MyWatchlistGrid();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWatchlistAsync = ref.watch(myWatchlistProvider);
    return myWatchlistAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Center(child: Text('Could not load watchlist')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(EvaIcons.bookmarkOutline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Your watchlist is empty',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add dramas to your watchlist to see them here',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 9 / 16,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DramaDetailScreen(dramaId: items[index].id),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha : 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: items[index].fullPosterPath,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}