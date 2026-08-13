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

**Libris** is a modern book discovery and library management mobile application. Designed around a warm, vintage-inspired **Warm Ivory** aesthetic (`#F0EADE`), Libris empowers readers to browse trending literature, search millions of titles via the Open Library API, view rich book metadata and previews, and save favorite titles locally for offline reading.

---

## ✨ Key Features

- **🔍 Book Exploration & Search**: Real-time multi-criteria search by title, author, or genre. Built with input debouncing and minimum query validation to optimize API request efficiency and minimize latency.
- **📚 Comprehensive Book Details**: Deep-dive into metadata including detailed overview summaries, author credits, edition counts, average ratings, and instant action controls (*Read Preview* / *Download PDF*).
- **❤️ Personal Library & Offline Favorites**: Save favorite books locally with one-tap persistence using Hive. Saved titles are neatly rendered in an adaptive 2-column grid layout accessible offline.
- **🚀 First-Time Onboarding Walkthrough**: Interactive multi-screen onboarding guide introducing app features to new users, backed by `SharedPreferences` for persistent launch state tracking.
- **🛡️ Robust Error Handling & Fallbacks**: Centralized error sanitization mapping low-level network and API errors into friendly user messages, complete with custom retry states and shimmer loading screens.

---

## 🛠️ Tech Stack & Architecture

### **Technology Stack**

| Layer | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter (SDK `^3.12.2`) | Cross-platform UI development |
| **Language** | Dart (`^3.12.2`) | Strongly typed application logic |
| **Architecture** | Feature-first Clean Architecture | Separation of concerns (Data, Domain, Presentation) |
| **State Management**| `flutter_bloc` / Cubit | Predictable, reactive state management |
| **Networking** | `dio` & Open Library API | HTTP requests, timeout handling, and response parsing |
| **Local Storage** | `hive` & `hive_flutter` | Fast key-value offline storage for favorites & cache |
| **Preferences** | `shared_preferences` | Onboarding state & app configuration persistence |
| **Functional Error Handling** | `dartz` | `Either<Failure, T>` functional programming error flow |
| **Navigation** | `go_router` | Declarative route management and deep-linking |
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
│   ├── api_constants.dart          # API endpoints, query params, and base URLs
│   ├── app_colors.dart             # Palette definitions (Warm Ivory, Accents)
│   └── hive_constants.dart         # Hive box names and storage keys
├── core/
│   ├── errors/
│   │   └── failure.dart            # Sealed Failure hierarchy (Server, Cache, Format)
│   ├── models/
│   │   └── book_model.dart         # Core Book data model
│   ├── services/
│   │   └── onboarding_service.dart # Onboarding state persistence
│   ├── utils/
│   │   ├── api_service.dart        # Dio client wrapper & request handler
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
│   │   └── presentation/           # ExploreCubit & Search TextField widgets
│   ├── home/                       # Home Feed & Filtered Lists feature module
│   │   ├── data/
│   │   └── presentation/           # FeaturedBooksCubit & FilterBooksCubit
│   ├── library/                    # Favorites & Offline Library feature module
│   │   ├── data/
│   │   └── presentation/           # LibraryCubit & 2-column Saved Books Grid
│   ├── main/                       # Main Navigation Container view
│   ├── onboarding/                 # First-Time User Experience (FTUE) walkthrough
│   └── splash/                     # Splash screen initialization
└── main.dart                       # Application entry point & Hive initialization
```

---

## 🛡️ Error Handling Architecture

Libris utilizes a centralized, fail-safe error handling pipeline. Exceptions occurring at the network, socket, parsing, or database level are intercepted and mapped into unified `Failure` domain objects before reaching the UI.

```text
┌────────────────┐      ┌─────────────────────────┐      ┌───────────────────────┐      ┌──────────────────────┐
│  Dio / Socket  │ ───► │   ServerFailure Factory │ ───► │  Either<Failure, T>   │ ───► │  CustomErrorWidget   │
│   Exception    │      │  Sanitizes Status Codes │      │ (Functional Return)   │      │ (User Retry Button)  │
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

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.