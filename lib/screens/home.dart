import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/components/statistics_bar.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/screens/add_tab.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
  final _textEditingController = TextEditingController();
  late TabController _tabController;
  final Map<int, InAppWebViewController> _webViewControllers = {};
  var _minimized = false;

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
      final title = Consumer<UserModel>(builder: (context, userModel, child) {
        if (userModel.channels.isNotEmpty) {
          // TODO: Implement multi-channel rendering.
          return Text(
            "/${userModel.channels.first.displayName}",
            overflow: TextOverflow.fade,
          );
        }
        return Text("RealtimeChat");
      });

      final actions = [
        Consumer<UserModel>(builder: (context, userModel, child) {
          if (userModel.channels.isNotEmpty) {
            // TODO: Implement multi-channel rendering.
            final channel = userModel.channels.first;
            return StatisticsBarWidget(
                provider: channel.provider,
                channelId: channel.channelId,
                isStatsVisible: layoutModel.isStatsVisible);
          }
          return Container();
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
              if (value == "Settings") {
                Navigator.pushNamed(context, "/settings");
              } else if (value == "Lock Layout" || value == "Unlock Layout") {
                layoutModel.locked = !layoutModel.locked;
              } else if (value == "Sign Out") {
                await Provider.of<ChatHistoryModel>(context, listen: false)
                    .subscribe({});
                model.signOut();
              }
            },
            itemBuilder: (context) {
              final options = {
                layoutModel.locked ? "Unlock Layout" : "Lock Layout",
                'Settings',
                'Sign Out'
              };
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

      final input = layoutModel.isInputLockable && layoutModel.locked
          ? Container()
          : Container(
              color: Theme.of(context).primaryColor,
              child: SafeArea(
                top: false,
                bottom: true,
                left: false,
                right: false,
                minimum: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _textEditingController,
                      textInputAction: TextInputAction.send,
                      maxLines: null,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          hintText: "Send a message...",
                          hintStyle: TextStyle(color: Colors.white),
                          border: InputBorder.none),
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
                        final model =
                            Provider.of<UserModel>(context, listen: false);
                        model.send(model.channels.first, value);
                        _textEditingController.clear();
                      },
                    ),
                  ),
                  Consumer<UserModel>(builder: (context, userModel, child) {
                    return PopupMenuButton<String>(
                      icon: Icon(Icons.build),
                      onSelected: (value) async {
                        if (value == "Clear Chat") {
                          final channel = userModel.channels.first;
                          FirebaseFunctions.instance.httpsCallable("clear")({
                            "provider": channel.provider,
                            "channelId": channel.channelId,
                          });
                          Provider.of<ChatHistoryModel>(context, listen: false)
                              .clear();
                        } else if (value == "Raid") {}
                      },
                      itemBuilder: (context) {
                        final options = {'Clear Chat'};
                        return options.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(choice),
                          );
                        }).toList();
                      },
                    );
                  }),
                ]),
              ),
            );

      final chatPanel = ChatPanelWidget(
        onScrollback: (isScrolling) {
          setState(() {
            _minimized = isScrolling;
          });
        },
      );

      if (_tabController.length != layoutModel.tabs.length) {
        _tabController.dispose();
        _tabController =
            TabController(length: layoutModel.tabs.length, vsync: this);
      }

      return Scaffold(
        appBar: AppBar(
            leading: const Padding(
              padding: EdgeInsets.all(12),
              child: Image(image: AssetImage('assets/TwitchGlitchPurple.png')),
            ),
            title: title,
            actions: actions,
            bottom: layoutModel.locked
                ? null
                : PreferredSize(
                    preferredSize: Size.fromHeight(56),
                    child: Builder(builder: (context) {
                      if (layoutModel.tabs.length == 0) {
                        return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) {
                                        return AddTabScreen();
                                      }),
                                    );
                                  },
                                  icon: Icon(Icons.add, color: Colors.white)),
                            ]);
                      }
                      return Row(children: [
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return AddTabScreen();
                                }),
                              );
                            },
                            icon: Icon(Icons.add, color: Colors.white)),
                        IconButton(
                            onPressed: () {
                              final index = _tabController.index;
                              _webViewControllers[index]?.loadUrl(
                                  urlRequest: URLRequest(
                                      url: Uri.parse(
                                          layoutModel.tabs[index].uri)));
                            },
                            icon: Icon(Icons.refresh, color: Colors.white)),
                        IconButton(
                            onPressed: () {
                              final index = _tabController.index;
                              showDialog(
                                context: context,
                                builder: (context) {
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
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: Icon(Icons.close, color: Colors.white)),
                      ]);
                    }))),
        body: Column(
          children: [
            layoutModel.tabs.length == 0
                ? Container()
                : AnimatedContainer(
                    height: _minimized
                        ? min(layoutModel.panelHeight, 100)
                        : layoutModel.panelHeight,
                    duration: Duration(milliseconds: 400),
                    child: ClipRect(
                        child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minHeight: layoutModel.panelHeight,
                      maxHeight: layoutModel.panelHeight,
                      child: TabBarView(
                        controller: _tabController,
                        children: layoutModel.tabs.asMap().entries.map((entry) {
                          return PersistentWebViewWidget(
                            onWebViewCreated: (controller) {
                              _webViewControllers[entry.key] = controller;
                            },
                            initialUrl: entry.value.uri.toString(),
                          );
                        }).toList(),
                      ),
                    )),
                  ),
            layoutModel.tabs.length == 0
                ? Container()
                : GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (layoutModel.locked) {
                        return;
                      }
                      layoutModel.updatePanelHeight(dy: details.delta.dy);
                    },
                    child: Divider(thickness: layoutModel.locked ? 4 : 16),
                  ),
            Expanded(child: chatPanel),
            input,
          ],
        ),
      );
    });
  }
}
