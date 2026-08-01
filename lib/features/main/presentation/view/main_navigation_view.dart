import 'package:flutter/material.dart';
import 'package:libris_app/core/widgets/custom_bottom_navigation_bar.dart';
import 'package:libris_app/features/explore/presentation/view/explore_view.dart';
import 'package:libris_app/features/home/presentation/view/widgets/home_view_body.dart';
import 'package:libris_app/features/library/presentation/view/library_view.dart';
import 'package:libris_app/features/profile/presentation/view/profile_view.dart';

/// Main navigation screen featuring a BottomNavigationBar and sliding animations
/// when switching between 4 separate views using PageView and PageController.
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
  late PageController _pageController;

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
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _views,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _currentIndex,
        onItemTapped: _onTabSelected,
      ),
    );
  }
}
