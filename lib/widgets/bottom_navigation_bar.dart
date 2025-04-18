import 'package:flutter/material.dart';
import '../screens/login.dart';
import '../screens/Viscalendario.dart';
import '../screens/Vissemana.dart';

class CustomBottomNavBar extends StatelessWidget {
  final BuildContext parentContext;
  final VoidCallback onAdd;
  final VoidCallback onSearch;

  const CustomBottomNavBar({
    required this.parentContext,
    required this.onAdd,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () => _menu(parentContext),
          ),
          label: "Vistas",
        ),
        BottomNavigationBarItem(
          icon: IconButton(icon: const Icon(Icons.add), onPressed: onAdd),
          label: "Añadir",
        ),
        BottomNavigationBarItem(
          icon: IconButton(icon: const Icon(Icons.search), onPressed: onSearch),
          label: "Buscar",
        ),
        BottomNavigationBarItem(
          icon: IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => Login()));
            },
          ),
          label: "Cuenta",
        ),
      ],
    );
  }

  void _menu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('Calendario'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Viscalendario(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_week),
              title: const Text('Semana'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Vissemana()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ajustes'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Ayuda'),
              onTap: () {},
            ),
          ],
        );
      },
    );
  }
}
