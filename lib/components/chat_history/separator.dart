import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SeparatorWidget extends StatelessWidget {
  final DateTime timestamp;
  final format = DateFormat();

  SeparatorWidget(this.timestamp, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          format.format(timestamp),
          style: Theme.of(context).textTheme.caption,
        ),
      ),
    );
  }
}
