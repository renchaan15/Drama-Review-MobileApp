// lib/features/home/presentation/screens/see_all_screen.dart

import 'package:drama_review_app/core/models/category_type.dart';
import 'package:drama_review_app/core/providers/tmdb_providers.dart';
import 'package:drama_review_app/shared_widgets/drama_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SeeAllScreen extends ConsumerWidget {
  final String title;
  final CategoryType categoryType;

  const SeeAllScreen({
    super.key,
    required this.title,
    required this.categoryType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dengan cerdas memilih provider mana yang akan digunakan berdasarkan categoryType
    final dramasAsyncProvider = switch (categoryType) {
      CategoryType.onAir => onAirDramasProvider,
      CategoryType.popular => popularDramasProvider,
      CategoryType.topRated => topRatedDramasProvider,
    };

    final dramasAsync = ref.watch(dramasAsyncProvider);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: dramasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (dramas) {
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2 / 3.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: dramas.length,
            itemBuilder: (context, index) {
              return DramaCard(drama: dramas[index]);
            },
          );
        },
      ),
    );
  }
}