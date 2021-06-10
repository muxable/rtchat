import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_panel.dart';
import 'package:rtchat/components/settings_button.dart';
import 'package:rtchat/components/title_bar.dart';
import 'package:rtchat/models/layout.dart';
import 'package:wakelock/wakelock.dart';

class PersistentWebViewWidget extends StatefulWidget {
  final void Function(InAppWebViewController) onWebViewCreated;
  final String initialUrl;

  PersistentWebViewWidget(
      {required this.onWebViewCreated, required this.initialUrl});

  @override
  _PersistentWebViewWidget createState() => _PersistentWebViewWidget();
}

class _PersistentWebViewWidget extends State<PersistentWebViewWidget>
    with AutomaticKeepAliveClientMixin<PersistentWebViewWidget> {
  final GlobalKey _webViewKey = GlobalKey();
  final InAppWebViewGroupOptions _webViewOptions = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(transparentBackground: true),
      android: AndroidInAppWebViewOptions(useHybridComposition: true),
      ios: IOSInAppWebViewOptions(allowsInlineMediaPlayback: true));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InAppWebView(
      key: _webViewKey,
      initialOptions: _webViewOptions,
      initialUrlRequest: URLRequest(url: Uri.parse(widget.initialUrl)),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  var _minimized = false;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
  }

  @override
  void dispose() {
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
      return Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            title: TitleBarWidget(),
            actions: [SettingsButtonWidget()]),
        body: Builder(builder: (context) {
          if (MediaQuery.of(context).orientation == Orientation.portrait) {
            return Column(children: [
              AnimatedContainer(
                height: _minimized
                    ? min(layoutModel.panelHeight, 0)
                    : layoutModel.panelHeight,
                duration: Duration(milliseconds: 400),
                child: Container(),
              ),
              Expanded(
                  child: ChannelPanelWidget(
                onScrollback: (isScrolled) {
                  setState(() {
                    _minimized = isScrolled;
                  });
                },
                onResize: (dy) {
                  layoutModel.updatePanelHeight(dy: dy);
                },
              )),
            ]);
          } else {
            return Container();
          }
        }),
      );
    });
  }
}
