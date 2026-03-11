import 'package:avas_eto/screens/about_screen.dart';
import 'package:avas_eto/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:avas_eto/controller/auth_controller.dart';
import 'package:avas_eto/controller/settings_controller.dart';
import 'package:avas_eto/controller/tareas_controller.dart';
import 'package:avas_eto/services/inicia_con_google.dart';
import 'package:avas_eto/utils/app_toast.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'eisenhower_screen.dart';
import 'tareas_inicio.dart';

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
  bool _driveAuthorized = false;
  bool _checkingDrive = true;
  bool _authorizingDrive = false;
  DateTime? _lastBackPressedAt;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressedAt == null ||
        now.difference(_lastBackPressedAt!) > const Duration(seconds: 1)) {
      _lastBackPressedAt = now;
      AppToast.info(
        context,
        'Presiona nuevamente para salir',
        duration: const Duration(seconds: 1),
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
    controller = Provider.of<TareasController>(context, listen: false);

    enableNotifications();
    _refreshDriveAuthorizationStatus();
  }

  void enableNotifications() async {
    notificationsEnabled = await _settingsController.isEnabled();
    mobileDataUploadsEnabled = _settingsController.mobileDataUploadsEnabled;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _refreshDriveAuthorizationStatus() async {
    final authorized = await isDriveAccessGranted();
    if (!mounted) return;
    setState(() {
      _driveAuthorized = authorized;
      _checkingDrive = false;
    });
  }

  Future<void> _connectDrive() async {
    if (_authorizingDrive) return;
    setState(() => _authorizingDrive = true);
    try {
      final status = await requestDriveAccessInteractive();
      final authorizedNow = await isDriveAccessGranted();
      if (!mounted) return;

      final shouldMarkAuthorized =
          authorizedNow || status == DriveAccessRequestStatus.granted;
      if (shouldMarkAuthorized) {
        setState(() {
          _driveAuthorized = true;
          _checkingDrive = false;
        });
      }

      if (shouldMarkAuthorized) {
        AppToast.success(context, 'Google Drive conectado correctamente.');
      } else {
        switch (status) {
          case DriveAccessRequestStatus.cancelled:
            AppToast.info(
              context,
              'Conexion a Drive cancelada por el usuario.',
            );
            break;
          case DriveAccessRequestStatus.denied:
            AppToast.warning(
              context,
              'No se otorgo acceso a Drive. Seguiras en modo parcial.',
            );
            break;
          case DriveAccessRequestStatus.failed:
            AppToast.error(
              context,
              'No se pudo completar la autorizacion de Google Drive.',
            );
            break;
          case DriveAccessRequestStatus.granted:
            AppToast.success(context, 'Google Drive conectado correctamente.');
            break;
        }
      }
      await _refreshDriveAuthorizationStatus();
    } finally {
      if (mounted) setState(() => _authorizingDrive = false);
    }
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

  Widget _buildSectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildGuestAccessCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF152338) : const Color(0xFFEAF3FF);
    final border = isDark ? const Color(0xFF2F4F77) : const Color(0xFFA2C4EE);
    final title = isDark ? const Color(0xFFE8F2FF) : const Color(0xFF15314F);
    final body = isDark ? const Color(0xFFBDD1EC) : const Color(0xFF2A496C);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: title.withAlpha(28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cloud_sync_rounded, color: title),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sincronizacion segura con Google',
                      style: TextStyle(
                        color: title,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inicia sesion para sincronizar tareas en la nube y guardar adjuntos en tu Google Drive.',
                      style: TextStyle(
                        color: body,
                        height: 1.35,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Si no autorizas Drive, podras usar la app en modo parcial y activarlo despues desde esta misma pantalla.',
            style: TextStyle(color: body, height: 1.35),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => Login()));
              },
              child: const Text('Iniciar sesion'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInSummary(BuildContext context, User user) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryColor = Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage:
                user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child:
                user.photoURL == null
                    ? const Icon(Icons.account_circle, size: 42)
                    : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesion iniciada',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? 'Cuenta de Google conectada',
                  style: TextStyle(color: secondaryColor, height: 1.35),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => _confirmSignOut(context),
            child: const Text('Cerrar sesion'),
          ),
        ],
      ),
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
        if (!mounted) return;
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
              const SizedBox(height: 12),
              _buildSectionHeader(context, 'Cuenta'),
              if (user != null)
                _buildSignedInSummary(context, user)
              else
                _buildGuestAccessCard(context),
              const SizedBox(height: 18),
              _buildSectionHeader(context, 'Adjuntos y sincronizacion'),
              ListTile(
                leading: Icon(
                  _driveAuthorized
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color:
                      _driveAuthorized
                          ? Colors.green
                          : Theme.of(context).iconTheme.color,
                ),
                title: const Text('Google Drive para adjuntos'),
                subtitle: Text(
                  _checkingDrive
                      ? 'Verificando estado...'
                      : _driveAuthorized
                      ? 'Conectado y listo para subir adjuntos'
                      : 'Modo parcial activo: adjuntos solo locales',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                trailing:
                    _driveAuthorized
                        ? IconButton(
                          tooltip: 'Actualizar estado',
                          onPressed: _refreshDriveAuthorizationStatus,
                          icon: const Icon(Icons.refresh_rounded),
                        )
                        : TextButton(
                          onPressed:
                              _authorizingDrive || _checkingDrive
                                  ? null
                                  : _connectDrive,
                          child:
                              _authorizingDrive
                                  ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Conectar'),
                        ),
              ),
              ListTile(
                leading:
                    mobileDataUploadsEnabled
                        ? Icon(
                          Icons.perm_data_setting,
                          color: Theme.of(context).iconTheme.color,
                        )
                        : Icon(
                          Icons.wifi,
                          color: Theme.of(context).iconTheme.color,
                        ),
                title: Text(
                  'Subir adjuntos con datos moviles',
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
                    if (!mounted) return;
                    setState(() {
                      mobileDataUploadsEnabled = value;
                    });
                  },
                  activeThumbColor: Colors.blueAccent,
                ),
              ),
              Divider(color: Theme.of(context).dividerColor),
              _buildSectionHeader(context, 'Preferencias'),
              ListTile(
                leading: Icon(
                  notificationsEnabled
                      ? Icons.notifications_on
                      : Icons.notifications_off,
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
                    if (!mounted) return;
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                  activeThumbColor: Colors.blueAccent,
                ),
              ),
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
                onTap: _showThemeDialog,
              ),
              Divider(color: Theme.of(context).dividerColor),
              _buildSectionHeader(context, 'Informacion'),
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
