import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BookReaderView extends StatefulWidget {
  final String url;

  const BookReaderView({super.key, required this.url});

  @override
  State<BookReaderView> createState() => _BookReaderViewState();
}

class _BookReaderViewState extends State<BookReaderView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  String _currentUrl = '';
  String _pageTitle = '';
  bool _canGoBack = false;
  bool _hasError = false;
  String _errorMessage = '';
  double _textZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
                _loadingProgress = 0.05;
                _currentUrl = url;
              });
            }
          },
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = (progress / 100.0).clamp(0.05, 1.0);
              });
            }
          },
          onPageFinished: (String url) async {
            if (mounted) {
              final title = await _controller.getTitle();
              final canBack = await _controller.canGoBack();
              setState(() {
                _isLoading = false;
                _loadingProgress = 1.0;
                _currentUrl = url;
                _pageTitle = title ?? '';
                _canGoBack = canBack;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _updateNavState() async {
    final canBack = await _controller.canGoBack();
    if (mounted) {
      setState(() {
        _canGoBack = canBack;
      });
    }
  }

  Future<void> _launchExternalBrowser() async {
    final Uri? uri = Uri.tryParse(
      _currentUrl.isNotEmpty ? _currentUrl : widget.url,
    );
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareUrl() {
    HapticFeedback.lightImpact();
    final urlToShare = _currentUrl.isNotEmpty ? _currentUrl : widget.url;
    unawaited(
      SharePlus.instance.share(
        ShareParams(
          text: urlToShare,
          subject: _pageTitle.isNotEmpty ? _pageTitle : null,
        ),
      ),
    );
  }

  void _copyToClipboard() {
    HapticFeedback.mediumImpact();
    final text = _currentUrl.isNotEmpty ? _currentUrl : widget.url;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_alt_circle_fill,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Link copied to clipboard',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 90),
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  void _changeZoom(double delta) {
    HapticFeedback.selectionClick();
    final newZoom = (_textZoom + delta).clamp(0.6, 2.0);
    setState(() {
      _textZoom = (newZoom * 10).round() / 10;
    });
    unawaited(
      _controller.runJavaScript('document.body.style.zoom = "$_textZoom";'),
    );
  }

  void _showReaderOptionsSheet() {
    HapticFeedback.mediumImpact();
    final isDark = context.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final sheetBg = isDark
              ? const Color(0xFF1E1E1E).withValues(alpha: 0.94)
              : const Color(0xFFF2F2F7).withValues(alpha: 0.94);
          final cardBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
          final primaryText = isDark ? Colors.white : Colors.black87;
          final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                color: sheetBg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Website info header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSecure
                                ? CupertinoIcons.lock_shield_fill
                                : CupertinoIcons.globe,
                            size: 24,
                            color: _isSecure
                                ? const Color(0xFF34C759)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _parsedHost,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_pageTitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _pageTitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Text Zoom Controls (Safari aA)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _OptionButton(
                            label: 'A',
                            subLabel: 'Smaller',
                            isSmall: true,
                            onTap: () {
                              _changeZoom(-0.1);
                              setModalState(() {});
                            },
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '${(_textZoom * 100).toInt()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: primaryText,
                                ),
                              ),
                            ),
                          ),
                          _OptionButton(
                            label: 'A',
                            subLabel: 'Larger',
                            isSmall: false,
                            onTap: () {
                              _changeZoom(0.1);
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Safari Action Grid / List
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _SafariListTile(
                            icon: CupertinoIcons.share,
                            title: 'Share Page',
                            onTap: () {
                              Navigator.pop(ctx);
                              _shareUrl();
                            },
                          ),
                          Divider(
                            height: 0.5,
                            indent: 48,
                            color: isDark
                                ? const Color(0xFF38383A)
                                : const Color(0xFFE5E5EA),
                          ),
                          _SafariListTile(
                            icon: CupertinoIcons.doc_on_doc,
                            title: 'Copy Link',
                            onTap: () {
                              Navigator.pop(ctx);
                              _copyToClipboard();
                            },
                          ),
                          Divider(
                            height: 0.5,
                            indent: 48,
                            color: isDark
                                ? const Color(0xFF38383A)
                                : const Color(0xFFE5E5EA),
                          ),
                          _SafariListTile(
                            icon: CupertinoIcons.arrow_clockwise,
                            title: 'Reload Page',
                            onTap: () {
                              Navigator.pop(ctx);
                              unawaited(_controller.reload());
                            },
                          ),
                          Divider(
                            height: 0.5,
                            indent: 48,
                            color: isDark
                                ? const Color(0xFF38383A)
                                : const Color(0xFFE5E5EA),
                          ),
                          _SafariListTile(
                            icon: CupertinoIcons.compass,
                            title: 'Open in Safari / Browser',
                            onTap: () {
                              Navigator.pop(ctx);
                              unawaited(_launchExternalBrowser());
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String get _parsedHost {
    final uri = Uri.tryParse(_currentUrl);
    if (uri == null || uri.host.isEmpty) return 'Website';
    final host = uri.host;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  bool get _isSecure {
    final uri = Uri.tryParse(_currentUrl);
    return uri?.scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final capsuleBgColor = isDark
        ? const Color(0xFF2C2C2E).withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.92);

    final capsuleBorderColor = isDark
        ? const Color(0xFF3A3A3C).withValues(alpha: 0.8)
        : const Color(0xFFD1D1D6).withValues(alpha: 0.7);

    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.black87;
    final accentTint = context.colors.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF000000)
            : const Color(0xFFF2F2F7),
        body: Stack(
          children: [
            // ────────────────────────────────────────────
            //  WEBVIEW LAYER (Safe below notch, full bleed at bottom)
            // ────────────────────────────────────────────
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(top: topPadding),
                child: _hasError
                    ? _buildErrorView(isDark)
                    : WebViewWidget(controller: _controller),
              ),
            ),

            // ────────────────────────────────────────────
            //  TOP PROGRESS BAR (Thin floating indicator)
            // ────────────────────────────────────────────
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _isLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  minHeight: 2.0,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(accentTint),
                ),
              ),
            ),

            // ────────────────────────────────────────────
            //  FLOATING BOTTOM BAR (Authentic Safari Pill Bar)
            //  ◁  [ 🔒 archive.org        ↻ ]  ⬆
            // ────────────────────────────────────────────
            Positioned(
              bottom: bottomPadding > 0 ? bottomPadding : 16,
              left: 16,
              right: 16,
              child: _buildSafariFloatingBottomBar(
                isDark: isDark,
                capsuleBgColor: capsuleBgColor,
                capsuleBorderColor: capsuleBorderColor,
                iconColor: iconColor,
                accentTint: accentTint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the floating Safari bottom address & control bar matching iOS 17/18
  Widget _buildSafariFloatingBottomBar({
    required bool isDark,
    required Color capsuleBgColor,
    required Color capsuleBorderColor,
    required Color iconColor,
    required Color accentTint,
  }) {
    return Row(
      children: [
        // ◁ Back Navigation Button
        _SafariFloatingButton(
          icon: CupertinoIcons.chevron_back,
          iconSize: 20,
          iconColor: _canGoBack ? iconColor : iconColor.withValues(alpha: 0.35),
          bgColor: capsuleBgColor,
          borderColor: capsuleBorderColor,
          onTap: () async {
            unawaited(HapticFeedback.lightImpact());
            if (await _controller.canGoBack()) {
              await _controller.goBack();
              await _updateNavState();
            } else {
              if (mounted) {
                unawaited(Navigator.of(context).maybePop());
              }
            }
          },
        ),

        const SizedBox(width: 8),

        // ══════════════════════════════════════════════════
        // Center Capsule (Search / Domain / SSL / Reload)
        // ══════════════════════════════════════════════════
        Expanded(
          child: GestureDetector(
            onTap: _showReaderOptionsSheet,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: capsuleBgColor,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: capsuleBorderColor, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.08,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // SSL or Reader Icon
                      Icon(
                        _isSecure
                            ? CupertinoIcons.lock_fill
                            : CupertinoIcons.globe,
                        size: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),

                      // Domain / Host Name
                      Expanded(
                        child: Text(
                          _parsedHost,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1C1C1E),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Reload / Stop Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          unawaited(_controller.reload());
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                          ),
                          child: Icon(
                            _isLoading
                                ? CupertinoIcons.xmark
                                : CupertinoIcons.arrow_clockwise,
                            size: 14,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ⬆ Share / Action Menu Button
        _SafariFloatingButton(
          icon: CupertinoIcons.share,
          iconSize: 19,
          iconColor: iconColor,
          bgColor: capsuleBgColor,
          borderColor: capsuleBorderColor,
          onTap: _shareUrl,
        ),
      ],
    );
  }

  /// Error placeholder widget when offline or page fails to load
  Widget _buildErrorView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFE5E5EA),
              ),
              child: Icon(
                CupertinoIcons.wifi_exclamationmark,
                size: 44,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cannot Open Page',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Safari cannot open the page because the network connection was lost or the URL is invalid.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  onPressed: () {
                    unawaited(_controller.reload());
                  },
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  onPressed: () {
                    unawaited(_launchExternalBrowser());
                  },
                  child: const Text('Open in Browser'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular floating button used on left/right of the Safari address bar
class _SafariFloatingButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _SafariFloatingButton({
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: iconSize, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// Safari Zoom / Option Button
class _OptionButton extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool isSmall;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.subLabel,
    required this.isSmall,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 14 : 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// iOS Safari Action List Tile
class _SafariListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SafariListTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 20, color: context.colors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
          letterSpacing: -0.2,
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_forward,
        size: 14,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}

