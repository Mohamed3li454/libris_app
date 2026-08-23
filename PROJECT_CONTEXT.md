# Libris App - Comprehensive Project Context & Technical Reference

> **Document Purpose**: This document serves as the single source of truth and comprehensive technical reference for the Libris Flutter application. It details the architecture, API integration, state management, domain contracts, data models, persistence, and navigation systems based strictly on the codebase implementation.

---

## Table of Contents
1. [Project Overview & Architecture](#project-overview--architecture)
2. [API Layer](#1-api-layer)
   - [API Constants](#api-constants)
   - [Dio Client & ApiService Configuration](#dio-client--apiservice-configuration)
   - [Feature API Endpoints & Contract Details](#feature-api-endpoints--contract-details)
3. [State Management (Cubits)](#2-state-management-cubits)
   - [FeaturedBooksCubit](#featuredbookscubit)
   - [FilterBooksCubit](#filterbookscubit)
   - [ExploreCubit](#explorecubit)
   - [BookDetailsCubit](#bookdetailscubit)
   - [LibraryCubit](#librarycubit)
4. [Domain Layer](#3-domain-layer)
   - [Repository Interfaces](#repository-interfaces)
   - [Entities & Use Cases Assessment](#entities--use-cases-assessment)
   - [Failure Hierarchy & Functional Error Flow](#failure-hierarchy--functional-error-flow)
5. [Data Layer](#4-data-layer)
   - [Data Models & Serialization](#data-models--serialization)
   - [Data Sources & Repository Implementations](#data-sources--repository-implementations)
6. [Local Storage (Hive & SharedPreferences)](#5-local-storage-hive--sharedpreferences)
   - [Hive Boxes & Data Structures](#hive-boxes--data-structures)
   - [Hive Constants](#hive-constants)
   - [SharedPreferences (Onboarding State)](#sharedpreferences-onboarding-state)
7. [Routing & Navigation](#6-routing--navigation)
   - [GoRouter Configuration](#gorouter-configuration)
   - [Nested Bottom Navigation Mechanics](#nested-bottom-navigation-mechanics)

---

## Project Overview & Architecture

- **Application Name**: Libris App
- **Language**: Dart (SDK `^3.12.2`)
- **Framework**: Flutter (Material 3)
- **Architecture Pattern**: Clean Architecture with Feature-First packaging + BLoC/Cubit state management pattern.
- **Key External Dependencies**: `dio`, `dartz`, `flutter_bloc`, `equatable`, `hive`/`hive_flutter`, `go_router`, `cached_network_image`, `shimmer`, `flutter_dotenv`, `shared_preferences`, `google_fonts`, `lottie`, `smooth_page_indicator`, `url_launcher`.

---

## 1. API Layer

### API Constants
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/constants/api_constants.dart`

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get apiKey => dotenv.env['API_KEY'] ?? '';
}
```

- **Base URL**: `https://openlibrary.org/` (Defined in `/Users/mohamed3li/projects/libris_app/lib/core/utils/api_service.dart`)
- **API Keys / Environment**: `ApiConstants.apiKey` reads the `API_KEY` environment variable loaded asynchronously at startup in `main.dart` via `dotenv.load(fileName: ".env")`.
- **Note on Endpoints in `api_constants.dart`**: Not found. Endpoints and query parameters are declared and formatted directly within `/Users/mohamed3li/projects/libris_app/lib/core/utils/api_service.dart`.

---

### Dio Client & ApiService Configuration
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/core/utils/api_service.dart`

```dart
import 'package:dio/dio.dart';

class ApiService {
  final String baseUrl = "https://openlibrary.org/";
  final Dio _dio;

  ApiService(this._dio);

  Future<Map<String, dynamic>> getData({required String endPoint}) async {
    Response response = await _dio.get("$baseUrl$endPoint");
    return response.data;
  }
  ...
}
```

#### Detailed Configuration Breakdown:
1. **Instantiation**: `ApiService` receives a `Dio` instance injected via constructor (`ApiService(this._dio)`). In Cubits, default unconfigured `Dio()` instances are instantiated (e.g. `ApiService(Dio())`).
2. **BaseOptions**: Not explicitly configured on the `Dio` instance. The base URL `https://openlibrary.org/` is maintained as a constant string inside `ApiService` and concatenated directly with `endPoint` (`"$baseUrl$endPoint"`).
3. **Timeouts (Connect/Receive/Send)**: Not configured explicitly in `ApiService` (Dio default timeouts apply). However, timeout exceptions (`connectionTimeout`, `sendTimeout`, `receiveTimeout`) are gracefully caught and mapped to user-friendly messages in `/Users/mohamed3li/projects/libris_app/lib/core/errors/failure.dart`.
4. **Interceptors**: None configured in `ApiService`.
5. **Headers**: Default standard Dio headers are used; Open Library REST endpoints are public and do not require custom auth headers.
6. **Error Handling**: `_dio.get()` executes asynchronously. Uncaught exceptions propagate directly to the calling Repository Implementation layer (`HomeRepoImpl`, `SearchRepoImpl`, `DetailsRepoImpl`), where `DioException` instances are caught and translated into domain `ServerFailure` objects via `ServerFailure.fromDioError(e)`.

---

### Feature API Endpoints & Contract Details

#### 1. Home Feature
- **Repository Implementation Path**: `/Users/mohamed3li/projects/libris_app/lib/features/home/data/repos/home_repo_impl.dart`
- **Underlying Service Path**: `/Users/mohamed3li/projects/libris_app/lib/core/utils/api_service.dart`

##### A. `fetchFeaturedBooks()`
- **Calling Method**: `HomeRepoImpl.fetchFeaturedBooks()` calling `ApiService.getData(endPoint: "trending/weekly.json?limit=20")`
- **Exact Endpoint**: `https://openlibrary.org/trending/weekly.json?limit=20`
- **Parameters**: None (Hardcoded query parameter `limit=20` in `endPoint`)
- **JSON Response Shape Example**:
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
    },
    {
      "key": "/works/OL45804W",
      "title": "The Hobbit",
      "author_name": ["J.R.R. Tolkien"],
      "cover_i": 8406786,
      "first_publish_year": 1937
    }
  ],
  "days": 7
}
```

##### B. `fetchFilterBooks({required String category})`
- **Calling Method**: `HomeRepoImpl.fetchFilterBooks({required String category})` calling `ApiService.getData(endPoint: "search.json?q=$subject&limit=50")`
- **Exact Endpoint**: `https://openlibrary.org/search.json?q={subject}&limit=50`
  - *Logic*: If `category.isEmpty` or `category.toLowerCase() == 'all'`, `subject` defaults to `'general'`, otherwise `category.toLowerCase()`.
- **Parameters**: `category` (`String`, required)
- **JSON Response Shape Example**:
```json
{
  "numFound": 14205,
  "start": 0,
  "numFoundExact": true,
  "docs": [
    {
      "key": "/works/OL102749W",
      "title": "Clean Code",
      "author_name": ["Robert C. Martin"],
      "cover_i": 9257697,
      "first_publish_year": 2008
    }
  ]
}
```

---

#### 2. Explore Feature
- **Repository Implementation Path**: `/Users/mohamed3li/projects/libris_app/lib/features/explore/data/repos/search_repo_impl.dart`
- **Underlying Service Path**: `/Users/mohamed3li/projects/libris_app/lib/core/utils/api_service.dart`

##### A. `searchBooks(String query)`
- **Calling Method**: `SearchRepoImpl.searchBooks(String query)` calling `ApiService.searchBooks(String query)` -> `ApiService.getData(endPoint: "search.json?q=$encodedQuery&limit=50")`
- **Exact Endpoint**: `https://openlibrary.org/search.json?q={Uri.encodeComponent(query)}&limit=50`
- **Parameters**: `query` (`String`)
- **JSON Response Shape Example**:
```json
{
  "numFound": 320,
  "start": 0,
  "docs": [
    {
      "key": "/works/OL27479W",
      "title": "1984",
      "author_name": ["George Orwell"],
      "cover_i": 12645114,
      "first_publish_year": 1949
    }
  ]
}
```

##### B. `fetchBooksBySubject(String subject)`
- **Calling Method**: `SearchRepoImpl.fetchBooksBySubject(String subject)` calling `ApiService.fetchBooksBySubject(String subject)` -> `ApiService.getData(endPoint: "subjects/$cleanSubject.json?limit=50")`
  - *Logic*: Subject is cleaned via `subject.toLowerCase().replaceAll(' ', '_')`.
- **Exact Endpoint**: `https://openlibrary.org/subjects/{cleanSubject}.json?limit=50`
- **Parameters**: `subject` (`String`)
- **JSON Response Shape Example**:
```json
{
  "key": "/subjects/science_fiction",
  "name": "Science Fiction",
  "work_count": 8900,
  "works": [
    {
      "key": "/works/OL262758W",
      "title": "Dune",
      "authors": [
        {
          "key": "/authors/OL31574A",
          "name": "Frank Herbert"
        }
      ],
      "cover_id": 11149138,
      "first_publish_year": 1965
    }
  ]
}
```

##### C. `fetchTrendingBooks({int limit = 50})`
- **Calling Method**: `SearchRepoImpl.fetchTrendingBooks({int limit = 50})` calling `ApiService.fetchTrendingBooks({int limit = 50})` -> `ApiService.getData(endPoint: "trending/weekly.json?limit=$limit")`
- **Exact Endpoint**: `https://openlibrary.org/trending/weekly.json?limit={limit}`
- **Parameters**: `limit` (`int`, optional, default = `50`)
- **JSON Response Shape Example**:
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

---

#### 3. Details Feature
- **Repository Implementation Path**: `/Users/mohamed3li/projects/libris_app/lib/features/details/data/repos/details_repo_impl.dart`
- **Underlying Service Path**: `/Users/mohamed3li/projects/libris_app/lib/core/utils/api_service.dart`

##### A. `fetchBookDetails(String workKey)` & `fetchBookRating(String workKey)`
- **Calling Method**: `DetailsRepoImpl.fetchBookDetails(String workKey)` executes concurrent API calls via `Future.wait([apiService.fetchBookDetails(workKey), apiService.fetchBookRating(workKey).catchError(...)])`.
- **Exact Endpoints**:
  1. Book Details: `https://openlibrary.org/{cleanKey}.json` (where `cleanKey` strips leading `'/'` if present).
  2. Book Ratings: `https://openlibrary.org/{cleanKey}/ratings.json`
- **Parameters**: `workKey` (`String`, e.g. `"/works/OL82563W"` or `"works/OL82563W"`)
- **JSON Response Shape Examples**:
  - *Details Endpoint Response*:
```json
{
  "description": {
    "type": "/type/text",
    "value": "Harry Potter has never even heard of Hogwarts when the letters start dropping on the doormat..."
  },
  "title": "Harry Potter and the Sorcerer's Stone",
  "key": "/works/OL82563W",
  "subjects": [
    "Fantasy",
    "Wizards",
    "Magic",
    "Hogwarts School of Witchcraft and Wizardry"
  ],
  "links": [
    {
      "title": "Internet Archive",
      "url": "https://archive.org/details/harrypotterphilosophersstone"
    }
  ]
}
```
  - *Ratings Endpoint Response*:
```json
{
  "summary": {
    "average": 4.62,
    "count": 2841,
    "sortable": 4.618
  }
}
```

---

#### 4. Library Feature
- **API Call Status**: **Not found**
- **Explanation**: The Library feature operates purely offline and communicates strictly with local Hive storage (`kFavoritesBox`) via `FavoritesRepoImpl`. It does not perform any HTTP or API network operations.

---

## 2. State Management (Cubits)

```
                       ┌─────────────────────────┐
                       │      UI / Widgets       │
                       └────────────┬────────────┘
                                    │ triggers method
                                    ▼
                       ┌─────────────────────────┐
                       │          Cubit          │
                       └────────────┬────────────┘
                                    │ calls
                                    ▼
                       ┌─────────────────────────┐
                       │   Repository Contract   │
                       └────────────┬────────────┘
                                    │
                  ┌─────────────────┴─────────────────┐
                  ▼                                   ▼
        ┌───────────────────┐               ┌───────────────────┐
        │    ApiService     │               │   Hive Storage    │
        │   (Dio Client)    │               │  (Local Caches)   │
        └───────────────────┘               └───────────────────┘
```

---

### FeaturedBooksCubit
- **Full File Paths**:
  - Cubit: `/Users/mohamed3li/projects/libris_app/lib/features/home/presentation/manager/featured books cubit/featured_books_cubit.dart`
  - States: `/Users/mohamed3li/projects/libris_app/lib/features/home/presentation/manager/featured books cubit/featured_books_state.dart`
- **Inheritance**: `Cubit<FeaturedBooksState>` with `Equatable`

#### States & Payload:
1. `FeaturedBooksInitial`: Initial state before fetching. Carries no payload.
2. `FeaturedBooksLoading`: Emitted immediately when `fetchFeaturedBooks()` starts. Carries no payload.
3. `FeaturedBooksSuccess`: Emitted when books are fetched successfully.
   - Payload: `final List<BookModel> books;`
4. `FeaturedBooksFailure`: Emitted when an error occurs.
   - Payload: `final String errMessage;`

#### Public Methods & Invocations:
- `Future<void> fetchFeaturedBooks()`:
  - Emits `FeaturedBooksLoading()`.
  - Invokes `HomeRepo.fetchFeaturedBooks()`.
  - On `Left(failure)`, emits `FeaturedBooksFailure(failure.errMessage)`.
  - On `Right(books)`, emits `FeaturedBooksSuccess(books)`.
  - Checks `if (isClosed) return;` to prevent emitting states on unmounted widgets.

#### Listening / Calling Widgets:
- **Provided in**: `HomeView` (`/Users/mohamed3li/projects/libris_app/lib/features/home/presentation/view/home_view.dart`) via `MultiBlocProvider`.
- **Listened by**:
  - `FeaturedListViewBuilder` (`/Users/mohamed3li/projects/libris_app/lib/features/home/presentation/view/widgets/featured_list_view_builder.dart`) via `BlocBuilder<FeaturedBooksCubit, FeaturedBooksState>`.
- **Called by**:
  - `HomeView` (triggered on create: `..fetchFeaturedBooks()`).
  - `HomeViewBody` (pull-to-refresh `RefreshIndicator` triggers `featuredCubit.fetchFeaturedBooks()`).
  - `FeaturedListViewBuilder` (retry button in `CustomErrorWidget`).

---

### FilterBooksCubit
- **Full File Paths**:
  - Cubit: `/Users/mohamed3li/projects/libris_app/lib/features/home/presentation/manager/filter_books_cubit/filter_books_cubit.dart`
  - States: `/Users/mohamed3li/projects/libris_app/lib/features/home/presentation/manager/filter_books_cubit/filter_books_state.dart`
- **Inheritance**: `Cubit<FilterBooksState>` with `Equatable`
- **Internal State Variables**: `String currentCategory = 'All';`

#### States & Payload:
1. `FilterBooksInitial`: Initial state before any category fetch. Carries no payload.
2. `FilterBooksLoading`: Emitted immediately when fetching starts. Carries no payload.
3. `FilterBooksSuccess`: Emitted when category books are retrieved.
   - Payload: `final List<BookModel> books;`, `final String category;`
4. `FilterBooksFailure`: Emitted when category fetching fails.
   - Payload: `final String errMessage;`

#### Public Methods & Invocations:
- `Future<void> fetchFilterBooks({required String category})`:
  - Sets `currentCategory = category`.
  - Emits `FilterBooksLoading()`.
  - Invokes `HomeRepo.fetchFilterBooks(category: category)`.
  - On `Left(failure)`, emits `FilterBooksFailure(failure.errMessage)`.
  - On `Right(books)`, emits `FilterBooksSuccess(books: books, category: category)`.

#### Listening / Calling Widgets:
- **Provided in**: `HomeView` (`/Users/mohamed3li/projects/libris_app/lib/features/home/presentation/view/home_view.dart`) via `MultiBlocProvider`.
- **Listened by**:
  - `FilterBookSliverListView` (`/Users/mohamed3li/projects/libris_app/lib/features/home/presentation/view/widgets/filter_book_sliver_list_view.dart`) via `BlocBuilder<FilterBooksCubit, FilterBooksState>`.
- **Called by**:
  - `HomeView` (on initialization: `..fetchFilterBooks(category: 'All')`).
  - `HomeViewBody` (pull-to-refresh `RefreshIndicator`).
  - `FilterChipsList` (`/Users/mohamed3li/projects/libris_app/lib/features/home/presentation/view/widgets/filter_chips_list.dart`) when user taps on any chip (Tech, Fiction, History, Business, etc.).
  - `FilterBookSliverListView` (retry button in `CustomErrorWidget`).

---

### ExploreCubit
- **Full File Paths**:
  - Cubit: `/Users/mohamed3li/projects/libris_app/lib/features/explore/presentation/manager/explore_cubit/explore_cubit.dart`
  - States: `/Users/mohamed3li/projects/libris_app/lib/features/explore/presentation/manager/explore_cubit/explore_state.dart`
- **Inheritance**: `Cubit<ExploreState>` with `Equatable`
- **Internal State Variables**: `Timer? _debounceTimer;` (400ms debounce timer for keystroke throttling).

#### States & Payload:
1. `ExploreInitial`: Initial default screen state (shows welcome search guide). Carries no payload.
2. `ExploreLoading`: Emitted while searching or fetching categories. Carries no payload.
3. `ExploreSuccess`: Emitted when search results or category books are found.
   - Payload: `final List<BookModel> books;`, `final String? query;`, `final String? activeCategory;`
4. `ExploreEmpty`: Emitted when an API query returns 0 books.
   - Payload: `final String query;`
5. `ExploreFailure`: Emitted on search/network errors.
   - Payload: `final String errMessage;`

#### Public Methods & Invocations:
- `void searchBooksDebounced(String query)`: Cancels active timer, validates query length (minimum 3 characters; emits `ExploreInitial()` if shorter), schedules `searchBooks(cleanQuery)` after 400ms.
- `Future<void> searchBooks(String query)`: Validates input, emits `ExploreLoading()`, calls `SearchRepo.searchBooks(cleanQuery)`. Emits `ExploreEmpty` if list is empty, or `ExploreSuccess` if books exist.
- `Future<void> fetchBooksBySubject(String subject)`: Cancels timer, emits `ExploreLoading()`, calls `SearchRepo.fetchBooksBySubject(subject)`.
- `Future<void> fetchTrendingBooks({int limit = 50})`: Cancels timer, emits `ExploreLoading()`, calls `SearchRepo.fetchTrendingBooks(limit: limit)`.
- `void resetSearch()`: Cancels timer, emits `ExploreInitial()`.
- `close()`: Cancels timer and closes cubit.

#### Listening / Calling Widgets:
- **Provided in**: `ExploreView` (`/Users/mohamed3li/projects/libris_app/lib/features/explore/presentation/view/explore_view.dart`).
- **Listened by**:
  - `ExploreViewBody` (`/Users/mohamed3li/projects/libris_app/lib/features/explore/presentation/view/widgets/explore_view_body.dart`) via `BlocBuilder<ExploreCubit, ExploreState>`.
- **Called by**:
  - `CustomSearchTextField` (`/Users/mohamed3li/projects/libris_app/lib/features/explore/presentation/view/widgets/custom_search_text_field.dart`) on typing (`searchBooksDebounced`) and clear (`resetSearch`).
  - `ExploreCategoryChipsList` (`/Users/mohamed3li/projects/libris_app/lib/features/explore/presentation/view/widgets/explore_category_chips_list.dart`) (`fetchBooksBySubject`).
  - `ExploreViewBody` (`_executeInitialSearch` routing from Home's "See All" triggers `fetchTrendingBooks`).
  - `ExploreViewBody` (retry button in `CustomErrorWidget`).

---

### BookDetailsCubit
- **Full File Paths**:
  - Cubit: `/Users/mohamed3li/projects/libris_app/lib/features/details/presentation/manager/book_details_cubit/book_details_cubit.dart`
  - States: `/Users/mohamed3li/projects/libris_app/lib/features/details/presentation/manager/book_details_cubit/book_details_state.dart`
- **Inheritance**: `Cubit<BookDetailsState>` with `Equatable`

#### States & Payload:
1. `BookDetailsInitial`: Initial state before fetching details. Carries no payload.
2. `BookDetailsLoading`: Emitted while details and ratings are being fetched. Carries no payload.
3. `BookDetailsSuccess`: Emitted when detailed book information and ratings are loaded.
   - Payload: `final BookDetailModel bookDetail;`
4. `BookDetailsFailure`: Emitted if the details request fails.
   - Payload: `final String errMessage;`

#### Public Methods & Invocations:
- `Future<void> fetchBookDetails({required String workKey})`:
  - Emits `BookDetailsLoading()`.
  - Invokes `DetailsRepo.fetchBookDetails(workKey)`.
  - On `Left(failure)`, emits `BookDetailsFailure(failure.errMessage)`.
  - On `Right(bookDetail)`, emits `BookDetailsSuccess(bookDetail)`.

#### Listening / Calling Widgets:
- **Provided in**: `DetailsView` (`/Users/mohamed3li/projects/libris_app/lib/features/details/presentation/view/details_view.dart`).
- **Listened by**:
  - `BookHeaderInfo` (`/Users/mohamed3li/projects/libris_app/lib/features/details/presentation/view/widgets/book_header_info.dart`) to show primary genre/category tag with shimmer loading.
  - `BookStatsCard` (`/Users/mohamed3li/projects/libris_app/lib/features/details/presentation/view/widgets/book_stats_card.dart`) to show ratings and votes with shimmer loading.
  - `BookDescriptionSection` (`/Users/mohamed3li/projects/libris_app/lib/features/details/presentation/view/widgets/book_description_section.dart`) to display full expandable/collapsible description.
  - `BookActionBottomBar` (`/Users/mohamed3li/projects/libris_app/lib/features/details/presentation/view/widgets/book_action_bottom_bar.dart`) to extract dynamic `readUrl` and `downloadUrl`.
- **Called by**:
  - `DetailsView` upon creation (`if (bookModel != null && bookModel!.key.isNotEmpty) cubit.fetchBookDetails(...)`).

---

### LibraryCubit
- **Full File Paths**:
  - Cubit: `/Users/mohamed3li/projects/libris_app/lib/features/library/presentation/manager/library_cubit/library_cubit.dart`
  - States: `/Users/mohamed3li/projects/libris_app/lib/features/library/presentation/manager/library_cubit/library_state.dart`
- **Inheritance**: `Cubit<LibraryState>` with `Equatable`

#### States & Payload:
1. `LibraryInitial`: Initial state before querying Hive. Carries no payload.
2. `LibraryLoading`: Emitted while querying Hive storage. Carries no payload.
3. `LibrarySuccess`: Emitted when at least one favorite book exists in the box.
   - Payload: `final List<BookModel> books;`
4. `LibraryEmpty`: Emitted when the favorite box has 0 books. Carries no payload.
5. `LibraryFailure`: Emitted on Hive read exceptions.
   - Payload: `final String errMessage;`

#### Public Methods & Invocations:
- `void fetchFavoriteBooks()`:
  - Emits `LibraryLoading()`.
  - Invokes `FavoritesRepo.getFavoriteBooks()`.
  - Emits `LibraryEmpty()` if empty or `LibrarySuccess(books)` if non-empty.
- `Future<bool> toggleFavoriteBook(BookModel book)`:
  - Invokes `FavoritesRepo.toggleFavoriteBook(book)`.
  - Re-invokes `fetchFavoriteBooks()` to refresh UI state. Returns `bool` (`true` if saved, `false` if removed).
- `Future<void> removeFavoriteBook(String key)`:
  - Invokes `FavoritesRepo.removeFavoriteBook(key)`.
  - Re-invokes `fetchFavoriteBooks()`.
- `bool isBookFavorite(String key)`:
  - Returns `FavoritesRepo.isBookFavorite(key)` directly.

#### Listening / Calling Widgets:
- **Provided in**: `LibraryView` (`/Users/mohamed3li/projects/libris_app/lib/features/library/presentation/view/library_view.dart`).
- **Listened by**:
  - `LibraryViewBody` (`/Users/mohamed3li/projects/libris_app/lib/features/library/presentation/view/widgets/library_view_body.dart`) via `BlocBuilder<LibraryCubit, LibraryState>`.
- **Called by**:
  - `LibraryView` upon creation (`..fetchFavoriteBooks()`).
  - `SavedBookCard` (`/Users/mohamed3li/projects/libris_app/lib/features/library/presentation/view/widgets/saved_book_card.dart`) on clicking bookmark remove icon (`removeFavoriteBook`), and after returning from Details navigation to refresh favorite state.
  - `LibraryViewBody` (retry button on `CustomErrorWidget`).

---

## 3. Domain Layer

### Repository Interfaces

#### 1. `HomeRepo`
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/features/home/data/repos/home_repo.dart`
- **Method Signatures**:
```dart
abstract class HomeRepo {
  Future<Either<Failure, List<BookModel>>> fetchFeaturedBooks();
  Future<Either<Failure, List<BookModel>>> fetchFilterBooks({
    required String category,
  });
}
```

#### 2. `SearchRepo`
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/features/explore/data/repos/search_repo.dart`
- **Method Signatures**:
```dart
abstract class SearchRepo {
  Future<Either<Failure, List<BookModel>>> searchBooks(String query);
  Future<Either<Failure, List<BookModel>>> fetchBooksBySubject(String subject);
  Future<Either<Failure, List<BookModel>>> fetchTrendingBooks({int limit = 50});
}
```

#### 3. `DetailsRepo`
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/features/details/data/repos/details_repo.dart`
- **Method Signatures**:
```dart
abstract class DetailsRepo {
  Future<Either<Failure, BookDetailModel>> fetchBookDetails(String workKey);
}
```

#### 4. `FavoritesRepo`
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/features/library/data/repos/favorites_repo.dart`
- **Method Signatures**:
```dart
abstract class FavoritesRepo {
  List<BookModel> getFavoriteBooks();
  Future<void> addFavoriteBook(BookModel book);
  Future<void> removeFavoriteBook(String key);
  bool isBookFavorite(String key);
  Future<bool> toggleFavoriteBook(BookModel book);
}
```

---

### Entities & Use Cases Assessment
- **Entities Status**: **Not found**
  - *Details*: The codebase does not maintain a segregated `domain/entities/` directory. Domain models and Data models are unified directly within `lib/core/models/book_model.dart`, `lib/features/details/data/models/book_detail_model.dart`, and `lib/features/onboarding/data/models/onboarding_model.dart`.
- **Use Cases Status**: **Not found**
  - *Details*: The codebase does not use individual Use Case / Interactor classes. Cubits directly inject and interact with the Repository interfaces.

---

### Failure Hierarchy & Functional Error Flow

#### Failure Hierarchy Tree
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/core/errors/failure.dart`

```
                      ┌────────────────────────┐
                      │    abstract Failure    │
                      │  (String errMessage)   │
                      └───────────┬────────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         ▼                        ▼                        ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  ServerFailure   │    │  FormatFailure   │    │   CacheFailure   │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

#### Code Implementation Details:
1. `Failure` (Base Class):
```dart
abstract class Failure {
  final String errMessage;
  const Failure(this.errMessage);
}
```
2. `ServerFailure`:
   - Contains factory `ServerFailure.fromDioError(DioException dioException)`:
     - `DioExceptionType.connectionTimeout` -> `'Connection timeout. Please try again.'`
     - `DioExceptionType.sendTimeout` -> `'Send timeout. Please check your connection.'`
     - `DioExceptionType.receiveTimeout` -> `'Receive timeout. Please try again later.'`
     - `DioExceptionType.badCertificate` -> `'Bad certificate error with server.'`
     - `DioExceptionType.badResponse` -> delegates to `ServerFailure.fromResponse(statusCode, data)`
     - `DioExceptionType.cancel` -> `'Request to server was canceled.'`
     - `DioExceptionType.connectionError` -> `'No internet connection. Please check your network.'`
     - `DioExceptionType.unknown` (with `SocketException`) -> `'No internet connection. Please check your network.'` / `'Unexpected network error. Please try again.'`
     - `default` -> `'An unexpected error occurred. Please try again.'`
   - Contains factory `ServerFailure.fromResponse(int? statusCode, dynamic response)`:
     - `400`, `401`, `403` -> extracts nested `response['error']['message']` if present, else `'Authentication or request error. Please try again.'`
     - `404` -> `'Requested item not found. Please try again later.'`
     - `500` -> `'Internal server error. Please try again later.'`
     - Other status codes -> `'An unexpected server error occurred. Please try again.'`
3. `FormatFailure`:
   - Default message: `'Unable to process book data. Please try again.'` (Catches `FormatException` and `TypeError`).
4. `CacheFailure`:
   - Default message: `'Failed to load saved offline data.'`

#### How Errors Flow from Data to Presentation:

```
[ Data Layer: ApiService / Dio ]
               │
               ▼ throws DioException / TypeError / FormatException
[ Data Layer: RepoImpl (try/catch) ]
               │
               ▼ converts to Left(ServerFailure / FormatFailure)
[ Presentation Layer: Cubit (result.fold) ]
               │
               ▼ emits StateFailure(failure.errMessage)
[ Presentation Layer: BlocBuilder Widget ]
               │
               ▼ renders CustomErrorWidget(errMessage, onRetry) or SnackBar
```

---

## 4. Data Layer

### Data Models & Serialization

#### 1. `BookModel` & `BookResponseModel`
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/core/models/book_model.dart`
- **Fields**:
  - `final String key;`
  - `final String title;`
  - `final String authorName;`
  - `final String coverUrl;`
  - `final int? firstPublishYear;`
- **`BookResponseModel.fromJson(Map<String, dynamic> json)`**:
  - Checks `json['works'] ?? json['docs'] ?? []` to support both Open Library Search and Trending/Subjects API structures polymorphically.
- **`BookModel.fromJson(Map<String, dynamic> json)`**:
  - Cover Image: Extracts `json['cover_id'] ?? json['cover_i']`. If present, constructs `'https://covers.openlibrary.org/b/id/$coverId-L.jpg'`. If explicit `cover_url` exists, uses it; otherwise falls back to `'https://via.placeholder.com/150?text=No+Cover'`.
  - Author Parsing: Parses `authors` list (extracting `firstAuthor['name']` if map or string representation) or `author_name` list (extracting first item as string). Defaults to `'Unknown Author'`.
  - Fallbacks: Title defaults to `'No Title'`, Key defaults to `''`.
- **`BookModel.toJson()`**:
```dart
Map<String, dynamic> toJson() {
  return {
    'key': key,
    'title': title,
    'author_name': [authorName],
    'cover_url': coverUrl,
    'first_publish_year': firstPublishYear,
  };
}
```

#### 2. `BookDetailModel`
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/features/details/data/models/book_detail_model.dart`
- **Fields**:
  - `final String key;`
  - `final String title;`
  - `final String description;`
  - `final String primaryCategory;`
  - `final List<String> subjects;`
  - `final double averageRating;`
  - `final int ratingCount;`
  - `final String readUrl;`
  - `final String downloadUrl;`
- **`BookDetailModel.fromJson({required Map<String, dynamic> detailsJson, Map<String, dynamic>? ratingJson})`**:
  - Link Resolution: Iterates over `detailsJson['links']`. If a link contains `archive.org` or ends with `.pdf`, assigns it to `downloadLink`. Otherwise assigns to `readLink`. Both fall back to `'https://openlibrary.org$fullKey'`.
  - Description Parsing: Handles `detailsJson['description']` whether it is a raw `String` or an object `{'value': '...'}`. Defaults to `'No description available for this book.'`.
  - Subjects & Primary Category: Extracts `detailsJson['subjects']` list; assigns first entry to `primaryCategory`, defaulting to `'General'`.
  - Rating Extraction: Extracts `ratingJson['summary']['average']` (as `double`) and `count` (as `int`). Defaults to `0.0` and `0`.
- **`toJson`**: Not found (The model is read-only from Open Library API and is not written to local cache in JSON format).

#### 3. `OnboardingModel`
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/features/onboarding/data/models/onboarding_model.dart`
- **Fields**:
  - `final String title;`
  - `final String subtitle;`
  - `final String lottiePath;`
  - `final String badgeText;`
- **Serialization**: `fromJson` / `toJson` Not found (Static compile-time constant model instantiated in `OnboardingView`).

---

### Data Sources & Repository Implementations

| Repository Implementation | Full File Path | Data Source(s) Used | Methods Implemented & Logic |
| :--- | :--- | :--- | :--- |
| **`HomeRepoImpl`** | `lib/features/home/data/repos/home_repo_impl.dart` | `ApiService`, `Hive.box(kFeaturedBox)`, `Hive.box(kFilterBox)` | • `fetchFeaturedBooks()`: Calls `apiService.getData("trending/weekly.json?limit=20")`. Saves raw works to `kFeaturedBox` under `'featured_list'`. On network error, reads cached list from Hive box before returning failure.<br>• `fetchFilterBooks({category})`: Calls `apiService.getData("search.json?q=$subject&limit=50")`. Caches raw response in `kFilterBox` under key `subject`. On error, falls back to Hive cached data. |
| **`SearchRepoImpl`** | `lib/features/explore/data/repos/search_repo_impl.dart` | `ApiService` | • `searchBooks(query)`: Calls `apiService.searchBooks(query)`.<br>• `fetchBooksBySubject(subject)`: Calls `apiService.fetchBooksBySubject(subject)`.<br>• `fetchTrendingBooks({limit})`: Calls `apiService.fetchTrendingBooks(limit: limit)`. |
| **`DetailsRepoImpl`** | `lib/features/details/data/repos/details_repo_impl.dart` | `ApiService` | • `fetchBookDetails(workKey)`: Concurrently calls `apiService.fetchBookDetails(workKey)` and `apiService.fetchBookRating(workKey)`. Merges both responses into `BookDetailModel`. |
| **`FavoritesRepoImpl`** | `lib/features/library/data/repos/favorites_repo_impl.dart` | `Hive.box(kFavoritesBox)` | • `getFavoriteBooks()`: Iterates over all keys in `kFavoritesBox`, deserializes each map via `BookModel.fromJson()`.<br>• `addFavoriteBook(book)`: Puts `book.toJson()` in box under `book.key`.<br>• `removeFavoriteBook(key)`: Deletes key from box.<br>• `isBookFavorite(key)`: Checks `box.containsKey(key)`.<br>• `toggleFavoriteBook(book)`: Adds or removes book dynamically. |

---

## 5. Local Storage (Hive & SharedPreferences)

### Hive Boxes & Data Structures

```
┌────────────────────────────────────────────────────────────────────────────┐
│                                Hive Storage                                │
├─────────────────────────┬──────────────────────────┬───────────────────────┤
│    featured_books_box   │     filter_books_box     │  favorites_books_box  │
│      (kFeaturedBox)     │       (kFilterBox)       │    (kFavoritesBox)    │
├─────────────────────────┼──────────────────────────┼───────────────────────┤
│ Key: 'featured_list'    │ Key: <category_slug>     │ Key: <book_work_key>  │
│ Value: List<dynamic>    │ Value: List<dynamic>     │ Value: Map<String,    │
│ (Raw works/docs maps)   │ (Raw works/docs maps)    │             dynamic>  │
│                         │                          │ (Serialized BookModel)│
└─────────────────────────┴──────────────────────────┴───────────────────────┘
```

#### Detailed Box Specifications:

1. **`featured_books_box` (`kFeaturedBox`)**:
   - **Key**: `'featured_list'` (String)
   - **Stored Value Structure**: `List<dynamic>` (List of Open Library raw book map objects from `data['works'] ?? data['docs']`).
   - **Purpose**: Offline caching for home screen featured carousel.

2. **`filter_books_box` (`kFilterBox`)**:
   - **Key**: Category name slug (e.g. `'general'`, `'tech'`, `'fiction'`, `'history'`).
   - **Stored Value Structure**: `List<dynamic>` (List of Open Library raw book map objects from `data['works'] ?? data['docs']`).
   - **Purpose**: Offline caching for home screen category filter list view.

3. **`favorites_books_box` (`kFavoritesBox`)**:
   - **Key**: Book work key (e.g. `'/works/OL82563W'`).
   - **Stored Value Structure**: `Map<String, dynamic>` (Serialized via `BookModel.toJson()`):
```json
{
  "key": "/works/OL82563W",
  "title": "Harry Potter and the Sorcerer's Stone",
  "author_name": ["J.K. Rowling"],
  "cover_url": "https://covers.openlibrary.org/b/id/10521270-L.jpg",
  "first_publish_year": 1997
}
```
   - **Purpose**: Persistent local storage of user bookmarked/saved books for the Library tab.

---

### Hive Constants
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/constants/hive_constants.dart`

```dart
const String kFeaturedBox = 'featured_books_box';
const String kFilterBox = 'filter_books_box';
const String kFavoritesBox = 'favorites_books_box';
```

- **Initialization in `main.dart`**:
```dart
await Hive.initFlutter();
await Hive.openBox(kFeaturedBox);
await Hive.openBox(kFilterBox);
await Hive.openBox(kFavoritesBox);
```

---

### SharedPreferences (Onboarding State)
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/core/services/onboarding_service.dart`
- **Key**: `_kFirstTimeUserKey = 'is_first_time_user'`
- **Methods**:
  - `static Future<bool> isFirstTimeUser()`: Reads boolean flag (defaults to `true`).
  - `static Future<void> setFirstTimeUserComplete()`: Writes `false` to prevent future onboarding displays on app launch.

---

## 6. Routing & Navigation

### GoRouter Configuration
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/core/widgets/router.dart`

```dart
import 'package:go_router/go_router.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/details/presentation/view/details_view.dart';
import 'package:libris_app/features/main/presentation/view/main_navigation_view.dart';
import 'package:libris_app/features/onboarding/presentation/view/onboarding_view.dart';
import 'package:libris_app/features/splash/presentation/view/splash_view.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingView(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainNavigationView(),
    ),
    GoRoute(
      path: '/details',
      builder: (context, state) {
        final bookModel = state.extra as BookModel?;
        return DetailsView(bookModel: bookModel);
      },
    ),
  ],
);
```

#### Route Mapping Table:

| Route Path | Target View Widget | Target File Full Path | Arguments / Extra Passed | Description & Behavior |
| :--- | :--- | :--- | :--- | :--- |
| `'/'` | `SplashView` | `/Users/mohamed3li/projects/libris_app/lib/features/splash/presentation/view/splash_view.dart` | None | Initial startup route. Runs 1.2s logo animation + 1.8s delay, checks `OnboardingService.isFirstTimeUser()`, routes to `'/onboarding'` or `'/main'`. |
| `'/onboarding'` | `OnboardingView` | `/Users/mohamed3li/projects/libris_app/lib/features/onboarding/presentation/view/onboarding_view.dart` | None | 3-slide introductory carousel. On completion/skip, flags user in `SharedPreferences` and calls `context.go('/main')`. |
| `'/main'` | `MainNavigationView` | `/Users/mohamed3li/projects/libris_app/lib/features/main/presentation/view/main_navigation_view.dart` | `initialIndex` (optional, defaults to 0) | Core tab container holding `HomeView`, `ExploreView`, and `LibraryView` in a synchronized `PageView`. |
| `'/details'` | `DetailsView` | `/Users/mohamed3li/projects/libris_app/lib/features/details/presentation/view/details_view.dart` | `state.extra as BookModel?` | Book details view displaying cover, metadata, author, ratings, reviews, and action buttons. |

---

### Nested Bottom Navigation Mechanics
- **Full File Path**: `/Users/mohamed3li/projects/libris_app/lib/features/main/presentation/view/main_navigation_view.dart`
- **Bottom Navigation Bar Widget Path**: `/Users/mohamed3li/projects/libris_app/lib/core/widgets/custom_bottom_navigation_bar.dart`

```
┌─────────────────────────────────────────────────────────────┐
│                    MainNavigationView                       │
├─────────────────────────────────────────────────────────────┤
│  PageView (PageController):                                 │
│    Index 0: HomeView()                                      │
│    Index 1: ExploreView(initialQuery: _exploreSearchQuery)  │
│    Index 2: LibraryView()                                   │
├─────────────────────────────────────────────────────────────┤
│  CustomBottomNavigationBar:                                 │
│    [ 🏠 Home ]        [ 🔍 Explore ]        [ 📖 Library ]  │
└─────────────────────────────────────────────────────────────┘
```

#### Navigation Actions & Methods:
1. **Cross-Tab Deep Query Navigation (`navigateToExploreWithQuery(String query)`)**:
   - Exposed through static helper `MainNavigationView.of(context)?.navigateToExploreWithQuery(query)`.
   - Used by `FeaturedBooksSection` ("See All" button) to navigate to the Explore tab (index 1) with query `'trending_all'`.
2. **Page Switching (`_onTabSelected(int index)`)**:
   - Changes active index and animates `PageController` using `Curves.easeInOut` over 300ms.
3. **Keep-Alive**:
   - `ExploreViewBody` implements `AutomaticKeepAliveClientMixin` (`wantKeepAlive => true`) to preserve search text, active categories, and scroll positions across bottom navigation tab switches.
