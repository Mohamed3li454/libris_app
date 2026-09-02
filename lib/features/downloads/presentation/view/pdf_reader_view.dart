import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libris_app/core/services/pdf_progress_service.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:pdfx/pdfx.dart';

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

class _PdfReaderViewState extends State<PdfReaderView>
    with WidgetsBindingObserver {
  final ValueNotifier<int> _page = ValueNotifier<int>(1);
  final ValueNotifier<int> _pageCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> _chromeVisible = ValueNotifier<bool>(true);

  PdfControllerPinch? _controller;
  Timer? _saveDebounce;
  bool _preparing = true;
  String? _error;
  int _savedPage = 1;
  Offset? _gestureStart;
  DateTime? _gestureStartedAt;
  var _didPan = false;
  var _didRestore = false;

  String get _progressKey {
    final name = widget.args.filePath.split(RegExp(r'[/\\]')).last;
    return name.isEmpty ? widget.args.filePath : name;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final path = widget.args.filePath;
      if (!await File(path).exists()) {
        if (!mounted) return;
        setState(() {
          _preparing = false;
          _error = 'This PDF file is no longer available.';
        });
        return;
      }
      _savedPage = await PdfProgressService.getLastPage(_progressKey);
      if (_savedPage < 1) _savedPage = 1;
      if (!mounted) return;
      _controller = PdfControllerPinch(
        document: PdfDocument.openFile(path),
        initialPage: _savedPage,
      );
      _page.value = _savedPage;
      setState(() => _preparing = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preparing = false;
        _error = 'Could not open this PDF.';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_flushSave());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDebounce?.cancel();
    final page = _page.value;
    unawaited(PdfProgressService.saveLastPage(_progressKey, page));
    _controller?.dispose();
    _page.dispose();
    _pageCount.dispose();
    _chromeVisible.dispose();
    super.dispose();
  }

  Future<void> _flushSave() {
    return PdfProgressService.saveLastPage(_progressKey, _page.value);
  }

  void _onPageChanged(int page) {
    if (page < 1) return;
    if (page != _page.value) {
      _chromeVisible.value = false;
    }
    _page.value = page;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(PdfProgressService.saveLastPage(_progressKey, page));
    });
  }

  void _onInteractionStart(ScaleStartDetails details) {
    _gestureStart = details.focalPoint;
    _gestureStartedAt = DateTime.now();
    _didPan = false;
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    final start = _gestureStart;
    if (start == null) {
      _chromeVisible.value = false;
      return;
    }
    if ((details.focalPoint - start).distance > 6) {
      _didPan = true;
      _chromeVisible.value = false;
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    final start = _gestureStart;
    final startedAt = _gestureStartedAt;
    _gestureStart = null;
    _gestureStartedAt = null;
    if (start == null || startedAt == null) return;
    final elapsed = DateTime.now().difference(startedAt);
    if (!_didPan && elapsed < const Duration(milliseconds: 320)) {
      _chromeVisible.value = !_chromeVisible.value;
    }
  }

  Future<void> _goToPage() async {
    final total = _pageCount.value;
    if (total < 1) return;
    final field = TextEditingController(text: '${_page.value}');
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Go to page'),
          content: TextField(
            controller: field,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '1 – $total',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              Navigator.pop(dialogContext, int.tryParse(value));
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, int.tryParse(field.text)),
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
    field.dispose();
    if (result == null || _controller == null) return;
    final target = result.clamp(1, total);
    await _controller!.animateToPage(
      pageNumber: target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    _chromeVisible.value = true;
  }

  @override
  Widget build(BuildContext context) {
    final canvas = context.isDark
        ? const Color(0xFF1F1B16)
        : const Color(0xFFD8CFC0);

    return Scaffold(
      backgroundColor: canvas,
      body: _preparing
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.mutedColor),
                ),
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: MediaQuery.paddingOf(context).top,
                    ),
                    Expanded(
                      child: PdfViewPinch(
                        controller: _controller!,
                        padding: 12,
                        minScale: 1,
                        maxScale: 6,
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                          options: const DefaultBuilderOptions(),
                          documentLoaderBuilder: (_) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          pageLoaderBuilder: (_) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorBuilder: (_, error) => Center(
                            child: Text(
                              'Could not open this PDF.',
                              style: TextStyle(color: context.mutedColor),
                            ),
                          ),
                        ),
                        onDocumentLoaded: (document) {
                          _pageCount.value = document.pagesCount;
                          if (_didRestore) return;
                          _didRestore = true;
                          final target = _savedPage.clamp(
                            1,
                            document.pagesCount,
                          );
                          _page.value = target;
                        },
                        onDocumentError: (_) {
                          if (!mounted) return;
                          setState(() => _error = 'Could not open this PDF.');
                        },
                        onPageChanged: _onPageChanged,
                        onInteractionStart: _onInteractionStart,
                        onInteractionUpdate: _onInteractionUpdate,
                        onInteractionEnd: _onInteractionEnd,
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _chromeVisible,
                  builder: (context, visible, _) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ClipRect(
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          offset: visible ? Offset.zero : const Offset(0, -1),
                          child: IgnorePointer(
                            ignoring: !visible,
                            child: Material(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              elevation: 4,
                              shadowColor: Colors.black.withValues(alpha: 0.08),
                              child: SafeArea(
                                bottom: false,
                                child: SizedBox(
                                  height: kToolbarHeight,
                                  width: double.infinity,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Back',
                                        onPressed: () {
                                          unawaited(_flushSave());
                                          Navigator.of(context).maybePop();
                                        },
                                        icon: Icon(
                                          Icons.arrow_back_rounded,
                                          color: context.titleColor,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          widget.args.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: context.titleColor,
                                          ),
                                        ),
                                      ),
                                      ValueListenableBuilder<int>(
                                        valueListenable: _page,
                                        builder: (context, current, _) {
                                          return ValueListenableBuilder<int>(
                                            valueListenable: _pageCount,
                                            builder: (context, total, _) {
                                              if (total < 1) {
                                                return const SizedBox.shrink();
                                              }
                                              return TextButton(
                                                onPressed: _goToPage,
                                                child: Text(
                                                  '$current / $total',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        context.colors.primary,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
