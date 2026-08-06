import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/features/library/data/repos/favorites_repo_impl.dart';

class FavoriteIconButton extends StatefulWidget {
  final BookModel? bookModel;

  const FavoriteIconButton({super.key, this.bookModel});

  @override
  State<FavoriteIconButton> createState() => _FavoriteIconButtonState();
}

class _FavoriteIconButtonState extends State<FavoriteIconButton> {
  final _favoritesRepo = FavoritesRepoImpl();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  @override
  void didUpdateWidget(covariant FavoriteIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookModel?.key != widget.bookModel?.key) {
      _checkFavoriteStatus();
    }
  }

  void _checkFavoriteStatus() {
    if (widget.bookModel != null && widget.bookModel!.key.isNotEmpty) {
      setState(() {
        _isSaved = _favoritesRepo.isBookFavorite(widget.bookModel!.key);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.bookModel == null || widget.bookModel!.key.isEmpty) return;

    final isNowSaved = await _favoritesRepo.toggleFavoriteBook(
      widget.bookModel!,
    );
    setState(() {
      _isSaved = isNowSaved;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowSaved
                ? 'Added to your Library'
                : 'Removed from your Library',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        size: 28,
        color: AppColors.primary,
      ),
      onPressed: _toggleFavorite,
    );
  }
}
