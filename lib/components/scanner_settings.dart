import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerSettings extends StatelessWidget {
  const ScannerSettings({super.key, required this.scanController});

  final MobileScannerController scanController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TorchState>(
      valueListenable: scanController.torchState,
      builder: (context, value, child) {
        const Color iconColor = Colors.white;

        return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                color: iconColor,
              ),
            ),
            IconButton(
              onPressed: () => scanController.toggleTorch(),
              icon: Icon(
                value == TorchState.on ? Icons.flash_off : Icons.flash_on,
                color: iconColor,
              ),
            ),
          ],
        );
      },
    );
  }
}
