<div align="center">

# 📚 Libris

**Discover, Explore, and Manage Your Personal Library with Elegance**

A modern Flutter reading companion for book discovery, dual-source search, Archive.org reading, and an offline personal library. Built around a Warm Ivory visual identity with light and dark themes.

[![Flutter](https://img.shields.io/badge/Flutter-3.12+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--First%20Cubit-765A1F?style=for-the-badge)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State%20Management-Flutter%20Bloc%20%2F%20Cubit-42A5F5?style=for-the-badge&logo=bloc&logoColor=white)](https://bloclibrary.dev)
[![Storage](https://img.shields.io/badge/Local%20Storage-Hive-FF6F00?style=for-the-badge)](https://docs.hivedb.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

---

</div>

## Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Tech Stack & Architecture](#-tech-stack--architecture)
- [Project Structure](#-project-structure)
- [Error Handling Architecture](#-error-handling-architecture)
- [Getting Started / Installation](#-getting-started--installation)
- [License](#-license)

---

## Overview

**Libris** is a book discovery and personal library app. The Warm Ivory palette (`#F0EADE`) powers a light theme, with a matching dark theme available from Settings.

Discovery uses **Open Library** for rich metadata (descriptions, ratings, language, similar titles). Search also queries **Internet Archive** so extra readable copies — including Arabic titles that Open Library often misses — still appear. Details always prefer Open Library. **Read Now** opens the Archive.org book reader in 2-up mode, preferring an English public scan that matches the Open Library title.

---

## Key Features

- **Search (Open Library + Archive.org)**: Debounced Explore search (400ms, min 3 characters), pagination, infinite scroll. Results merge Open Library first (richer records) with Archive.org-only titles that are not already on Open Library. English is preferred for Latin queries; Arabic queries are not forced to English.
- **Explore Welcome Hub**: Recent searches (`SharedPreferences`), trending chips, a 10-genre grid, and authors from the saved library.
- **Book Details**: Open Library description, ratings, year, language, similar books, and shimmer loading (including Read / Download buttons). Read Now opens `https://archive.org/details/{id}/page/n19/mode/2up` after resolving an English public identifier by title — not a random/foreign `ia` id attached to the work.
- **Personal Library**: Collections *All*, *Want to Read*, *Reading*, *Finished*, *Favorites*. Sort by recently added, title, or year. Collection counts. Reading progress slider on *Reading* books. Shared `LibraryCubit` so bookmarks from Details refresh the Library tab.
- **Backup & Restore**: Export JSON via the share sheet (`share_plus` + temp file). Import a `.json` file (`file_picker`).
- **Home**: Weekly trending carousel (8-hour Hive cache), category chips with English-biased Open Library search, pull-to-refresh, search icon (jumps to Explore), settings icon.
- **Settings**: System / Light / Dark theme (`ThemeCubit` + SharedPreferences), clear home cache, clear search history, about.
- **Onboarding**: Three Lottie slides (Discover / Open Book Pages / Library) with accurate copy — no fake in-app PDF reader.
- **Shimmer & Errors**: Skeleton loading on Home, Explore, Details (including action bar). `ServerFailure.fromDioError` + retry UI. Explore load-more keeps existing results on failure.

---

## Tech Stack & Architecture

### Technology Stack

| Layer | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter (SDK `^3.12.2`) | Cross-platform UI |
| **Language** | Dart (`^3.12.2`) | Application logic |
| **Architecture** | Feature-first + Cubit + repository interfaces | UI → Cubit → Repo → ApiService / Hive |
| **DI** | `ServiceLocator` (`lib/core/di/service_locator.dart`) | Shared `ApiService`, repos |
| **State** | `flutter_bloc` Cubits | Theme, library, home, explore, details |
| **Networking** | `dio` | Open Library + Archive.org |
| **Metadata API** | Open Library | Works, search, ratings, editions, trending |
| **Reader / extra search** | Internet Archive | Public text search + 2-up reader URLs |
| **Local Storage** | `hive` / `hive_flutter` | Featured/filter cache (TTL) + saved library |
| **Preferences** | `shared_preferences` | Onboarding, search history, theme mode |
| **Backup** | `share_plus`, `file_picker`, `path_provider` | Library JSON export/import |
| **Navigation** | `go_router` | Splash, onboarding, main, details, settings |
| **UI** | `google_fonts`, `shimmer`, `lottie`, `cached_network_image`, `flutter_staggered_grid_view` | Theme, loading, onboarding, covers, library grid |
| **Links** | `url_launcher` | Archive.org reader in an external browser |

Cubits receive repositories from `ServiceLocator` (overridable in tests). `ThemeCubit` and `LibraryCubit` are provided at the app root in `main.dart`.

---

## Project Structure

```text
lib/
├── constants/
│   ├── app_colors.dart
│   └── hive_constants.dart
├── core/
│   ├── di/service_locator.dart
│   ├── errors/failure.dart
│   ├── models/book_model.dart
│   ├── services/
│   │   ├── onboarding_service.dart
│   │   └── search_history_service.dart
│   ├── theme/app_theme.dart
│   ├── utils/
│   │   ├── api_service.dart
│   │   ├── dio_factory.dart
│   │   └── styles.dart
│   └── widgets/
│       ├── custom_bottom_navigation_bar.dart
│       ├── custom_error_widget.dart
│       └── router.dart
├── features/
│   ├── details/
│   ├── explore/
│   ├── home/
│   ├── library/
│   ├── main/
│   ├── onboarding/
│   ├── settings/
│   └── splash/
└── main.dart
test/
├── onboarding_test.dart
├── search_history_service_test.dart
└── widget_test.dart
```

Android application id: `com.mohamed.libris` (INTERNET permission in the main manifest). iOS display name: Libris.

---

## Error Handling Architecture

```text
DioException / parse error
        → ServerFailure / FormatFailure
        → Either<Failure, T>
        → Cubit Failure state
        → CustomErrorWidget (retry)
```

Explore pagination failures emit `ExploreSuccess` with `loadMoreError` so the current list is kept. Library Hive errors surface as `LibraryFailure`.

---

## Getting Started / Installation

### Prerequisites

- Flutter SDK `>= 3.12.2`
- Git

### Steps

```bash
git clone https://github.com/Mohamed3li454/libris_app.git
cd libris_app
flutter pub get
flutter run
flutter test   # optional
```

No `.env` file is required. Open Library and Archive.org are used without an API key.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
