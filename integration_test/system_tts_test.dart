import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native system speech lists voices and completes playback', (
    tester,
  ) async {
    final engine = SystemTtsEngine();
    addTearDown(engine.dispose);
    final voices = await engine.voices().timeout(const Duration(seconds: 30));
    expect(voices, isNotEmpty);
    final english = voices.where((voice) => voice.speaks('en'));
    expect(english, isNotEmpty);
    await engine
        .speak('System speech is ready.', voice: english.first)
        .timeout(const Duration(seconds: 60));
    await engine.stop();
    await engine
        .speak('Speech still works after stopping.', voice: english.first)
        .timeout(const Duration(seconds: 60));
  });
}
