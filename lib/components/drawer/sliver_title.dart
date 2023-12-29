import 'package:flutter/material.dart';

class SliverTitleWidget extends StatelessWidget {
  final String title;
  const SliverTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4, top: 8),
            child: Text(
              title,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary, fontSize: 18),
            ),
          )
        ],
      ),
    );
  }
}
