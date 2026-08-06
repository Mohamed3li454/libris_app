import 'package:flutter/material.dart';
import 'package:libris_app/constants/app_colors.dart';

/// Data class representing each navigation tab item.
class NavItemData {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const NavItemData({required this.icon, this.activeIcon, required this.label});
}

/// A custom, animated BottomNavigationBar widget designed with warm beige tones,
/// pill-shaped active state containers, and smooth tab switching transitions.
class CustomBottomNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int>? onItemTapped;
  final Color backgroundColor;
  final Color activePillColor;
  final Color activeColor;
  final Color inactiveColor;
  final Color topBorderColor;

  const CustomBottomNavigationBar({
    super.key,
    this.selectedIndex = 0, // Default active index set to Home (index 0)
    this.onItemTapped,
    this.backgroundColor = AppColors.background,
    this.activePillColor = const Color(0xFFE8DFC8),
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.secondary,
    this.topBorderColor = const Color(0xFFE5DDD0),
  });

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  late int _currentIndex;

  static const List<NavItemData> _navItems = [
    NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavItemData(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explore',
    ),
    NavItemData(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Library',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(CustomBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _currentIndex = widget.selectedIndex;
    }
  }

  void _handleTap(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    widget.onItemTapped?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border(
          top: BorderSide(color: widget.topBorderColor, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isActive = _currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _handleTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastOutSlowIn,
                      padding: EdgeInsets.symmetric(
                        horizontal: isActive ? 16 : 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? widget.activePillColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              isActive
                                  ? (item.activeIcon ?? item.icon)
                                  : item.icon,
                              key: ValueKey<String>('${item.label}_$isActive'),
                              color: isActive
                                  ? widget.activeColor
                                  : widget.inactiveColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isActive
                                  ? widget.activeColor
                                  : widget.inactiveColor,
                              letterSpacing: 0.1,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
