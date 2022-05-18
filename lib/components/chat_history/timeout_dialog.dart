import 'package:flutter/material.dart';

class TimeoutDialog extends StatefulWidget {
  final String title;
  final void Function(Duration) onPressed;

  const TimeoutDialog({Key? key, required this.title, required this.onPressed})
      : super(key: key);

  @override
  State<TimeoutDialog> createState() => _TimeoutDialogState();
}

class _TimeoutDialogState extends State<TimeoutDialog> {
  var _value = 5;

  String get _label {
    switch (_value) {
      case 1:
        return "1 minute";
      case 2:
        return "15 minutes";
      case 3:
        return "1 hour";
      case 4:
        return "6 hours";
      case 5:
        return "1 day";
      case 6:
        return "2 days";
      case 7:
        return "1 week";
      case 8:
        return "1 month";
      case 9:
        return "3 months";
      case 10:
        return "1 year";
      case 11:
        return "forever";
    }
    return "";
  }

  Duration get _duration {
    switch (_value) {
      case 1:
        return const Duration(minutes: 1);
      case 2:
        return const Duration(minutes: 15);
      case 3:
        return const Duration(hours: 1);
      case 4:
        return const Duration(hours: 6);
      case 5:
        return const Duration(days: 1);
      case 6:
        return const Duration(days: 2);
      case 7:
        return const Duration(days: 7);
      case 8:
        return const Duration(days: 30);
      case 9:
        return const Duration(days: 90);
      case 10:
        return const Duration(days: 365);
      case 11:
        return const Duration(days: 100 * 365);
    }
    return const Duration(days: 100 * 365);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          height: 56,
          child: Slider(
            value: _value.toDouble(),
            min: 1,
            max: 11,
            divisions: 11,
            label: _label,
            onChanged: (double value) {
              setState(() {
                _value = value.toInt();
              });
            },
          ),
        ),
        actions: [
          TextButton(
              child: Text("Timeout for $_label"),
              onPressed: () {
                widget.onPressed(_duration);
              })
        ]);
  }
}
