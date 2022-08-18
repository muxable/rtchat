import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

class DonationsScreen extends StatelessWidget {
  const DonationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Third-party donations")),
      body: ListView(
        children: [
          ListTile(
            leading: const Image(image: AssetImage('assets/streamlabs.png')),
            title: const Text("Streamlabs"),
            subtitle: const Text("Link your Streamlabs account"),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final idToken =
                  await FirebaseAuth.instance.currentUser?.getIdToken();
              final result = await FlutterWebAuth.authenticate(
                  url:
                      "https://chat.rtirl.com/auth/streamlabs/redirect?token=$idToken",
                  callbackUrlScheme: "com.rtirl.chat");
              final token = Uri.parse(result).queryParameters['token'];
              if (token == null) {
                messenger.showSnackBar(const SnackBar(
                  content: Text(
                      "Hmm, that didn't work. Try again, or ask on Discord?"),
                ));
              }
            },
          )
        ],
      ),
    );
  }
}
