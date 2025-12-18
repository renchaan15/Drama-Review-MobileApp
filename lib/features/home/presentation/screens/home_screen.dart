// lib/features/home/presentation/screens/home_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drama_review_app/core/models/category_type.dart';
import 'package:drama_review_app/core/models/drama_model.dart';
import 'package:drama_review_app/core/providers/tmdb_providers.dart';
import 'package:drama_review_app/features/drama_details/presentation/screens/drama_details_screen.dart';
import 'package:drama_review_app/features/home/presentation/screens/see_all_screen.dart';
import 'package:drama_review_app/shared_widgets/drama_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topRatedAsync = ref.watch(topRatedDramasProvider);
    final onAirAsync = ref.watch(onAirDramasProvider);
    final popularAsync = ref.watch(popularDramasProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 400,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            stretch: true,
            // 1. KEMBALIKAN LOGO KE POSISI TITLE UTAMA
            title: Image.asset(
              'assets/images/splash_logo.png', // <-- PASTIKAN PATH INI BENAR
              height: 32,
            ),
            flexibleSpace: FlexibleSpaceBar(
              // 2. HAPUS PROPERTI 'title' DARI SINI
              stretchModes: const [StretchMode.zoomBackground],
              background: topRatedAsync.when(
                data: (dramas) => dramas.isNotEmpty
                    ? _FeaturedDramaHeader(drama: dramas.first)
                    : const SizedBox.shrink(),
                loading: () => const _ShimmerLoadingFeatured(),
                error: (e, s) => const Center(child: Text('Cannot load banner')),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                onAirAsync.when(
                  data: (dramas) => _HorizontalDramaList(title: 'Sedang Tayang', dramas: dramas, categoryType: CategoryType.onAir),
                  loading: () => const _ShimmerLoadingCarousel(title: 'Sedang Tayang'),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
                popularAsync.when(
                  data: (dramas) => _HorizontalDramaList(title: 'Populer', dramas: dramas, categoryType: CategoryType.popular),
                  loading: () => const _ShimmerLoadingCarousel(title: 'Populer'),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
                topRatedAsync.when(
                  data: (dramas) => _HorizontalDramaList(title: 'Rating Tertinggi', dramas: dramas.skip(1).toList(), categoryType: CategoryType.topRated),
                  loading: () => const _ShimmerLoadingCarousel(title: 'Rating Tertinggi'),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 3. PINDAHKAN SEMUA KONTEN HEADER KE DALAM BACKGROUND
class _FeaturedDramaHeader extends StatelessWidget {
  final Drama drama;
  const _FeaturedDramaHeader({required this.drama});

  @override
  Widget build(BuildContext context) {
    // Dapatkan tinggi status bar untuk padding yang akurat
    
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(imageUrl: drama.fullBackdropPath, fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha:0.6), // Gradien atas lebih gelap
                Colors.transparent,
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha:0.9),
                Theme.of(context).scaffoldBackgroundColor,
              ],
              stops: const [0.0, 0.4, 0.9, 1.0],
            ),
          ),
        ),
        // Gunakan Positioned dan Padding untuk menempatkan konten dengan benar
        Positioned(
          bottom: 24, // Beri jarak dari bawah
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drama.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [const Shadow(blurRadius: 4, color: Colors.black)],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rating: ${drama.voteAverage.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => DramaDetailScreen(dramaId: drama.id),
                  ));
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Lihat Detail'),
                style: Theme.of(context).filledButtonTheme.style?.copyWith(
                      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12, horizontal: 20)),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget-widget lain di bawah ini tidak perlu diubah
class _HorizontalDramaList extends StatelessWidget {
  final String title;
  final List<Drama> dramas;
  final CategoryType categoryType;
  const _HorizontalDramaList({
    required this.title,
    required this.dramas,
    required this.categoryType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, categoryType: categoryType),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dramas.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: SizedBox(
                  width: 140,
                  child: DramaCard(drama: dramas[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final CategoryType categoryType;
  const _SectionHeader({required this.title, required this.categoryType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeeAllScreen(
                    title: title,
                    categoryType: categoryType,
                  ),
                ),
              );
            },
            child: const Text('Lihat Semua >'),
          ),
        ],
      ),
    );
  }
}

class _ShimmerLoadingCarousel extends StatelessWidget {
  final String title;
  const _ShimmerLoadingCarousel({required this.title});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 8, 12),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 220,
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.surface,
            highlightColor: Theme.of(context).scaffoldBackgroundColor,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 140,
                    child: Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerLoadingFeatured extends StatelessWidget {
  const _ShimmerLoadingFeatured();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surface,
      highlightColor: Theme.of(context).scaffoldBackgroundColor,
      child: Container(color: Colors.black, height: 400),
    );
  }
}