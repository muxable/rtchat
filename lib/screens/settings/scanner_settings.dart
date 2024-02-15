import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Widget scannerSettings(
    BuildContext ctx, MobileScannerController scanController) {
  return ValueListenableBuilder<TorchState>(
    valueListenable: scanController.torchState,
    builder: (context, value, child) {
      const Color iconColor = Colors.white;

      Icon? icon;

      switch (value) {
        case TorchState.on:
          icon = const Icon(
            Icons.flash_off,
            color: iconColor,
          );
          break;
        case TorchState.off:
          icon = const Icon(
            Icons.flash_on,
            color: iconColor,
          );
          break;
      }

      return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(
              Icons.close,
              color: iconColor,
            ),
          ),
          IconButton(onPressed: () => scanController.toggleTorch(), icon: icon),
        ],
      );
    },
  );
}
