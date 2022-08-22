import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/adapters/donations.dart';
import 'package:rtchat/models/user.dart';

class DonationsScreen extends StatelessWidget {
  const DonationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Third-party donations")),
        body: Consumer<UserModel>(
          builder: (context, userModel, child) {
            final userId = userModel.user?.uid;
            return ListView(
              children: [
                const ListTile(
                  leading: Image(image: AssetImage('assets/realtimecash.png')),
                  title: Text("RealtimeCash"),
                  subtitle: Text("Connect an ETH or MATIC wallet"),
                ),
                if (userId != null)
                  Padding(
                      padding: const EdgeInsets.only(left: 88, right: 16),
                      child: StreamBuilder<String?>(
                        stream: DonationsAdapter.instance
                            .forRealtimeChatAddress(userId: userId),
                        builder: (context, snapshot) {
                          return TextField(
                              controller: TextEditingController()
                                ..text = snapshot.data ?? "",
                              readOnly: true,
                              decoration: InputDecoration(
                                  hintText: "Wallet address",
                                  suffixIcon: IconButton(
                                      icon: const Icon(Icons.qr_code_scanner),
                                      onPressed: () {
                                        showModalBottomSheet<void>(
                                            context: context,
                                            builder: (context) {
                                              return MobileScanner(
                                                  allowDuplicates: false,
                                                  onDetect: (barcode, args) {
                                                    Navigator.of(context).pop();
                                                  });
                                            });
                                      })),
                              keyboardType: TextInputType.url);
                        },
                      )),
                const Divider(),
                ListTile(
                  leading:
                      const Image(image: AssetImage('assets/streamlabs.png')),
                  title: const Text("Streamlabs"),
                  subtitle: const Text("See your Streamlabs donations"),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final userModel =
                        Provider.of<UserModel>(context, listen: false);
                    final idToken =
                        await FirebaseAuth.instance.currentUser?.getIdToken();
                    final provider = userModel.userChannel?.provider;
                    if (provider == null) {
                      messenger.showSnackBar(const SnackBar(
                          content: Text(
                              "Some strange authentication error occurred. Try signing out, or ask on Discord?")));
                      return;
                    }
                    final result = await FlutterWebAuth.authenticate(
                        url:
                            "https://chat.rtirl.com/auth/streamlabs/redirect?token=$idToken&provider=$provider",
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
            );
          },
        ));
  }
}
