// lib/features/home/presentation/screens/main_screen.dart

import 'package:drama_review_app/features/explore/presentation/screens/explore_screen.dart';
import 'package:drama_review_app/features/home/presentation/screens/home_screen.dart';
import 'package:drama_review_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:drama_review_app/features/search/presentation/screens/search_screen.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body tidak berubah
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // Kita ganti BottomNavigationBar standar dengan versi kustom
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// --- WIDGET BARU: FLOATING NAVIGATION BAR KUSTOM ---
class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const _FloatingNavBar({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        // --- PERBAIKAN DI SINI ---
        // Mengurangi padding vertikal dari 12.0 menjadi 8.0
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: EvaIcons.home,
                label: 'Home',
                isSelected: selectedIndex == 0,
                onTap: () => onItemTapped(0),
              ),
              _NavBarItem(
                icon: EvaIcons.compassOutline,
                label: 'Explore',
                isSelected: selectedIndex == 1,
                onTap: () => onItemTapped(1),
              ),
              _NavBarItem(
                icon: EvaIcons.search,
                label: 'Search',
                isSelected: selectedIndex == 2,
                onTap: () => onItemTapped(2),
              ),
              _NavBarItem(
                icon: EvaIcons.person,
                label: 'Profile',
                isSelected: selectedIndex == 3,
                onTap: () => onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// --- WIDGET BARU: ITEM NAVIGASI DENGAN ANIMASI ---
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[500];
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent, // Memastikan area sentuh lebih besar
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            // Teks akan muncul dan menghilang dengan animasi
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        label,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}