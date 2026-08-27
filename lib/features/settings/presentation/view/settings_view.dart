import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libris_app/core/di/service_locator.dart';
import 'package:libris_app/core/services/search_history_service.dart';
import 'package:libris_app/core/theme/app_theme.dart';
import 'package:libris_app/features/settings/presentation/manager/theme_cubit.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _clearCache(BuildContext context) async {
    await ServiceLocator.homeRepo.clearCache();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cached book lists cleared.')),
    );
  }

  Future<void> _clearSearchHistory(BuildContext context) async {
    await SearchHistoryService.clearRecentSearches();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search history cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: context.titleColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Appearance',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.mutedColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              return SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (value) {
                  context.read<ThemeCubit>().setThemeMode(value.first);
                },
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Data',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.mutedColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cached_rounded, color: context.colors.primary),
            title: const Text('Clear home cache'),
            subtitle: const Text('Removes cached featured and category lists.'),
            onTap: () => _clearCache(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.history_rounded, color: context.colors.primary),
            title: const Text('Clear search history'),
            onTap: () => _clearSearchHistory(context),
          ),
          const SizedBox(height: 28),
          Text(
            'About',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.mutedColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.menu_book_rounded, color: context.colors.primary),
            title: const Text('Libris'),
            subtitle: const Text(
              'Version 1.0.0\nBook data from Open Library.',
            ),
            isThreeLine: true,
          ),
        ],
      ),
    );
  }
}
