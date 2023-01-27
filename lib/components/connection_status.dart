import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final _delay = const Duration(seconds: 5);

  const ConnectionStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // add a sentinel listener so Firebase connects to the db.
        StreamBuilder(
            stream: FirebaseDatabase.instance.ref('sentinel').onValue,
            builder: (context, snapshot) => Container()),
        StreamBuilder<DateTime?>(
            stream: FirebaseDatabase.instance
                .ref('.info/connected')
                .onValue
                .map((event) {
              return event.snapshot.value == false ? DateTime.now() : null;
            }),
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) {
                return Container();
              }
              return RebuildableWidget(
                  rebuildAt: {data.add(_delay)},
                  builder: (context) {
                    if (DateTime.now().difference(data) < _delay) {
                      return Container();
                    }
                    return Container(
                      width: double.infinity,
                      height: 48,
                      alignment: Alignment.center,
                      color: Colors.red,
                      child: Text(AppLocalizations.of(context)!.reconnecting),
                    );
                  });
            }),
      ],
    );
  }
}
