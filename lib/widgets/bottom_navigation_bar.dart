import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onSelect;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onSelect,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor:
          backgroundColor ??
          Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      selectedItemColor:
          selectedItemColor ??
          Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
      unselectedItemColor:
          unselectedItemColor ??
          Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (i) => onSelect?.call(i),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.grid_view),
          label: 'Matriz',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.view_list),
          label: 'Tareas',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.more_horiz),
          label: 'Más',
        ),
      ],
    );
  }
}
