import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'my_reports_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'community_screen.dart';
import '../services/localization_service.dart';
import 'auth_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MyReportsScreen(),
    const MapScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final tr = AppTranslations.of(context);

    final List<String> titles = [
      '', // Home
      tr.translate('reports_title'),
      tr.translate('map_title'),
      tr.translate('profile_title'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _selectedIndex == 0 
          ? Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            )
          : null,
        title: _selectedIndex == 0 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr.translate('hello')}, ${user?.name ?? "User"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  tr.translate('welcome_back'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            )
          : Text(
              titles[_selectedIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_outlined, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CommunityScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          showUnselectedLabels: true,
          elevation: 0,
          backgroundColor: Colors.blue[900],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined, size: 28),
              activeIcon: const Icon(Icons.home, size: 30),
              label: tr.translate('home_title'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_outlined, size: 28),
              activeIcon: const Icon(Icons.assignment, size: 30),
              label: tr.translate('reports_title'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined, size: 28),
              activeIcon: const Icon(Icons.explore, size: 30),
              label: tr.translate('home_title') == 'Accueil' ? 'Carte' : 'Map',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle_outlined, size: 28),
              activeIcon: const Icon(Icons.account_circle, size: 30),
              label: tr.translate('profile_title') == 'Mon Profil' ? 'Profil' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
