import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/main.dart';

class _FailingCompleter extends ImageStreamCompleter {
  void fail(Object error) => reportError(
    context: ErrorDescription('resolving an image codec'),
    exception: error,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('image load failures are not fatal', () {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    try {
      final completer =
          _FailingCompleter()..addListener(ImageStreamListener((_, _) {}));
      completer.fail(Exception('Could not getPixels for frame 1'));
    } finally {
      FlutterError.onError = previous;
    }

    expect(reported, hasLength(1));
    expect(isFatalFlutterError(reported.single), isFalse);
  });

  test('silent flutter errors are not fatal', () {
    expect(
      isFatalFlutterError(
        FlutterErrorDetails(
          exception: StateError('x'),
          library: 'widgets library',
          silent: true,
        ),
      ),
      isFalse,
    );
  });

  test('other flutter errors are fatal', () {
    expect(
      isFatalFlutterError(
        FlutterErrorDetails(
          exception: StateError('x'),
          library: 'widgets library',
        ),
      ),
      isTrue,
    );
  });
}
