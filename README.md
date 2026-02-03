# LilyNotes

A widget-based note-taking app built with Flutter. Organize your thoughts, track habits, manage tasks, and more using customizable widgets on pages.

## Features

- **Text Blocks** - Rich text notes and descriptions
- **Checklists** - Task lists with checkable items
- **Habit Tracker** - Track daily habits with visual feedback
- **Progress Bars** - Monitor progress toward goals
- **Timers** - Countdown and stopwatch functionality
- **Score/Counter** - Keep track of scores or counts
- **Counter Lists** - Multiple named counters in one widget
- **Expense Tracker** - Log and categorize expenses
- **Bookmarks** - Save and organize links
- **Dividers** - Visual separators for organization

## Tech Stack

- Flutter 3.9+
- Hive for local storage
- Provider for state management

## Getting Started

### Prerequisites

- Flutter SDK 3.9 or higher
- Android Studio or VS Code with Flutter extension

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/TOMSLAUS/lilynotes.git
   cd lilynotes
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Release

#### Android

1. Create `android/key.properties` with your signing configuration:
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=YOUR_KEY_ALIAS
   storeFile=PATH_TO_YOUR_KEYSTORE.jks
   ```

2. Build the APK:
   ```bash
   flutter build apk --release
   ```

#### iOS

```bash
flutter build ios --release
```

## Project Structure

```
lib/
  main.dart           # App entry point
  models/             # Data models (AppPage, AppWidget, WidgetType)
  providers/          # State management (AppState, ThemeProvider)
  screens/            # App screens (Home, Search, About)
  services/           # Storage and widget bridge services
  theme/              # App theming and colors
  widgets/            # Widget implementations
```

## License

This project is licensed under the CC BY-NC 4.0 License - you are free to use, modify, and share this software for non-commercial purposes. See the [LICENSE](LICENSE) file for details.
