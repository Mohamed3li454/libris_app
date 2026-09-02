import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/di/service_locator.dart';
import 'package:libris_app/core/errors/failure.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/utils/api_service.dart';
import 'package:libris_app/core/utils/pdf_file_utils.dart';
import 'package:libris_app/features/downloads/data/models/download_item.dart';
import 'package:libris_app/features/downloads/data/repos/downloads_repo.dart';
import 'package:libris_app/features/downloads/data/services/download_service.dart';

part 'downloads_state.dart';

class DownloadsCubit extends Cubit<DownloadsState> {
  final DownloadsRepo downloadsRepo;
  final DownloadService downloadService;
  final ApiService apiService;

  final Map<String, CancelToken> _tokens = {};
  final Set<String> _pausedIds = {};
  final Set<String> _cancelledIds = {};
  final Map<String, DateTime> _lastProgressEmit = {};

  DownloadsCubit({
    DownloadsRepo? downloadsRepo,
    DownloadService? downloadService,
    ApiService? apiService,
  }) : downloadsRepo = downloadsRepo ?? ServiceLocator.downloadsRepo,
       downloadService = downloadService ?? ServiceLocator.downloadService,
       apiService = apiService ?? ServiceLocator.apiService,
       super(const DownloadsState());

  Future<void> load() async {
    final items = downloadsRepo.getAll();
    final restored = <DownloadItem>[];
    for (final item in items) {
      if (item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.queued) {
        final paused = item.copyWith(status: DownloadStatus.paused);
        await downloadsRepo.save(paused);
        restored.add(paused);
      } else {
        restored.add(item);
      }
    }
    if (!isClosed) emit(DownloadsState(items: restored));
  }

