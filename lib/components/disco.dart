import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/style.dart';

final discoModeColors = [
  Colors.red.withValues(alpha: 0.7),
  Colors.blue.withValues(alpha: 0.7),
  Colors.green.withValues(alpha: 0.7),
  Colors.purple.withValues(alpha: 0.7),
  Colors.yellow.withValues(alpha: 0.7),
  Colors.cyan.withValues(alpha: 0.7),
  Colors.brown.withValues(alpha: 0.7),
];

class DiscoWidget extends StatelessWidget {
  final Widget child;
  final bool isEnabled;

  const DiscoWidget({required this.child, required this.isEnabled, super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<StyleModel, bool>(
      selector: (context, model) => model.isDiscoModeAvailable,
      builder: (context, isDiscoModeAvailable, child) {
        if (isEnabled && isDiscoModeAvailable) {
          return Stack(
            children: [
              child!,
              StreamBuilder<int>(
                  stream: Stream.periodic(
                      const Duration(milliseconds: 150), (x) => x),
                  builder: (context, snapshot) {
                    final index = (snapshot.data ?? 0);
                    final color = index % 2 != 0
                        ? Colors.white
                        : discoModeColors[
                            (index ~/ 2) % discoModeColors.length];
                    return Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        color: color,
                      ),
                    );
                  }),
            ],
          );
        }
        return child!;
      },
      child: child,
    );
  }
}
