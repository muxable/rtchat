import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/components/auth/twitch.dart';
import 'package:rtchat/components/channel_search_bottom_sheet.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/themes.dart';

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class OnboardingScreen extends StatelessWidget {
  final void Function(Channel) onChannelSelect;

  const OnboardingScreen({Key? key, required this.onChannelSelect})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Themes.darkTheme,
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Image(
                        width: 160, image: AssetImage('assets/logo.png')),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 64),
                        child: Text("RealtimeChat",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.white))),
                    LoginOptionsWidget(onChannelSelect: onChannelSelect),
                  ],
                ),
              ),
            ),
          )),
    );
  }
}

class LoginOptionsWidget extends StatefulWidget {
  final void Function(Channel) onChannelSelect;

  const LoginOptionsWidget({Key? key, required this.onChannelSelect})
      : super(key: key);

  @override
  State<LoginOptionsWidget> createState() => _LoginOptionsWidgetState();
}

class _LoginOptionsWidgetState extends State<LoginOptionsWidget> {
  var _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    return Column(children: [
      SizedBox(
        width: 400,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: SignInWithTwitch(
              onStart: () {
                setState(() {
                  _isLoading = true;
                });
              },
              onComplete: () {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _isLoading = false;
                });
              },
            )),
      ),
      Text(AppLocalizations.of(context)!.or,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.white)),
      SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64),
          child: ElevatedButton(
            child: Text(
              AppLocalizations.of(context)!.continueAsGuest,
              textAlign: TextAlign.center,
            ),
            onPressed: () async {
              FirebaseAnalytics.instance.logLogin(loginMethod: "anonymous");
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return DraggableScrollableSheet(
                      initialChildSize: 0.8,
                      maxChildSize: 0.9,
                      expand: false,
                      builder: (context, controller) {
                        return ChannelSearchBottomSheetWidget(
                            onChannelSelect: widget.onChannelSelect,
                            controller: controller);
                      });
                },
              );
            },
          ),
        ),
      )
    ]);
  }
}
