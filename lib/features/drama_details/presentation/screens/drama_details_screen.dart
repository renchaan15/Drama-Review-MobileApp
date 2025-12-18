// lib/features/drama_details/presentation/screens/drama_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drama_review_app/core/models/cast_member_model.dart';
import 'package:drama_review_app/core/models/drama_detail_model.dart';
import 'package:drama_review_app/core/providers/database_providers.dart';
import 'package:drama_review_app/core/providers/firebase_providers.dart';
import 'package:drama_review_app/core/providers/tmdb_providers.dart';
import 'package:drama_review_app/features/drama_details/presentation/screens/review_comments_screen.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';

class DramaDetailScreen extends ConsumerWidget {
  final int dramaId;
  const DramaDetailScreen({super.key, required this.dramaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dramaDetailAsync = ref.watch(dramaDetailProvider(dramaId));

    return Scaffold(
      body: dramaDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (drama) {
          return CustomScrollView(
            slivers: [
              _HeaderSection(drama: drama),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TitleAndInfoSection(drama: drama),
                    _ActionBar(drama: drama),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(title: 'Synopsis'),
                          ReadMoreText(
                            drama.overview,
                            trimLines: 4,
                            colorClickableText: Theme.of(context).colorScheme.primary,
                            trimMode: TrimMode.Line,
                            trimCollapsedText: '...read more',
                            trimExpandedText: ' show less',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400], height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          _TrailerPreview(dramaId: drama.id),
                          _CastSection(dramaId: drama.id),
                          const SizedBox(height: 24),
                          _SectionHeader(title: 'Reviews'),
                          _ReviewSection(dramaId: drama.id), // <-- PERUBAHAN ADA DI DALAM SINI
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final DramaDetail drama;
  const _HeaderSection({required this.drama});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: drama.fullBackdropPath,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleAndInfoSection extends StatelessWidget {
  final DramaDetail drama;
  const _TitleAndInfoSection({required this.drama});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Card(
              elevation: 12,
              shadowColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(imageUrl: drama.fullPosterPath, fit: BoxFit.cover, width: 130, height: 180),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    drama.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [const Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: drama.genres.take(3).map((genre) => Text(
                      genre.name,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  final DramaDetail drama;
  const _ActionBar({required this.drama});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rating', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Row(
                children: [
                  Icon(EvaIcons.star, color: Theme.of(context).colorScheme.primary, size: 24),
                  const SizedBox(width: 4),
                  Text(drama.voteAverage.toStringAsFixed(1), style: Theme.of(context).textTheme.titleLarge),
                  Text('/10', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Tombol Trailer telah dihapus dari sini
              _WatchlistButton(drama: drama),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) => _WriteReviewSheet(dramaId: drama.id),
                  );
                },
                icon: const Icon(EvaIcons.edit2Outline, size: 28),
                tooltip: 'Write a Review',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- PERBAIKAN UTAMA ADA DI SINI: _WatchlistButton ---
class _WatchlistButton extends ConsumerWidget {
  final DramaDetail drama;
  const _WatchlistButton({required this.drama});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistStatus = ref.watch(watchlistStatusProvider(drama.id));
    final dbService = ref.read(databaseServiceProvider);

    return watchlistStatus.when(
      data: (isInWatchlist) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: isInWatchlist
              // --- STATE 2: SUDAH DISIMPAN ---
              // Icon solid, berwarna Emas (primary)
              ? IconButton(
                  key: const ValueKey('in_watchlist'),
                  onPressed: () => dbService.removeFromWatchlist(drama.id),
                  icon: Icon(EvaIcons.bookmark), // Icon "bookmark" solid
                  color: Theme.of(context).colorScheme.primary, // Warna emas
                  iconSize: 28,
                  tooltip: 'Saved in Watchlist',
                )
              // --- STATE 1: BELUM DISIMPAN ---
              // Icon outline, berwarna standar (putih/abu-abu)
              : IconButton(
                  key: const ValueKey('not_in_watchlist'),
                  onPressed: () => dbService.addToWatchlist(drama),
                  icon: Icon(EvaIcons.bookmarkOutline), // Icon "bookmark" outline
                  iconSize: 28,
                  tooltip: 'Save to Watchlist',
                ),
        );
      },
      loading: () => const SizedBox(
        width: 48, // Ukuran standar IconButton
        height: 48,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, stack) => const IconButton(onPressed: null, icon: Icon(Icons.error)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _TrailerPreview extends ConsumerWidget {
  final int dramaId;
  const _TrailerPreview({required this.dramaId});

  void _playTrailer(BuildContext context, String youtubeKey) async {
    final Uri youtubeUrl = Uri.parse('https://www.youtube.com/watch?v=$youtubeKey');
    if (await canLaunchUrl(youtubeUrl)) {
      await launchUrl(youtubeUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch trailer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailerAsync = ref.watch(dramaTrailerProvider(dramaId));
    return trailerAsync.when(
      data: (trailer) {
        if (trailer == null) return const SizedBox.shrink();
        
        // Widget ini sekarang akan muncul setelah sinopsis
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0), // Beri jarak ke Cast
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Trailer'),
              GestureDetector(
                onTap: () => _playTrailer(context, trailer.key),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: trailer.youtubeThumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey[800],
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey[800],
                          child: const Icon(Icons.error, color: Colors.grey),
                        ),
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha : 0.3)),
                      ),
                      Icon(
                        EvaIcons.playCircle,
                        color: Colors.white.withValues(alpha : 0.8),
                        size: 60,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      error: (e, s) => const SizedBox.shrink(),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}


class _CastSection extends ConsumerWidget {
  final int dramaId;
  const _CastSection({required this.dramaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final castAsync = ref.watch(dramaCastProvider(dramaId));
    return castAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const SizedBox.shrink(),
      data: (cast) {
        if (cast.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Cast & Characters'),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cast.length,
                itemBuilder: (context, index) => _CastCard(castMember: cast[index]),
                separatorBuilder: (context, index) => const SizedBox(width: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CastCard extends StatelessWidget {
  final CastMember castMember;
  const _CastCard({required this.castMember});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: castMember.fullProfilePath,
              height: 120,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(castMember.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(castMember.character, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

// --- ROMBAK TOTAL _ReviewSection ---
class _ReviewSection extends ConsumerWidget {
  final int dramaId;
  const _ReviewSection({required this.dramaId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(dramaReviewsProvider(dramaId));
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Center(child: Text('Could not load reviews.')),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(child: Text('No reviews yet.'));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(child: Icon(EvaIcons.personOutline)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(review.username, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              RatingBarIndicator(
                                rating: review.rating,
                                itemBuilder: (context, index) => Icon(EvaIcons.star, color: Theme.of(context).colorScheme.primary),
                                itemCount: 5,
                                itemSize: 16.0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(review.reviewText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[300])),
                    const Divider(height: 24),
                    // --- TOMBOL AKSI BARU (SUKA & KOMENTAR) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tombol Suka
                        TextButton.icon(
                          onPressed: () {
                            if (currentUserId != null) {
                              ref.read(databaseServiceProvider).toggleLikeReview(review.id);
                            }
                          },
                          icon: Icon(
                            review.isLikedBy(currentUserId ?? '') ? EvaIcons.heart : EvaIcons.heartOutline,
                            color: review.isLikedBy(currentUserId ?? '') ? Colors.red : Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(review.likeCount.toString(), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ),
                        // Tombol Komentar
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ReviewCommentsScreen(review: review)),
                            );
                          },
                          icon: Icon(EvaIcons.messageSquareOutline, color: Colors.grey[400]),
                          label: Text(review.commentCount.toString(), style: TextStyle(color: Colors.grey[400])),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WriteReviewSheet extends ConsumerStatefulWidget {
  final int dramaId;
  const _WriteReviewSheet({required this.dramaId});
  @override
  ConsumerState<_WriteReviewSheet> createState() => __WriteReviewSheetState();
}

class __WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  double _rating = 3.0;
  final _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReview() async {
     if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review text cannot be empty.')),
      );
      return;
    }
    setState(() { _isLoading = true; });
    try {
      await ref.read(databaseServiceProvider).postReview(
        tmdbId: widget.dramaId,
        rating: _rating,
        reviewText: _textController.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post review: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 24),
          Text('Write Your Review', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 0.5,
            allowHalfRating: true,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => Icon(EvaIcons.star, color: Theme.of(context).colorScheme.primary),
            onRatingUpdate: (rating) => setState(() => _rating = rating),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Your review',
              alignLabelWithHint: true,
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _submitReview, child: const Text('Submit Review')),
          ),
        ],
      ),
    );
  }
}