import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/shell_tab_provider.dart';
import 'appointments_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ShellTabProvider>();

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [
          HomeScreen(),
          SearchScreen(),
          FavoritesScreen(),
          AppointmentsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab.index,
        onTap: tab.goTo,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_outlined),
            activeIcon: Icon(Icons.event_available),
            label: 'Citas',
          ),
        ],
      ),
    );
  }
}
