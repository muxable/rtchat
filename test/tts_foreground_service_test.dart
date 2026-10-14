import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/tts_foreground_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final l10n = lookupAppLocalizations(const Locale('en'));

  late List<MethodCall> calls;
  late TtsModel model;
  late TtsForegroundService service;

  setUpAll(() async {
    await initializeDateFormatting('en');
    for (final name in ['flutter_tts', 'com.ryanheise.just_audio.methods']) {
      messenger.setMockMethodCallHandler(
          MethodChannel(name), (call) async => null);
    }
  });

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(TtsForegroundService.channel,
        (call) async {
      calls.add(call);
      return null;
    });
    model = TtsModel.fromJson({});
    service = TtsForegroundService(model, () => l10n, enabled: true);
  });

  tearDown(() {
    service.dispose();
    model.dispose();
    messenger.setMockMethodCallHandler(TtsForegroundService.channel, null);
  });

  // TtsModel notifies its listeners after the next frame.
  Future<void> frame(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    tester.binding.scheduleFrame();
    await tester.pump();
  }

  testWidgets('does nothing while tts is off', (tester) async {
    expect(calls, isEmpty);
  });

  testWidgets('runs the service while tts is on', (tester) async {
    model.setMode(l10n, TtsMode.enabled);
    await frame(tester);
    expect(calls.map((c) => c.method), ['start']);
    expect(calls.last.arguments['text'], l10n.textToSpeechEnabled);
    expect(calls.last.arguments['turnOff'], l10n.turnOffTextToSpeech);

    model.setMode(l10n, TtsMode.disabled);
    await frame(tester);
    expect(calls.map((c) => c.method), ['start', 'stop']);
  });

  testWidgets('updates the notification when switching to alerts only',
      (tester) async {
    model.setMode(l10n, TtsMode.enabled);
    await frame(tester);
    model.setMode(l10n, TtsMode.alertsOnly);
    await frame(tester);
    expect(calls.map((c) => c.method), ['start', 'start']);
    expect(calls.last.arguments['text'], l10n.alertsEnabled);
  });

  testWidgets("the notification's turn off button turns tts off",
      (tester) async {
    model.setMode(l10n, TtsMode.enabled);
    await frame(tester);

    await messenger.handlePlatformMessage(
        TtsForegroundService.channel.name,
        TtsForegroundService.channel.codec
            .encodeMethodCall(const MethodCall('turnOff')),
        (_) {});
    await frame(tester);

    expect(model.mode, TtsMode.disabled);
    expect(calls.last.method, 'stop');
  });

  testWidgets('stops the service when disposed while running', (tester) async {
    model.setMode(l10n, TtsMode.enabled);
    await frame(tester);
    service.dispose();
    expect(calls.last.method, 'stop');
    // tearDown disposes again; that must be harmless.
  });
}
