// lib/shared_widgets/drama_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drama_review_app/core/models/drama_model.dart';
import 'package:drama_review_app/features/drama_details/presentation/screens/drama_details_screen.dart';
import 'package:flutter/material.dart';

// Ubah menjadi StatefulWidget untuk mengelola state sentuhan
class DramaCard extends StatefulWidget {
  final Drama drama;
  const DramaCard({super.key, required this.drama});

  @override
  State<DramaCard> createState() => _DramaCardState();
}

class _DramaCardState extends State<DramaCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DramaDetailScreen(dramaId: widget.drama.id),
          ),
        );
      },
      // Tambahkan listener sentuhan untuk efek skala
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        // Terapkan skala berdasarkan state _isPressed
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.drama.fullPosterPath,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[850]),
                errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha:0.9), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  widget.drama.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // Gunakan textTheme dari tema untuk konsistensi
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [const Shadow(blurRadius: 2.0, color: Colors.black)],
                      ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Theme.of(context).colorScheme.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        widget.drama.voteAverage.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}