  Future<DownloadEnqueueResult> enqueue({
    required BookModel book,
    String? archiveIdentifier,
    String? directPdfUrl,
  }) async {
    final id = book.key.isNotEmpty
        ? book.key
        : '/ia/${archiveIdentifier ?? book.iaId ?? ''}';
    if (id.isEmpty || id == '/ia/') {
      return DownloadEnqueueResult.noSource;
    }

    final existing = state.itemById(id);
    if (existing != null) {
      if (existing.status == DownloadStatus.downloading ||
          existing.status == DownloadStatus.queued) {
        return DownloadEnqueueResult.alreadyInProgress;
      }
      if (existing.status == DownloadStatus.completed &&
          existing.localPath != null &&
          await File(existing.localPath!).exists()) {
        return DownloadEnqueueResult.alreadyCompleted;
      }
      if (existing.status == DownloadStatus.paused) {
        await resume(id);
        return DownloadEnqueueResult.started;
      }
    }

    final hasPdfLink =
        directPdfUrl != null && directPdfUrl.toLowerCase().endsWith('.pdf');
    final identifier = archiveIdentifier ?? book.iaId;
    if (!hasPdfLink && (identifier == null || identifier.isEmpty)) {
      return DownloadEnqueueResult.noSource;
    }

    final item = DownloadItem(
      id: id,
      title: book.title,
      authorName: book.authorName,
      coverUrl: book.coverUrl,
      archiveIdentifier: identifier,
      remoteUrl: hasPdfLink ? directPdfUrl : null,
      status: DownloadStatus.queued,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _upsert(item);
    unawaited(_start(id, resume: false));
    return DownloadEnqueueResult.started;
  }

  Future<void> pause(String id) async {
    _pausedIds.add(id);
    _tokens[id]?.cancel('paused');
    final item = state.itemById(id);
    if (item == null) return;
    await _upsert(item.copyWith(status: DownloadStatus.paused));
  }

  Future<void> resume(String id) async {
    final item = state.itemById(id);
    if (item == null) return;
    if (item.status == DownloadStatus.downloading ||
        item.status == DownloadStatus.queued) {
      return;
    }
    _pausedIds.remove(id);
    _cancelledIds.remove(id);
    await _upsert(
      item.copyWith(status: DownloadStatus.queued, clearError: true),
    );
    unawaited(_start(id, resume: true));
  }

  Future<void> retry(String id) async {
    final item = state.itemById(id);
    if (item == null) return;
    await downloadsRepo.deleteFile(item.localPath);
    _pausedIds.remove(id);
    _cancelledIds.remove(id);
    await _upsert(
      item.copyWith(
        status: DownloadStatus.queued,
        progress: 0,
        receivedBytes: 0,
        clearError: true,
      ),
    );
    unawaited(_start(id, resume: false));
  }

  Future<void> cancel(String id) async {
    _cancelledIds.add(id);
    _pausedIds.remove(id);
    _tokens[id]?.cancel('cancelled');
    final item = state.itemById(id);
    await downloadsRepo.deleteFile(item?.localPath);
    await downloadsRepo.delete(id);
    _tokens.remove(id);
    _emitWithout(id);
  }

  Future<void> delete(String id) async {
    _cancelledIds.add(id);
    _tokens[id]?.cancel('cancelled');
    final item = state.itemById(id);
    await downloadsRepo.deleteFile(item?.localPath);
    await downloadsRepo.delete(id);
    _tokens.remove(id);
    _pausedIds.remove(id);
    _cancelledIds.remove(id);
    _emitWithout(id);
  }

  Future<void> _start(String id, {required bool resume}) async {
    var item = state.itemById(id);
    if (item == null) return;
    if (_pausedIds.contains(id) || _cancelledIds.contains(id)) return;

    try {
      var url = item.remoteUrl;
      final isPdfUrl = url != null && url.toLowerCase().contains('.pdf');
      if (!isPdfUrl) {
        url = await apiService.resolveArchivePdfUrl(
          identifier: item.archiveIdentifier,
          title: item.title,
          author: item.authorName,
        );
      }
      if (_pausedIds.contains(id) || _cancelledIds.contains(id) || isClosed) {
        return;
      }
      if (url == null || url.isEmpty) {
        await _upsert(
          item.copyWith(
            status: DownloadStatus.failed,
            errorMessage: 'No public PDF is available for this book.',
          ),
        );
        return;
      }

      final dir = await downloadsRepo.downloadsDirectory();
      final savePath = '$dir/${downloadsRepo.fileNameFor(item.id)}';
      item = item.copyWith(
        remoteUrl: url,
        localPath: savePath,
        status: DownloadStatus.downloading,
        clearError: true,
      );
      await _upsert(item);

      var startByte = 0;
      final file = File(savePath);
      if (resume && await file.exists()) {
        startByte = await file.length();
      } else if (await file.exists()) {
        await file.delete();
      }

      if (_pausedIds.contains(id) || _cancelledIds.contains(id) || isClosed) {
        return;
      }

      final token = CancelToken();
      _tokens[id] = token;
      final referer = item.archiveIdentifier != null
          ? archiveReaderUrl(item.archiveIdentifier!)
          : null;

      await downloadService.download(
        url: url,
        savePath: savePath,
        cancelToken: token,
        startByte: startByte,
        referer: referer,
        onProgress: (received, total) {
          _onProgress(id, received, total);
        },
      );

      if (_cancelledIds.contains(id) || isClosed) return;
      if (_pausedIds.contains(id)) return;

      if (!await fileLooksLikePdf(savePath)) {
        await downloadsRepo.deleteFile(savePath);
        await _upsert(
          item.copyWith(
            status: DownloadStatus.failed,
            errorMessage: 'The downloaded file is not a valid PDF.',
          ),
        );
        return;
      }

      final completed = (state.itemById(id) ?? item).copyWith(
        status: DownloadStatus.completed,
        progress: 1,
        completedAt: DateTime.now().millisecondsSinceEpoch,
        clearError: true,
      );
      if (completed.totalBytes <= 0 && await File(savePath).exists()) {
        final size = await File(savePath).length();
        await _upsert(
          completed.copyWith(receivedBytes: size, totalBytes: size),
        );
      } else {
        await _upsert(completed);
      }
    } on DioException catch (error) {
      if (_cancelledIds.contains(id) || isClosed) return;
      if (_pausedIds.contains(id) || error.type == DioExceptionType.cancel) {
        final current = state.itemById(id);
        if (current != null && current.status != DownloadStatus.paused) {
          await _upsert(current.copyWith(status: DownloadStatus.paused));
        }
        return;
      }
      final message = _messageFromDio(error);
      final current = state.itemById(id) ?? item;
      if (current == null) return;
      await _upsert(
        current.copyWith(status: DownloadStatus.failed, errorMessage: message),
      );
    } catch (_) {
      if (_cancelledIds.contains(id) || isClosed) return;
      final current = state.itemById(id) ?? item;
      if (current == null) return;
      await _upsert(
        current.copyWith(
          status: DownloadStatus.failed,
          errorMessage: 'Download failed. Please try again.',
        ),
      );
    } finally {
      _tokens.remove(id);
    }
  }

  void _onProgress(String id, int received, int total) {
    if (isClosed || _pausedIds.contains(id) || _cancelledIds.contains(id)) {
      return;
    }
    final now = DateTime.now();
    final last = _lastProgressEmit[id];
    final isDone = total > 0 && received >= total;
    if (!isDone &&
        last != null &&
        now.difference(last).inMilliseconds < 250) {
      return;
    }
    _lastProgressEmit[id] = now;

    final current = state.itemById(id);
    if (current == null) return;
    final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : current.progress;
    final updated = current.copyWith(
      status: DownloadStatus.downloading,
      receivedBytes: received,
      totalBytes: total > 0 ? total : current.totalBytes,
      progress: progress,
    );
    emit(_replace(updated));
    unawaited(downloadsRepo.save(updated));
  }

  String _messageFromDio(DioException error) {
    final code = error.response?.statusCode;
    if (code == 401 || code == 403) {
      return 'This book cannot be downloaded. You can still read it online.';
    }
    return ServerFailure.fromDioError(error).errMessage;
  }

  Future<void> _upsert(DownloadItem item) async {
    await downloadsRepo.save(item);
    if (!isClosed) emit(_replace(item));
  }

  DownloadsState _replace(DownloadItem item) {
    final items = [...state.items];
    final index = items.indexWhere((element) => element.id == item.id);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.insert(0, item);
    }
    return DownloadsState(items: items);
  }

  void _emitWithout(String id) {
    if (isClosed) return;
    emit(
      DownloadsState(
        items: state.items.where((item) => item.id != id).toList(),
      ),
    );
  }

  @override
  Future<void> close() {
    for (final token in _tokens.values) {
      if (!token.isCancelled) {
        token.cancel('cubit-closed');
      }
    }
    _tokens.clear();
    return super.close();
  }
}
