import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/features/details/presentation/manager/book_details_cubit/book_details_cubit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class BookActionBottomBar extends StatelessWidget {
  final String? fallbackWorkKey;

  const BookActionBottomBar({super.key, this.fallbackWorkKey});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    try {
      final Uri uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open link. Please check your browser.'),
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open link. Please check your browser.'),
          ),
        );
      }
    }
  }

  String? _openLibraryReadUrl() {
    if (fallbackWorkKey == null || fallbackWorkKey!.isEmpty) return null;
    String cleanKey = fallbackWorkKey!.startsWith('/')
        ? fallbackWorkKey!
        : '/$fallbackWorkKey';
    return 'https://openlibrary.org$cleanKey';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookDetailsCubit, BookDetailsState>(
      builder: (context, state) {
        final isLoading =
            state is BookDetailsLoading || state is BookDetailsInitial;

        String? readUrl = _openLibraryReadUrl();
        String? downloadUrl;

        if (state is BookDetailsSuccess) {
          readUrl = state.bookDetail.readUrl;
          downloadUrl = state.bookDetail.downloadUrl;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: isLoading
                ? _buildShimmerButtons(context)
                : Row(
              children: [
                if (downloadUrl != null && downloadUrl.isNotEmpty) ...[
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _launchURL(context, downloadUrl!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: context.colors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: context.colors.primary.withValues(
                                alpha: 0.2,
                              ),
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Download PDF',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (readUrl != null && readUrl.isNotEmpty) {
                          _launchURL(context, readUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reader link not available yet'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_rounded, size: 20),
                      label: const Text(
                        'Read Now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerButtons(BuildContext context) {
    final baseColor = context.isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final highlightColor =
        context.isDark ? Colors.grey[500]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
