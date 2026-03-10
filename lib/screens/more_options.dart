import 'package:avas_eto/screens/about_screen.dart';
import 'package:avas_eto/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'eisenhower_screen.dart';
import 'tareas_inicio.dart';
import 'package:avas_eto/controller/auth_controller.dart';
import 'package:avas_eto/controller/settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:avas_eto/controller/tareas_controller.dart';

class MoreOptions extends StatefulWidget {
  final Future<void> Function(dynamic tarea)? onAddTask;
  final Future<void> Function(dynamic tarea, bool completada)? onToggle;
  final AuthController? authController;
  final SettingsController? settingsController;
  final bool embedded;

  const MoreOptions({
    super.key,

    this.onAddTask,
    this.onToggle,
    this.authController,
    this.settingsController,
    this.embedded = false,
  });

  @override
  State<MoreOptions> createState() => _MoreOptionsState();
}

class _MoreOptionsState extends State<MoreOptions> {
  late final dynamic controller;
  late final Future<void> Function(dynamic tarea)? onAddTask = widget.onAddTask;
  late final Future<void> Function(dynamic tarea, bool)? onToggle =
      widget.onToggle;

  late final AuthController _authController;
  late final SettingsController _settingsController;
  bool notificationsEnabled = true;
  bool mobileDataUploadsEnabled = false;
  DateTime? _lastBackPressedAt;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressedAt == null ||
        now.difference(_lastBackPressedAt!) > const Duration(seconds: 1)) {
      _lastBackPressedAt = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Presiona nuevamente para salir'),
            duration: Duration(seconds: 1),
          ),
        );
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _authController =
        widget.authController ??
        Provider.of<AuthController>(context, listen: false);
    _settingsController =
        widget.settingsController ??
        Provider.of<SettingsController>(context, listen: false);
    // Obtain TareasController from Provider (no longer passed via widget)
    controller = Provider.of<TareasController>(context, listen: false);

    enableNotifications();
  }

  void enableNotifications() async {
    // Lógica para habilitar o deshabilitar notificaciones (delegada al SettingsController)
    notificationsEnabled = await _settingsController.isEnabled();
    mobileDataUploadsEnabled = _settingsController.mobileDataUploadsEnabled;
    setState(() {});
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Seguir sistema';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Seleccionar tema',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context,
                'Seguir sistema',
                Icons.brightness_auto,
                ThemeMode.system,
              ),
              _buildThemeOption(
                context,
                'Claro',
                Icons.light_mode,
                ThemeMode.light,
              ),
              _buildThemeOption(
                context,
                'Oscuro',
                Icons.dark_mode,
                ThemeMode.dark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    IconData icon,
    ThemeMode mode,
  ) {
    final isSelected = _settingsController.themeMode == mode;

    return ListTile(
      leading: Icon(
        icon,
        color:
            isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        label,
        style: TextStyle(
          color:
              isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          isSelected
              ? Icon(Icons.check, color: Theme.of(context).primaryColor)
              : null,
      onTap: () async {
        await _settingsController.setThemeMode(mode);
        setState(() {});
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<User?>(
      stream: _authController.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Center(
          child: Column(
            children: [
              const SizedBox(height: 20),

              if (user != null) ...[
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                  child:
                      user.photoURL == null
                          ? const Icon(Icons.account_circle, size: 80)
                          : null,
                ),
                const SizedBox(height: 20),
                Text(
                  'Hola, ${user.email}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () => _confirmSignOut(context),
                  child: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ] else ...[
                const Icon(Icons.account_circle, size: 80),
                const SizedBox(height: 20),
                Text(
                  'Inicia sesión para más opciones',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => Login()));
                  },
                  child: const Text(
                    'Iniciar sesión',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],

              const SizedBox(height: 30),
              ListTile(
                leading:
                    notificationsEnabled == true
                        ? Icon(
                          Icons.notifications_on,
                          color: Theme.of(context).iconTheme.color,
                        )
                        : Icon(
                          Icons.notifications_off,
                          color: Theme.of(context).iconTheme.color,
                        ),
                title: Text(
                  'Notificaciones',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: (bool value) async {
                    await _settingsController.setEnabled(value);
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                  activeThumbColor: Colors.blueAccent,
                ),
              ),
              ListTile(
                leading: Icon(
                  mobileDataUploadsEnabled
                      ? Icons.perm_data_setting
                      : Icons.wifi,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(
                  'Subir adjuntos con datos móviles',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  mobileDataUploadsEnabled
                      ? 'Permitido tambien fuera de Wi-Fi'
                      : 'Solo se subiran con Wi-Fi',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                trailing: Switch(
                  value: mobileDataUploadsEnabled,
                  onChanged: (bool value) async {
                    await _settingsController.setMobileDataUploadsEnabled(
                      value,
                    );
                    setState(() {
                      mobileDataUploadsEnabled = value;
                    });
                  },
                  activeThumbColor: Colors.blueAccent,
                ),
              ),
              // Selector de tema
              ListTile(
                leading: Icon(
                  _settingsController.themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : _settingsController.themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.brightness_auto,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(
                  'Tema',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  _getThemeModeLabel(_settingsController.themeMode),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                onTap: () => _showThemeDialog(),
              ),
              Divider(color: Theme.of(context).dividerColor),
              ListTile(
                leading: Icon(
                  Icons.info,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(
                  'Acerca de',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AboutScreen(
                            onAddTask: widget.onAddTask,
                            onToggle: widget.onToggle,
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (widget.embedded) {
      return SingleChildScrollView(child: content);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Center(
            child: Text(
              'Más opciones',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        body: content,
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 2,
          onSelect: (i) {
            if (i == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => TareasInicio()),
              );
            } else if (i == 1) {
              if (controller != null && onAddTask != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => EisenhowerScreen(
                          onAddTask: onAddTask!,
                          onToggle: onToggle,
                          currentIndex: 1,
                        ),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => TareasInicio()),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () async {
                  await _authController.signOut();
                  Navigator.of(context).pop();
                },
                child: const Text('Sí', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'No',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
