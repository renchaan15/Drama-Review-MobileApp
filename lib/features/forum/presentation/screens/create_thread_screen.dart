// lib/features/forum/presentation/screens/create_thread_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drama_review_app/core/models/drama_model.dart'; // Import model Drama
import 'package:drama_review_app/core/providers/database_providers.dart';
import 'package:drama_review_app/features/forum/presentation/screens/drama_picker_screen.dart'; // Import picker
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateThreadScreen extends ConsumerStatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  ConsumerState<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends ConsumerState<CreateThreadScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  
  // State untuk menyimpan drama yang dipilih
  Drama? _attachedDrama;

  void _submitThread() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul dan konten tidak boleh kosong.')));
      return;
    }
    setState(() { _isLoading = true; });

    try {
      await ref.read(databaseServiceProvider).createNewThread(
            _titleController.text.trim(),
            _contentController.text.trim(),
            attachedDrama: _attachedDrama, // Kirim lampiran (bisa null)
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // Fungsi untuk membuka picker
  void _pickDrama() async {
    final Drama? selectedDrama = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DramaPickerScreen()),
    );

    if (selectedDrama != null) {
      setState(() {
        _attachedDrama = selectedDrama;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topik Baru'),
        actions: [
          _isLoading
              ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())
              : IconButton(onPressed: _submitThread, icon: const Icon(Icons.send)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Judul Topik',
              hintText: 'Apa yang ingin didiskusikan?',
            ),
            style: Theme.of(context).textTheme.titleLarge,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          
          // --- BAGIAN LAMPIRAN ---
          if (_attachedDrama != null)
            Stack(
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: CachedNetworkImage(
                      imageUrl: _attachedDrama!.fullPosterPath,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(_attachedDrama!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Lampiran Drama'),
                    tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: () => setState(() => _attachedDrama = null),
                    icon: const Icon(Icons.close, size: 18),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _pickDrama,
              icon: const Icon(Icons.add_link),
              label: const Text('Lampirkan Drama (Opsional)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
              ),
            ),
          // --- AKHIR BAGIAN LAMPIRAN ---

          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Isi diskusi...',
              alignLabelWithHint: true,
              border: InputBorder.none,
            ),
            maxLines: 15,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}