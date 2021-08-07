import 'package:flutter/material.dart';

class DismissibleDeleteBackground extends StatelessWidget {
  const DismissibleDeleteBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.red,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [Icon(Icons.delete), Icon(Icons.delete)])));
  }
}
