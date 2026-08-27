# Libris App — Project Context & Technical Reference

Single source of truth for the current codebase: architecture, APIs, cubits, models, persistence, and navigation.

---

## Table of Contents

1. [Overview](#overview)
2. [Bootstrap & DI](#bootstrap--di)
3. [API Layer](#api-layer)
4. [Search merge & reading](#search-merge--reading)
5. [State management](#state-management)
6. [Models](#models)
7. [Repositories](#repositories)
8. [Local storage](#local-storage)
9. [Routing & navigation](#routing--navigation)
10. [Theming & settings](#theming--settings)

---

## Overview

- **Name**: Libris
- **SDK**: Dart `^3.12.2` / Flutter Material 3
- **Pattern**: Feature-first folders + Cubit + repository interfaces (no use-case layer)
- **Android**: `applicationId` / namespace `com.mohamed.libris`; `INTERNET` in the main manifest; label `Libris`
- **Dependencies (runtime)**: `dio`, `dartz`, `flutter_bloc`, `equatable`, `hive` / `hive_flutter`, `go_router`, `cached_network_image`, `shimmer`, `shared_preferences`, `google_fonts`, `lottie`, `smooth_page_indicator`, `url_launcher`, `flutter_staggered_grid_view`, `share_plus`, `file_picker`, `path_provider`

Removed / unused: `flutter_dotenv`, `http`, `flutter_screenutil_plus`, `lib/constants/api_constants.dart`.

---

## Bootstrap & DI

`lib/main.dart`:

1. `Hive.initFlutter()` and open `kFeaturedBox`, `kFilterBox`, `kFavoritesBox`
2. `ServiceLocator.init()`
3. `runApp(MyApp)`

`MyApp` wraps the router with:

- `ThemeCubit` (persisted `theme_mode`)
- `LibraryCubit` (app-wide so Details bookmarks refresh Library)

`lib/core/di/service_locator.dart` holds:

- `ApiService(DioFactory.dio)`
- `HomeRepoImpl`, `SearchRepoImpl`, `DetailsRepoImpl`, `FavoritesRepoImpl`

Cubits default to `ServiceLocator.*` when no repo is injected.

---

## API Layer

### DioFactory — `lib/core/utils/dio_factory.dart`

Shared `Dio` with connect/send 12s, receive 15s, `Accept: application/json`. No interceptors.

### ApiService — `lib/core/utils/api_service.dart`

**Open Library** base: `https://openlibrary.org/`

| Method | Endpoint |
| :--- | :--- |
| `fetchBookDetails(workKey)` | `{cleanKey}.json` |
| `fetchBookRating(workKey)` | `{cleanKey}/ratings.json` |
| `fetchWorkEditions(workKey)` | `{cleanKey}/editions.json?limit=20` |
| `fetchTrendingBooks` | `trending/weekly.json?limit=` |
| `searchBooks` | `search.json?q=...&limit=&page=` plus `&language=eng` unless the query contains Arabic |
| `fetchBooksBySubject` | `search.json?q=subject:{subject}&language=eng&limit=&page=` |

**Internet Archive** (full URLs on the same Dio):

| Method | Role |
| :--- | :--- |
| `searchArchiveBooks` | `advancedsearch.php` — `mediatype:texts`, optional English/Arabic language filter, excludes `inlibrary` / `printdisabled` when `publicOnly` |
| `fetchArchiveMetadata` | `https://archive.org/metadata/{identifier}` |
| `resolveArchiveReaderUrl` | Finds a public identifier by title (English-only when the title is not Arabic; skips non-English docs). Returns `https://archive.org/details/{id}/page/n19/mode/2up` |

Home featured still uses `trending/weekly.json?limit=20`. Home filters use `search.json?q={subject}&language=eng&limit=50`.

Cache keys: `featured_list_eng`, `{subject}_eng`. TTL 8 hours. `HomeRepo.clearCache()` wipes featured + filter boxes.

---

## Search merge & reading

### Explore search — `SearchRepoImpl.searchBooks`

Runs Open Library search and Archive search in parallel.

1. **Open Library results first** (metadata, covers, `/works/` keys, English bias for Latin queries).
2. **Archive.org-only books appended** if the normalized title is not already in the OL list.
3. Matching titles are **not** given the Archive `ia` id (that id is often a French/Spanish scan).
4. If Archive returns empty, one retry without the language filter.

`normalizeBookTitle` lowercases, strips the subtitle after `:`, and keeps letters/digits/Arabic.

### Details — `DetailsRepoImpl.fetchBookDetails`

1. If `workKey` contains `/works/`, load Open Library details + ratings + editions.
2. If the item is Archive-only (`/ia/...`), try to resolve an Open Library work by title; if found, use OL details.
3. Only if there is no OL work, fall back to Archive metadata.
4. **Read / Download URLs** are never the OL `ia` / attached identifier. They always come from `resolveArchiveReaderUrl(title: openLibraryTitle)` so the reader language matches the details screen (English for English titles).

Reader URL shape:

`https://archive.org/details/{identifier}/page/n19/mode/2up`

Direct `/download/` PDF links are not used (they caused HTTP 401).

Details action bar shows shimmer while `BookDetailsLoading` / `BookDetailsInitial`.

---

## State management

```
UI → Cubit → Repo interface → ApiService / Hive
```

| Cubit | Path | Notes |
| :--- | :--- | :--- |
| `ThemeCubit` | `features/settings/presentation/manager/theme_cubit.dart` | `ThemeMode` system/light/dark |
| `LibraryCubit` | `features/library/presentation/manager/library_cubit/` | App-scoped; collections, sort, progress, backup |
| `FeaturedBooksCubit` | `features/home/presentation/manager/featured_books_cubit/` | Folder has no spaces |
| `FilterBooksCubit` | `features/home/presentation/manager/filter_books_cubit/` | |
| `ExploreCubit` | `features/explore/presentation/manager/explore_cubit/` | Debounce 400ms; `loadMoreError` keeps the list |
| `BookDetailsCubit` | `features/details/presentation/manager/book_details_cubit/` | Then loads similar books by OL subject |

### LibraryCubit

Collections: `All`, `Want to Read`, `Reading`, `Finished`, `Favorites`.

Sort: `LibrarySort.recent` | `title` | `year`.

Also: `collectionCounts`, `updateBookProgress` (100% moves to Finished), JSON export/import.

### ExploreCubit `ExploreSuccess`

`books`, `query`, `activeCategory`, `hasMore`, `isLoadingMore`, `loadMoreError`.

---

## Models

### `BookModel` — `lib/core/models/book_model.dart`

`key`, `title`, `authorName`, `coverUrl`, `firstPublishYear`, `collection`, `addedAt`, `progress`, `language`, `iaId`.

- `fromJson`: Open Library `works` / `docs` (cover via `cover_id` / `cover_i`; empty string if none — no placeholder.com).
- `fromArchiveJson` / `listFromArchiveResponse`: Archive search docs; `key` is `/ia/{identifier}`; cover `https://archive.org/services/img/{id}`.
- Helpers: `preferEnglishBooks`, `languageCodeFromJson`, `normalizeBookTitle`, `containsArabic`, `archiveReaderUrl`, `isArchiveBook`.

### `BookDetailModel` — `features/details/data/models/book_detail_model.dart`

OL `fromJson` (description string or `{value}`, subjects, ratings, language from work/editions preferring English when present).

`fromArchive` for metadata fallback.

`readUrl` / `downloadUrl` overwritten by the resolved Archive reader URL.

### `OnboardingModel`

Static slides in `OnboardingView`: Discover Great Books / Open Book Pages / Build Your Library.

---

## Repositories

| Impl | Sources | Behavior |
| :--- | :--- | :--- |
| `HomeRepoImpl` | ApiService, Hive | Trending + category search with English param; TTL cache; `clearCache` |
| `SearchRepoImpl` | ApiService | Merged search; subject + trending stay Open Library |
| `DetailsRepoImpl` | ApiService | OL details first; Archive reader by English title |
| `FavoritesRepoImpl` | Hive `kFavoritesBox` | CRUD, collection, progress, JSON backup |

---

## Local storage

### Hive

| Box | Keys | Value |
| :--- | :--- | :--- |
| `featured_books_box` | `featured_list_eng` | `{timestamp, items}` |
| `filter_books_box` | `{subject}_eng` | `{timestamp, items}` |
| `favorites_books_box` | work key | `BookModel.toJson()` including `collection`, `added_at`, `progress` |

### SharedPreferences

| Key | Use |
| :--- | :--- |
| `is_first_time_user` | Onboarding |
| `recent_searches` | Max 10 |
| `theme_mode` | `system` / `light` / `dark` |

---

## Routing & navigation

`lib/core/widgets/router.dart`

| Path | View |
| :--- | :--- |
| `/` | Splash |
| `/onboarding` | Onboarding |
| `/main` | Tabs: Home, Explore, Library (`PageView` with `NeverScrollableScrollPhysics`) |
| `/details` | `DetailsView` (`extra: BookModel`) |
| `/settings` | Settings |

`MainNavigationView`:

- `navigateToExplore()` — Home search icon
- `navigateToExploreWithQuery(query)` — Home “See All” (`trending_all`)

Bottom nav colors follow `ThemeData`.

Library view does **not** create its own cubit; it uses the root `LibraryCubit`. `FavoriteIconButton` calls that cubit.

Home AppBar: Libris wordmark, search, settings.

---

## Theming & settings

`lib/core/theme/app_theme.dart`

- Light: background `#F0EADE`, primary `#765A1F`
- Dark: background `#1A1610`, primary `#D4B56A`
- `LibrisTheme` on `BuildContext`: `colors`, `isDark`, `titleColor`, `mutedColor`, `pillColor`

Settings: segmented theme control, clear home cache, clear search history, about (v1.0.0, Open Library attribution).

Library backup: write JSON to a temp file and `SharePlus.instance.share`; import via `FilePicker` (`json`).
