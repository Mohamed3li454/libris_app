import 'package:equatable/equatable.dart';

enum DownloadStatus { queued, downloading, paused, completed, failed, cancelled }

enum DownloadEnqueueResult {
  started,
  alreadyInProgress,
  alreadyCompleted,
  noSource,
  offline,
  failed,
}

class DownloadItem extends Equatable {
  final String id;
  final String title;
  final String authorName;
  final String coverUrl;
  final String? archiveIdentifier;
  final String? remoteUrl;
  final String? localPath;
  final DownloadStatus status;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final String? errorMessage;
  final int createdAt;
  final int? completedAt;

  const DownloadItem({
    required this.id,
    required this.title,
    required this.authorName,
    required this.coverUrl,
    this.archiveIdentifier,
    this.remoteUrl,
    this.localPath,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  bool get isInProgress =>
      status == DownloadStatus.queued ||
      status == DownloadStatus.downloading ||
      status == DownloadStatus.paused;

  bool get canOpen {
    return status == DownloadStatus.completed &&
        localPath != null &&
        localPath!.isNotEmpty;
  }

  String get sizeLabel {
    if (totalBytes > 0) {
      return '${formatBytes(receivedBytes)} / ${formatBytes(totalBytes)}';
    }
    if (receivedBytes > 0) return formatBytes(receivedBytes);
    return '';
  }

  DownloadItem copyWith({
    String? remoteUrl,
    String? localPath,
    DownloadStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
    int? completedAt,
    bool clearError = false,
  }) {
    return DownloadItem(
      id: id,
      title: title,
      authorName: authorName,
      coverUrl: coverUrl,
      archiveIdentifier: archiveIdentifier,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'No Title',
      authorName: json['author_name']?.toString() ?? 'Unknown Author',
      coverUrl: json['cover_url']?.toString() ?? '',
      archiveIdentifier: json['archive_identifier']?.toString(),
      remoteUrl: json['remote_url']?.toString(),
      localPath: json['local_path']?.toString(),
      status: DownloadStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => DownloadStatus.queued,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      receivedBytes: (json['received_bytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['total_bytes'] as num?)?.toInt() ?? 0,
      errorMessage: json['error_message']?.toString(),
      createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
      completedAt: (json['completed_at'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author_name': authorName,
      'cover_url': coverUrl,
      'archive_identifier': archiveIdentifier,
      'remote_url': remoteUrl,
      'local_path': localPath,
      'status': status.name,
      'progress': progress,
      'received_bytes': receivedBytes,
      'total_bytes': totalBytes,
      'error_message': errorMessage,
      'created_at': createdAt,
      'completed_at': completedAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    authorName,
    coverUrl,
    archiveIdentifier,
    remoteUrl,
    localPath,
    status,
    progress,
    receivedBytes,
    totalBytes,
    errorMessage,
    createdAt,
    completedAt,
  ];
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final digits = size < 10 && unitIndex > 0 ? 1 : 0;
  return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
}
