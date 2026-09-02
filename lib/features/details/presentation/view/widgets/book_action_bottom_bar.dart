import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/services/connectivity_cubit.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/core/utils/app_routes.dart';
import 'package:libris_app/core/widgets/app_dialog.dart';
import 'package:libris_app/features/details/data/models/book_detail_model.dart';
import 'package:libris_app/features/details/presentation/manager/book_details_cubit/book_details_cubit.dart';
import 'package:libris_app/features/downloads/data/models/download_item.dart';
import 'package:libris_app/features/downloads/presentation/manager/downloads_cubit/downloads_cubit.dart';
import 'package:libris_app/features/downloads/presentation/view/pdf_reader_view.dart';
import 'package:libris_app/features/details/presentation/view/widgets/water_fill_download_button.dart';
import 'package:shimmer/shimmer.dart';

class BookActionBottomBar extends StatelessWidget {
  final String? fallbackWorkKey;
  final BookModel? bookModel;

  const BookActionBottomBar({
    super.key,
    this.fallbackWorkKey,
    this.bookModel,
  });

  String? _openLibraryReadUrl() {
    if (fallbackWorkKey == null || fallbackWorkKey!.isEmpty) return null;
    final String cleanKey = fallbackWorkKey!.startsWith('/')
        ? fallbackWorkKey!
        : '/$fallbackWorkKey';
    return 'https://openlibrary.org$cleanKey';
  }

  BookModel? _resolveBook(BookDetailModel? detail) {
    if (bookModel != null) return bookModel;
    if (detail == null) return null;
    return BookModel(
      key: detail.key,
      title: detail.title,
      authorName: 'Unknown Author',
      coverUrl: '',
      iaId: detail.archiveIdentifier,
    );
  }

  Future<void> _openPdf(BuildContext context, DownloadItem item) async {
    if (!item.canOpen) {
      await AppDialog.error(
        context,
        message: 'This PDF file is no longer available.',
      );
      return;
    }
    if (!context.mounted) return;
    await context.push(
      AppRoutes.pdfReader,
      extra: PdfReaderArgs(filePath: item.localPath!, title: item.title),
    );
  }

  Future<void> _onDownloadPressed(
    BuildContext context, {
    required BookDetailModel? detail,
  }) async {
    final book = _resolveBook(detail);
    if (book == null) return;

    final cubit = context.read<DownloadsCubit>();
    final item = cubit.state.itemById(book.key);

    if (item?.status == DownloadStatus.completed) {
      await _openPdf(context, item!);
      return;
    }
    if (item?.status == DownloadStatus.downloading ||
        item?.status == DownloadStatus.queued) {
      await context.push(AppRoutes.downloads);
      return;
    }
    if (item?.status == DownloadStatus.paused) {
      await cubit.resume(item!.id);
      return;
    }
    if (item?.status == DownloadStatus.failed) {
      await cubit.retry(item!.id);
      return;
    }

    final connectivity = context.read<ConnectivityCubit>().state;
    if (connectivity is ConnectivityDisconnected) {
      await AppDialog.error(
        context,
        message: 'No internet connection. Please check your network.',
      );
      return;
    }

    final result = await cubit.enqueue(
      book: book,
      archiveIdentifier: detail?.archiveIdentifier ?? book.iaId,
      directPdfUrl: detail != null && detail.hasDirectPdf
          ? detail.downloadUrl
          : null,
    );
    if (!context.mounted) return;

    switch (result) {
      case DownloadEnqueueResult.started:
        await AppDialog.success(context, message: 'Download started.');
      case DownloadEnqueueResult.alreadyInProgress:
        await context.push(AppRoutes.downloads);
      case DownloadEnqueueResult.alreadyCompleted:
        final completed = cubit.state.itemById(book.key);
        if (completed != null) {
          await _openPdf(context, completed);
        }
      case DownloadEnqueueResult.noSource:
        await AppDialog.error(
          context,
          message: 'No public PDF is available for this book.',
        );
      case DownloadEnqueueResult.offline:
        await AppDialog.error(
          context,
          message: 'No internet connection. Please check your network.',
        );
      case DownloadEnqueueResult.failed:
        await AppDialog.error(
          context,
          message: 'Could not start download. Please try again.',
        );
    }
  }

  String _downloadLabel(DownloadItem? item) {
    if (item == null) return 'Download PDF';
    switch (item.status) {
      case DownloadStatus.queued:
        return 'Waiting…';
      case DownloadStatus.downloading:
        final percent = (item.progress * 100).clamp(0, 100).round();
        return '$percent%';
      case DownloadStatus.paused:
        return 'Resume';
      case DownloadStatus.completed:
        return 'Open PDF';
      case DownloadStatus.failed:
        return 'Retry';
      case DownloadStatus.cancelled:
        return 'Download PDF';
    }
  }

  double _downloadFill(DownloadItem? item) {
    if (item == null) return 0;
    switch (item.status) {
      case DownloadStatus.queued:
        return 0.12;
      case DownloadStatus.downloading:
        return item.progress.clamp(0.08, 1.0);
      case DownloadStatus.paused:
        return item.progress.clamp(0.08, 1.0);
      case DownloadStatus.completed:
        return 1;
      case DownloadStatus.failed:
        return item.progress.clamp(0.0, 1.0);
      case DownloadStatus.cancelled:
        return 0;
    }
  }

  bool _downloadWaving(DownloadItem? item) {
    return item?.status == DownloadStatus.queued ||
        item?.status == DownloadStatus.downloading;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookDetailsCubit, BookDetailsState>(
      builder: (context, state) {
        final isLoading =
            state is BookDetailsLoading || state is BookDetailsInitial;

        String? readUrl = _openLibraryReadUrl();
        BookDetailModel? detail;
        var canDownload = false;

        if (state is BookDetailsSuccess) {
          detail = state.bookDetail;
          readUrl = detail.readUrl;
          canDownload = detail.hasPdfDownload;
        }

        final book = _resolveBook(detail);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: isLoading
                ? _buildShimmerButtons(context)
                : Row(
                    children: [
                      if (canDownload) ...[
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: BlocBuilder<DownloadsCubit, DownloadsState>(
                              builder: (context, downloadsState) {
                                final item = book == null
                                    ? null
                                    : downloadsState.itemById(book.key);
                                return WaterFillDownloadButton(
                                  label: _downloadLabel(item),
                                  progress: _downloadFill(item),
                                  waving: _downloadWaving(item),
                                  onPressed: () => _onDownloadPressed(
                                    context,
                                    detail: detail,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (readUrl != null && readUrl.isNotEmpty) {
                                context.push(
                                  AppRoutes.bookReader,
                                  extra: readUrl,
                                );
                              } else {
                                unawaited(
                                  AppDialog.info(
                                    context,
                                    message: 'Reader link not available yet',
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.primary,
                              foregroundColor: context.colors.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.menu_book_rounded, size: 20),
                            label: const Text(
                              'Read Now',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerButtons(BuildContext context) {
    final baseColor = context.isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final highlightColor = context.isDark
        ? Colors.grey[500]!
        : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
