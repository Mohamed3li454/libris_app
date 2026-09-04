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

  PdfController? _controller;
  PdfDocument? _document;
  Timer? _saveDebounce;
  Timer? _hintTimer;
  DateTime _lastChromeToggle = DateTime.fromMillisecondsSinceEpoch(0);

  bool _preparing = true;
  bool _isFullRead = false;
  bool _showFullReadHint = false;
  Axis _scrollDirection = Axis.horizontal;
  String? _error;
  int _savedPage = 1;

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

      _controller = PdfController(
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
    _document?.close();
    _page.dispose();
    _pageCount.dispose();
    _chromeVisible.dispose();
    super.dispose();
  }

  Future<void> _flushSave() {
    return PdfProgressService.saveLastPage(_progressKey, _page.value);
  }

  void _toggleChrome() {
    final now = DateTime.now();
    if (now.difference(_lastChromeToggle).inMilliseconds < 220) {
      return;
    }
    _lastChromeToggle = now;
    _chromeVisible.value = !_chromeVisible.value;
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
  }

  void _onPageChanged(int page) {
    if (page < 1) return;
    if (page != _page.value) {
      _chromeVisible.value = false;
    }
    _page.value = page;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(PdfProgressService.saveLastPage(_progressKey, page));
    });
  }

  Future<void> _goToPage() async {
    final total = _pageCount.value;
    if (total < 1) return;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _GoToPageDialog(
        currentPage: _page.value,
        totalPages: total,
      ),
    );

    if (result == null || _controller == null || !mounted) return;
    final target = result.clamp(1, total);
    if (target == _page.value) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controller == null) return;
      if ((target - _page.value).abs() == 1) {
        _controller!.animateToPage(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      } else {
        _controller!.jumpToPage(target);
      }
      _chromeVisible.value = true;
    });
  }

  Future<PdfPageImage?> _renderPage(PdfPage page) {
    double scale = 2.5;
    if (mounted) {
      final mediaQuery = MediaQuery.of(context);
      final targetWidth = mediaQuery.size.width * mediaQuery.devicePixelRatio;
      if (page.width > 0) {
        scale = (targetWidth / page.width).clamp(2.0, 3.2);
      }
    }
    return page.render(
      width: page.width * scale,
      height: page.height * scale,
      format: PdfPageImageFormat.jpeg,
      backgroundColor: '#ffffff',
      quality: 92,
    );
  }

  PhotoViewGalleryPageOptions _buildPageOptions(
    BuildContext context,
    Future<PdfPageImage> pageImage,
    int index,
    PdfDocument document,
  ) {
    return PhotoViewGalleryPageOptions(
      imageProvider: PdfPageImageProvider(
        pageImage,
        index,
        document.id,
      ),
      minScale: PhotoViewComputedScale.contained * 1.0,
      maxScale: PhotoViewComputedScale.contained * 3.5,
      initialScale: PhotoViewComputedScale.contained * 1.0,
      filterQuality: FilterQuality.high,
      basePosition: Alignment.center,
      onTapUp: (context, details, controllerValue) => _toggleChrome(),
    );
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
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Opening ${widget.args.title}...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              )
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
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _toggleChrome,
                          child: PdfView(
                            controller: _controller!,
                            scrollDirection: _scrollDirection,
                            pageSnapping: true,
                            physics: const BouncingScrollPhysics(),
                            backgroundDecoration: BoxDecoration(
                              color: canvas,
                            ),
                            renderer: _renderPage,
                            builders: PdfViewBuilders<DefaultBuilderOptions>(
                              options: const DefaultBuilderOptions(),
                              pageBuilder: _buildPageOptions,
                              documentLoaderBuilder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              pageLoaderBuilder: (_) => const Center(
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                              errorBuilder: (_, error) => Center(
                                child: Text(
                                  'Could not open this PDF.',
                                  style: TextStyle(color: context.mutedColor),
                                ),
                              ),
                            ),
                            onDocumentLoaded: (document) {
                              _document = document;
                              _pageCount.value = document.pagesCount;
                            },
                            onDocumentError: (_) {
                              if (!mounted) return;
                              setState(
                                () => _error = 'Could not open this PDF.',
                              );
                            },
                            onPageChanged: _onPageChanged,
                          ),
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
                                        IconButton(
                                          tooltip: _scrollDirection ==
                                                  Axis.horizontal
                                              ? 'Switch to vertical scroll'
                                              : 'Switch to horizontal pages',
                                          onPressed: () {
                                            setState(() {
                                              _scrollDirection =
                                                  _scrollDirection ==
                                                          Axis.horizontal
                                                      ? Axis.vertical
                                                      : Axis.horizontal;
                                            });
                                          },
                                          icon: Icon(
                                            _scrollDirection == Axis.horizontal
                                                ? Icons.swap_vert_rounded
                                                : Icons.swap_horiz_rounded,
                                            color: context.titleColor,
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

class _GoToPageDialog extends StatefulWidget {
  final int currentPage;
  final int totalPages;

  const _GoToPageDialog({
    required this.currentPage,
    required this.totalPages,
  });

  @override
  State<_GoToPageDialog> createState() => _GoToPageDialogState();
}

class _GoToPageDialogState extends State<_GoToPageDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: '${widget.currentPage}');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_textController.text.trim());
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Go to page'),
      content: TextField(
        controller: _textController,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: '1 – ${widget.totalPages}',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Go'),
        ),
      ],
    );
  }
}
