import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/drawer/sliver_search_bar.dart';
import 'package:rtchat/components/drawer/sliver_title.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/chat_state.dart';

class LeftDrawerWidget extends StatefulWidget {
  final Channel channel;

  const LeftDrawerWidget({required this.channel, Key? key}) : super(key: key);

  @override
  State<LeftDrawerWidget> createState() => LeftDrawerWidgetState();
}

class LeftDrawerWidgetState extends State<LeftDrawerWidget> {
  String _search = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
      child: Consumer<ChatStateModel>(
        builder: (context, chatStateModel, snapshot) {
          final viewers = chatStateModel.viewers;
          if (viewers == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final filtered = viewers.query(_search);
          return SafeArea(
            top: false,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(top: 24),
                  sliver: SliverAppBar(
                      actions: const [SizedBox()],
                      //disable the drawer icon that appears on the right of the app bar
                      centerTitle: false,
                      title: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          'Search Viewers',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      automaticallyImplyLeading: false),
                ),
                SliverSearchBarWidget(
                  onFilterBySearchBarText: (value) =>
                      setState(() => _search = value),
                ),
                if (filtered.broadcaster.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(title: "Broadcaster"),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      filtered.broadcaster.map((name) {
                        return Padding(
                        padding: const EdgeInsets.only(left: 24),
                          child: Text(name),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (filtered.moderators.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(title: "Moderators"),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      filtered.moderators.map((name) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(name),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (filtered.vips.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(title: "Community VIPs"),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      filtered.vips.map((name) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(name),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (filtered.viewers.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(title: "Viewers"),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      filtered.viewers.map((name) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(name),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
