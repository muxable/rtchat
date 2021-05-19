import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/screens/add_tab.dart';
import 'package:rtchat/screens/settings.dart';
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
    Wakelock.enable();
  }

  @override
  void dispose() {
    Wakelock.disable();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
      final title = Consumer<UserModel>(builder: (context, model, child) {
        if (model.channels.isNotEmpty) {
          // TODO: Implement multi-channel rendering.
          return Text("/${model.channels.first.channel}");
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
        Consumer<UserModel>(builder: (context, model, child) {
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
                await Provider.of<ChatHistoryModel>(context, listen: false)
                    .subscribe({});
                model.signOut();
              }
            },
            itemBuilder: (context) {
              final options = {'Add Browser Panel', 'Settings', 'Sign Out'};
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

      final input = Container(
        color: Colors.grey.shade900,
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
          child: TextField(
            controller: _textEditingController,
            textInputAction: TextInputAction.send,
            maxLines: null,
            decoration: InputDecoration(
              hintText: "Send a message...",
            ),
            onChanged: (text) {
              final filtered = text.replaceAll('\n', ' ');
              if (filtered == text) {
                return;
              }
              _textEditingController.value = TextEditingValue(
                  text: filtered,
                  selection: TextSelection.fromPosition(TextPosition(
                      offset: _textEditingController.text.length)));
            },
            onSubmitted: (value) async {
              value = value.trim();
              if (value.isEmpty) {
                return;
              }
              final model = Provider.of<UserModel>(context, listen: false);
              model.send(model.channels.first, value);
              _textEditingController.clear();
            },
          ),
        ),
      );

      if (layoutModel.tabs.length == 0) {
        return Scaffold(
          appBar: AppBar(title: title, actions: actions),
          body: Column(children: [Expanded(child: ChatPanelWidget()), input]),
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
                            _webViewControllers[index]
                                ?.loadUrl(layoutModel.tabs[index].uri);
                          },
                          icon: Icon(Icons.refresh)),
                      IconButton(
                          onPressed: () {
                            final index = _tabController.index;
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                      'Remove tab ${layoutModel.tabs[index].label}?'),
                                  actions: [
                                    TextButton(
                                      child: Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: Text('Confirm'),
                                      onPressed: () {
                                        layoutModel.removeTab(index);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
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
              child: Divider(thickness: 16),
            ),
            Expanded(child: ChatPanelWidget()),
            input,
          ],
        ),
      );
    });
  }
}
