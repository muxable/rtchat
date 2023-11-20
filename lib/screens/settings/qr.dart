import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rtchat/models/qr_code.dart';
import 'package:rtchat/models/user.dart';

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
              height: querySize.height * 0.48,
              width: querySize.width * 0.85,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(querySize.width * 0.06),
                gradient: qrModel.currentGradient,
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: inviteLink,
                    embeddedImage: userChannel?.profilePicture,
                  ),
                  Text(
                    "/${userModel.userChannel?.displayName ?? ""}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
