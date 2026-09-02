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
  Timer? _hintTimer;
  bool _preparing = true;
  bool _isFullRead = false;
  bool _showFullReadHint = false;
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
    _hintTimer?.cancel();
    if (_isFullRead) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
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

  void _toggleFullRead() {
    final next = !_isFullRead;
    setState(() {
      _isFullRead = next;
      _showFullReadHint = next;
    });

    _hintTimer?.cancel();
    if (next) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      );
      _chromeVisible.value = false;
      _hintTimer = Timer(const Duration(milliseconds: 2400), () {
        if (mounted && _showFullReadHint) {
          setState(() => _showFullReadHint = false);
        }
      });
    } else {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
      );
      _chromeVisible.value = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controller == null) return;
      unawaited(
        _controller!.animateToPage(
          pageNumber: _page.value,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        ),
      );
    });
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
    final canvas = _isFullRead
        ? (context.isDark ? Colors.black : Colors.white)
        : (context.isDark
            ? const Color(0xFF1F1B16)
            : const Color(0xFFD8CFC0));

    return PopScope(
      canPop: !_isFullRead,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isFullRead) {
          _toggleFullRead();
        }
      },
      child: Scaffold(
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
                        height: _isFullRead
                            ? 0
                            : MediaQuery.paddingOf(context).top,
                      ),
                      Expanded(
                        child: PdfViewPinch(
                          controller: _controller!,
                          padding: _isFullRead ? 0 : 12,
                          minScale: 1,
                          maxScale: 6,
                          backgroundDecoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: _isFullRead
                                ? const []
                                : const [
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
                                        IconButton(
                                          tooltip: _isFullRead
                                              ? 'Exit Full Read'
                                              : 'Full Read',
                                          onPressed: _toggleFullRead,
                                          icon: Icon(
                                            _isFullRead
                                                ? Icons.fullscreen_exit_rounded
                                                : Icons.fullscreen_rounded,
                                            color: _isFullRead
                                                ? context.colors.primary
                                                : context.titleColor,
                                          ),
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
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    bottom: _showFullReadHint ? 36 : -60,
                    left: 24,
                    right: 24,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _showFullReadHint ? 1.0 : 0.0,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x40000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Full Read Mode • Tap screen for controls',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
