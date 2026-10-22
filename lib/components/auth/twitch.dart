import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/auth/companion_auth.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/user.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Signs in with a provider's account.
class SignInButton extends StatelessWidget {
  final String provider;
  final void Function()? onStart;
  final void Function()? onComplete;

  const SignInButton({
    super.key,
    required this.provider,
    this.onStart,
    this.onComplete,
  });

  static const _colors = {
    Providers.twitch: Color(0xFF6441A5),
    Providers.kick: Color(0xFF53FC18),
  };

  String _label(AppLocalizations l10n) {
    switch (provider) {
      case Providers.kick:
        return l10n.signInWithKick;
      default:
        return l10n.signInWithTwitch;
    }
  }

  /// Keeps the probes' web views alive until they answer. Otherwise the
  /// controller is garbage collected, the plugin tears down the native web
  /// view and the page never finishes loading.
  static final _probes = <WebViewController>{};

  static Future<bool> isGlobalThisSupported() async {
    final completer = Completer<bool>();
    final controller =
        WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
    _probes.add(controller);
    // Read the result directly instead of posting it to a JavaScript channel:
    // WKWebView doesn't inject channels into about:blank, so on iOS the
    // script threw and the probe never answered.
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) async {
          if (completer.isCompleted) {
            return;
          }
          try {
            final result = await controller.runJavaScriptReturningResult(
              "typeof globalThis !== 'undefined'",
            );
            completer.complete(result == true || result == "true");
          } catch (e) {
            // don't block sign in if the probe itself fails.
            completer.complete(true);
          }
        },
      ),
    );
    controller.loadRequest(Uri.parse("about:blank"));
    return completer.future.whenComplete(() => _probes.remove(controller));
  }

  @override
  Widget build(BuildContext context) {
    final color = _colors[provider] ?? Theme.of(context).colorScheme.primary;
    return ElevatedButton(
      style: ButtonStyle(backgroundColor: WidgetStateProperty.all(color)),
      child: Text(
        _label(AppLocalizations.of(context)!),
        style: TextStyle(
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        ),
      ),
      onPressed: () async {
        final isGlobalThisSupported =
            await SignInButton.isGlobalThisSupported();
        if (!context.mounted) {
          return;
        }
        if (!isGlobalThisSupported) {
          // we need to sign in via QR code, so show a bottom sheet with a QR code.
          // generate a uuid
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return CompanionAuthWidget(provider: provider, isTooOld: true);
            },
          );
          return;
        }
        final user = Provider.of<UserModel>(context, listen: false);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        final navigator = Navigator.of(context);
        final localizations = MaterialLocalizations.of(context);
        final modalBarrierColor =
            Theme.of(context).bottomSheetTheme.modalBarrierColor;
        final navigatorContext = navigator.context;
        if (!navigatorContext.mounted) {
          return;
        }
        final capturedThemes = InheritedTheme.capture(
          from: context,
          to: navigatorContext,
        );
        final retrySnackbar = SnackBar(
          content: Text(AppLocalizations.of(context)!.signInError),
          action: SnackBarAction(
            label: "Sign in with another device",
            onPressed: () {
              navigator.push(
                ModalBottomSheetRoute(
                  builder: (context) {
                    return CompanionAuthWidget(
                      provider: provider,
                      isTooOld: false,
                    );
                  },
                  capturedThemes: capturedThemes,
                  isScrollControlled: true,
                  barrierOnTapHint: localizations.scrimOnTapHint(
                    localizations.bottomSheetLabel,
                  ),
                  modalBarrierColor: modalBarrierColor,
                ),
              );
            },
          ),
        );
        onStart?.call();
        try {
          await FirebaseAnalytics.instance.logLogin(loginMethod: provider);
          final url = Uri.https('chat.rtirl.com', '/auth/$provider/redirect');
          final result = await FlutterWebAuth2.authenticate(
            url: url.toString(),
            callbackUrlScheme: "com.rtirl.chat",
          );
          final token = Uri.parse(result).queryParameters['token'];
          if (token != null) {
            await user.signIn(provider, token);
            // there's a bit of lag between the sign in call completing and the
            // ui updating to the homepage. delay the onComplete handler so any
            // loading indicator still shows.
            Timer(const Duration(seconds: 3), () {
              onComplete?.call();
            });
          } else {
            onComplete?.call();
            scaffoldMessenger.showSnackBar(retrySnackbar);
          }
        } catch (e) {
          onComplete?.call();
          if (!(e is PlatformException && e.code == "CANCELLED")) {
            scaffoldMessenger.showSnackBar(retrySnackbar);
          }
        }
      },
    );
  }
}

class SignInWithTwitch extends StatelessWidget {
  final void Function()? onStart;
  final void Function()? onComplete;

  const SignInWithTwitch({super.key, this.onStart, this.onComplete});

  @override
  Widget build(BuildContext context) => SignInButton(
    provider: Providers.twitch,
    onStart: onStart,
    onComplete: onComplete,
  );
}

class SignInWithKick extends StatelessWidget {
  final void Function()? onStart;
  final void Function()? onComplete;

  const SignInWithKick({super.key, this.onStart, this.onComplete});

  @override
  Widget build(BuildContext context) => SignInButton(
    provider: Providers.kick,
    onStart: onStart,
    onComplete: onComplete,
  );
}
