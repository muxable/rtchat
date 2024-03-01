import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/components/drawer/sliver_search_bar.dart';
import 'package:rtchat/components/drawer/sliver_title.dart';
import 'package:rtchat/models/adapters/chat_state.dart';
import 'package:rtchat/models/channels.dart';

class EndDrawerWidget extends StatefulWidget {
  final Channel channel;

  final Function(String) onError;

  const EndDrawerWidget(
      {required this.channel, super.key, required this.onError});

  @override
  State<EndDrawerWidget> createState() => EndDrawerWidgetState();
}

class EndDrawerWidgetState extends State<EndDrawerWidget> {
  String _search = "";
  Viewers? _viewers;

  @override
  void initState() {
    super.initState();
    _loadViewers();
  }

  void _loadViewers() async {
    try {
      final viewers = await ChatStateAdapter.instance
          .getViewers(channelId: widget.channel.toString());
      if (!mounted) return;
      setState(() => _viewers = viewers);
    } catch (e) {
      widget.onError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if viewers data is available and build UI accordingly
    if (_viewers == null) {
      // Show loading or empty state
      return const CircularProgressIndicator();
    }

    final filtered = _viewers!.query(_search);

    return Container(
        color: Theme.of(context).canvasColor,
        child: SafeArea(
            top: false,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(top: 24),
                  sliver: SliverAppBar(
                    actions: const [SizedBox()],
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
                    automaticallyImplyLeading: false,
                  ),
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
            )));
  }
}
