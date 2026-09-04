# Libris App — Comprehensive Project Context & Technical Reference

> **Document Purpose**: This document is the technical reference for the Libris Flutter application. It describes architecture, API contracts, state management, models, persistence, reader implementations, downloads system, and navigation strictly as implemented in the codebase.

---

## Table of Contents

1. [Project Overview & Architecture](#project-overview--architecture)
2. [Bootstrap, DI & Theming](#bootstrap-di--theming)
3. [API Layer](#1-api-layer)
    - [DioFactory & ApiService Configuration](#dio-client--apiservice-configuration)
    - [Open Library Endpoints](#open-library-endpoints)
    - [Internet Archive Endpoints](#internet-archive-endpoints)
    - [Feature API Contracts](#feature-api-endpoints--contract-details)
4. [Search Merge & Dual Reader Architecture](#search-merge--dual-reader-architecture)
5. [State Management (Cubits)](#2-state-management-cubits)
6. [Domain Layer](#3-domain-layer)
7. [Data Layer](#4-data-layer)
8. [Local Storage (Hive & SharedPreferences)](#5-local-storage-hive--sharedpreferences)
9. [Routing & Navigation](#6-routing--navigation)
10. [Shared UI, Readers & Motion System](#7-shared-ui-readers--motion-system)
11. [Continuous Integration & Platform Configuration](#8-continuous-integration--platform-configuration)

---

## Project Overview & Architecture

- **Application Name**: Libris
- **Language**: Dart (SDK `^3.12.2`)
- **Framework**: Flutter (Material 3)
- **Architecture Pattern**: Feature-first packaging + Cubit state management + repository interfaces. There is no separate use-case / entity layer.
- **Android**: `applicationId` and namespace `com.mohamed.libris`; label `Libris`; `INTERNET` and `ACCESS_NETWORK_STATE` declared in the **main** `AndroidManifest.xml`; `usesCleartextTraffic="true"`.
- **iOS**: `CFBundleDisplayName` / `CFBundleName` = `Libris`.
- **Key Runtime Dependencies**: `dio`, `dartz`, `flutter_bloc`, `equatable`, `hive` / `hive_flutter`, `go_router`, `cached_network_image`, `shimmer`, `shared_preferences`, `google_fonts`, `lottie`, `smooth_page_indicator`, `url_launcher`, `flutter_staggered_grid_view`, `share_plus`, `file_picker`, `path_provider`, `connectivity_plus`, `webview_flutter`, `pdfx`.

**Removed from the project** (do not document as current): `flutter_dotenv`, `http`, `flutter_screenutil_plus`, `flutter_pdfview`, `sole_toast`, `lib/constants/api_constants.dart`, `.env` bootstrap, book notes functionality.

```
UI (Views / Widgets)
        │
     Cubit
        │
  Repo interface   (lives under features/*/data/repos/)
        │
    Repo impl  →  ApiService / Dio  or  Hive  or  DownloadService
```

Cubits default to `ServiceLocator` instances and accept optional constructor injection for unit tests.

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
  await _openBoxSafe(kDownloadsBox);
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

`MyApp` provides root application Cubits:

- `ThemeCubit` — persisted `ThemeMode`
- `LibraryCubit` — **app-scoped** so Details bookmarks and collection updates refresh the Library tab (`fetchFavoriteBooks()`)
- `DownloadsCubit` — **app-scoped** background download manager (`load()`)
- `ConnectivityCubit` — **app-scoped** internet connectivity monitor (`checkConnectivity()`)

`MaterialApp.router` configures `AppTheme.light`, `AppTheme.dark`, `themeMode` from `ThemeCubit`, and `routerConfig` from `router`. The `builder` wraps the app shell in a `Stack` featuring an animated top `OfflineBanner` triggered when `ConnectivityCubit` emits `ConnectivityDisconnected`.

### ServiceLocator — `lib/core/di/service_locator.dart`

```dart
class ServiceLocator {
  ServiceLocator._();

  static late final ApiService apiService;
  static late final HomeRepo homeRepo;
  static late final SearchRepo searchRepo;
  static late final DetailsRepo detailsRepo;
  static late final FavoritesRepo favoritesRepo;
  static late final DownloadsRepo downloadsRepo;
  static late final DownloadService downloadService;

  static void init() {
    apiService = ApiService(DioFactory.dio);
    homeRepo = HomeRepoImpl(apiService: apiService);
    searchRepo = SearchRepoImpl(apiService: apiService);
    detailsRepo = DetailsRepoImpl(apiService: apiService);
    favoritesRepo = FavoritesRepoImpl();
    downloadsRepo = DownloadsRepoImpl();
    downloadService = DownloadService(DioFactory.downloadDio);
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

  // General API client for Open Library and Internet Archive metadata
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

  // Dedicated client for high-res PDF binary streaming and downloads
  static final Dio _downloadDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(hours: 2),
      followRedirects: true,
      maxRedirects: 8,
      headers: {
        'Accept': '*/*',
        'User-Agent': 'LibrisApp/1.0 (https://archive.org)',
      },
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

  static Dio get downloadDio => _downloadDio;
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
  Future<String?> resolveArchivePdfUrl({String? identifier, String? title, String? author});
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
| `resolveArchivePdfUrl` | Resolves direct downloadable public PDF links from metadata file listings. Filters out encrypted, thumbnail, or restricted copies, scoring best OCR/text PDF formats. |
| `resolveArchiveReaderUrl` | Title search for a **public** identifier. When `preferEnglish` and the title is not Arabic, **only** documents with an English language field are accepted. Returns `https://archive.org/details/{identifier}/page/n19/mode/2up` |

Direct archive download URL constructor: `archivePdfDownloadUrl(identifier, filename) => 'https://archive.org/download/$identifier/$filename'`.

Cover for Archive-only rows: `https://archive.org/services/img/{identifier}`.

---

### Feature API Endpoints & Contract Details

#### 1. Home Feature
**Repository**: `lib/features/home/data/repos/home_repo_impl.dart`
- **`fetchFeaturedBooks()`**: `trending/weekly.json?limit=20` (Hive `kFeaturedBox` key `featured_list_eng`, 8h TTL).
- **`fetchFilterBooks({required String category})`**: `search.json?q={subject}&language=eng&limit=50` (Hive `kFilterBox` key `{subject}_eng`).
- **`clearCache()`**: Clears `kFeaturedBox` and `kFilterBox`. Invoked from Settings.

#### 2. Explore Feature
**Repository**: `lib/features/explore/data/repos/search_repo_impl.dart`
- **`searchBooks(query, {page, limit})`**: Parallel search across Open Library and Internet Archive. Deduplicates Archive results whose normalized title already appears in Open Library.
- **`fetchBooksBySubject`**: Open Library subject search with `language=eng`.
- **`fetchTrendingBooks`**: `trending/weekly.json`.

#### 3. Details Feature
**Repository**: `lib/features/details/data/repos/details_repo_impl.dart`
- Resolves Open Library description, ratings, editions, and similar books.
- Resolves reader URL (`resolveArchiveReaderUrl`) and downloadable PDF link (`resolveArchivePdfUrl` or Open Library links).

#### 4. Downloads Feature
**Repository**: `lib/features/downloads/data/repos/downloads_repo_impl.dart`
**Service**: `lib/features/downloads/data/services/download_service.dart`
- Manages persisted records in `kDownloadsBox` (`downloads_books_box`).
- Handles file system paths under application documents directory (`/downloads`).
- Resumes incomplete downloads using HTTP byte-range requests (`Range: bytes={startByte}-`).
- Validates file integrity using `%PDF` byte signature (`fileLooksLikePdf`).

#### 5. Library Feature
**Repository**: `lib/features/library/data/repos/favorites_repo_impl.dart`
- Pure local persistence via Hive `kFavoritesBox`.

---

## Search Merge & Dual Reader Architecture

```
User Action: Explore Search
     ├─ Open Library API Search ──► Ranked first (canonical metadata, /works/ keys)
     └─ Internet Archive Search ──► Appended if title does not already exist in Open Library

User Action: Read Now
     └─ Opens In-App Safari Webview Reader (BookReaderView)
         └─ URL: https://archive.org/details/{identifier}/page/n19/mode/2up
         └─ Custom floating Safari control bar, text zoom, sharing, copy link

User Action: Download PDF
     └─ DownloadsCubit enqueues download via DownloadService (resumable byte range)
     └─ File downloaded to app storage and verified with %PDF magic bytes
     └─ Saved in Hive kDownloadsBox

User Action: Open Downloaded PDF
     └─ Opens In-App PDF Reader (PdfReaderView)
         └─ Powered by pdfx (PdfView + PdfController)
         └─ Remembers last read page via PdfProgressService
         └─ Immersive Full Read Mode (zero margins, edge-to-edge, status/nav bars hidden)
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
- **State**: `ThemeMode` (`system` | `light` | `dark`)
- **Storage**: SharedPreferences key `theme_mode`

### ConnectivityCubit (app-scoped)
- **Path**: `lib/core/services/connectivity_cubit.dart`
- **States**: `ConnectivityInitial`, `ConnectivityConnected`, `ConnectivityDisconnected`
- **Package**: `connectivity_plus`

### DownloadsCubit (app-scoped)
- **Path**: `lib/features/downloads/presentation/manager/downloads_cubit/`
- **State**: `DownloadsState` (`items: List<DownloadItem>`)
- **Computed**: `inProgressItems`, `completedItems`, `activeCount`, `isEmpty`, `itemById(id)`
- **Methods**: `load()`, `enqueue({book, archiveIdentifier, directPdfUrl})`, `pause(id)`, `resume(id)`, `retry(id)`, `cancel(id)`, `delete(id)`
- **Features**: CancelToken management, progress throttling (250ms), byte validation, auto-resume handling.

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
- **Debounce**: 650ms; ignores queries shorter than 2 characters
- **Cancellation**: `_activeRequestId` tracking cancels obsolete in-flight requests
- **Page size**: 20
- **Modes**: `ExploreMode.none`, `ExploreMode.search`, `ExploreMode.subject`, `ExploreMode.trending`
- **States**: `ExploreInitial`, `ExploreLoading`, `ExploreSuccess(books, query, activeCategory, hasMore, isLoadingMore, loadMoreError)`, `ExploreEmpty`, `ExploreFailure`
- **Methods**: `searchBooksDebounced`, `searchBooks`, `fetchBooksBySubject`, `fetchTrendingBooks`, `loadMore`, `resetSearch`

### BookDetailsCubit
- **Path**: `lib/features/details/presentation/manager/book_details_cubit/`
- **States**: `Initial`, `Loading`, `Success(BookDetailModel)`, `Failure(String)`
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

| Interface | Path | Key Methods |
| :--- | :--- | :--- |
| `HomeRepo` | `features/home/data/repos/home_repo.dart` | `fetchFeaturedBooks`, `fetchFilterBooks`, `clearCache` |
| `SearchRepo` | `features/explore/data/repos/search_repo.dart` | `searchBooks`, `fetchBooksBySubject`, `fetchTrendingBooks` |
| `DetailsRepo` | `features/details/data/repos/details_repo.dart` | `fetchBookDetails(workKey, {BookModel? book})` |
| `FavoritesRepo` | `features/library/data/repos/favorites_repo.dart` | get/add/remove/toggle, `isBookFavorite`, `updateBookCollection`, `updateBookProgress`, export/import JSON |
| `DownloadsRepo` | `features/downloads/data/repos/downloads_repo.dart` | `getAll`, `getById`, `save`, `delete`, `downloadsDirectory`, `deleteFile`, `fileNameFor` |

### Failure Hierarchy — `lib/core/errors/failure.dart`

`Failure` extends `Equatable` (`props => [errMessage]`).

- **`ServerFailure`**: Maps `DioException` via `fromDioError` and status codes via `fromResponse`.
  - **`DioExceptionType.unknown`**: checks `dioException.error is SocketException` or message string for offline detection.
  - **Status codes**: handles 400, 401, 403, 404, 408 (Request Timeout), 429 (Too Many Requests), 500, 502 (Bad Gateway), 503 (Service Unavailable).
- **`FormatFailure`**: Default `'Unable to process book data. Please try again.'`.
- **`CacheFailure`**: Default `'Failed to load saved offline data.'`.

---

## 4. Data Layer

### Data Models & Serialization

#### 1. `BookModel` — `lib/core/models/book_model.dart`
Extends `Equatable`. Represents any book row across Home, Explore, Details, and Library.
- Properties: `key`, `title`, `authorName`, `coverUrl`, `firstPublishYear`, `collection`, `addedAt`, `progress`, `language`, `iaId`.
- Defensive JSON parsing on `authors`/`author_name` (supports both `List` and `String`).
- Helpers: `BookModel.fromJson`, `BookModel.fromArchiveJson`, `normalizeBookTitle`, `containsArabic`, `isArchiveBook`, `archiveReaderUrl`.

#### 2. `BookDetailModel` — `lib/features/details/data/models/book_detail_model.dart`
Represents full book metadata, ratings, categories, reading URL, and direct download links.
- Properties: `key`, `title`, `description`, `primaryCategory`, `subjects`, `averageRating`, `ratingCount`, `readUrl`, `downloadUrl`, `language`, `archiveIdentifier`.
- Computed getters: `hasDirectPdf`, `hasPdfDownload`.

#### 3. `DownloadItem` — `lib/features/downloads/data/models/download_item.dart`
Extends `Equatable`. Represents an offline download record.
- Properties: `id`, `title`, `authorName`, `coverUrl`, `archiveIdentifier`, `remoteUrl`, `localPath`, `status` (`queued`, `downloading`, `paused`, `completed`, `failed`, `cancelled`), `progress`, `receivedBytes`, `totalBytes`, `errorMessage`, `createdAt`, `completedAt`.
- Computed getters: `isInProgress`, `canOpen`, `sizeLabel`.

---

## 5. Local Storage (Hive & SharedPreferences)

### Hive Boxes
Opened via `_openBoxSafe(boxName)` in `main.dart` with automatic recovery on box corruption.

- `kFeaturedBox` (`featured_books_box`): Featured trending books (8h TTL).
- `kFilterBox` (`filter_books_box`): Category filter results.
- `kFavoritesBox` (`favorites_books_box`): Personal library books (keyed by `BookModel.key`).
- `kDownloadsBox` (`downloads_books_box`): Persisted download metadata (keyed by `DownloadItem.id`).

### Hive Constants — `lib/constants/hive_constants.dart`
```dart
const String kFeaturedBox = 'featured_books_box';
const String kFilterBox = 'filter_books_box';
const String kFavoritesBox = 'favorites_books_box';
const String kDownloadsBox = 'downloads_books_box';
```

### SharedPreferences
- `is_first_time_user`: `OnboardingService`
- `recent_searches`: `SearchHistoryService` (Max 10)
- `theme_mode`: `ThemeCubit` (`system` / `light` / `dark`)
- `pdf_last_page_{bookId}`: `PdfProgressService` (Reading progress per PDF file)

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
  static const String bookReader = '/bookReader';
  static const String downloads = '/downloads';
  static const String pdfReader = '/pdfReader';
}
```

### GoRouter Configuration — `lib/core/widgets/router.dart`

| Route Constant | Path | View | Arguments / Transition |
| :--- | :--- | :--- | :--- |
| `AppRoutes.splash` | `/` | `SplashView` | Default Builder |
| `AppRoutes.onboarding` | `/onboarding` | `OnboardingView` | `fadeSlidePage` |
| `AppRoutes.main` | `/main` | `MainNavigationView` | `fadeSlidePage` |
| `AppRoutes.details` | `/details` | `DetailsView` | `extra: BookModel?`, `fadeSlidePage` |
| `AppRoutes.settings` | `/settings` | `SettingsView` | `fadeSlidePage` |
| `AppRoutes.bookReader` | `/bookReader` | `BookReaderView` | `extra: String (url)`, `fadeUpFadeRightPage` |
| `AppRoutes.downloads` | `/downloads` | `DownloadsView` | `fadeSlidePage` |
| `AppRoutes.pdfReader` | `/pdfReader` | `PdfReaderView` | `extra: PdfReaderArgs(filePath, title)`, `fadeUpFadeRightPage` |

---

## 7. Shared UI, Readers & Motion System

### In-App Readers

#### 1. In-App Webview Reader (`BookReaderView`)
- **Engine**: `webview_flutter`.
- **UI Paradigm**: Safari iOS-inspired floating capsule bar with host indicator, SSL security badge, reload action, and share sheet button.
- **Reader Controls**: Modal bottom sheet with dynamic text zoom (60% to 200% via JS injection), copy link to clipboard, reload, and external browser escape hatch.
- **Offline & Error Handling**: Custom error placeholder with reconnect retry button.

#### 2. In-App PDF Reader & Full Read Mode (`PdfReaderView`)
- **Engine**: `pdfx` (`PdfView` with `PdfController` and `PhotoViewGallery`).
- **High-DPI Razor-Sharp Rendering**: Dynamic scale calculation (2.0x to 3.2x) based on physical device screen width and DPR (`devicePixelRatio`). Renders at high-quality JPEG (92% quality, #ffffff background) to eliminate all blurriness and pixelation.
- **Dual Reading Modes**:
  - **Horizontal Page Flip (تقليب أفقي)**: Natural book reading experience with page snapping and 60/120 FPS hardware-accelerated transitions.
  - **Vertical Continuous Scroll (تمرير رأسي)**: Smooth document/webtoon style reading with snapping.
  - Quick-switch toggle button directly in the reader toolbar.
- **Pinch-To-Zoom & Pan**: `PhotoViewGalleryPageOptions` with 1.0x to 3.5x scale and `FilterQuality.high`.
- **Progress Persistence**: `PdfProgressService` automatically restores and debounces-saves page progress.
- **Navigation**: "Go to page" numeric input dialog.
- **Full Read Mode (وضع القراءة الكاملة)**:
  - **Edge-to-edge pages**: 0 top system inset, distraction-free canvas background.
  - **System Immersive**: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` completely hides status bar and navigation pill.
  - **Distraction-Free UX**: Toolbar auto-slides out of view. Tapping anywhere toggles the toolbar back on cleanly via `onTapUp`.
  - **PopScope Guard**: Android back gesture gracefully exits Full Read Mode first rather than abruptly closing the book.
  - **Floating Hint Toast**: Brief 2.4-second overlay badge on activation explaining how to access controls.
- **Resource Management**: Properly closes `PdfDocument` and disposes `PdfController` to prevent native memory leaks.

### Micro-Animations & Custom Components

- **`WaterFillDownloadButton`**: Interactive download button featuring a dual sinusoidal wave CustomPainter (`_WaterPainter`) and animated `_FillClipper`. The label dynamically clips between dry brand color and wet text color as progress increases.
- **`AppDialog`**: Unified overlay toast system (`AppDialog.success`, `error`, `info`) with `CurvedAnimation`, haptic feedback, elastic icon pop, and swipe-up dismissal. Replaced third-party toast dependencies.
- **`FadeSlideIn`**: Staggered list view entrance animator with index-based progressive delays.
- **`fadeUpFadeRightPage`**: Apple-inspired fluid modal transition (500ms slide up with `Cubic(0.16, 1.0, 0.3, 1.0)`, 420ms dismiss to right).
- **`FilterChipsList`**: Smooth scale animation (`AnimatedScale` 1.05x on select) with gold glow box shadow.
- **`FavoriteIconButton`**: Custom `TweenSequence` scale bounce (1.0 -> 1.85 -> 1.0) with immediate `AppDialog.success` notification.
- **`ShimmerContainer`**: Reusable skeleton loader box with configurable width, height, and border radius.
- **`OfflineBanner`**: Real-time network status notification banner anchored at the top of the app window.

---

## 8. Continuous Integration & Platform Configuration

### GitHub Actions Workflow — `.github/workflows/build_apk.yml`
- Triggers on push / PR to `main` and `master`, or via manual `workflow_dispatch`.
- Environment: Ubuntu latest, Java 17 (Temurin), Flutter stable.
- Runs: `flutter pub get`, `flutter test`, and `flutter build apk --release`.
- Uploads: `libris-release-apk` artifact (`build/app/outputs/flutter-apk/app-release.apk`) with 30-day retention.

### Android Manifest Permissions & Queries
- `android.permission.INTERNET`
- `android.permission.ACCESS_NETWORK_STATE`
- `usesCleartextTraffic="true"`
- Intent queries for `https`, `http`, `text/plain` (PROCESS_TEXT), and `*/*` (SEND).
