<div align="center">

# 📚 Libris

**Discover, Explore, and Manage Your Personal Library with Elegance**

A modern, high-performance Flutter application built for seamless book discovery, dual-source search, interactive previews, Archive.org reading, and offline personal library management. Powered by Open Library and Internet Archive APIs, and engineered with a feature-first Cubit architecture.

[![Flutter](https://img.shields.io/badge/Flutter-3.12+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--First%20%2B%20Cubit-765A1F?style=for-the-badge)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State%20Management-Flutter%20Bloc%20%2F%20Cubit-42A5F5?style=for-the-badge&logo=bloc&logoColor=white)](https://bloclibrary.dev)
[![Storage](https://img.shields.io/badge/Local%20Storage-Hive-FF6F00?style=for-the-badge)](https://docs.hivedb.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

---

</div>

## 📖 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Tech Stack & Architecture](#-tech-stack--architecture)
- [Project Structure](#-project-structure)
- [Error Handling Architecture](#-error-handling-architecture)
- [Getting Started / Installation](#-getting-started--installation)
- [License](#-license)

---

## 🌟 Overview

**Libris** is a modern book discovery and library management application. Designed around a warm, vintage-inspired **Warm Ivory** aesthetic (`#F0EADE`) with a matching dark theme, Libris lets readers browse trending literature, search millions of titles, open public scans on Internet Archive, and save books locally.

Metadata (descriptions, ratings, language, similar titles) comes from **Open Library**. Explore search also queries **Internet Archive** so extra readable copies — including Arabic titles that Open Library often misses — still appear. Details always prefer Open Library. **Read Now** opens the Archive.org book reader in 2-up mode after resolving an English public identifier from the Open Library title, rather than a random foreign-language scan.

---

## ✨ Key Features

- **🔍 Dual-Source Search**: Real-time search by title, author, or genre with 400ms input debouncing, a 3-character minimum, paginated results (20 items per page), infinite scroll, and a "Load more" fallback. Open Library results are listed first (richer records). Archive.org-only titles that are not already on Open Library are appended. Latin queries prefer English; Arabic queries are not forced to English.
- **🧭 Smart Explore Welcome Screen**: Contextual hub showing recent search history (`SharedPreferences`), trending topic chips, a 10-genre browse grid (`ExploreGenresGrid`), and author recommendations from the saved library.
- **📚 Comprehensive Book Details**: Open Library overview, author, year, language, ratings, similar titles, and shimmer loading — including skeleton placeholders for the Read / Download action bar. Read Now opens `https://archive.org/details/{identifier}/page/n19/mode/2up`. Direct `/download/` PDF links are not used (they produced HTTP 401).
- **❤️ Personal Library & Collections**: Organize saved books into *All*, *Want to Read*, *Reading*, *Finished*, and *Favorites*, with live counts, sort (recently added / title / year), and a reading-progress slider on *Reading* titles. A shared `LibraryCubit` keeps bookmarks from Details in sync with the Library tab.
- **📝 Personal Book Notes & Reviews**: Add, edit, and persist personal notes or reviews for any saved book in your library via an interactive dialog (`BookNotesDialog`). A visual note indicator highlights books with saved notes.
- **📡 Real-Time Connectivity Monitoring**: Live internet connection tracking powered by `connectivity_plus`. Automatically displays a top animated `OfflineBanner` whenever the device disconnects from the network.
- **💾 Library Backup & Restore**: Export a formatted JSON backup through the system share sheet (`share_plus` + temp file). Import a `.json` file via `file_picker` and merge into Hive.
- **🧱 Staggered Masonry Layout**: Saved titles render in an adaptive 2-column masonry grid (`flutter_staggered_grid_view`).
- **🏠 Home Feed**: Weekly trending carousel (Hive cache, 8-hour TTL), English-biased category chips, pull-to-refresh, a search icon that jumps to Explore, and a settings icon.
- **⚙️ Settings & Appearance**: System / Light / Dark theme (`ThemeCubit` + SharedPreferences), clear home cache, clear search history, and an About section.
- **🏠 Home-to-Explore Deep Linking**: "See All" on the featured carousel navigates to Explore and loads trending books via `MainNavigationView.navigateToExploreWithQuery`.
- **🚀 Interactive Onboarding**: Three Lottie slides (Discover / Open Book Pages / Build Your Library) with accurate copy — the app does not claim an in-app PDF reader. State is persisted with `SharedPreferences`.
- **🛡️ Robust Error Handling & Crash Recovery**: Defensive Hive box opening (`_openBoxSafe`) with automatic corruption recovery, enhanced `ServerFailure` (408, 429, 502, 503 status codes + `SocketException` checks), `DioFactory` debug logging, and theme-aware error displays.

---

## 🛠️ Tech Stack & Architecture

### **Technology Stack**

| Layer | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter (SDK `^3.12.2`) | Cross-platform UI development |
| **Language** | Dart (`^3.12.2`) | Strongly typed application logic |
| **Architecture** | Feature-first + Cubit + repository interfaces | UI → Cubit → Repo → ApiService / Hive |
| **Dependency Injection** | `ServiceLocator` | Shared `ApiService` and repository instances |
| **State Management** | `flutter_bloc` / Cubit | Predictable, reactive state management |
| **Networking** | `dio` & `connectivity_plus` | Centralized `DioFactory`, timeouts, connectivity listener |
| **Metadata API** | Open Library REST API | Works, search, ratings, editions, trending |
| **Reader / extra search** | Internet Archive | Public text search and 2-up reader URLs |
| **Local Storage** | `hive` & `hive_flutter` | Offline favorites, notes, and home-feed cache |
| **Preferences** | `shared_preferences` | Onboarding, recent searches, theme mode |
| **Backup** | `share_plus`, `file_picker`, `path_provider` | Library JSON export and file import |
| **Grid Layout** | `flutter_staggered_grid_view` | Masonry grid for the saved library |
| **Functional Error Handling** | `dartz` & `equatable` | `Either<Failure, T>` flow and value equality |
| **Navigation & Routes** | `go_router` & `AppRoutes` | Declarative routes, constants, 404 fallback |
| **Animations** | `lottie` | Vector animations for onboarding |
| **UI Components** | `smooth_page_indicator`, `shimmer`, `ShimmerContainer` | Page indicators and shared skeleton loading |
| **External Actions** | `url_launcher` | Opening Archive.org reader URLs |
| **Design System** | Centralized `AppColors` & `AppTheme` | Light/dark `ThemeData`, `google_fonts` (Inter) |
| **Image Caching** | `cached_network_image` | Cover caching with fallbacks |

### **Architecture Overview**

Libris uses a **feature-first** layout with Cubits talking to repository interfaces. There is no separate use-case / entity layer.

```
                  ┌─────────────────────────────────────┐
                  │          Presentation Layer         │
                  │  (Views, Widgets, Cubits, States)   │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │         Repository Contracts        │
                  │  HomeRepo, SearchRepo, DetailsRepo, │
                  │           FavoritesRepo             │
                  └──────────────────▲──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │             Data Layer              │
                  │  ApiService, Hive, Model mapping    │
                  └─────────────────────────────────────┘
```

- **Presentation**: `flutter_bloc` Cubits emit Loading / Success / Failure (and Empty where relevant). `ThemeCubit`, `LibraryCubit`, and `ConnectivityCubit` are provided at the application root.
- **Repositories**: Interfaces live next to implementations under each feature’s `data/repos/` folder. Defaults come from `ServiceLocator`.
- **Data**: `ApiService` talks to Open Library and Archive.org via Dio `queryParameters`. Hive stores the home cache and personal library with notes.

---

## 📁 Project Structure

```text
lib/
├── constants/
├── app_colors.dart             # Brand palette & semantic tokens
│   └── hive_constants.dart         # Hive box names
├── core/
│   ├── di/
│   │   └── service_locator.dart    # ApiService + repository singletons
│   ├── errors/
│   │   └── failure.dart            # Equatable ServerFailure, FormatFailure, CacheFailure
│   ├── models/
│   │   └── book_model.dart         # Equatable BookModel + Archive mapping & notes helpers
│   ├── services/
│   │   ├── connectivity_cubit.dart # Real-time network state management
│   │   ├── onboarding_service.dart
│   │   └── search_history_service.dart
│   ├── theme/
│   │   └── app_theme.dart          # Light/dark cached ThemeData + LibrisTheme extension
│   ├── utils/
│   │   ├── api_service.dart        # Open Library + Archive.org client (queryParameters)
│   │   ├── app_routes.dart         # Centralized route path constants
│   │   ├── dio_factory.dart        # Shared Dio instance + Debug LogInterceptor
│   │   └── styles.dart             # Inter typography helpers
│   └── widgets/
│       ├── custom_bottom_navigation_bar.dart
│       ├── custom_error_widget.dart# Theme-aware error display
│       ├── offline_banner.dart     # Top animated offline notification
│       ├── page_transitions.dart   # RTL-aware page transition animator
│       ├── router.dart             # GoRouter routes + 404 error handler
│       └── shimmer_container.dart  # Shared skeleton loading placeholder
├── features/
│   ├── details/                    # OL metadata, similar books, Archive reader
│   ├── explore/                    # Merged search, subjects, welcome hub
│   ├── home/                       # Featured carousel + category lists
│   ├── library/                    # Offline collections, sort, notes, backup
│   ├── main/                       # Tab shell (Home / Explore / Library)
│   ├── onboarding/                 # First-launch walkthrough
│   ├── settings/                   # Theme, cache, about
│   └── splash/                     # Launch screen
└── main.dart                       # Safe Hive init + ServiceLocator + Root providers
test/
├── core/
│   ├── errors/
│   │   └── failure_test.dart       # Unit tests for ServerFailure & Dio error mapping
│   └── models/
│       └── book_model_test.dart    # Unit tests for BookModel parsing, equality, helpers
├── onboarding_test.dart
├── search_history_service_test.dart
└── widget_test.dart
```

**Android**: application id / namespace `com.mohamed.libris`, display label `Libris`, `INTERNET` in the main manifest.  
**iOS**: display name `Libris`.

---

## 🛡️ Error Handling Architecture

Libris maps network, socket, parsing, and database failures into domain `Failure` objects before they reach the UI.

```text
┌────────────────┐      ┌─────────────────────────┐      ┌───────────────────────┐      ┌──────────────────────┐
│ DioFactory /   │ ───► │   ServerFailure Factory │ ───► │  Either<Failure, T>   │ ───► │  CustomErrorWidget   │
│ Socket Error   │      │  Sanitizes Status Codes │      │ (Functional Return)   │      │ (User Retry Button)  │
└────────────────┘      └─────────────────────────┘      └───────────────────────┘      └──────────────────────┘
```

### **Failure Class Hierarchy & Persistence Safety**

- **`ServerFailure`**: Extends `Equatable`. Maps `DioException` types (timeouts, bad certificate, 4xx/5xx, offline) and HTTP status codes (400, 401, 403, 404, 408, 429, 500, 502, 503) to readable messages. Detects `SocketException` errors safely.
- **`CacheFailure`**: Reserved for local persistence errors.
- **`FormatFailure`**: JSON / mapping errors.
- **`_openBoxSafe` Recovery**: On application launch, Hive box opening is wrapped in corruption recovery logic that automatically deletes corrupted box files from disk and retries, preventing fatal startup crashes.

Explore pagination failures emit `ExploreSuccess` with `loadMoreError` so the current result list is preserved. Library Hive errors emit `LibraryFailure`.

---

## 🚀 Getting Started / Installation

### **Prerequisites**

- **Flutter SDK**: `>= 3.12.2` ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: Bundled with Flutter
- **Git**

### **Installation Steps**

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Mohamed3li454/libris_app.git
   cd libris_app
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the Application**:
   ```bash
   flutter run
   ```

4. **Run Unit & Widget Tests**:
   ```bash
   flutter test
   ```

No `.env` file or API key is required. Open Library and Internet Archive are used without authentication.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
