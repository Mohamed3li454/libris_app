import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:libris_app/constants/hive_constants.dart';
import 'package:libris_app/features/downloads/data/models/download_item.dart';
import 'package:libris_app/features/downloads/data/repos/downloads_repo.dart';
import 'package:path_provider/path_provider.dart';

class DownloadsRepoImpl implements DownloadsRepo {
  Box get _box => Hive.box(kDownloadsBox);

  @override
  List<DownloadItem> getAll() {
    try {
      final items = <DownloadItem>[];
      for (final key in _box.keys) {
        final raw = _box.get(key);
        if (raw is Map) {
          items.add(DownloadItem.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
      return items;
    } catch (e) {
      debugPrint('Error loading downloads: $e');
      return [];
    }
  }

  @override
  DownloadItem? getById(String id) {
    try {
      final raw = _box.get(id);
      if (raw is Map) {
        return DownloadItem.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (e) {
      debugPrint('Error reading download $id: $e');
    }
    return null;
  }

  @override
  Future<void> save(DownloadItem item) async {
    try {
      await _box.put(item.id, item.toJson());
    } catch (e) {
      debugPrint('Error saving download: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      debugPrint('Error deleting download: $e');
    }
  }

  @override
  Future<String> downloadsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<void> deleteFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  @override
  String fileNameFor(String id) {
    final safe = id.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    final trimmed = safe.replaceAll(RegExp(r'_+'), '_').replaceAll(
      RegExp(r'^_|_$'),
      '',
    );
    final name = trimmed.isEmpty ? 'book' : trimmed;
    return '$name.pdf';
  }
}
