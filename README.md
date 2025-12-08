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
- 💾 Persistencia de datos con SQLite

## Requisitos Previos

- Flutter SDK 3.7.0 o superior
- Dart SDK
- Android Studio / Xcode / Visual Studio (dependiendo de la plataforma objetivo)

## Dependencias Principales

- `flutter` - Framework de desarrollo
- `cupertino_icons` - Iconos de estilo iOS
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
├── main.dart           # Punto de entrada y pantalla principal de tareas
├── Login.dart          # Pantalla de inicio de sesión
├── Registro.dart       # Pantalla de registro
├── LoginInput.dart     # Componentes de entrada para login
├── Google.dart         # Integración con Google Sign-In
└── BotonDeInicio.dart  # Botones personalizados
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
