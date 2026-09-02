import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/features/downloads/presentation/manager/downloads_cubit/downloads_cubit.dart';
import 'package:libris_app/features/downloads/presentation/view/widgets/download_item_tile.dart';
import 'package:libris_app/features/downloads/presentation/view/widgets/empty_downloads_view.dart';

class DownloadsView extends StatelessWidget {
  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: context.titleColor,
        elevation: 0,
      ),
      body: BlocBuilder<DownloadsCubit, DownloadsState>(
        builder: (context, state) {
          if (state.isEmpty) {
            return const EmptyDownloadsView();
          }

          final inProgress = state.inProgressItems;
          final completed = state.completedItems;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (inProgress.isNotEmpty) ...[
                _sectionTitle(context, 'In progress'),
                const SizedBox(height: 12),
                for (final item in inProgress) DownloadItemTile(item: item),
                const SizedBox(height: 12),
              ],
              if (completed.isNotEmpty) ...[
                _sectionTitle(context, 'Downloaded'),
                const SizedBox(height: 12),
                for (final item in completed) DownloadItemTile(item: item),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.mutedColor,
        letterSpacing: 0.6,
      ),
    );
  }
}
