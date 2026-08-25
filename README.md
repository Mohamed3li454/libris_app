<div align="center">

# 📚 Libris

**Discover, Explore, and Manage Your Personal Library with Elegance**

A modern, high-performance Flutter application built for seamless book discovery, real-time search, interactive previews, and offline personal library management. Powered by Open Library REST APIs and engineered with Clean Architecture principles.

[![Flutter](https://img.shields.io/badge/Flutter-3.12+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-765A1F?style=for-the-badge)](https://flutter.dev)
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

**Libris** is a modern book discovery and library management mobile application. Designed around a warm, vintage-inspired **Warm Ivory** aesthetic (`#F0EADE`), Libris empowers readers to browse trending literature, search millions of titles via the Open Library API with paginated results, view rich book metadata and previews, and save favorite titles locally for offline reading — all backed by recent search history and smart genre discovery.

---

## ✨ Key Features

- **🔍 Book Exploration & Search**: Real-time multi-criteria search by title, author, or genre. Built with 400ms input debouncing, minimum 3-character query validation, and paginated results (20 items per page) with infinite scroll and a "Load more" fallback.
- **🧭 Smart Explore Welcome Screen**: Contextual discovery hub showing recent search history (persisted via `SharedPreferences`), trending topic suggestions (`#` tags), a 10-genre browse grid (`ExploreGenresGrid`), and author recommendations pulled from your saved library.
- **📚 Comprehensive Book Details**: Deep-dive into metadata including detailed overview summaries, author credits, publication year, average ratings, and instant action controls (*Read Now* / *Download PDF* via `url_launcher`).
- **❤️ Personal Library & Collections**: Organize saved books into custom reading categories (*Favorites*, *Want to Read*, *Finished*) with live filter chips and seamless collection switching.
- **💾 Library Backup & Restore**: One-tap export to generate formatted JSON backups directly to the clipboard, alongside an import modal to restore or merge saved books into offline Hive storage.
- **🧱 Staggered Masonry Layout**: Saved titles are rendered in an adaptive, 2-column **Masonry grid** layout (`flutter_staggered_grid_view`) with dynamic cover aspect ratios.
- **🏠 Home-to-Explore Deep Linking**: "See All" on the featured carousel navigates directly to the Explore tab and loads trending books via `MainNavigationView.navigateToExploreWithQuery`.
- **🚀 Interactive Onboarding Walkthrough**: Engaging multi-screen onboarding guide introducing app features with custom vector Lottie animations (`search_list.json`, `read_icon.json`, `save.json`) and `smooth_page_indicator`, backed by `SharedPreferences` for persistent launch state tracking.
- **🛡️ Robust Error Handling & Shimmer Feedback**: Centralized error sanitization via `DioFactory` timeouts and `ServerFailure.fromDioError`, paired with smooth skeleton shimmer loading states across all feeds.

---

## 🛠️ Tech Stack & Architecture

### **Technology Stack**

| Layer | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter (SDK `^3.12.2`) | Cross-platform UI development |
| **Language** | Dart (`^3.12.2`) | Strongly typed application logic |
| **Architecture** | Feature-first Clean Architecture | Separation of concerns (Data, Domain, Presentation) |
| **State Management**| `flutter_bloc` / Cubit | Predictable, reactive state management |
| **Networking** | `dio` & Open Library API | HTTP requests via centralized `DioFactory`, timeout handling, and paginated response parsing |
| **Local Storage** | `hive` & `hive_flutter` | Fast key-value offline storage for favorites & cache |
| **Preferences** | `shared_preferences` | Onboarding state, recent search history & app configuration persistence |
| **Grid Layout** | `flutter_staggered_grid_view` | Masonry-style staggered grid for the saved books library |
| **Functional Error Handling** | `dartz` | `Either<Failure, T>` functional programming error flow |
| **Navigation** | `go_router` | Declarative route management and deep-linking |
| **Animations** | `lottie` | Rich vector JSON animations for interactive onboarding |
| **UI Components** | `smooth_page_indicator`, `shimmer` | Page indicators and visual shimmer loading feedback |
| **External Actions** | `url_launcher` | Opening reader URLs and external PDF download links |
| **Design System** | Custom Warm Ivory Theme | Custom palette, `google_fonts`, `flutter_screenutil_plus` |
| **Image Caching** | `cached_network_image` | Efficient image caching with placeholder shimmer support |

---

### **Architecture Overview**

Libris adheres to **Clean Architecture** combined with a **Feature-First** organizational approach:

```
                  ┌─────────────────────────────────────┐
                  │          Presentation Layer         │
                  │  (Views, Widgets, Cubits, States)   │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │            Domain Layer             │
                  │ (Entities, Use Cases, Repositories) │
                  └──────────────────▲──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │             Data Layer              │
                  │(Models, Data Sources, Repo Impls)   │
                  └─────────────────────────────────────┘
```

- **Data Layer**: Manages external data sources (`ApiService`, Open Library REST API) and local database storage (`Hive`). Converts raw JSON responses into strongly-typed Data Models.
- **Domain Layer**: Contains business rules, repository interfaces (`HomeRepo`, `SearchRepo`, `FavoritesRepo`), and core entities. Uses `dartz` `Either<Failure, T>` return types for safe error propagation.
- **Presentation Layer**: Built with `flutter_bloc` (Cubit pattern). UI components listen to state streams (`Loading`, `Success`, `Failure`) and trigger user interactions cleanly separated from underlying business logic.

---

## 📁 Project Structure

```text
lib/
├── constants/
│   ├── api_constants.dart          # API key from environment variables
│   ├── app_colors.dart             # Palette definitions (Warm Ivory, Accents)
│   └── hive_constants.dart         # Hive box names and storage keys
├── core/
│   ├── errors/
│   │   └── failure.dart            # Failure hierarchy (Server, Cache, Format)
│   ├── models/
│   │   └── book_model.dart         # Core Book data model
│   ├── services/
│   │   ├── onboarding_service.dart # Onboarding state persistence
│   │   └── search_history_service.dart # Recent search history (SharedPreferences)
│   ├── utils/
│   │   ├── api_service.dart        # Dio client wrapper & paginated request handler
│   │   ├── dio_factory.dart        # Centralized Dio instance with timeouts & headers
│   │   └── styles.dart             # Typography & TextStyle definitions
│   └── widgets/
│       ├── custom_bottom_navigation_bar.dart
│       ├── custom_error_widget.dart# Standardized UI error feedback & retry
│       └── router.dart             # GoRouter route configurations
├── features/
│   ├── details/                    # Book Details feature module
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repos/
│   │   └── presentation/
│   │       ├── manager/            # BookDetailsCubit
│   │       └── view/
│   ├── explore/                    # Search & Category Exploration feature module
│   │   ├── data/
│   │   └── presentation/           # ExploreCubit, pagination, welcome screen widgets
│   ├── home/                       # Home Feed & Filtered Lists feature module
│   │   ├── data/
│   │   └── presentation/           # FeaturedBooksCubit & FilterBooksCubit
│   ├── library/                    # Favorites & Offline Library feature module
│   │   ├── data/
│   │   └── presentation/           # LibraryCubit & Masonry saved-books grid
│   ├── main/                       # Main Navigation Container view
│   ├── onboarding/                 # First-Time User Experience (FTUE) walkthrough
│   └── splash/                     # Splash screen initialization
└── main.dart                       # Application entry point & Hive initialization
test/
├── fetch_featured_test.dart        # Featured books repository integration test
├── onboarding_test.dart            # Onboarding service unit test
├── search_history_service_test.dart# Search history persistence unit test
└── widget_test.dart                # Default Flutter widget smoke test
```

---

## 🛡️ Error Handling Architecture

Libris utilizes a centralized, fail-safe error handling pipeline. Exceptions occurring at the network, socket, parsing, or database level are intercepted and mapped into unified `Failure` domain objects before reaching the UI.

```text
┌────────────────┐      ┌─────────────────────────┐      ┌───────────────────────┐      ┌──────────────────────┐
│ DioFactory /   │ ───► │   ServerFailure Factory │ ───► │  Either<Failure, T>   │ ───► │  CustomErrorWidget   │
│ Socket Error   │      │  Sanitizes Status Codes │      │ (Functional Return)   │      │ (User Retry Button)  │
└────────────────┘      └─────────────────────────┘      └───────────────────────┘      └──────────────────────┘
```

### **Failure Class Hierarchy**

- **`ServerFailure`**: Intercepts `DioException` types (Connection Timeout, Bad Certificate, 4xx/5xx responses, No Internet connection) and translates raw HTTP status codes or socket timeouts into clean, human-readable UI notifications.
- **`CacheFailure`**: Wraps local database storage errors when reading or persisting favorite books in Hive boxes.
- **`FormatFailure`**: Handles data mapping and JSON deserialization errors gracefully.

---

## 🚀 Getting Started / Installation

### **Prerequisites**

Ensure you have the following installed on your machine:
- **Flutter SDK**: `>= 3.12.2` ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: Included with Flutter SDK
- **Git**

### **Installation Steps**

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Mohamed3li454/libris_app.git
   cd libris_app
   ```

2. **Configure Environment Variables**:
   Create a `.env` file in the root directory (or copy from `.env.example`):
   ```bash
   cp .env.example .env
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the Application**:
   ```bash
   flutter run
   ```

5. **Run Tests** (optional):
   ```bash
   flutter test
   ```

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.