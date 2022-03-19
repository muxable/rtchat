import 'package:flutter/material.dart';

class SliverTitleWidget extends StatelessWidget {
  final String title;
  const SliverTitleWidget({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return SliverAppBar(
    //   toolbarHeight: 16,
    //   expandedHeight: 32,
    //   title: Text(
    //     title,
    //     style: const TextStyle(color: Colors.redAccent, fontSize: 18),
    //   ),
    //   pinned: true,
    // );

    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4, top: 8),
            child: Text(
              title,
              style: const TextStyle(color: Colors.redAccent, fontSize: 18),
            ),
          )
        ],
      ),
    );
  }
}
