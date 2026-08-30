# Libris App — Comprehensive Project Context & Technical Reference

> **Document Purpose**: This document is the technical reference for the Libris Flutter application. It describes architecture, API contracts, state management, models, persistence, and navigation strictly as implemented in the codebase.

---

## Table of Contents

1. [Project Overview & Architecture](#project-overview--architecture)
2. [Bootstrap, DI & Theming](#bootstrap-di--theming)
3. [API Layer](#1-api-layer)
    - [DioFactory & ApiService](#dio-client--apiservice-configuration)
    - [Open Library Endpoints](#open-library-endpoints)
    - [Internet Archive Endpoints](#internet-archive-endpoints)
    - [Feature API Contracts](#feature-api-endpoints--contract-details)
4. [Search Merge & Reader Resolution](#search-merge--reader-resolution)
5. [State Management (Cubits)](#2-state-management-cubits)
6. [Domain Layer](#3-domain-layer)
7. [Data Layer](#4-data-layer)
8. [Local Storage](#5-local-storage-hive--sharedpreferences)
9. [Routing & Navigation](#6-routing--navigation)

---

## Project Overview & Architecture

- **Application Name**: Libris
- **Language**: Dart (SDK `^3.12.2`)
- **Framework**: Flutter (Material 3)
- **Architecture Pattern**: Feature-first packaging + Cubit state management + repository interfaces. There is no separate use-case / entity layer.
- **Android**: `applicationId` and namespace `com.mohamed.libris`; label `Libris`; `INTERNET` declared in the **main** `AndroidManifest.xml`.
- **iOS**: `CFBundleDisplayName` / `CFBundleName` = `Libris`.
- **Key Runtime Dependencies**: `dio`, `dartz`, `flutter_bloc`, `equatable`, `hive` / `hive_flutter`, `go_router`, `cached_network_image`, `shimmer`, `shared_preferences`, `google_fonts`, `lottie`, `smooth_page_indicator`, `url_launcher`, `flutter_staggered_grid_view`, `share_plus`, `file_picker`, `path_provider`, `connectivity_plus`.

**Removed from the project** (do not document as current): `flutter_dotenv`, `http`, `flutter_screenutil_plus`, `lib/constants/api_constants.dart`, `.env` bootstrap.

```
UI (Views / Widgets)
        │
     Cubit
        │
  Repo interface   (lives under features/*/data/repos/)
        │
   Repo impl  →  ApiService / Dio  or  Hive
```

Cubits default to `ServiceLocator` instances and accept optional constructor injection for tests.

---

## Bootstrap, DI & Theming

### `main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await _openBoxSafe(kFeaturedBox);
  await _openBoxSafe(kFilterBox);
  await _openBoxSafe(kFavoritesBox);
  ServiceLocator.init();
  runApp(const MyApp());
}

Future<void> _openBoxSafe(String boxName) async {
  try {
    await Hive.openBox(boxName);
  } catch (_) {
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox(boxName);
  }
}
```

`MyApp` provides:

- `ThemeCubit` — persisted `ThemeMode`
- `LibraryCubit` — **app-scoped** so Details bookmarks refresh the Library tab
- `ConnectivityCubit` — **app-scoped** internet connectivity monitor (`checkConnectivity()`)

`MaterialApp.router` configures `AppTheme.light`, `AppTheme.dark`, `themeMode` from `ThemeCubit`, and `routerConfig` from `router`. The `builder` function wraps the app shell in a `Stack` featuring an animated top `OfflineBanner` triggered when `ConnectivityCubit` emits `ConnectivityDisconnected`.

### ServiceLocator — `lib/core/di/service_locator.dart`

```dart
class ServiceLocator {
  static late final ApiService apiService;
  static late final HomeRepo homeRepo;
  static late final SearchRepo searchRepo;
  static late final DetailsRepo detailsRepo;
  static late final FavoritesRepo favoritesRepo;

  static void init() {
    apiService = ApiService(DioFactory.dio);
    homeRepo = HomeRepoImpl(apiService: apiService);
    searchRepo = SearchRepoImpl(apiService: apiService);
    detailsRepo = DetailsRepoImpl(apiService: apiService);
    favoritesRepo = FavoritesRepoImpl();
  }
}
```

### AppColors & AppTheme

- **`lib/constants/app_colors.dart`**: Centralizes brand colors and semantic tokens (`background`, `primary`, `secondary`, `accent`, `muted`, `lightOnSurface`, `darkBackground`, `darkCard`, `darkPrimary`, `darkOnSurface`, `lightOutline`, `darkOutline`, `darkMuted`, `lightPill`, `error`, `success`, `disabled`, `overlay`).
- **`lib/core/theme/app_theme.dart`**: Exposes cached `static final ThemeData light` and `static final ThemeData dark` instances.

| Mode | Background | Primary | On-surface |
| :--- | :--- | :--- | :--- |
| Light | `#F0EADE` (`AppColors.background`) | `#765A1F` (`AppColors.primary`) | `#2C2416` (`AppColors.lightOnSurface`) |
| Dark | `#1A1610` (`AppColors.darkBackground`) | `#D4B56A` (`AppColors.darkPrimary`) | `#F0EADE` (`AppColors.darkOnSurface`) |

`LibrisTheme` extension on `BuildContext`: `colors`, `isDark`, `titleColor`, `mutedColor`, `pillColor`.

`ThemeCubit` persists `theme_mode` (`system` / `light` / `dark`) in SharedPreferences.

---

## 1. API Layer

### Dio Client & ApiService Configuration

#### DioFactory — `lib/core/utils/dio_factory.dart`

```dart
class DioFactory {
  DioFactory._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  )..interceptors.addAll([
      if (kDebugMode)
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          error: true,
        ),
    ]);

  static Dio get dio => _dio;
}
```

- **Interceptors**: `LogInterceptor` active strictly in `kDebugMode` (logs request method/URL and response error status only).
- **Error handling**: `DioException` is mapped in repositories via `ServerFailure.fromDioError`.

#### ApiService — `lib/core/utils/api_service.dart`

```dart
class ApiService {
  final String baseUrl = "https://openlibrary.org/";
  final Dio _dio;

  Future<Map<String, dynamic>> getData({required String endPoint, Map<String, dynamic>? queryParameters});
  Future<Map<String, dynamic>> fetchBookDetails(String workKey);
  Future<Map<String, dynamic>> fetchBookRating(String workKey);
  Future<Map<String, dynamic>> fetchWorkEditions(String workKey, {int limit = 20});
  Future<Map<String, dynamic>> fetchTrendingBooks({int limit = 50});
  Future<Map<String, dynamic>> searchBooks(String query, {int page = 1, int limit = 20});
  Future<Map<String, dynamic>> fetchBooksBySubject(String subject, {int page = 1, int limit = 20});
  Future<Map<String, dynamic>> searchArchiveBooks(String query, {int page = 1, int limit = 20, bool publicOnly = true, bool applyLanguageFilter = true});
  Future<Map<String, dynamic>> fetchArchiveMetadata(String identifier);
  Future<String?> resolveArchiveReaderUrl({required String title, String? author, bool preferEnglish = true});
}
```

All query parameters are formatted into `queryParameters` maps passed to Dio for URL encoding. Open Library paths are concatenated onto `baseUrl`. Archive.org calls use absolute URLs on the same `Dio` instance.

---

### Open Library Endpoints

`cleanKey` strips a leading `/` from a work key such as `/works/OL82563W`.

| Method | HTTP | URL / Query Params |
| :--- | :--- | :--- |
| `fetchBookDetails` | GET | `https://openlibrary.org/{cleanKey}.json` |
| `fetchBookRating` | GET | `https://openlibrary.org/{cleanKey}/ratings.json` |
| `fetchWorkEditions` | GET | `https://openlibrary.org/{cleanKey}/editions.json` `queryParameters: {'limit': 20}` |
| `fetchTrendingBooks` | GET | `https://openlibrary.org/trending/weekly.json` `queryParameters: {'limit': limit}` |
| `searchBooks` | GET | `https://openlibrary.org/search.json` `queryParameters: {'q': query, 'limit': limit, 'page': page}` + `'language': 'eng'` unless `containsArabic(query)` |
| `fetchBooksBySubject` | GET | `https://openlibrary.org/search.json` `queryParameters: {'q': 'subject:{subject}', 'language': 'eng', 'limit': limit, 'page': page}` |

Home featured: `trending/weekly.json` (`limit=20`).  
Home filters: `search.json` (`q={subject}`, `language=eng`, `limit=50`).

---

### Internet Archive Endpoints

| Method | URL / behavior |
| :--- | :--- |
| `searchArchiveBooks` | `https://archive.org/advancedsearch.php` via Dio `queryParameters` — `mediatype:texts`, optional English or Arabic language clause, `NOT collection:inlibrary AND NOT collection:printdisabled` when `publicOnly` |
| `fetchArchiveMetadata` | `https://archive.org/metadata/{identifier}` |
| `resolveArchiveReaderUrl` | Title search for a **public** identifier. When `preferEnglish` and the title is not Arabic, **only** documents with an English language field are accepted. Returns `https://archive.org/details/{identifier}/page/n19/mode/2up` |

Direct `archive.org/download/...pdf` URLs are **not** used (they produced HTTP 401).

Cover for Archive-only rows: `https://archive.org/services/img/{identifier}`.

---

### Feature API Endpoints & Contract Details

#### 1. Home Feature

**Repository**: `lib/features/home/data/repos/home_repo_impl.dart`

##### A. `fetchFeaturedBooks()`

- **Endpoint**: `https://openlibrary.org/trending/weekly.json?limit=20`
- **Cache**: Hive `kFeaturedBox` key `featured_list_eng`, envelope `{ timestamp, items }`, TTL 8 hours. Network failure falls back to valid cache.

##### B. `fetchFilterBooks({required String category})`

- **Endpoint**: `https://openlibrary.org/search.json?q={subject}&language=eng&limit=50`
- **Cache**: `kFilterBox` key `{subject}_eng`.

##### C. `clearCache()`

Clears `kFeaturedBox` and `kFilterBox`. Invoked from Settings.

---

#### 2. Explore Feature

**Repository**: `lib/features/explore/data/repos/search_repo_impl.dart`

##### A. `searchBooks(query, {page, limit})` — merged

1. Parallel:
   - Open Library `searchBooks`
   - Archive `searchArchiveBooks`
2. If Archive is empty, retry Archive with `applyLanguageFilter: false`.
3. Merge: **Open Library first**. Archive rows whose `normalizeBookTitle` already exists in OL are dropped. Remaining Archive-only books are appended.

`normalizeBookTitle`: lowercase, take text before `:`, strip non letter/digit/Arabic, collapse spaces.

##### B. `fetchBooksBySubject`

Open Library subject search with `language=eng`. Used by Explore chips and Details similar books.

##### C. `fetchTrendingBooks`

`trending/weekly.json`. Used when Home “See All” passes `trending_all`.

---

#### 3. Details Feature

**Repository**: `lib/features/details/data/repos/details_repo_impl.dart`

##### Resolution order

1. If `workKey` contains `/works/` → load Open Library details.
2. Else try `_findOpenLibraryWorkKey(book)` (OL search by title, exact normalized match).
3. Else if Archive identifier (`/ia/{id}` or `book.isArchiveBook`) → Archive metadata fallback.
4. Reader URL is always `resolveArchiveReaderUrl(title: openLibraryTitle)`.

---

#### 4. Library Feature

No HTTP. All state is Hive `kFavoritesBox` via `FavoritesRepoImpl`.

---

## Search Merge & Reader Resolution

```
Explore query
    ├─ Open Library search  ──►  ranked first (metadata, /works/ keys)
    └─ Archive.org search   ──►  only titles not already in OL

Details tap
    ├─ Prefer Open Library work JSON (description, ratings, language, similar)
    └─ Read Now → resolveArchiveReaderUrl(OL title, English-only if not Arabic)
                 → https://archive.org/details/{id}/page/n19/mode/2up
```

---

## 2. State Management (Cubits)

```
                       ┌─────────────────────────┐
                       │      UI / Widgets       │
                       └────────────┬────────────┘
                                    │
                                    ▼
                       ┌─────────────────────────┐
                       │          Cubit          │
                       └────────────┬────────────┘
                                    │
                                    ▼
                       ┌─────────────────────────┐
                       │   Repository Contract   │
                       └────────────┬────────────┘
                   ┌────────────────┴────────────────┐
                   ▼                                 ▼
         ┌───────────────────┐             ┌───────────────────┐
         │    ApiService     │             │   Hive Storage    │
         └───────────────────┘             └───────────────────┘
```

### ThemeCubit

- **Path**: `lib/features/settings/presentation/manager/theme_cubit.dart`
- **State**: `ThemeMode`
- **Methods**: `setThemeMode(ThemeMode)`
- **Storage**: SharedPreferences key `theme_mode`

### ConnectivityCubit (app-scoped)

- **Path**: `lib/core/services/connectivity_cubit.dart`
- **States**: `ConnectivityInitial`, `ConnectivityConnected`, `ConnectivityDisconnected`
- **Methods**: `checkConnectivity()`
- **Package**: `connectivity_plus`

### FeaturedBooksCubit

- **Path**: `lib/features/home/presentation/manager/featured_books_cubit/`
- **States**: `Initial`, `Loading`, `Success(List<BookModel> books)`, `Failure(String errMessage)`
- **Method**: `fetchFeaturedBooks()`

### FilterBooksCubit

- **Path**: `lib/features/home/presentation/manager/filter_books_cubit/`
- **Field**: `currentCategory` (default `'All'`)
- **Method**: `fetchFilterBooks({required String category})`

### ExploreCubit

- **Path**: `lib/features/explore/presentation/manager/explore_cubit/`
- **Debounce**: 400ms; ignore queries shorter than 3 characters
- **Page size**: 20
- **States**: `ExploreInitial`, `ExploreLoading`, `ExploreSuccess`, `ExploreEmpty`, `ExploreFailure`
- **Methods**: `searchBooksDebounced`, `searchBooks`, `fetchBooksBySubject`, `fetchTrendingBooks`, `loadMore`, `resetSearch`

### BookDetailsCubit

- **Path**: `lib/features/details/presentation/manager/book_details_cubit/`
- **States**: `Initial`, `Loading`, `Success`, `Failure`
- **Method**: `fetchBookDetails({required String workKey, BookModel? book})`

### LibraryCubit (app-scoped)

- **Path**: `lib/features/library/presentation/manager/library_cubit/`
- **Collections**: `All`, `Want to Read`, `Reading`, `Finished`, `Favorites`
- **Sort**: `LibrarySort.recent` | `title` | `year`
- **States**: `Initial`, `Loading`, `Success`, `Empty`, `Failure`
- **Methods**: `fetchFavoriteBooks`, `toggleFavoriteBook`, `setCollectionFilter`, `setSort`, `moveBookToCollection`, `updateBookProgress`, `exportFavoritesJson`, `importFavoritesJson`, `removeFavoriteBook`, `isBookFavorite`

All Cubits check `isClosed` before emitting state after async operations.

---

## 3. Domain Layer

### Repository Interfaces

| Interface | Path | Methods |
| :--- | :--- | :--- |
| `HomeRepo` | `features/home/data/repos/home_repo.dart` | `fetchFeaturedBooks`, `fetchFilterBooks`, `clearCache` |
| `SearchRepo` | `features/explore/data/repos/search_repo.dart` | `searchBooks`, `fetchBooksBySubject`, `fetchTrendingBooks` |
| `DetailsRepo` | `features/details/data/repos/details_repo.dart` | `fetchBookDetails(workKey, {BookModel? book})` |
| `FavoritesRepo` | `features/library/data/repos/favorites_repo.dart` | get/add/remove/toggle, `isBookFavorite`, `updateBookCollection`, `updateBookProgress`, export/import JSON |

### Failure Hierarchy — `lib/core/errors/failure.dart`

`Failure` extends `Equatable` (`props => [errMessage]`).

- **`ServerFailure`**: Maps `DioException` via `fromDioError` and status codes via `fromResponse`.
  - **`DioExceptionType.unknown`**: checks `dioException.error is SocketException` or message string for offline detection.
  - **Status codes**: handles 400, 401, 403, 404, 408 (Request Timeout), 429 (Too Many Requests), 500, 502 (Bad Gateway), 503 (Service Unavailable). Supports String or Map error bodies.
- **`FormatFailure`**: Default `'Unable to process book data. Please try again.'`.
- **`CacheFailure`**: Default `'Failed to load saved offline data.'`.

---

## 4. Data Layer

### Data Models & Serialization

#### 1. `BookModel` — `lib/core/models/book_model.dart`

Extends `Equatable` (`props => [key, title, authorName, coverUrl, firstPublishYear, collection, addedAt, progress, language, iaId]`).

| Field | Type | Notes |
| :--- | :--- | :--- |
| `key` | `String` | `/works/OL…W` or `/ia/{identifier}` |
| `title` | `String` | default `'No Title'` |
| `authorName` | `String` | first author; `'Unknown Author'` |
| `coverUrl` | `String` | OL cover URL, Archive img service, or `''` |
| `firstPublishYear` | `int?` | publication year |
| `collection` | `String?` | Hive library tag |
| `addedAt` | `int?` | epoch ms |
| `progress` | `int?` | 0–100 reading percentage |
| `language` | `String?` | normalized code (`ENG`, `ARA`, …) |
| `iaId` | `String?` | Archive identifier |

`BookModel.fromJson` performs defensive type checks (`is List`, `is String`) on `authors` / `author_name` to prevent `TypeError` exceptions on non-standard API responses.

Factories & Helpers: `BookModel.fromJson`, `BookModel.fromArchiveJson`, `BookResponseModel.fromJson`, `BookModel.listFromArchiveResponse`, `isArchiveBook`, `copyWith`, `toJson`, `preferEnglishBooks`, `languageCodeFromJson`, `normalizeBookTitle`, `containsArabic`, `archiveReaderUrl`, `iaIdFromJson`.

---

## 5. Local Storage (Hive & SharedPreferences)

### Hive Boxes

Boxes are opened via `_openBoxSafe(boxName)` in `main.dart` with automatic recovery on box corruption.

- `kFeaturedBox` (`featured_books_box`): Featured trending books (8h TTL).
- `kFilterBox` (`filter_books_box`): Category filter results.
- `kFavoritesBox` (`favorites_books_box`): Personal library books (keyed by `BookModel.key`).

**Favorites payload**:

```json
{
  "key": "/works/OL82563W",
  "title": "Harry Potter and the Sorcerer's Stone",
  "author_name": ["J.K. Rowling"],
  "cover_url": "https://covers.openlibrary.org/b/id/10521270-L.jpg",
  "first_publish_year": 1997,
  "collection": "Want to Read",
  "added_at": 1735689600000,
  "progress": 0,
  "language": "ENG",
  "ia": null
}
```

### Hive Constants — `lib/constants/hive_constants.dart`

```dart
const String kFeaturedBox = 'featured_books_box';
const String kFilterBox = 'filter_books_box';
const String kFavoritesBox = 'favorites_books_box';
```

### SharedPreferences

- `is_first_time_user`: `OnboardingService`
- `recent_searches`: `SearchHistoryService` (Max 10)
- `theme_mode`: `ThemeCubit` (`system` / `light` / `dark`)

---

## 6. Routing & Navigation

### AppRoutes — `lib/core/utils/app_routes.dart`

```dart
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String main = '/main';
  static const String details = '/details';
  static const String settings = '/settings';
}
```

### GoRouter — `lib/core/widgets/router.dart`

| Path Constant | Route String | View | Extra / transition |
| :--- | :--- | :--- | :--- |
| `AppRoutes.splash` | `/` | `SplashView` | Builder |
| `AppRoutes.onboarding` | `/onboarding` | `OnboardingView` | `fadeSlidePage` |
| `AppRoutes.main` | `/main` | `MainNavigationView` | `fadeSlidePage` |
| `AppRoutes.details` | `/details` | `DetailsView` | `state.extra as BookModel?`, `fadeSlidePage` |
| `AppRoutes.settings` | `/settings` | `SettingsView` | `fadeSlidePage` |

`router.dart` includes an `errorBuilder` showing a 404 `'Page not found'` fallback.
`fadeSlidePage` in `lib/core/widgets/page_transitions.dart` dynamically calculates horizontal slide offsets based on `Directionality.of(context)` (supports LTR and RTL directions).

---

## 7. Shared UI Components

- **`ShimmerContainer`** (`lib/core/widgets/shimmer_container.dart`): Reusable skeleton loader box with customizable `width`, `height`, and `borderRadius`. Used across `ExploreShimmerLoading`, `FeaturedBooksShimmerLoading`, and `FilterBooksShimmerLoading`.
- **`CustomErrorWidget`** (`lib/core/widgets/custom_error_widget.dart`): Theme-aware error display using `Theme.of(context).colorScheme.onSurface` for perfect readability in Light and Dark modes.
- **`OfflineBanner`** (`lib/core/widgets/offline_banner.dart`): Animated top banner displaying `'No internet connection'` during network dropouts.
