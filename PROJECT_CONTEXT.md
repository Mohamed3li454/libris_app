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
- **Key Runtime Dependencies**: `dio`, `dartz`, `flutter_bloc`, `equatable`, `hive` / `hive_flutter`, `go_router`, `cached_network_image`, `shimmer`, `shared_preferences`, `google_fonts`, `lottie`, `smooth_page_indicator`, `url_launcher`, `flutter_staggered_grid_view`, `share_plus`, `file_picker`, `path_provider`.

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
  await Hive.openBox(kFeaturedBox);
  await Hive.openBox(kFilterBox);
  await Hive.openBox(kFavoritesBox);
  ServiceLocator.init();
  runApp(const MyApp());
}
```

`MyApp` provides:

- `ThemeCubit` — persisted `ThemeMode`
- `LibraryCubit` — **app-scoped** so Details bookmarks refresh the Library tab

Then `MaterialApp.router` with `AppTheme.light`, `AppTheme.dark`, and `themeMode` from `ThemeCubit`.

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

### AppTheme — `lib/core/theme/app_theme.dart`

| Mode | Background | Primary | On-surface |
| :--- | :--- | :--- | :--- |
| Light | `#F0EADE` | `#765A1F` | `#2C2416` |
| Dark | `#1A1610` | `#D4B56A` | `#F0EADE` |

`LibrisTheme` on `BuildContext`: `colors`, `isDark`, `titleColor`, `mutedColor`, `pillColor`.

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
  );

  static Dio get dio => _dio;
}
```

- **Interceptors**: none.
- **Error handling**: `DioException` is mapped in repositories via `ServerFailure.fromDioError`.

#### ApiService — `lib/core/utils/api_service.dart`

```dart
class ApiService {
  final String baseUrl = "https://openlibrary.org/";
  final Dio _dio;

