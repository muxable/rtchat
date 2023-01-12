import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/components/drawer/sliver_search_bar.dart';
import 'package:rtchat/components/drawer/sliver_title.dart';
import 'package:rtchat/models/adapters/chat_state.dart';
import 'package:rtchat/models/channels.dart';

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
      child: FutureBuilder<Viewers>(
        future: ChatStateAdapter.instance
            .getViewers(channelId: widget.channel.toString()),
        builder: (context, snapshot) {
          final viewers = snapshot.data;
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
                          AppLocalizations.of(context)!.searchViewers,
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
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(
                        title: AppLocalizations.of(context)!.broadcaster),
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
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(
                        title: AppLocalizations.of(context)!.moderators),
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
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(
                        title: AppLocalizations.of(context)!.communityVips),
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
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(
                        title: AppLocalizations.of(context)!.viewers),
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
