import 'package:flutter/material.dart';

class TaskDialogShell extends StatelessWidget {
  final String title;
  final List<Widget> trailing;
  final Widget body;
  final Widget footer;

  const TaskDialogShell({
    super.key,
    required this.title,
    required this.body,
    required this.footer,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final viewPadding = MediaQuery.of(context).viewPadding;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: viewInsets.bottom + viewPadding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...trailing,
              ],
            ),
            const SizedBox(height: 10),
            Expanded(child: SingleChildScrollView(child: body)),
            const SizedBox(height: 10),
            footer,
          ],
        ),
      ),
    );
  }
}

class TaskDialogToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  const TaskDialogToolbarButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor:
            theme.brightness == Brightness.dark
                ? Colors.white.withAlpha(12)
                : Colors.black.withAlpha(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, color: color ?? theme.iconTheme.color),
    );
  }
}

class TaskDialogMetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const TaskDialogMetaTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              theme.brightness == Brightness.dark
                  ? Colors.white.withAlpha(8)
                  : Colors.black.withAlpha(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.iconTheme.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
