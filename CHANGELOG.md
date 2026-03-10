# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

## [1.1.1] - 2026-03-09

### Added
- **Server Sync on Login**: Tasks now automatically sync from Firestore when user logs in.
- **User-Scoped Local Storage**: Local storage now isolates tasks by user ID to prevent cross-account data mixing.
- **Focus Score System**: Intelligent task prioritization based on importance (priority × 3), urgency (days remaining), and procrastination count.
- **"Foco de hoy" Tab**: New tab showing top 5 most important tasks based on focus score algorithm, replacing "Pendientes" tab.
- **"Todas" Tab**: Shows all tasks with completed ones at the bottom, replacing "Completadas" tab.
- **Postponement Tracking**: Counter (`vecesPospuesta`) that increments when task deadline is changed.
- **Quadrant Detail View**: Tap on any Eisenhower Matrix quadrant to view all tasks in that quadrant in full screen.
- **Optimistic UI Updates**: Checkbox changes now reflect immediately for better responsiveness.

### Changed
- **Checkbox Colors**: Now based on Eisenhower quadrant (Urgent/Important) instead of priority level.
- **Urgency Threshold**: Reduced to 2 days for more accurate urgent task classification.
- **Task Ordering**: Completed tasks automatically move to the end of all lists (Todas, Matrix, Quadrant details).
- **Navigation Architecture**: Centralized bottom navigation shell for consistent UX across all screens.

### Fixed
- **Matrix Task Interaction**: Tasks in Eisenhower Matrix now properly open edit dialog when tapped.
- **Quadrant Checkbox Updates**: Checkboxes in quadrant detail view now update immediately without lag.
- **Cross-Tab Sync**: Marking a task complete in "Foco de hoy" now correctly updates its position in "Todas" tab.

## [1.1.0] - 2026-03-09

### Added
- Added clearer About screen content describing the current app scope.
- Added in-app privacy policy section in About screen.
- Added README updates for scope, release notes, and Android-only support.

### Changed
- Reordered bottom navigation to: Tareas, Matriz, Mas.
- Updated light theme surfaces to a consistent off-white/gray tone.
- Updated date picker and time picker theming to match app colors.
- Updated dialog theming so confirmation dialogs respect app theme.
- Improved day visibility for current day in date picker when selected.

### Fixed
- Fixed body routing after nav reorder so Tareas and Matriz show in correct tabs.
- Fixed floating action button visibility on the Tareas tab.

## [1.0.0] - 2025-01-01

### Added
- Initial public version.
