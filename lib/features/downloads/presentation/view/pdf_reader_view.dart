import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:libris_app/core/theme/app_theme.dart';

class PdfReaderArgs {
  final String filePath;
  final String title;

  const PdfReaderArgs({required this.filePath, required this.title});
}

class PdfReaderView extends StatefulWidget {
  final PdfReaderArgs args;

  const PdfReaderView({super.key, required this.args});

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView> {
  final ValueNotifier<String> _pageLabel = ValueNotifier<String>('');
  late final bool _missing;
  PDFView? _pdfView;

  @override
  void initState() {
    super.initState();
    _missing = !File(widget.args.filePath).existsSync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_missing || _pdfView != null) return;
    _pdfView = PDFView(
      filePath: widget.args.filePath,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: false,
      pageSnap: false,
      fitPolicy: FitPolicy.WIDTH,
      preventLinkNavigation: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      onRender: (pages) {
        final total = pages ?? 0;
        if (total > 0 && _pageLabel.value.isEmpty) {
          _pageLabel.value = '1 / $total';
        }
      },
      onPageChanged: (page, total) {
        final current = (page ?? 0) + 1;
        final count = total ?? 0;
        if (count > 0) {
          _pageLabel.value = '$current / $count';
        }
      },
    );
  }

  @override
  void dispose() {
    _pageLabel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.args.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: context.titleColor,
        elevation: 0,
        actions: [
          ValueListenableBuilder<String>(
            valueListenable: _pageLabel,
            builder: (context, label, _) {
              if (label.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.mutedColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _missing
          ? Center(
              child: Text(
                'This PDF file is no longer available.',
                style: TextStyle(color: context.mutedColor),
              ),
            )
          : _pdfView,
    );
  }
}
