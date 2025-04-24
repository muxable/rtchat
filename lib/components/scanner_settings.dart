import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerSettings extends StatelessWidget {
  const ScannerSettings({super.key, required this.scanController});

  final MobileScannerController scanController;

  @override
  Widget build(BuildContext context) {
    const Color iconColor = Colors.white;
    return ValueListenableBuilder(
      valueListenable: scanController,
      builder: (context, value, child) {
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
                scanController.value.torchState == TorchState.on
                    ? Icons.flash_off
                    : Icons.flash_on,
                color: iconColor,
              ),
            ),
          ],
        );
      },
    );
  }
}
