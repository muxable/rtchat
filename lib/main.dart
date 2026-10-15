import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/firebase_options.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/commands.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/chat.dart';
import 'package:rtchat/models/messages/twitch/badge.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/qr_code.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/models/stream_preview.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/neural_engine_selector.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/views.dart';
import 'package:rtchat/screens/home.dart';
import 'package:rtchat/screens/onboarding.dart';
import 'package:rtchat/screens/settings/activity_feed.dart';
import 'package:rtchat/screens/settings/audio_sources.dart';
import 'package:rtchat/screens/settings/backup.dart';
import 'package:rtchat/screens/settings/chat_history.dart';
import 'package:rtchat/screens/settings/default_channels.dart';
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
import 'package:rtchat/screens/settings/twitch/badges.dart';
import 'package:rtchat/themes.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await StreamingSharedPreferences.instance;
  final voicePacks = VoicePackRepository(
      directory: Directory(
          '${(await getApplicationSupportDirectory()).path}/voice_packs'));

  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // persistence isn't useful to us since we're using Firestore as an event
  // stream and it uses memory/cache space.
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: false);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));

  AudioPlayer.global.setAudioContext(AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
    ),
  ));
  runApp(App(prefs: prefs, voicePacks: voicePacks));
}

class App extends StatefulWidget {
  final StreamingSharedPreferences prefs;

  /// The installed neural voice packs: with one installed, chat is read with
  /// its voice. Without a repository, only with the system voices.
  final VoicePackRepository? voicePacks;