  Future<Map<String, dynamic>> getData({required String endPoint});
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

Open Library paths are concatenated onto `baseUrl`. Archive.org calls use absolute URLs on the same `Dio` instance.

---

### Open Library Endpoints

`cleanKey` strips a leading `/` from a work key such as `/works/OL82563W`.

| Method | HTTP | URL |
| :--- | :--- | :--- |
| `fetchBookDetails` | GET | `https://openlibrary.org/{cleanKey}.json` |
| `fetchBookRating` | GET | `https://openlibrary.org/{cleanKey}/ratings.json` |
| `fetchWorkEditions` | GET | `https://openlibrary.org/{cleanKey}/editions.json?limit=20` |
| `fetchTrendingBooks` | GET | `https://openlibrary.org/trending/weekly.json?limit={limit}` |
| `searchBooks` | GET | `https://openlibrary.org/search.json?q={query}&limit={limit}&page={page}` + `&language=eng` unless `containsArabic(query)` |
| `fetchBooksBySubject` | GET | `https://openlibrary.org/search.json?q=subject:{subject}&language=eng&limit={limit}&page={page}` |

Home featured: `trending/weekly.json?limit=20`.  
Home filters: `search.json?q={subject}&language=eng&limit=50` (`subject` is `general` when category is All).

---

### Internet Archive Endpoints

| Method | URL / behavior |
| :--- | :--- |
| `searchArchiveBooks` | `https://archive.org/advancedsearch.php?q=...&output=json` — `mediatype:texts`, optional English or Arabic language clause, `NOT collection:inlibrary AND NOT collection:printdisabled` when `publicOnly` |
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
- **Response shape**:

```json
{
  "query": "weekly",
  "works": [
    {
      "key": "/works/OL82563W",
      "title": "Harry Potter and the Sorcerer's Stone",
      "author_name": ["J.K. Rowling"],
      "cover_i": 10521270,
      "first_publish_year": 1997
    }
  ]
}
```

##### B. `fetchFilterBooks({required String category})`

- **Endpoint**: `https://openlibrary.org/search.json?q={subject}&language=eng&limit=50`
- **Cache**: `kFilterBox` key `{subject}_eng`.
- **Response shape**: `docs[]` with `key`, `title`, `author_name`, `cover_i`, `first_publish_year`, optional `language`.

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
3. Merge: **Open Library first**. Archive rows whose `normalizeBookTitle` already exists in OL are dropped (not attached as `iaId`). Remaining Archive-only books are appended.

`normalizeBookTitle`: lowercase, take text before `:`, strip non letter/digit/Arabic, collapse spaces.

##### B. `fetchBooksBySubject`

Open Library subject search with `language=eng` (see table above). Used by Explore chips and Details similar books.

##### C. `fetchTrendingBooks`

`trending/weekly.json?limit=`. Used when Home “See All” passes `trending_all`.

---

#### 3. Details Feature

**Repository**: `lib/features/details/data/repos/details_repo_impl.dart`

##### Resolution order

1. If `workKey` contains `/works/` → load Open Library details.
2. Else try `_findOpenLibraryWorkKey(book)` (OL search by title, exact normalized match).
3. Else if Archive identifier (`/ia/{id}` or `book.isArchiveBook`) → Archive metadata fallback.
4. Reader URL is **never** the Open Library `ia` field and **never** an `iaId` copied from merge. It is always `resolveArchiveReaderUrl(title: openLibraryTitle)` so the scan language matches the details page.

##### Concurrent OL calls (`Future.wait`)

1. `GET /{cleanKey}.json`
2. `GET /{cleanKey}/ratings.json` (errors swallowed → `{}`)
3. `GET /{cleanKey}/editions.json?limit=20` (errors swallowed → `{}`)

**Details JSON (excerpt)**:

```json
{
  "key": "/works/OL82563W",
  "title": "Harry Potter and the Sorcerer's Stone",
  "description": { "value": "Harry Potter has never even heard of Hogwarts..." },
  "subjects": ["Fantasy", "Wizards", "Magic"],
  "languages": [{ "key": "/languages/eng" }]
}
```

**Ratings JSON (excerpt)**:

```json
{
  "summary": { "average": 4.62, "count": 2841 }
}
```

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

This split exists because Archive.org has more publicly readable files (including Arabic), while Open Library has better catalog metadata. Attaching Archive `identifier` onto an OL row caused French/Spanish readers; that path was removed.

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

### FeaturedBooksCubit

- **Path**: `lib/features/home/presentation/manager/featured_books_cubit/` (no spaces in the folder name)
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
- **States**:
  - `ExploreInitial`
  - `ExploreLoading`
  - `ExploreSuccess(books, query, activeCategory, hasMore, isLoadingMore, loadMoreError)`
  - `ExploreEmpty(query)`
  - `ExploreFailure(errMessage)`
- **Methods**: `searchBooksDebounced`, `searchBooks`, `fetchBooksBySubject`, `fetchTrendingBooks`, `loadMore`, `resetSearch`
- **Load more**: on failure, re-emits `ExploreSuccess` with `loadMoreError` so the existing list is kept; UI shows a SnackBar.

### BookDetailsCubit

- **Path**: `lib/features/details/presentation/manager/book_details_cubit/`
- **States**: `Initial`, `Loading`, `Success(bookDetail, similarBooks, isSimilarLoading)`, `Failure(errMessage)`
- **Method**: `fetchBookDetails({required String workKey, BookModel? book})`
- After OL success, loads similar books via `SearchRepo.fetchBooksBySubject` (first subject / primary category). Skips when category is empty or `general`.

### LibraryCubit (app-scoped)

- **Path**: `lib/features/library/presentation/manager/library_cubit/`
- **Collections**: `All`, `Want to Read`, `Reading`, `Finished`, `Favorites`
- **Sort**: `LibrarySort.recent` | `title` | `year`
- **Fields**: `selectedCollection`, `selectedSort`, `collectionCounts`
- **States**: `Initial`, `Loading`, `Success(books, selectedCollection, sort, counts)`, `Empty(selectedCollection)`, `Failure(errMessage)`
- **Methods**: `fetchFavoriteBooks`, `toggleFavoriteBook`, `setCollectionFilter`, `setSort`, `moveBookToCollection`, `updateBookProgress` (100% → Finished), `exportFavoritesJson`, `importFavoritesJson`, `removeFavoriteBook`, `isBookFavorite`

`FavoriteIconButton` uses `context.read<LibraryCubit>()` instead of constructing `FavoritesRepoImpl` locally.

---

## 3. Domain Layer

### Repository Interfaces

| Interface | Path | Methods |
| :--- | :--- | :--- |
| `HomeRepo` | `features/home/data/repos/home_repo.dart` | `fetchFeaturedBooks`, `fetchFilterBooks`, `clearCache` |
| `SearchRepo` | `features/explore/data/repos/search_repo.dart` | `searchBooks`, `fetchBooksBySubject`, `fetchTrendingBooks` |
| `DetailsRepo` | `features/details/data/repos/details_repo.dart` | `fetchBookDetails(workKey, {BookModel? book})` |
| `FavoritesRepo` | `features/library/data/repos/favorites_repo.dart` | get/add/remove/toggle, `isBookFavorite`, `updateBookCollection`, `updateBookProgress`, export/import JSON |

Network repos return `Either<Failure, T>`. `FavoritesRepo` is Hive-only (exceptions are logged; list methods return `[]` on error).

### Entities & Use Cases

Not present. `BookModel` is the shared data/domain model in `lib/core/models/`.

### Failure Hierarchy — `lib/core/errors/failure.dart`

- `Failure(errMessage)`
- `ServerFailure` + `fromDioError` + `fromResponse`
- `FormatFailure`
- `CacheFailure` (defined; home cache miss currently returns `ServerFailure` after empty cache)

---

## 4. Data Layer

### Data Models & Serialization

#### 1. `BookModel` — `lib/core/models/book_model.dart`

| Field | Type | Notes |
| :--- | :--- | :--- |
| `key` | `String` | `/works/OL…W` or `/ia/{identifier}` |
| `title` | `String` | default `'No Title'` |
| `authorName` | `String` | first author; `'Unknown Author'` |
| `coverUrl` | `String` | OL cover URL, Archive img service, or `''` (no placeholder.com) |
| `firstPublishYear` | `int?` | |
| `collection` | `String?` | Hive library tag |
| `addedAt` | `int?` | epoch ms |
| `progress` | `int?` | 0–100 |
| `language` | `String?` | normalized code (`ENG`, `ARA`, …) |
| `iaId` | `String?` | Archive identifier for Archive-only rows |

Factories:

- `BookModel.fromJson` — Open Library `works` / `docs`
- `BookModel.fromArchiveJson` — Archive search doc
- `BookResponseModel.fromJson` — `works` or `docs`, then `preferEnglishBooks`
- `BookModel.listFromArchiveResponse` — `response.docs`

Helpers: `isArchiveBook`, `copyWith`, `toJson`, `preferEnglishBooks`, `languageCodeFromJson({preferEnglish})`, `normalizeBookTitle`, `containsArabic`, `archiveReaderUrl`, `iaIdFromJson`.

#### 2. `BookDetailModel` — `features/details/data/models/book_detail_model.dart`

| Field | Type |
| :--- | :--- |
| `key`, `title`, `description`, `primaryCategory` | `String` |
| `subjects` | `List<String>` |
| `averageRating` | `double` |
| `ratingCount` | `int` |
| `readUrl` | `String` |
| `downloadUrl` | `String?` |
| `language` | `String?` |

- `fromJson({detailsJson, ratingJson, editionsJson})` — OL mapping; language prefers English from work then editions.
- `fromArchive({identifier, metadataJson})` — fallback only.
- `copyWith` used to inject the resolved Archive reader URL into both `readUrl` and `downloadUrl`.

#### 3. `OnboardingModel`

`title`, `subtitle`, `lottiePath`, `badgeText`. Compile-time slides in `OnboardingView`:

1. Discover Great Books / DISCOVER  
2. Open Book Pages / READ  
3. Build Your Library / LIBRARY  

---

### Data Sources & Repository Implementations

| Implementation | Path | Sources | Logic |
| :--- | :--- | :--- | :--- |
| `HomeRepoImpl` | `features/home/data/repos/home_repo_impl.dart` | ApiService, Hive featured/filter | Trending + English category search; TTL cache; `clearCache` |
| `SearchRepoImpl` | `features/explore/data/repos/search_repo_impl.dart` | ApiService | Merged OL+Archive search; OL subjects/trending |
| `DetailsRepoImpl` | `features/details/data/repos/details_repo_impl.dart` | ApiService | OL details first; Archive reader by English title |
| `FavoritesRepoImpl` | `features/library/data/repos/favorites_repo_impl.dart` | Hive favorites | CRUD, collection, progress, JSON backup |

---

## 5. Local Storage (Hive & SharedPreferences)

### Hive Boxes

```
┌────────────────────────────────────────────────────────────────────────────┐
│                                Hive Storage                                │
├─────────────────────────┬──────────────────────────┬───────────────────────┤
│    featured_books_box   │     filter_books_box     │  favorites_books_box  │
│      (kFeaturedBox)     │       (kFilterBox)       │    (kFavoritesBox)    │
├─────────────────────────┼──────────────────────────┼───────────────────────┤
│ Key: featured_list_eng  │ Key: {subject}_eng       │ Key: <book work key>  │
│ Value: {timestamp,      │ Value: {timestamp,       │ Value: BookModel map  │
│         items}          │         items}           │                       │
└─────────────────────────┴──────────────────────────┴───────────────────────┘
```

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

Default collection on add: `Favorites`. Progress 100 writes collection `Finished`.

### Hive Constants — `lib/constants/hive_constants.dart`

```dart
const String kFeaturedBox = 'featured_books_box';
const String kFilterBox = 'filter_books_box';
const String kFavoritesBox = 'favorites_books_box';
```

### SharedPreferences

| Key | Service | Behavior |
| :--- | :--- | :--- |
| `is_first_time_user` | `OnboardingService` | Default `true`; set `false` on skip / Get Started |
| `recent_searches` | `SearchHistoryService` | Max 10; case-insensitive dedupe; min length 3 |
| `theme_mode` | `ThemeCubit` | `system` / `light` / `dark` |

---

## 6. Routing & Navigation

### GoRouter — `lib/core/widgets/router.dart`

| Path | View | Extra / notes |
| :--- | :--- | :--- |
| `/` | `SplashView` | 1.2s animation + 1.8s delay → onboarding or main |
| `/onboarding` | `OnboardingView` | Skip / Get Started → `context.go('/main')` |
| `/main` | `MainNavigationView` | Home / Explore / Library |
| `/details` | `DetailsView` | `state.extra as BookModel?` |
| `/settings` | `SettingsView` | Theme, cache, about |

### MainNavigationView

```
┌─────────────────────────────────────────────────────────────┐
│                    MainNavigationView                       │
├─────────────────────────────────────────────────────────────┤
│  PageView (NeverScrollableScrollPhysics):                   │
│    Index 0: HomeView()                                      │
│    Index 1: ExploreView(initialQuery: _exploreSearchQuery)  │
│    Index 2: LibraryView()   // uses root LibraryCubit       │
├─────────────────────────────────────────────────────────────┤
│  CustomBottomNavigationBar (theme-aware):                   │
│    [ Home ]              [ Explore ]           [ Library ]  │
└─────────────────────────────────────────────────────────────┘
```

- `navigateToExplore()` — Home search icon.
- `navigateToExploreWithQuery(query)` — Home “See All” (`trending_all`).
- Explore is remounted with `ValueKey(_exploreSearchQuery)`.
- `ExploreViewBody` uses `AutomaticKeepAliveClientMixin`.

### Home chrome

`CustomAppBar`: Libris wordmark, search (`navigateToExplore`), settings (`context.push('/settings')`).

### Details chrome

`BookActionBottomBar`: shimmer pair while loading; then Download (if URL present) + **Read Now**. Both open the resolved Archive 2-up reader.

### Library chrome

Collection chips with counts, sort menu, share export, file import. `SavedBookCard` move/remove + progress editor for *Reading*.

### Explore welcome (`ExploreWelcomeState`)

1. Recent searches (Clear)  
2. Trending chips (Atomic Habits, Clean Code, Dune, …)  
3. Genre grid (Fiction, Programming, History, Science, Fantasy, Self-Help, Business, Mystery, Romance, Philosophy)  
4. Authors from saved library (up to 6)

### Settings

SegmentedButton for theme; clear home cache; clear search history; About (Libris 1.0.0, Open Library attribution).
