import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? trailing;

  const CustomAppBar({super.key, this.leading, this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          leading ?? const SizedBox.shrink(),
          if (title != null) ...[
            Expanded(child: Center(child: title)),
          ] else ...[
            const Spacer(),
          ],
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
