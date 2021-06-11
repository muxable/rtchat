import 'package:flutter/material.dart';

class TitleBarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TabBar(
          tabs: [
            Tab(icon: Icon(Icons.calendar_view_day)),
            Tab(icon: Icon(Icons.preview)),
          ],
        ),
      ),
      Expanded(child: Container()),
    ]);
  }
}
