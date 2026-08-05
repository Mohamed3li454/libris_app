# Libris App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Libris is a modern cross-platform Flutter app for discovering, browsing, and viewing book details. The codebase demonstrates feature-based organization, Cubit state management, local caching with Hive, and a lightweight API integration layer.

---

Demo

![Libris screenshot](assets/book.jpg)

Quick summary
- Clean, modular architecture with feature folders
- Fast browsing: featured books, filters, and search
- Detailed book pages with actions and local caching

Features
- Home: featured books, filter chips, and curated lists
- Explore: search and filter across genres/tags
- Details: book metadata, description, stats, and action bar
- Local caching and persistence (Hive)
- Platform support: Android, iOS, Web, macOS, Linux, Windows

Tech stack
- Flutter & Dart
- State management: flutter_bloc / Cubit
- Local storage: Hive (and platform-specific sqflite where applicable)
- HTTP: dart:io / http or Dio (see lib/core/utils/api_service.dart)

Requirements
- Flutter SDK (>= 3.x)
- Android Studio or Xcode for device emulation and platform builds
- Platform toolchains installed (Android SDK, Xcode)

Getting started (developer)

1. Clone the repository
   git clone <repo-url>
   cd libris_app

2. Install dependencies
   flutter pub get

3. Run the app
   flutter run

4. Build release
   - Android: flutter build apk
   - iOS: flutter build ios  (macOS + Xcode required)
   - Web: flutter build web

Developer tips
- Use Android Studio or VS Code with Flutter extensions for hot reload and debugging
- Run a specific platform: flutter run -d chrome or flutter run -d <device-id>
- Inspect API endpoints and keys in: lib/constants/api_constants.dart
- Example environment variables: copy `.env.example` to `.env` and fill required values

Project structure (high level)

- lib/
  - core/           # shared widgets, styles, errors, services
  - constants/      # app constants and API config
  - features/       # feature modules (home, explore, details)
  - main.dart       # app entry + router
- assets/           # images and static assets
- android/, ios/, web/, macos/, linux/, windows/  # platform folders

Testing
- Run all tests: flutter test
- Run a single test file: flutter test test/path/to_test.dart

Common commands
- Format: dart format .
- Analyze: flutter analyze
- Clean: flutter clean

Configuration
- .env.example contains sample environment variables used by the app
- Hive boxes/constants: lib/constants/hive_constants.dart

Contributing
- Open issues for bugs and feature requests
- Fork, create a feature branch, and submit a PR with tests
- Keep changes small and add clear commit messages

Roadmap ideas
- Add CI (GitHub Actions) for tests and analyzer
- Improve test coverage with widget/integration tests
- Add user authentication and bookmarks

Acknowledgements
- Built with Flutter. Uses community packages; see pubspec.yaml for full dependency list.

License
This project is unlicensed by default — add a LICENSE file (MIT recommended) if you want to open-source it.

Contact
Maintainer: (add name & email or GitHub handle)

---

Want badges (CI/coverage), a short README variant, or a CONTRIBUTING.md next? Reply with what to include and any CI provider. 