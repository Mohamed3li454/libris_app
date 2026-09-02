import 'package:libris_app/features/downloads/data/models/download_item.dart';

abstract class DownloadsRepo {
  List<DownloadItem> getAll();
  DownloadItem? getById(String id);
  Future<void> save(DownloadItem item);
  Future<void> delete(String id);
  Future<String> downloadsDirectory();
  Future<void> deleteFile(String? path);
  String fileNameFor(String id);
}
