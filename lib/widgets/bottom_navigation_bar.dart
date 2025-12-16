import 'package:avas_eto/screens/cuentas.dart';
import 'package:avas_eto/screens/more_options.dart';
import 'package:flutter/material.dart';
import '../screens/vista_calendario.dart';
import '../screens/vista_semana.dart';

class CustomBottomNavBar extends StatelessWidget {
  final BuildContext parentContext;
  final VoidCallback onAdd;
  final VoidCallback onSearch;
  final List<Color> coloresDisponibles;

  const CustomBottomNavBar({
    super.key,
    required this.parentContext,
    required this.onAdd,
    required this.onSearch,
    required this.coloresDisponibles,
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
          icon: IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              Navigator.push(
                context,
                // MaterialPageRoute(builder: (context) => CuentaScreen()),
                MaterialPageRoute(builder: (context) => MoreOptions()),
              );
            },
          ),
          label: "Más",
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
                    builder:
                        (context) => CalendarioTareas(
                          coloresDisponibles: coloresDisponibles,
                        ),
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
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            VisSemana(coloresDisponibles: coloresDisponibles),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
