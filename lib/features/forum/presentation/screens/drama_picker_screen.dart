// lib/features/forum/presentation/screens/drama_picker_screen.dart

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drama_review_app/core/providers/tmdb_providers.dart'; // Pastikan ini mengimpor provider yang benar
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// State lokal untuk query picker
final pickerQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class DramaPickerScreen extends ConsumerStatefulWidget {
  const DramaPickerScreen({super.key});

  @override
  ConsumerState<DramaPickerScreen> createState() => _DramaPickerScreenState();
}

class _DramaPickerScreenState extends ConsumerState<DramaPickerScreen> {
  final _textController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(pickerQueryProvider.notifier).state = _textController.text;
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(pickerQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cari drama...',
            border: InputBorder.none,
            prefixIcon: Icon(EvaIcons.search),
          ),
        ),
      ),
      body: searchQuery.trim().isEmpty
          ? const Center(child: Text('Ketik judul drama untuk mencari'))
          : _PickerResultsList(query: searchQuery),
    );
  }
}

class _PickerResultsList extends ConsumerWidget {
  final String query;
  const _PickerResultsList({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- PERBAIKAN: Gunakan searchDramasProvider yang LAMA (FutureProvider) ---
    final searchResultsAsync = ref.watch(searchDramasProvider(query));

    return searchResultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (dramas) { // Data langsung berupa List<Drama>
        if (dramas.isEmpty) {
          return const Center(child: Text('Tidak ada hasil ditemukan.'));
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dramas.length,
            itemBuilder: (context, index) {
              final drama = dramas[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: drama.fullPosterPath,
                            width: 50,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        title: Text(drama.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Row(
                          children: [
                            const Icon(EvaIcons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(drama.voteAverage.toStringAsFixed(1)),
                          ],
                        ),
                        onTap: () {
                          // Kembalikan data drama ke halaman sebelumnya
                          Navigator.pop(context, drama);
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}