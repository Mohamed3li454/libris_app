import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:libris_app/core/utils/app_routes.dart';
import 'package:libris_app/core/widgets/app_dialog.dart';
import 'package:libris_app/features/downloads/data/models/download_item.dart';
import 'package:libris_app/features/downloads/presentation/manager/downloads_cubit/downloads_cubit.dart';
import 'package:libris_app/features/downloads/presentation/view/pdf_reader_view.dart';
import 'package:share_plus/share_plus.dart';

class DownloadItemTile extends StatelessWidget {
  final DownloadItem item;

  const DownloadItemTile({super.key, required this.item});

  Future<void> _openPdf(BuildContext context) async {
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

  Future<void> _share(BuildContext context) async {
    if (!item.canOpen) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(item.localPath!, mimeType: 'application/pdf')],
          title: item.title,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      await AppDialog.error(context, message: 'Could not share this PDF.');
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove download'),
          content: Text('Delete "${item.title}" from downloads?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await context.read<DownloadsCubit>().delete(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.30 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: item.status == DownloadStatus.completed
              ? () => _openPdf(context)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 78,
                    child: item.coverUrl.isEmpty
                        ? ColoredBox(
                            color: context.pillColor,
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: context.mutedColor,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: item.coverUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => ColoredBox(
                              color: context.pillColor,
                            ),
                            errorWidget: (context, url, error) => ColoredBox(
                              color: context.pillColor,
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: context.mutedColor,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildContent(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.titleColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.authorName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: context.mutedColor),
        ),
        const SizedBox(height: 8),
        Text(
          _statusLabel(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _statusColor(context),
          ),
        ),
        if (item.status == DownloadStatus.downloading ||
            item.status == DownloadStatus.paused ||
            item.status == DownloadStatus.queued) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: item.status == DownloadStatus.queued
                  ? null
                  : item.progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: context.colors.outline.withValues(alpha: 0.4),
              color: context.colors.primary,
            ),
          ),
          if (item.sizeLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.sizeLabel,
              style: TextStyle(fontSize: 11, color: context.mutedColor),
            ),
          ],
        ],
        if (item.status == DownloadStatus.failed &&
            item.errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            item.errorMessage!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.error),
          ),
        ],
        const SizedBox(height: 4),
        _buildActions(context),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final cubit = context.read<DownloadsCubit>();
    return Row(
      children: [
        if (item.status == DownloadStatus.downloading ||
            item.status == DownloadStatus.queued)
          _iconAction(
            context,
            tooltip: 'Pause',
            icon: Icons.pause_rounded,
            onPressed: () => cubit.pause(item.id),
          ),
        if (item.status == DownloadStatus.paused)
          _iconAction(
            context,
            tooltip: 'Resume',
            icon: Icons.play_arrow_rounded,
            onPressed: () => cubit.resume(item.id),
          ),
        if (item.status == DownloadStatus.failed)
          _iconAction(
            context,
            tooltip: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: () => cubit.retry(item.id),
          ),
        if (item.status == DownloadStatus.completed)
          _iconAction(
            context,
            tooltip: 'Open',
            icon: Icons.menu_book_rounded,
            onPressed: () => _openPdf(context),
          ),
        if (item.status == DownloadStatus.completed)
          _iconAction(
            context,
            tooltip: 'Share',
            icon: Icons.ios_share_rounded,
            onPressed: () => _share(context),
          ),
        if (item.isInProgress)
          _iconAction(
            context,
            tooltip: 'Cancel',
            icon: Icons.close_rounded,
            onPressed: () => cubit.cancel(item.id),
          ),
        const Spacer(),
        if (item.status == DownloadStatus.completed ||
            item.status == DownloadStatus.failed)
          _iconAction(
            context,
            tooltip: 'Delete',
            icon: Icons.delete_outline_rounded,
            onPressed: () => _confirmDelete(context),
          ),
      ],
    );
  }

  Widget _iconAction(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(icon, size: 22, color: context.colors.primary),
    );
  }

  String _statusLabel() {
    switch (item.status) {
      case DownloadStatus.queued:
        return 'Waiting…';
      case DownloadStatus.downloading:
        final percent = (item.progress * 100).clamp(0, 100).round();
        return 'Downloading $percent%';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return item.totalBytes > 0
            ? 'Downloaded · ${formatBytes(item.totalBytes)}'
            : 'Downloaded';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(BuildContext context) {
    switch (item.status) {
      case DownloadStatus.failed:
        return AppColors.error;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.paused:
        return context.mutedColor;
      default:
        return context.colors.primary;
    }
  }
}
