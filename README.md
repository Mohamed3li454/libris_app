<div align="center">

# 📚 Libris

**Discover, Explore, Read, and Manage Your Personal Library with Elegance**

A modern, high-performance Flutter application engineered for seamless book discovery, dual-source search, in-app reading (Safari-style Webview & Offline PDF Reader with Full Read Mode), background book downloads, and offline personal library management. Powered by Open Library and Internet Archive APIs, and built with a clean feature-first Cubit architecture.

[![Flutter](https://img.shields.io/badge/Flutter-3.12+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--First%20%2B%20Cubit-765A1F?style=for-the-badge)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State%20Management-Flutter%20Bloc%20%2F%20Cubit-42A5F5?style=for-the-badge&logo=bloc&logoColor=white)](https://bloclibrary.dev)
[![Storage](https://img.shields.io/badge/Local%20Storage-Hive-FF6F00?style=for-the-badge)](https://docs.hivedb.dev)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20APK%20Build-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)](.github/workflows/build_apk.yml)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

---

</div>

## 📖 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Tech Stack & Architecture](#-tech-stack--architecture)
- [Project Structure](#-project-structure)
- [Readers & Download Architecture](#-readers--download-architecture)
- [Error Handling Architecture](#-error-handling-architecture)
- [CI/CD & Automated Builds](#-cicd--automated-builds)
- [Getting Started / Installation](#-getting-started--installation)
- [License](#-license)

---

## 🌟 Overview

**Libris** is an all-in-one book discovery, reader, and library management application. Designed around a warm, vintage-inspired **Warm Ivory** aesthetic (`#F0EADE`) with a matching dark theme, Libris lets readers browse trending literature, search millions of titles, read directly inside the app, download public domain books for offline reading, and organize personal collections.

Metadata (descriptions, ratings, language, editions, similar titles) is fetched from **Open Library**. Explore search concurrently queries **Internet Archive** to surface readable copies — including Arabic and international literature that Open Library often misses.

### 📖 Dual Reading Experiences:
1. **In-App Safari-Style Webview Reader**: Read books online instantly with an iOS Safari-inspired floating control capsule, text zoom sheet (60% to 200%), page sharing, and copy link tools.
2. **In-App PDF Reader with Immersive Full Read Mode**: Downloaded books open inside a high-speed pinch-to-zoom PDF reader (`pdfx`). Readers can switch into **Full Read Mode (وضع القراءة الكاملة)** for a 100% distraction-free experience with edge-to-edge pages, hidden system bars, auto-hiding toolbars, and session progress tracking.

---

## ✨ Key Features

- **🔍 Dual-Source Search & Smart Explore**: Real-time search across Open Library and Internet Archive with 650ms debouncing, a 2-character minimum, active request cancellation (`_activeRequestId`) to prevent typing race conditions, paginated results (20 items per page), and infinite scroll. Open Library results are listed first; Archive.org-only titles that are not already in OL are appended. Latin queries prefer English; Arabic queries preserve Arabic script.
- **🧭 Contextual Explore Welcome Hub**: Displays recent search history (`SharedPreferences`), trending topic chips, a 10-genre browse grid (`ExploreGenresGrid`), and author recommendations from your personal library.
- **🌐 In-App Safari-Style Webview Reader (`BookReaderView`)**: Native in-app reader powered by `webview_flutter`. Features a floating bottom capsule with SSL security status, domain name indicator, back navigation, and reload action. Tap the capsule to open a blur bottom sheet with text zoom controls (smaller/larger `A` from 60% to 200%), link sharing, and external browser launch.
- **📄 In-App PDF Reader & Full Read Mode (`PdfReaderView`)**:
  - High-performance pinch-to-zoom and multi-page scrolling powered by `pdfx`.
  - **Reading Progress Tracking**: Automatically saves and restores the last-read page across app restarts via `PdfProgressService`.
  - **Go to Page**: Jump directly to any page number using a numeric input dialog.
  - **Immersive Full Read Mode (وضع القراءة الكاملة)**: Pages fill the screen edge-to-edge with `padding: 0`, 0 system margins, and no drop shadows. Consecutive pages stack seamlessly. Hides the status bar and navigation bar (`SystemUiMode.immersiveSticky`), hides the toolbar until tapped, and features `PopScope` protection so the Android back gesture exits Full Read Mode first rather than closing the book.
- **⬇️ Background Book Downloads (`DownloadsCubit` & `DownloadService`)**:
  - Downloads public domain PDFs from Internet Archive and Open Library with dedicated `Dio` streaming.
  - Supports pause, resume, retry, and cancellation with byte-range resume (`Range: bytes={startByte}-`).
  - Automatic validation with `%PDF` magic byte verification (`fileLooksLikePdf`) to ensure downloaded files are valid PDFs rather than HTML error pages.
  - Dedicated **Downloads Screen** (`DownloadsView`) with progress percentages, file sizes, and active download badge count in the Library tab.
- **🌊 Water Fill Download Button (`WaterFillDownloadButton`)**: An interactive download button on book details featuring dual sinusoidal wave animations (`_WaterPainter`) and animated label clipping that transitions between dry and wet colors as the download fills.
- **💬 Custom Toast & Overlay System (`AppDialog`)**: Unified top notification overlay (`AppDialog.success`, `error`, `info`) with haptic feedback, fluid slide/fade animations (`easeOutBack`), elastic icon pop, and swipe-up dismissal, replacing third-party toast dependencies.
- **❤️ Personal Library & Collections**: Organize saved titles into *All*, *Want to Read*, *Reading*, *Finished*, and *Favorites*, with live counts, sorting (recently added, title, year), and reading progress sliders on *Reading* books.
- **📡 Real-Time Connectivity Monitoring**: Live network tracking powered by `connectivity_plus`. Displays a top animated `OfflineBanner` whenever the device disconnects.
- **💾 Library Backup & Restore**: Export a formatted JSON backup through the system share sheet (`share_plus`). Import a `.json` backup file via `file_picker` and merge into Hive.
- **🧱 Staggered Masonry Layout**: Saved books render in an adaptive 2-column masonry grid (`flutter_staggered_grid_view`).
- **🏠 Home Feed**: Weekly trending carousel (Hive cache, 8-hour TTL), English-biased category chips with scale micro-animations, pull-to-refresh, search shortcut, and settings shortcut.
- **⚙️ Settings & Appearance**: System / Light / Dark theme (`ThemeCubit` + SharedPreferences), clear home cache, clear search history, and About section.
- **🚀 Interactive Onboarding**: Three Lottie slides (Discover / Open Book Pages / Build Your Library) with persistent first-launch flag in `SharedPreferences`.

---

## 🛠️ Tech Stack & Architecture

### **Technology Stack**

| Layer | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter (SDK `^3.12.2`) | Cross-platform UI development (Material 3) |
| **Language** | Dart (`^3.12.2`) | Strongly typed, null-safe application logic |
| **Architecture** | Feature-first + Cubit + repository interfaces | UI → Cubit → Repo → ApiService / Hive / DownloadService |
| **Dependency Injection** | `ServiceLocator` | Centralized repository and service singletons |
| **State Management** | `flutter_bloc` / Cubit | Predictable, reactive state management |
| **Networking** | `dio` & `connectivity_plus` | Centralized `DioFactory`, timeouts, download streaming, network listener |
| **Metadata API** | Open Library REST API | Works, search, ratings, editions, trending |
| **Archive & Full Text** | Internet Archive API | Public search, metadata, reader URLs, direct PDF downloads |
| **In-App Webview** | `webview_flutter` | Safari-style in-app reader for Internet Archive scans |
| **In-App PDF Viewer** | `pdfx` | Pinch-to-zoom PDF rendering with Full Read Mode |
| **Local Storage** | `hive` & `hive_flutter` | Offline library, downloads metadata, and home feed cache |
| **Preferences** | `shared_preferences` | Onboarding state, search history, theme mode, PDF page progress |
| **Backup** | `share_plus`, `file_picker`, `path_provider` | Library JSON backup export and file import |
| **Grid Layout** | `flutter_staggered_grid_view` | Masonry grid for saved books |
| **Functional Error Handling** | `dartz` & `equatable` | `Either<Failure, T>` return pattern and value equality |
| **Navigation & Routes** | `go_router` & `AppRoutes` | Declarative routing, iOS fluid modal page transitions (`fadeUpFadeRightPage`) |
| **Animations** | `lottie` | Vector animations for onboarding slides |
| **UI Components** | `smooth_page_indicator`, `shimmer`, `ShimmerContainer` | Page indicators and shared skeleton loading |
| **Design System** | Centralized `AppColors` & `AppTheme` | Warm Ivory light/dark `ThemeData`, `google_fonts` (Inter) |
| **Image Caching** | `cached_network_image` | Book cover caching with fallbacks |

---

## 📁 Project Structure

```text
lib/
├── constants/
│   ├── app_colors.dart                 # Brand palette, dark/light semantic tokens
│   └── hive_constants.dart             # Hive box name constants
├── core/
│   ├── di/
│   │   └── service_locator.dart        # Repositories, ApiService, DownloadService singletons
│   ├── errors/
│   │   └── failure.dart                # ServerFailure, FormatFailure, CacheFailure
│   ├── models/
│   │   └── book_model.dart             # BookModel entity + JSON/Archive mapping
│   ├── services/
│   │   ├── connectivity_cubit.dart     # Real-time network monitor & state
│   │   ├── onboarding_service.dart     # SharedPreferences first-time launch flag
│   │   ├── pdf_progress_service.dart   # PDF reading page persistence
│   │   └── search_history_service.dart # SharedPreferences recent searches
│   ├── theme/
│   │   └── app_theme.dart              # Light/dark ThemeData & LibrisTheme extension
│   ├── utils/
│   │   ├── api_service.dart            # Open Library + Internet Archive REST client
│   │   ├── app_routes.dart             # Centralized route name constants
│   │   ├── dio_factory.dart            # Shared API Dio & dedicated Download Dio
│   │   ├── pdf_file_utils.dart         # %PDF magic byte file validation
│   │   └── styles.dart                 # Typography helpers
│   └── widgets/
│       ├── app_dialog.dart             # Custom top animated toast/dialog overlay
│       ├── custom_bottom_navigation_bar.dart
│       ├── custom_error_widget.dart    # Theme-aware error display
│       ├── fade_slide_in.dart          # Staggered list view entrance animator
│       ├── offline_banner.dart         # Top animated offline notification
│       ├── page_transitions.dart       # RTL-aware slide & iOS fluid modal transitions
│       ├── router.dart                 # GoRouter route declarations & 404 handler
│       └── shimmer_container.dart      # Shared skeleton loader
├── features/
│   ├── details/                        # Book overview, similar books, action bottom bar
│   │   └── presentation/view/
│   │       ├── book_reader_view.dart   # In-app Safari-style Webview reader
│   │       └── widgets/
│   │           └── water_fill_download_button.dart # Animated wave download button
│   ├── downloads/                      # Background downloads manager & PDF viewer
│   │   ├── data/
│   │   │   ├── models/download_item.dart
│   │   │   ├── repos/downloads_repo.dart
│   │   │   └── services/download_service.dart
│   │   └── presentation/
│   │       ├── manager/downloads_cubit/
│   │       └── view/
│   │           ├── downloads_view.dart # Downloads queue and completed list
│   │           └── pdf_reader_view.dart# In-app PDF reader with Full Read Mode
│   ├── explore/                        # Dual-source search, subject chips, welcome hub
│   ├── home/                           # Featured carousel + filter chips list
│   ├── library/                        # Offline collections, sort, JSON backup
│   ├── main/                           # Bottom navigation shell (Home / Explore / Library)
│   ├── onboarding/                     # First-launch walkthrough slides
│   ├── settings/                       # Theme mode, cache cleanup, about
│   └── splash/                         # Launch screen
└── main.dart                           # Safe Hive init + Root Cubit providers
```

---

## 📖 Readers & Download Architecture

```
                                    ┌───────────────────────┐
                                    │   Book Details View   │
                                    └───────────┬───────────┘
                                                │
                       ┌────────────────────────┴────────────────────────┐
                       ▼                                                 ▼
             [ Read Now Button ]                              [ Download PDF Button ]
                       │                                                 │
                       ▼                                                 ▼
        ┌───────────────────────────────┐                 ┌───────────────────────────────┐
        │        BookReaderView         │                 │        DownloadsCubit         │
        │       (webview_flutter)       │                 │  Enqueues & Downloads via Dio │
        │  • iOS Safari floating pill   │                 │  Validates %PDF byte signature│
        │  • Text Zoom: 60% – 200%      │                 └──────────────┬────────────────┘
        │  • Share & Copy Link          │                                │
        └───────────────────────────────┘                                ▼
                                                          ┌───────────────────────────────┐
                                                          │         PdfReaderView         │
                                                          │            (pdfx)             │
                                                          │  • Pinch-to-zoom 1x – 6x      │
                                                          │  • Progress auto-saved        │
                                                          │  • Immersive Full Read Mode   │
                                                          │    (0 padding, hidden bars)   │
                                                          └───────────────────────────────┘
```

---

## 🛡️ Error Handling Architecture

Libris maps network, socket, parsing, and database failures into domain `Failure` objects before they reach the UI.

- **`ServerFailure`**: Extends `Equatable`. Maps `DioException` types (timeouts, bad certificate, 4xx/5xx, offline) and HTTP status codes (400, 401, 403, 404, 408, 429, 500, 502, 503) to readable messages. Detects `SocketException` safely.
- **`CacheFailure`**: Reserved for local persistence errors.
- **`FormatFailure`**: JSON / mapping errors.
- **`_openBoxSafe` Recovery**: On application launch, Hive box opening is wrapped in corruption recovery logic that automatically deletes corrupted box files from disk and retries, preventing fatal startup crashes.
- **Download Safety**: Downloads are validated using `%PDF` file header checks (`fileLooksLikePdf`) to ensure corrupt files are discarded.

---

## 🤖 CI/CD & Automated Builds

Libris includes an automated GitHub Actions workflow (`.github/workflows/build_apk.yml`) that runs on every push and pull request to `main` and `master`:

1. **Environment Setup**: Configures Java 17 and Flutter stable.
2. **Quality Checks**: Resolves dependencies (`flutter pub get`) and runs all unit & widget tests (`flutter test`).
3. **Artifact Compilation**: Builds a release APK (`flutter build apk --release`).
4. **Artifact Upload**: Uploads `libris-release-apk` for direct download with 30-day retention.

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

No `.env` file or API key is required. Open Library and Internet Archive are queried without authentication.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
