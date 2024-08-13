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

    final isLandScape = querySize.width > querySize.height;

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
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: querySize.height * 0.03,
                    ),
                    child: Container(
                      padding: EdgeInsets.only(
                        top: querySize.height * 0.02,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: inviteLink,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                          CircleAvatar(
                            radius: isLandScape ? 25 : 30,
                            backgroundImage: userChannel?.profilePicture,
                          ),
                        ],
                      ),
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
