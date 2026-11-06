import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans a QR code in a bottom sheet. Returns its text, or null if the sheet
/// is closed first.
Future<String?> scanQrCode(BuildContext context) =>
    showModalBottomSheet<String>(
      isScrollControlled: true,
      context: context,
      builder: (context) => const _QrScanner(),
    );

class _QrScanner extends StatefulWidget {
  const _QrScanner();

  @override
  State<_QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<_QrScanner> {
  // Owned by the sheet, so it's disposed only once the sheet is gone: the
  // closing animation still builds the camera view.
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  var _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
    // detections can arrive while the sheet closes; pop only once.
    if (_scanned || value == null || value.isEmpty) return;
    _scanned = true;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          errorBuilder: (context, error) => _ScannerError(error: error),
          onDetect: _onDetect,
        ),
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: _ScannerControls(controller: _controller),
        ),
      ],
    );
  }
}

class _ScannerControls extends StatelessWidget {
  const _ScannerControls({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    const Color iconColor = Colors.white;
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: iconColor),
            ),
            IconButton(
              onPressed: () => controller.toggleTorch(),
              icon: Icon(
                controller.value.torchState == TorchState.off
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

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    String errorMessage;

    switch (error.errorCode) {
      case MobileScannerErrorCode.controllerUninitialized:
        errorMessage = 'Controller not ready.';
        break;
      case MobileScannerErrorCode.permissionDenied:
        errorMessage = 'Permission denied';
        break;
      case MobileScannerErrorCode.unsupported:
        errorMessage = 'Scanning is unsupported on this device';
        break;
      default:
        errorMessage = 'Generic Error';
        break;
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.error, color: Colors.white),
            ),
            Text(errorMessage, style: const TextStyle(color: Colors.white)),
            Text(
              error.errorDetails?.message ?? '',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
