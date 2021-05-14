import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/twitch_user.dart';
import 'package:rtchat/screens/add_tab_screen.dart';
import 'package:rtchat/screens/settings_screen.dart';
import 'package:wakelock/wakelock.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _textEditingController = TextEditingController();
  late TabController _tabController;
  final Map<int, WebViewController> _webViewControllers = {};
  var _locked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    Provider.of<TwitchUserModel>(context, listen: false)
        .addListener(bindChatHistory);
    bindChatHistory(); // fire it once.
    Wakelock.enable();
  }

  @override
  void dispose() {
    Wakelock.disable();
    Provider.of<TwitchUserModel>(context, listen: false)
        .removeListener(bindChatHistory);
    _tabController.dispose();
    super.dispose();
  }

  void bindChatHistory() {
    final username =
        Provider.of<TwitchUserModel>(context, listen: false).username;
    if (username != null) {
      Provider.of<ChatHistoryModel>(context, listen: false)
          .subscribe("twitch", username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
      final title = Consumer<TwitchUserModel>(builder: (context, model, child) {
        if (model.isSignedIn() && model.username != null) {
          return Text("/${model.username}");
        }
        return Text("RealtimeChat");
      });

      final actions = [
        layoutModel.tabs.length == 0
            ? Container()
            : IconButton(
                icon: Icon(_locked ? Icons.lock : Icons.lock_open),
                tooltip: "Lock layout",
                onPressed: () {
                  setState(() {
                    _locked = !_locked;
                  });
                }),
        Consumer<ChatHistoryModel>(builder: (context, chatHistoryModel, child) {
          return IconButton(
              icon: Icon(chatHistoryModel.ttsEnabled
                  ? Icons.record_voice_over
                  : Icons.voice_over_off),
              tooltip: "Text to speech",
              onPressed: () {
                chatHistoryModel.ttsEnabled = !chatHistoryModel.ttsEnabled;
              });
        }),
        Consumer<TwitchUserModel>(builder: (context, model, child) {
          return PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == "Add Browser Panel") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return AddTabScreen();
                  }),
                );
              } else if (value == "Settings") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return SettingsScreen();
                  }),
                );
              } else if (value == "Sign Out") {
                model.clearToken();
              }
            },
            itemBuilder: (context) {
              final options = model.isSignedIn()
                  ? {'Add Browser Panel', 'Settings', 'Sign Out'}
                  : {'Add Browser Panel', 'Settings'};
              return options.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          );
        })
      ];

      final input = Padding(
        padding: EdgeInsets.all(16),
        child: TextField(
          controller: _textEditingController,
          textInputAction: TextInputAction.send,
          maxLines: null,
          decoration: InputDecoration(
            hintText: "Send a message...",
          ),
          onChanged: (text) {
            _textEditingController.text = text.replaceAll('\n', ' ');
          },
          onSubmitted: (value) async {
            value = value.trim();
            if (value.isEmpty) {
              return;
            }
            Provider.of<TwitchUserModel>(context, listen: false).send(value);
            _textEditingController.clear();
          },
        ),
      );

      if (layoutModel.tabs.length == 0) {
        return Scaffold(
          appBar: AppBar(title: title, actions: actions),
          body: Column(children: [Expanded(child: ChatPanel()), input]),
        );
      }

      if (_tabController.length != layoutModel.tabs.length) {
        _tabController.dispose();
        _tabController =
            TabController(length: layoutModel.tabs.length, vsync: this);
      }

      return Scaffold(
        appBar: AppBar(
            title: title,
            bottom: _locked
                ? null
                : PreferredSize(
                    child: Row(children: [
                      Expanded(
                          child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabs: layoutModel.tabs
                            .map((tab) => Tab(text: tab.label))
                            .toList(),
                      )),
                      IconButton(
                          onPressed: () {
                            final index = _tabController.index;
                            _webViewControllers[index]?.loadUrl(
                                layoutModel.tabs[index].uri.toString());
                          },
                          icon: Icon(Icons.refresh)),
                      IconButton(
                          onPressed: () {
                            final index = _tabController.index;
                            layoutModel.removeTab(index);
                          },
                          icon: Icon(Icons.close)),
                    ]),
                    preferredSize: Size.fromHeight(56),
                  ),
            actions: actions),
        body: Column(
          children: [
            Container(
              height: layoutModel.panelHeight,
              child: TabBarView(
                controller: _tabController,
                children: layoutModel.tabs.asMap().entries.map((entry) {
                  return WebView(
                      onWebViewCreated: (controller) {
                        _webViewControllers[entry.key] = controller;
                      },
                      javascriptMode: JavascriptMode.unrestricted,
                      allowsInlineMediaPlayback: true,
                      initialMediaPlaybackPolicy:
                          AutoMediaPlaybackPolicy.always_allow,
                      initialUrl: entry.value.uri.toString());
                }).toList(),
              ),
            ),
            GestureDetector(
              onVerticalDragUpdate: (details) {
                if (_locked) {
                  return;
                }
                layoutModel.updatePanelHeight(dy: details.delta.dy);
              },
              child: Divider(thickness: 5),
            ),
            Expanded(child: ChatPanel()),
            input,
          ],
        ),
      );
    });
  }
}
