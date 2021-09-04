import 'package:flutter/material.dart';

class DismissibleBackground extends StatelessWidget {
  final Color color;
  final IconData icon;

  const DismissibleBackground(
      {required this.color, required this.icon, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconTheme(
        data: Theme.of(context).primaryIconTheme,
        child: Container(
            color: color,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Icon(icon), Icon(icon)]))));
  }
}
