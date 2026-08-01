import 'package:flutter/material.dart';
import 'package:libris_app/core/widgets/custom_bottom_navigation_bar.dart';
import 'package:libris_app/features/explore/presentation/view/explore_view.dart';
import 'package:libris_app/features/home/presentation/view/widgets/home_view_body.dart';
import 'package:libris_app/features/library/presentation/view/library_view.dart';
import 'package:libris_app/features/profile/presentation/view/profile_view.dart';

/// Main navigation screen featuring a BottomNavigationBar and switching
/// between 4 separate views using IndexedStack to preserve view states.
class MainNavigationView extends StatefulWidget {
  final int initialIndex;

  const MainNavigationView({
    super.key,
    this.initialIndex = 0, // Default selected tab is Home (index 0)
  });

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  late int _currentIndex;

  final List<Widget> _views = const [
    HomeViewBody(),
    ExploreView(),
    LibraryView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _currentIndex,
        onItemTapped: _onTabSelected,
      ),
    );
  }
}
