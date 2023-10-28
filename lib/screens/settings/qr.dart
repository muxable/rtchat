import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rtchat/models/qr_code.dart';
import 'package:rtchat/models/user.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR code")),
      body: Consumer2<UserModel, QRModel>(
        builder: ((context, userModel, qrModel, child) {
          final querySize = MediaQuery.of(context).size;

          return Column(
            children: [
              SizedBox(
                height: querySize.height * 0.05,
              ),
              const QRDisplay(),
              SizedBox(
                height: querySize.height * 0.05,
              ),
              const Divider(),
              Text(" QR Version",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  )),
              Slider.adaptive(
                value: qrModel.version,
                min: 3,
                max: 16,
                divisions: 13,
                label: "${qrModel.version.toInt()}",
                onChanged: (value) {
                  qrModel.size = value;
                },
              ),
              SwitchListTile.adaptive(
                title: const Text('Use  profile image in the qr'),
                value: qrModel.useProfile,
                onChanged: (value) {
                  qrModel.toggleProfileImage();
                },
              ),
            ],
          );
        }),
      ),
    );
  }
}

class QRDisplay extends StatelessWidget {
  const QRDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final querySize = MediaQuery.of(context).size;

    return Consumer<UserModel>(builder: (context, userModel, child) {
      final userChannel = userModel.userChannel;
      final inviteLink = "https://www.twitch.tv/muxfd${userChannel?.channelId}";

      return Consumer<QRModel>(
        builder: (context, qrModel, child) {
          return GestureDetector(
            onTap: () {
              qrModel.changeGradient();
            },
            child: Container(
              height: querySize.height * 0.45,
              width: querySize.width * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(querySize.width * 0.08),
                gradient: qrModel.currentGradient,
              ),
              child: Column(
                children: [
                  qrModel.useProfile
                      ? QrImageView(
                          data: inviteLink,
                          version: qrModel.version.toInt(),
                          embeddedImage: userChannel?.profilePicture,
                        )
                      : QrImageView(
                          data: inviteLink,
                          version: qrModel.version.toInt(),
                          embeddedImage:
                              userChannel?.profilePicture.placeholderImage,
                        ),
                  Text("@${userModel.userChannel?.displayName ?? ""} ",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
