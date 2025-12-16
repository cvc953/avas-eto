# Avas Eto

Una aplicación de gestión de tareas desarrollada con Flutter que te permite organizar y administrar tus tareas de manera eficiente.

## Características

- ✅ Crear y gestionar tareas
- 🎨 Asignar colores personalizados a cada tarea
- 📋 Visualizar lista de tareas
- ✏️ Editar tareas existentes
- 🗑️ Eliminar tareas
- 👤 Sistema de autenticación con inicio de sesión
- 🔐 Integración con Google Sign-In
- 📱 Interfaz de usuario moderna con tema oscuro

## Requisitos Previos

- Flutter SDK 3.7.0 o superior
- Dart SDK
- Android Studio / Xcode / Visual Studio (dependiendo de la plataforma objetivo)

## Dependencias Principales

- `flutter` - Framework de desarrollo
- `flutter_signin_button` - Botones de inicio de sesión prediseñados
- `sqflite` - Base de datos SQLite para Flutter
- `path` - Utilidades para trabajar con rutas de archivos

## Instalación

1. Clona este repositorio:
```bash
git clone https://github.com/cvc953/avas-eto.git
cd avas-eto
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Ejecuta la aplicación:
```bash
flutter run
```

## Plataformas Soportadas

- ✅ Android

## Estructura del Proyecto

```
lib/
├── components
│   └── images
│       └── google.png
├── controller
│   └── tareas_controller.dart
├── dialogs
│   ├── agregar_tarea.dart
│   └── editar_tarea.dart
├── firebase_options.dart
├── main.dart
├── models
│   └── tarea.dart
├── repositories
│   └── tareas_repository.dart
├── screens
│   ├── cuentas.dart
│   ├── login.dart
│   ├── more_options.dart
│   ├── registro.dart
│   ├── tareas.dart
│   ├── tareas_inicio.dart
│   ├── tareas_list.dart
│   ├── tareas_tab_view.dart
│   ├── vista_calendario.dart
│   └── vista_semana.dart
├── services
│   ├── autenticacion.dart
│   ├── conectividad_service.dart
│   ├── inicia_con_google.dart
│   ├── local_database.dart
│   ├── local_storage_service.dart
│   ├── notificacion_service.dart
│   ├── notification_service.dart
│   ├── notifications_settings.dart
│   ├── password_reset.dart
│   ├── tarea_repository.dart
│   └── tareas_firestore_service.dart
├── utils
│   ├── permissions.dart
│   ├── tarea_firestore_mapper.dart
│   ├── tarea_helpers.dart
│   ├── tareas_location_helper.dart
│   └── theme.dart
└── widgets
    ├── boton_agregar.dart
    ├── boton_inicio.dart
    ├── bottom_navigation_bar.dart
    ├── buscar_tareas.dart
    ├── google.dart
    ├── login_input.dart
    ├── nombre_tarea.dart
    ├── tarea_card.dart
    ├── toggle_notifications.dart
    └── ui.dart
```

## Uso

1. **Añadir una tarea**: Toca el botón "+" en la barra inferior y escribe el nombre de tu tarea. Puedes seleccionar un color personalizado para categorizarla.

2. **Gestionar tareas**: Cada tarea tiene un menú de opciones (⋮) donde puedes editarla o eliminarla.

3. **Vistas**: Toca el botón de vistas para acceder a diferentes modos de visualización (Calendario, Código, Semana, Tabla de progreso).

4. **Cuenta**: Accede al sistema de autenticación tocando el icono de perfil.

## Desarrollo

Para ejecutar la aplicación en modo debug:
```bash
flutter run --debug
```

Para compilar una versión de release:
```bash
flutter build apk  # Para Android
flutter build ios  # Para iOS
flutter build web  # Para Web
```

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## Autor

Cristian Villalobos Cuadrado

## Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue o pull request para sugerencias y mejoras.
