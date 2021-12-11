import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/style.dart';

final discoModeColors = [
  Colors.red.withOpacity(0.7),
  Colors.blue.withOpacity(0.7),
  Colors.green.withOpacity(0.7),
  Colors.purple.withOpacity(0.7),
  Colors.yellow.withOpacity(0.7),
  Colors.cyan.withOpacity(0.7),
  Colors.brown.withOpacity(0.7),
];

class DiscoWidget extends StatelessWidget {
  final Widget child;
  final bool isEnabled;

  const DiscoWidget({required this.child, required this.isEnabled, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<StyleModel, bool>(
      selector: (context, model) => model.isDiscoModeAvailable,
      builder: (context, isDiscoModeAvailable, child) {
        if (isEnabled && isDiscoModeAvailable) {
          return StreamBuilder<int>(
              stream:
                  Stream.periodic(const Duration(milliseconds: 150), (x) => x),
              builder: (context, snapshot) {
                final index = (snapshot.data ?? 0);
                final color = index % 2 != 0
                    ? Colors.white
                    : discoModeColors[(index ~/ 2) % discoModeColors.length];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  color: color,
                  child: child,
                );
              });
        }
        return child!;
      },
      child: child,
    );
  }
}
