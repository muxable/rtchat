import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/auth/companion_auth.dart';
import 'package:rtchat/models/user.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SignInWithTwitch extends StatelessWidget {
  final void Function()? onStart;
  final void Function()? onComplete;
  final sessionUuid = const Uuid().v4();

  SignInWithTwitch({
    super.key,
    this.onStart,
    this.onComplete,
  });

  static Future<bool> isGlobalThisSupported() async {
    final completer = Completer<bool>();
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.addJavaScriptChannel("response", onMessageReceived: (message) {
      completer.complete(message.message == "true");
    });
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          controller.runJavaScript(
              "response.postMessage(typeof globalThis !== 'undefined');");
        },
      ),
    );
    controller.loadRequest(Uri.parse("about:blank"));
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(const Color(0xFF6441A5)),
      ),
      child: Text(AppLocalizations.of(context)!.signInWithTwitch,
          style: const TextStyle(
            color: Colors.white,
          )),
      onPressed: () async {
        final isGlobalThisSupported =
            await SignInWithTwitch.isGlobalThisSupported();
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
              return const CompanionAuthWidget(provider: "twitch");
            },
          );
          return;
        }
        final user = Provider.of<UserModel>(context, listen: false);
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final retrySnackbar =
            SnackBar(content: Text(AppLocalizations.of(context)!.signInError));
        onStart?.call();
        try {
          await FirebaseAnalytics.instance.logLogin(loginMethod: "twitch");
          final result = await FlutterWebAuth.authenticate(
              url: url.toString(), callbackUrlScheme: "com.rtirl.chat");
          final token = Uri.parse(result).queryParameters['token'];
          if (token != null) {
            await user.signIn(token);
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
