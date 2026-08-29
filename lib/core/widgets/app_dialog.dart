import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libris_app/constants/app_colors.dart';

enum AppDialogKind { success, error, info }

/// A unified, lightweight top pop-up dialog / toast designed specifically
/// for the Libris design system, replacing third-party toast dependencies.
class AppDialog {
  AppDialog._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;
  static _TopToastWidgetState? _currentState;

  /// Shows a top pop-up dialog with the specified [message], optional [title],
  /// and visual [kind].
  static Future<void> show(
    BuildContext context, {
    required String message,
    String? title,
    AppDialogKind kind = AppDialogKind.info,
    Duration duration = const Duration(milliseconds: 2600),
  }) async {
    // If context is no longer mounted, cannot show overlay
    if (!context.mounted) return;

    // Provide light haptic feedback for user confirmation
    try {
      unawaited(HapticFeedback.lightImpact());
    } catch (_) {}

    // Clean up any currently showing dialog
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    if (_currentEntry != null && _currentState != null) {
      // Animate out previous one before showing new one
      await _currentState?.animateOut();
      _currentEntry?.remove();
      _currentEntry = null;
      _currentState = null;
    } else {
      _currentEntry?.remove();
      _currentEntry = null;
    }

    late final OverlayEntry entry;
    final stateKey = GlobalKey<_TopToastWidgetState>();

    entry = OverlayEntry(
      builder: (context) {
        return _TopToastWidget(
          key: stateKey,
          message: message,
          title: title,
          kind: kind,
          onDismissed: () {
            _dismissTimer?.cancel();
            _dismissTimer = null;
            if (_currentEntry == entry) {
              entry.remove();
              _currentEntry = null;
              _currentState = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);

    // Give stateKey a frame to bind
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentState = stateKey.currentState;
    });

    _dismissTimer = Timer(duration, () async {
      if (_currentEntry == entry && stateKey.currentState != null) {
        await stateKey.currentState?.animateOut();
        if (_currentEntry == entry) {
          entry.remove();
          _currentEntry = null;
          _currentState = null;
        }
      } else if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
        _currentState = null;
      }
    });
  }

  /// Convenience method for success top dialog
  static Future<void> success(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    return show(
      context,
      message: message,
      title: title,
      kind: AppDialogKind.success,
      duration: duration,
    );
  }

  /// Convenience method for error top dialog
  static Future<void> error(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    return show(
      context,
      message: message,
      title: title,
      kind: AppDialogKind.error,
      duration: duration,
    );
  }

  /// Convenience method for info top dialog
  static Future<void> info(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    return show(
      context,
      message: message,
      title: title,
      kind: AppDialogKind.info,
      duration: duration,
    );
  }

  /// Manually dismiss any active dialog
  static Future<void> dismiss() async {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentState != null) {
      await _currentState?.animateOut();
    }
    _currentEntry?.remove();
    _currentEntry = null;
    _currentState = null;
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final AppDialogKind kind;
  final VoidCallback onDismissed;

  const _TopToastWidget({
    super.key,
    required this.message,
    this.title,
    required this.kind,
    required this.onDismissed,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.9),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.78,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.elasticOut),
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _controller.forward();
  }

  Future<void> animateOut() async {
    if (mounted && _controller.status != AnimationStatus.dismissed) {
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    final (Color iconColor, Color badgeColor, IconData icon) = switch (widget.kind) {
      AppDialogKind.success => (
        isDark ? const Color(0xFF66BB6A) : AppColors.success,
        (isDark ? const Color(0xFF66BB6A) : AppColors.success).withValues(alpha: isDark ? 0.20 : 0.14),
        Icons.check_rounded,
      ),
      AppDialogKind.error => (
        isDark ? const Color(0xFFEF5350) : AppColors.error,
        (isDark ? const Color(0xFFEF5350) : AppColors.error).withValues(alpha: isDark ? 0.20 : 0.14),
        Icons.error_outline_rounded,
      ),
      AppDialogKind.info => (
        isDark ? AppColors.darkPrimary : AppColors.primary,
        (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: isDark ? 0.20 : 0.14),
        Icons.info_outline_rounded,
      ),
    };

    final cardBg = isDark ? const Color(0xFF252017) : const Color(0xFFFCFAF7);
    final borderColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final subtitleColor = isDark ? AppColors.darkMuted : AppColors.muted;

    return Positioned(
      top: topPadding + 6,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Dismissible(
                key: const Key('top_toast_dismissible'),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismissed(),
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () async {
                      await animateOut();
                      widget.onDismissed();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 290,
                        minHeight: 38,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: _iconScaleAnimation,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: badgeColor,
                                ),
                                child: Icon(
                                  icon,
                                  size: 15,
                                  color: iconColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.title != null &&
                                      widget.title!.trim().isNotEmpty) ...[
                                    Text(
                                      widget.title!,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 1),
                                  ],
                                  Text(
                                    widget.message,
                                    style: TextStyle(
                                      fontSize: widget.title != null ? 11.5 : 12.5,
                                      fontWeight: widget.title != null
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                      color: widget.title != null
                                          ? subtitleColor
                                          : textColor,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

