import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/models/book_model.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/features/library/presentation/manager/library_cubit/library_cubit.dart';

class FavoriteIconButton extends StatefulWidget {
  final BookModel? bookModel;

  const FavoriteIconButton({super.key, this.bookModel});

  @override
  State<FavoriteIconButton> createState() => _FavoriteIconButtonState();
}

class _FavoriteIconButtonState extends State<FavoriteIconButton>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.85,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.85,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 45,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      final isSaved = context.read<LibraryCubit>().isBookFavorite(
        widget.bookModel!.key,
      );
      if (isSaved != _isSaved) {
        setState(() {
          _isSaved = isSaved;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.bookModel == null || widget.bookModel!.key.isEmpty) return;

    final isNowSaved = await context.read<LibraryCubit>().toggleFavoriteBook(
      widget.bookModel!,
    );
    setState(() {
      _isSaved = isNowSaved;
    });
    _controller.forward(from: 0);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowSaved ? 'Added to your Library' : 'Removed from your Library',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        icon: Icon(
          _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: 28,
          color: context.colors.primary,
        ),
        onPressed: _toggleFavorite,
      ),
    );
  }
}
