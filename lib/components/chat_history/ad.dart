import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/user.dart';

class AdMessageWidget extends StatefulWidget {
  final AdMessageModel model;

  const AdMessageWidget(this.model, {Key? key}) : super(key: key);

  @override
  State<AdMessageWidget> createState() => _AdMessageWidgetState();
}

class _AdMessageWidgetState extends State<AdMessageWidget> {
  FluidAdManagerBannerAd? _ad;

  @override
  void initState() {
    super.initState();

    FluidAdManagerBannerAd(
      adUnitId: widget.model.adId,
      request: const AdManagerAdRequest(),
      listener: AdManagerBannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _ad = ad as FluidAdManagerBannerAd;
          });
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    ).load();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) {
      return Container();
    }
    return Consumer<UserModel>(
      builder: (context, userModel, child) {
        final userId = userModel.user?.uid;
        return StreamBuilder<bool>(
            stream: userId == null
                ? Stream.value(true)
                : ProfilesAdapter.instance.getIsAdsEnabled(userId: userId),
            initialData: false,
            builder: (context, snapshot) {
              if (snapshot.data != true) {
                return Container();
              }
              return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    width: MediaQuery.of(context).size.width.toDouble(),
                    height: 72.0,
                    alignment: Alignment.center,
                    child: child,
                  ));
            });
      },
      child: FluidAdWidget(width: MediaQuery.of(context).size.width, ad: ad),
    );
  }
}
