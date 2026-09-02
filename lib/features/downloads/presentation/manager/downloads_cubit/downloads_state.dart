part of 'downloads_cubit.dart';

class DownloadsState extends Equatable {
  final List<DownloadItem> items;

  const DownloadsState({this.items = const []});

  List<DownloadItem> get inProgressItems {
    final list = items
        .where((item) => item.status != DownloadStatus.completed)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<DownloadItem> get completedItems {
    final list = items
        .where((item) => item.status == DownloadStatus.completed)
        .toList();
    list.sort((a, b) => (b.completedAt ?? 0).compareTo(a.completedAt ?? 0));
    return list;
  }

  int get activeCount => items
      .where(
        (item) =>
            item.status == DownloadStatus.queued ||
            item.status == DownloadStatus.downloading,
      )
      .length;

  bool get isEmpty => items.isEmpty;

  DownloadItem? itemById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  List<Object?> get props => [items];
}
