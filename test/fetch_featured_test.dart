// import 'package:dio/dio.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:libris_app/core/utils/api_service.dart';
// import 'package:libris_app/features/home/data/repos/home_repo_impl.dart';

// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();

//   setUpAll(() async {
//     await dotenv.load(fileName: ".env");
//   });

//   test('fetchFeaturedBooks debug test', () async {
//     final apiService = ApiService(dio: Dio());
//     final repo = HomeRepoImpl(apiService: apiService);

//     try {
//       print('Calling getData directly...');
//       var data = await apiService.getData(endPoint: "q=featured&maxResults=10");
//       print('Data fetched successfully, items length: ${data['items']?.length}');
//     } catch (e, stack) {
//       print('getData error: $e');
//       print(stack);
//     }

//     print('Calling fetchFeaturedBooks...');
//     final result = await repo.fetchFeaturedBooks();
//     result.fold(
//       (failure) => print('FAILURE: ${failure.errMessage}'),
//       (books) => print('SUCCESS: fetched ${books.length} books'),
//     );
//   });
// }
