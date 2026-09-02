import 'package:dio/dio.dart';

class DownloadService {
  final Dio _dio;

  DownloadService(this._dio);

  Future<void> download({
    required String url,
    required String savePath,
    required CancelToken cancelToken,
    int startByte = 0,
    String? referer,
    void Function(int received, int total)? onProgress,
  }) async {
    await _dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      deleteOnError: false,
      fileAccessMode: startByte > 0
          ? FileAccessMode.append
          : FileAccessMode.write,
      options: Options(
        headers: {
          if (startByte > 0) 'Range': 'bytes=$startByte-',
          if (referer != null && referer.isNotEmpty) 'Referer': referer,
        },
      ),
      onReceiveProgress: (received, total) {
        if (onProgress == null) return;
        final actualReceived = startByte + received;
        final actualTotal = total > 0 ? startByte + total : 0;
        onProgress(actualReceived, actualTotal);
      },
    );
  }
}
