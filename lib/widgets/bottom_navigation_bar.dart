import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onSelect;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
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
