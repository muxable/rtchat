import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/commands.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/twitch/badge.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/models/stream_preview.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/screens/home.dart';
import 'package:rtchat/screens/onboarding.dart';
import 'package:rtchat/screens/settings/activity_feed.dart';
import 'package:rtchat/screens/settings/audio_sources.dart';
import 'package:rtchat/screens/settings/backup.dart';
import 'package:rtchat/screens/settings/chat_history.dart';
import 'package:rtchat/screens/settings/events.dart';
import 'package:rtchat/screens/settings/events/channel_point.dart';
import 'package:rtchat/screens/settings/events/cheer.dart';
import 'package:rtchat/screens/settings/events/follow.dart';
import 'package:rtchat/screens/settings/events/host.dart';
import 'package:rtchat/screens/settings/events/hypetrain.dart';
import 'package:rtchat/screens/settings/events/poll.dart';
import 'package:rtchat/screens/settings/events/prediction.dart';
import 'package:rtchat/screens/settings/events/raid.dart';
import 'package:rtchat/screens/settings/events/raiding.dart';
import 'package:rtchat/screens/settings/events/subscription.dart';
import 'package:rtchat/screens/settings/quick_links.dart';
import 'package:rtchat/screens/settings/settings.dart';
import 'package:rtchat/screens/settings/third_party.dart';
import 'package:rtchat/screens/settings/tts.dart';
import 'package:rtchat/screens/settings/tts/cloud_tts.dart';
import 'package:rtchat/screens/settings/tts/languages.dart';
import 'package:rtchat/screens/settings/tts/voices.dart';
import 'package:rtchat/screens/settings/twitch/badges.dart';
import 'package:rtchat/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();
  final prefs = await SharedPreferences.getInstance();
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }

  // persistence isn't useful to us since we're using Firestore as an event
  // stream and it uses memory/cache space.
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: false);

  await runZonedGuarded(() async {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ));

    runApp(App(prefs: prefs));
  }, FirebaseCrashlytics.instance.recordError);
}

class App extends StatefulWidget {
  final SharedPreferences prefs;

