import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/main.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';

import '../fakes/fake_chat.dart';
import '../fakes/fake_tts_engine.dart';

final twitch = Channel(Providers.twitch, '1', 'muxfd');
final kick = Channel(Providers.kick, '2', 'muxfd');
final t0 = DateTime(2025, 1, 1, 12);

FakeChatMessage chat(String id, int seconds, Channel channel) =>
    FakeChatMessage(
      messageId: id,
      timestamp: t0.add(Duration(seconds: seconds)),
      author: FakeChatUser(userId: 'u', login: 'u'),
      message: 'text $id',
    )..channel = channel;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // what the engine was asked to say, and a gate that holds the current
  // utterance until it's released.
  late FakeTtsEngine engine;
  late Completer<void> gate;

  setUp(() {
    gate = Completer()..complete();
    engine = FakeTtsEngine()..onSpeak = (_) => gate.future;
  });

  late WidgetTester tester;

  /// Lets queued stream events and tts futures run.
  Future<void> idle() async {
    // platform channel replies complete outside the fake clock.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
  }

  late Map<Channel, StreamController<DeltaEvent>> streams;
  late MessagesModel model;
  late TtsModel tts;

  Future<void> setUpView(WidgetTester t, List<Channel> channels) async {
    tester = t;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SizedBox(),
      ),
    );
    streams = {for (final c in channels) c: StreamController<DeltaEvent>()};
    tts = TtsModel.fromJson({}, engine: engine);
    model =
        MessagesModel.fromJson({})
          ..forChannel = ((channel) => streams[channel]!.stream)
          ..tts = tts
          ..channels = channels;
    addTearDown(model.dispose);
  }

  Future<void> send(Channel channel, DeltaEvent event) async {
    streams[channel]!.add(event);
    await idle();
  }

  bool said(String id) =>
      engine.spoken.any((text) => text.contains('text $id'));

  testWidgets('a late live message in a merged view is read out', (
    tester,
  ) async {
    await setUpView(tester, [twitch, kick]);
    // initial history from both channels.
    await send(twitch, AppendDeltaEvent(chat('t-history', 1, twitch)));
    await send(twitch, LiveStateDeltaEvent(t0));
    await send(kick, AppendDeltaEvent(chat('k-history', 2, kick)));
    await send(kick, LiveStateDeltaEvent(t0));

    tts.setMode(lookupAppLocalizations(const Locale('en')), TtsMode.enabled);
    await send(twitch, AppendDeltaEvent(chat('t-live', 20, twitch)));
    // kick's stream delivers a message a little older than twitch's.
    await send(kick, AppendDeltaEvent(chat('k-live', 19, kick)));

    expect(model.messages.map((m) => m.messageId), [
      't-history',
      'k-history',
      'k-live',
      't-live',
    ]);
    expect(said('t-live'), isTrue);
    expect(said('k-live'), isTrue, reason: 'late live messages are read');
    expect(said('t-history'), isFalse);
    expect(said('k-history'), isFalse);
  });

  testWidgets('history arriving after tts is enabled is not read out', (
    tester,
  ) async {
    await setUpView(tester, [twitch, kick]);
    await send(twitch, AppendDeltaEvent(chat('t-history', 1, twitch)));
    await send(twitch, LiveStateDeltaEvent(t0));
    tts.setMode(lookupAppLocalizations(const Locale('en')), TtsMode.enabled);
    await send(twitch, AppendDeltaEvent(chat('t-live', 5, twitch)));
    // kick's history loads late, both before and after twitch's newest.
    await send(kick, AppendDeltaEvent(chat('k-old', 2, kick)));
    await send(kick, AppendDeltaEvent(chat('k-new', 6, kick)));
    await send(kick, LiveStateDeltaEvent(t0));

    expect(said('t-live'), isTrue);
    expect(said('k-old'), isFalse);
    expect(said('k-new'), isFalse);
  });

  testWidgets('clearing one channel keeps the other channel queued', (
    tester,
  ) async {
    await setUpView(tester, [twitch, kick]);
    await send(twitch, LiveStateDeltaEvent(t0));
    await send(kick, LiveStateDeltaEvent(t0));
    tts.setMode(lookupAppLocalizations(const Locale('en')), TtsMode.enabled);
    await idle();

    gate = Completer();
    await send(twitch, AppendDeltaEvent(chat('t1', 1, twitch)));
    await send(twitch, AppendDeltaEvent(chat('t2', 2, twitch)));
    await send(kick, AppendDeltaEvent(chat('k3', 3, kick)));
    expect(said('t1'), isTrue);

    await send(
      twitch,
      ClearDeltaEvent(
        messageId: 'clear',
        timestamp: t0.add(const Duration(seconds: 4)),
      ),
    );
    gate.complete();
    await idle();

    expect(
      said('t2'),
      isFalse,
      reason: "the cleared channel's queue is dropped",
    );
    expect(said('k3'), isTrue, reason: "the other channel's queue is kept");
  });

  testWidgets('clearing a single channel view stops everything', (
    tester,
  ) async {
    await setUpView(tester, [twitch]);
    await send(twitch, LiveStateDeltaEvent(t0));
    tts.setMode(lookupAppLocalizations(const Locale('en')), TtsMode.enabled);
    await idle();

    gate = Completer();
    await send(twitch, AppendDeltaEvent(chat('t1', 1, twitch)));
    await send(twitch, AppendDeltaEvent(chat('t2', 2, twitch)));
    await send(
      twitch,
      ClearDeltaEvent(
        messageId: 'clear',
        timestamp: t0.add(const Duration(seconds: 4)),
      ),
    );
    gate.complete();
    await idle();

    expect(said('t1'), isTrue);
    expect(said('t2'), isFalse);
  });
}
