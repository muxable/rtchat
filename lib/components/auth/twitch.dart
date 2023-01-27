import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/user.dart';

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SignInWithTwitch extends StatelessWidget {
  final void Function()? onStart;
  final void Function()? onComplete;

  const SignInWithTwitch({
    Key? key,
    this.onStart,
    this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(const Color(0xFF6441A5)),
      ),
      child: Text(AppLocalizations.of(context)!.signInWithTwitch),
      onPressed: () async {
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
