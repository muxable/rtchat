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
      final inviteLink =
          "https://www.twitch.tv/${userModel.userChannel?.displayName ?? ""}";

      return Consumer<QRModel>(
        builder: (context, qrModel, child) {
          return GestureDetector(
            onTap: () {
              qrModel.changeGradient();
            },
            child: Column(
              children: [
                Container(
                  height: querySize.height * 0.42,
                  width: querySize.width * 0.85,
                  padding: EdgeInsets.only(top: querySize.height * 0.01),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(querySize.width * 0.06),
                    color: Colors.white,
                  ),
                  child: QrImageView(
                    data: inviteLink,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color.fromARGB(255, 18, 135, 135),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Color(0xff1a5441),
                    ),
                    embeddedImage: userChannel?.profilePicture,
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(60, 60),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: querySize.height * 0.01),
                  child: Text(
                    "/${userModel.userChannel?.displayName ?? ""}",
                    overflow: TextOverflow.fade,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
