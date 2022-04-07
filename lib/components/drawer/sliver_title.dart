import 'package:flutter/material.dart';

class SliverTitleWidget extends StatelessWidget {
  final String title;
  const SliverTitleWidget({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4, top: 8),
            child: Text(
              title,
              style: const TextStyle(
                  color: Color.fromARGB(255, 238, 80, 80), fontSize: 18),
            ),
          )
        ],
      ),
    );
  }
}
