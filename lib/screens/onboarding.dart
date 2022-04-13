import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:rtchat/components/auth/twitch.dart';
import 'package:rtchat/models/channels.dart';

final _search = FirebaseFunctions.instance.httpsCallable("search");

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SearchResult {
  final String channelId;
  final String provider;
  final String displayName;
  final bool isOnline;
  final String imageUrl;
  final String title;

  const SearchResult(
      {required this.channelId,
      required this.provider,
      required this.displayName,
      required this.isOnline,
      required this.imageUrl,
      required this.title});
}

class CollapsibleWidget extends StatefulWidget {
  final Widget child;
  final bool expand;

  const CollapsibleWidget({Key? key, required this.expand, required this.child})
      : super(key: key);

  @override
  _CollapsibleWidgetState createState() => _CollapsibleWidgetState();
}

class _CollapsibleWidgetState extends State<CollapsibleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController expandController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    expandController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    animation = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastOutSlowIn,
    );
    if (widget.expand) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  void didUpdateWidget(CollapsibleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expand) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
        axisAlignment: 1.0, sizeFactor: animation, child: widget.child);
  }
}

class SearchDivider extends StatelessWidget {
  const SearchDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Flexible(child: Divider()),
      Padding(
          padding: const EdgeInsets.all(16),
          child: Text("or search for a channel",
              style: Theme.of(context)
                  .textTheme
                  .subtitle1)),
      const Flexible(child: Divider()),
    ]);
  }
}

class OnboardingScreen extends StatefulWidget {
  final void Function(Channel) onChannelSelect;

  const OnboardingScreen({Key? key, required this.onChannelSelect})
      : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _searchController = TextEditingController(text: "");
  var _value = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CollapsibleWidget(
                expand: _value == "",
                child: Column(children: [
                  const Image(width: 160, image: AssetImage('assets/logo.png')),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 64),
                      child: Text("RealtimeChat",
                          style: Theme.of(context)
                              .textTheme
                              .headline6)),
                  const SizedBox(
                    width: 400,
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 64),
                        child: SignInWithTwitch()),
                  ),
                  const SearchDivider(),
                ])),
            TextField(
                controller: _searchController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Text("twitch.tv/",
                            style: TextStyle(color: Colors.grey[700]))),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    suffixIcon: GestureDetector(
                        child: const Icon(Icons.cancel),
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _value = "";
                          });
                        }),
                    hintText: "muxfd",
                    fillColor: Colors.white70),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  setState(() {
                    _value = value;
                  });
                }),
            Flexible(
                child: CollapsibleWidget(
                    expand: _value != "",
                    child: FutureBuilder<List<SearchResult>?>(
                        future: _search(_value).then((result) {
                          return (result.data as List<dynamic>)
                              .map((data) => SearchResult(
                                  channelId: data['channelId'],
                                  provider: data['provider'],
                                  displayName: data['displayName'],
                                  isOnline: data['isOnline'],
                                  imageUrl: data['imageUrl'],
                                  title: data['title']))
                              .toList();
                        }),
                        initialData: null,
                        builder: (context, snapshot) {
                          final data = snapshot.data;
                          if (data == null) {
                            return const CircularProgressIndicator();
                          } else {
                            return ListView(
                              children: data
                                  .map((result) => ListTile(
                                      leading: Container(
                                        child: CircleAvatar(
                                          backgroundImage:
                                              NetworkImageWithRetry(
                                                  result.imageUrl),
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: result.isOnline
                                                ? Colors.green
                                                : Colors.red,
                                            width: 2.0,
                                          ),
                                        ),
                                      ),
                                      title: Text(result.displayName),
                                      subtitle: Text(result.title),
                                      onTap: () {
                                        widget.onChannelSelect(Channel(
                                          "twitch",
                                          result.channelId,
                                          result.displayName,
                                        ));
                                      }))
                                  .toList(),
                            );
                          }
                        }))),
          ],
        ),
      ),
    ));
  }
}
