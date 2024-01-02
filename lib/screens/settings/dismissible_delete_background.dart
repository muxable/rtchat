import 'package:flutter/material.dart';

class DismissibleDeleteBackground extends StatelessWidget {
  const DismissibleDeleteBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.red,
        child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Icon(Icons.delete), Icon(Icons.delete)])));
  }
}
