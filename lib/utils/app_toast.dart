import 'package:flutter/material.dart';

enum AppToastType { success, info, warning, error }

class AppToast {
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: AppToastType.success, duration: duration);
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: AppToastType.info, duration: duration);
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(context, message, type: AppToastType.warning, duration: duration);
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(context, message, type: AppToastType.error, duration: duration);
  }

  static void show(
    BuildContext context,
    String message, {
    required AppToastType type,
    Duration duration = const Duration(seconds: 3),
    bool replaceCurrent = true,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    if (replaceCurrent) {
      messenger.hideCurrentSnackBar();
    }

    final palette = _paletteFor(context, type);
    final icon = _iconFor(type);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 0,
        backgroundColor: Colors.transparent,
        content: Container(
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: palette.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: palette.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return Icons.check_circle_rounded;
      case AppToastType.info:
        return Icons.info_rounded;
      case AppToastType.warning:
        return Icons.warning_rounded;
      case AppToastType.error:
        return Icons.error_rounded;
    }
  }

  static _ToastPalette _paletteFor(BuildContext context, AppToastType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case AppToastType.success:
        return isDark
            ? const _ToastPalette(
              background: Color(0xFF112A1E),
              foreground: Color(0xFFE6FFF0),
              border: Color(0xFF2D8A5A),
              accent: Color(0xFF56D390),
            )
            : const _ToastPalette(
              background: Color(0xFFE9F8EF),
              foreground: Color(0xFF143A24),
              border: Color(0xFF5FBF83),
              accent: Color(0xFF1E8E4F),
            );
      case AppToastType.info:
        return isDark
            ? const _ToastPalette(
              background: Color(0xFF13263F),
              foreground: Color(0xFFE8F3FF),
              border: Color(0xFF4E86C9),
              accent: Color(0xFF71AAED),
            )
            : const _ToastPalette(
              background: Color(0xFFEAF4FF),
              foreground: Color(0xFF102A46),
              border: Color(0xFF78AEE8),
              accent: Color(0xFF2F76C2),
            );
      case AppToastType.warning:
        return isDark
            ? const _ToastPalette(
              background: Color(0xFF36250F),
              foreground: Color(0xFFFFF3DD),
              border: Color(0xFFD99B43),
              accent: Color(0xFFF0B85C),
            )
            : const _ToastPalette(
              background: Color(0xFFFFF6E6),
              foreground: Color(0xFF4A320D),
              border: Color(0xFFE9B15B),
              accent: Color(0xFFB9791E),
            );
      case AppToastType.error:
        return isDark
            ? const _ToastPalette(
              background: Color(0xFF3A171A),
              foreground: Color(0xFFFFECEE),
              border: Color(0xFFD36C72),
              accent: Color(0xFFE48389),
            )
            : const _ToastPalette(
              background: Color(0xFFFDECEE),
              foreground: Color(0xFF4A151A),
              border: Color(0xFFDE848A),
              accent: Color(0xFFB63D46),
            );
    }
  }
}

class _ToastPalette {
  final Color background;
  final Color foreground;
  final Color border;
  final Color accent;

  const _ToastPalette({
    required this.background,
    required this.foreground,
    required this.border,
    required this.accent,
  });
}
