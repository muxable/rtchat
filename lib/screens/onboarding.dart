import 'package:flutter/material.dart';
import 'package:rtchat/components/auth/twitch.dart';
import 'package:rtchat/components/channel_search_bottom_sheet.dart';
import 'package:rtchat/models/channels.dart';

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class OnboardingScreen extends StatelessWidget {
  final void Function(Channel) onChannelSelect;

  const OnboardingScreen({Key? key, required this.onChannelSelect})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
      ),
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Center(
              child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Image(width: 160, image: AssetImage('assets/logo.png')),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 64),
                      child: Text("RealtimeChat",
                          style: Theme.of(context)
                              .textTheme
                              .headline6
                              ?.copyWith(color: Colors.white))),
                  const SizedBox(
                    width: 400,
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 64),
                        child: SignInWithTwitch()),
                  ),
                    Text("or",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white)),
                  SizedBox(
                    width: 400,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64),
                      child: ElevatedButton(
                          child: const Text(
                            "Continue without signing in",
                            textAlign: TextAlign.center,
                          ),
                        onPressed: () async {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            builder: (context) {
                              return DraggableScrollableSheet(
                                  initialChildSize: 0.7,
                                  minChildSize: 0.7,
                                  maxChildSize: 0.9,
                                  expand: false,
                                  builder: (context, controller) {
                                    return ChannelSearchBottomSheetWidget(
                                        onChannelSelect: onChannelSelect,
                                        controller: controller);
                                  });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          )),
    );
  }
}