  static final observer =
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);

  const App({Key? key, required this.prefs}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _isDiscoModeRunning = false;
  Timer? _discoModeTimer;
  final _player = AudioCache();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserModel()),
        ChangeNotifierProvider(create: (context) {
          final model = ActivityFeedModel.fromJson(
              jsonDecode(widget.prefs.getString("activity_feed") ?? "{}"));
          return model
            ..addListener(() {
              widget.prefs
                  .setString("activity_feed", jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProvider(create: (context) {
          final model = LayoutModel.fromJson(
              jsonDecode(widget.prefs.getString("layout") ?? "{}"));
          return model
            ..addListener(() {
              widget.prefs.setString('layout', jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProxyProvider<UserModel, TtsModel>(
          create: (context) {
            final model = TtsModel.fromJson(
                jsonDecode(widget.prefs.getString("tts") ?? "{}"));
            return model
              ..addListener(() {
                widget.prefs.setString('tts', jsonEncode(model.toJson()));
              });
          },
          update: (context, userModel, model) => model!..update(userModel),
        ),
        ChangeNotifierProxyProvider2<UserModel, TtsModel, MessagesModel>(
          create: (context) {
            final model = MessagesModel.fromJson(
              jsonDecode(widget.prefs.getString("message_config") ?? "{}"),
            );
            model.onMessagePing = () => _player.play('message-sound.wav');
            model.channel =
                Provider.of<UserModel>(context, listen: false).activeChannel;
            model.tts = Provider.of<TtsModel>(context, listen: false);
            return model
              ..addListener(() {
                if (model.isLive && model.messages.isNotEmpty) {
                  final message = model.messages.last;
                  if (message is TwitchMessageModel &&
                      message.message == "!disco") {
                    _discoModeTimer?.cancel();
                    setState(() => _isDiscoModeRunning = true);
                    _discoModeTimer = Timer(const Duration(seconds: 5), () {
                      setState(() => _isDiscoModeRunning = false);
                    });
                  }
                }
                widget.prefs
                    .setString("message_config", jsonEncode(model.toJson()));
              });
          },
          update: (context, userModel, ttsModel, model) {
            model!.channel = userModel.activeChannel;
            model.tts = ttsModel;
            return model;
          },
          lazy: false,
        ),
        ChangeNotifierProvider(create: (context) {
          final model = QuickLinksModel.fromJson(
              jsonDecode(widget.prefs.getString("quick_links") ?? "{}"));
          return model
            ..addListener(() {
              widget.prefs.setString('quick_links', jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProvider(create: (context) {
          final model = StyleModel.fromJson(
              jsonDecode(widget.prefs.getString("style") ?? "{}"));
          return model
            ..addListener(() {
              widget.prefs.setString('style', jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProvider(create: (context) {
          final model = CommandsModel.fromJson(
              jsonDecode(widget.prefs.getString("commands") ?? "{}"));
          return model
            ..addListener(() {
              widget.prefs.setString("commands", jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProvider(create: (context) {
          final model = EventSubConfigurationModel.fromJson(
              jsonDecode(widget.prefs.getString("event_sub_configs") ?? "{}"));
          return model
            ..addListener(() {
              widget.prefs
                  .setString('event_sub_configs', jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProxyProvider<UserModel, TwitchBadgeModel>(
            create: (context) {
          final model = TwitchBadgeModel.fromJson(
              jsonDecode(widget.prefs.getString("twitch_badge") ?? "{}"));
          model.channel =
              Provider.of<UserModel>(context, listen: false).activeChannel;
          return model
            ..addListener(() {
              widget.prefs
                  .setString('twitch_badge', jsonEncode(model.toJson()));
            });
        }, update: (context, userModel, model) {
          model!.channel = userModel.activeChannel;
          return model;
        }),
        ChangeNotifierProxyProvider<UserModel, AudioModel>(
            create: (context) {
              final model = AudioModel.fromJson(
                  jsonDecode(widget.prefs.getString("audio") ?? "{}"));
              model.hostChannel =
                  Provider.of<UserModel>(context, listen: false).userChannel;
              return model
                ..addListener(() {
                  widget.prefs.setString('audio', jsonEncode(model.toJson()));
                });
            },
            update: (context, userModel, model) {
              model!.hostChannel = userModel.userChannel;
              return model;
            },
            lazy: false),
        ChangeNotifierProvider<StreamPreviewModel>(create: (context) {
          final model = StreamPreviewModel.fromJson(
              jsonDecode(widget.prefs.getString("stream_preview") ?? "{}"));
          return model
            ..addListener(() {
              widget.prefs
                  .setString('stream_preview', jsonEncode(model.toJson()));
            });
        }),
      ],
      child: Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        return MaterialApp(
          title: 'RealtimeChat',
          theme: Themes.lightTheme,
          darkTheme: Themes.darkTheme,
          themeMode: layoutModel.themeMode,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            LocaleNamesLocalizationsDelegate(),
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [App.observer],
          initialRoute: '/',
          routes: {
            '/': (context) {
              return Consumer<UserModel>(
                builder: (context, userModel, child) {
                  if (userModel.isLoading) {
                    // don't show anything yet.
                    return Container();
                  }
                  final activeChannel = userModel.activeChannel;
                  if (activeChannel == null) {
                    return OnboardingScreen(onChannelSelect: (channel) {
                      userModel.activeChannel = channel;
                    });
                  }
                  return HomeScreen(
                      isDiscoModeEnabled: _isDiscoModeRunning,
                      channel: activeChannel,
                      onChannelSelect: (channel) {
                        userModel.activeChannel = channel;
                      });
                },
              );
            },
            '/settings': (context) => const SettingsScreen(),
            '/settings/badges': (context) => const TwitchBadgesScreen(),
            '/settings/activity-feed': (context) => const ActivityFeedScreen(),
            '/settings/audio-sources': (context) => const AudioSourcesScreen(),
            '/settings/chat-history': (context) => const ChatHistoryScreen(),
            '/settings/text-to-speech': (context) => const TextToSpeechScreen(),
            '/settings/text-to-speech/cloud-tts': (context) =>
                const CloudTTSScreen(),
            '/settings/text-to-speech/languages': (context) =>
                const LanguagesScreen(),
            '/settings/text-to-speech/voices': (context) =>
                const VoicesScreen(),
            '/settings/quick-links': (context) => const QuickLinksScreen(),
            '/settings/backup': (context) => const BackupScreen(),
            '/settings/third-party': (context) => const ThirdPartyScreen(),
            '/settings/events': (context) => const EventsScreen(),
            '/settings/events/follow': (context) => const FollowEventScreen(),
            '/settings/events/cheer': (context) => const CheerEventScreen(),
            '/settings/events/subscription': (context) =>
                const SubscriptionEventScreen(),
            '/settings/events/raid': (context) => const RaidEventScreen(),
            '/settings/events/channel-point': (context) =>
                const ChannelPointRedemptionEventScreen(),
            '/settings/events/poll': (context) => const PollEventScreen(),
            '/settings/events/host': (context) => const HostEventScreen(),
            '/settings/events/hypetrain': (context) =>
                const HypetrainEventScreen(),
            '/settings/events/prediction': (context) =>
                const PredictionEventScreen(),
            '/settings/events/raiding': (context) => const RaidingEventScreen(),
          },
        );
      }),
    );
  }
}
