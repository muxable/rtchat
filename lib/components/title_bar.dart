import 'package:flutter/material.dart';
import 'package:rtchat/components/quick_links_bar.dart';
import 'package:rtchat/components/settings_button.dart';

class TitleBarWidget extends StatelessWidget {
  const TitleBarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 56,
        color: Theme.of(context).primaryColor,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(
            width: 168,
            child: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.calendar_view_day)),
                Tab(icon: Icon(Icons.preview)),
              ],
            ),
          ),
          QuickLinksBar(),
          const SettingsButtonWidget()
        ]));
  }
}
