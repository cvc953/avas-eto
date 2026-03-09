import 'package:avas_eto/screens/more_options.dart';
import 'package:flutter/material.dart';
import '../screens/vista_calendario.dart';
import '../screens/vista_semana.dart';

class CustomBottomNavBar extends StatelessWidget {
  final BuildContext parentContext;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<Color> coloresDisponibles;

  const CustomBottomNavBar({
    super.key,
    required this.parentContext,
    required this.currentIndex,
    required this.onSelect,
    required this.coloresDisponibles,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (i) => onSelect(i),
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