  static final observer =
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);

  const App({super.key, required this.prefs, this.voicePacks});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _isDiscoModeRunning = false;
  Timer? _discoModeTimer;
  NeuralEngineSelector? _neuralEngineSelector;

  @override
  void dispose() {
    _neuralEngineSelector?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserModel()),
        ChangeNotifierProvider(create: (context) {
          final model = ActivityFeedModel.fromJson(jsonDecode(widget.prefs
              .getString("activity_feed", defaultValue: '{}')
              .getValue()));
          return model
            ..addListener(() {
              widget.prefs
                  .setString("activity_feed", jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProvider(create: (context) {
          final model = LayoutModel.fromJson(jsonDecode(
              widget.prefs.getString("layout", defaultValue: '{}').getValue()));
          return model
            ..addListener(() {
              widget.prefs.setString('layout', jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProxyProvider<UserModel, ViewsModel>(
          create: (context) {
            final model = ViewsModel.fromJson(jsonDecode(widget.prefs
                .getString("views", defaultValue: '{}')
                .getValue()));
            return model
              ..addListener(() {
                widget.prefs.setString('views', jsonEncode(model.toJson()));
              });
          },
          update: (context, userModel, model) => model!..update(userModel),
        ),
        ChangeNotifierProxyProvider<ViewsModel, TtsModel>(
          create: (context) {
            final model = TtsModel.fromJson(jsonDecode(
                widget.prefs.getString("tts", defaultValue: '{}').getValue()));
            final voicePacks = widget.voicePacks;
            if (voicePacks != null) {
              _neuralEngineSelector = NeuralEngineSelector(
                repository: voicePacks,
                tts: model,
                reportError: (error, stack) =>
                    FirebaseCrashlytics.instance.recordError(error, stack),
              )..start();
            }
            return model
              ..addListener(() {
                widget.prefs.setString('tts', jsonEncode(model.toJson()));
              });
          },
          update: (context, views, model) => model!..update(views),
        ),
        ChangeNotifierProxyProvider2<ViewsModel, TtsModel, MessagesModel>(
          create: (context) {
            final model = MessagesModel.fromJson(
              jsonDecode(widget.prefs
                  .getString("message_config", defaultValue: '{}')
                  .getValue()),
            );
            final player = AudioPlayer();
            model.onMessagePing = () {
              // don't play alerts while the app is in the background.
              if (WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed) {
                player.play(AssetSource('message-sound.wav'));
              }
            };
            model.channels =
                Provider.of<ViewsModel>(context, listen: false).channels;
            model.tts = Provider.of<TtsModel>(context, listen: false);
            return model
              ..addListener(() {
                if (model.isLive && model.messages.isNotEmpty) {
                  final message = model.messages.last;
                  if (message is ChatMessage && message.message == "!disco") {
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
          update: (context, views, ttsModel, model) {
            model!.channels = views.channels;
            model.tts = ttsModel;
            return model;
          },
          lazy: false,
        ),
        ChangeNotifierProvider(create: (context) {
          final model = QuickLinksModel.fromJson(jsonDecode(widget.prefs
              .getString("quick_links", defaultValue: '{}')
              .getValue()));
          return model
            ..addListener(() {
              widget.prefs.setString('quick_links', jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProvider(create: (context) {
          final model = StyleModel.fromJson(jsonDecode(
              widget.prefs.getString("style", defaultValue: '{}').getValue()));
          return model
            ..addListener(() {
              widget.prefs.setString('style', jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProvider(create: ((context) {
          final model = QRModel.fromJson(jsonDecode(
              widget.prefs.getString("qr", defaultValue: '{}').getValue()));

          return model
            ..addListener(() {
              widget.prefs.setString('qr', jsonEncode(model.toJson()));
            });
        })),
        ChangeNotifierProvider(create: (context) {
          final model = CommandsModel.fromJson(jsonDecode(widget.prefs
              .getString("commands", defaultValue: '{}')
              .getValue()));
          return model
            ..addListener(() {
              widget.prefs.setString("commands", jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProvider(create: (context) {
          final model = EventSubConfigurationModel.fromJson(jsonDecode(widget
              .prefs
              .getString("event_sub_configs", defaultValue: '{}')
              .getValue()));
          return model
            ..addListener(() {
              widget.prefs
                  .setString('event_sub_configs', jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProxyProvider<ViewsModel, TwitchBadgeModel>(
            create: (context) {
          final model = TwitchBadgeModel.fromJson(jsonDecode(widget.prefs
              .getString("twitch_badge", defaultValue: '{}')
              .getValue()));
          model.channel =
              Provider.of<ViewsModel>(context, listen: false).primaryChannel;
          return model
            ..addListener(() {
              widget.prefs
                  .setString('twitch_badge', jsonEncode(model.toJson()));
            });
        }, update: (context, views, model) {
          model!.channel = views.primaryChannel;
          return model;
        }),
        ChangeNotifierProxyProvider<UserModel, AudioModel>(
            create: (context) {
              final model = AudioModel.fromJson(jsonDecode(widget.prefs
                  .getString("audio", defaultValue: '{}')
                  .getValue()));
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
          final model = StreamPreviewModel.fromJson(jsonDecode(widget.prefs
              .getString("stream_preview", defaultValue: '{}')
              .getValue()));
          return model
            ..addListener(() {
              widget.prefs
                  .setString('stream_preview', jsonEncode(model.toJson()));
            });
        }),
      ],
      child: Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
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
              return Consumer2<UserModel, ViewsModel>(
                builder: (context, userModel, views, child) {
                  if (userModel.isLoading) {
                    // don't show anything yet.
                    return Container();
                  }
                  final channel = views.primaryChannel;
                  if (channel == null) {
                    return OnboardingScreen(onChannelSelect: views.openChannel);
                  }
                  return HomeScreen(
                      isDiscoModeEnabled: _isDiscoModeRunning,
                      channel: channel,
                      onChannelSelect: views.openChannel);
                },
              );
            },
            '/settings': (context) => const SettingsScreen(),
            '/settings/badges': (context) => const TwitchBadgesScreen(),
            '/settings/default-channels': (context) =>
                const DefaultChannelsScreen(),
            '/settings/activity-feed': (context) => const ActivityFeedScreen(),
            '/settings/audio-sources': (context) => const AudioSourcesScreen(),
            '/settings/chat-history': (context) => const ChatHistoryScreen(),
            '/settings/text-to-speech': (context) => const TextToSpeechScreen(),
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
