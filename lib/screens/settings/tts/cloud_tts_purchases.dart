import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/product.dart';
import 'package:rtchat/models/purchases.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/product_list.dart';

class CloudTtsPurchasesScreen extends StatelessWidget {
  const CloudTtsPurchasesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var purchases = context.watch<Purchases>();
    var userModel = context.watch<UserModel>();
    String buttonText = 'Unavailable';
    Product? product;

    if (purchases.storeState == StoreState.available) {
      product = purchases.getProduct(cloudTtsSubscription);
      switch (product?.status) {
        case ProductStatus.purchasable:
          buttonText = 'Subscribe';
          break;
        case ProductStatus.pending:
          buttonText = 'Pending';
          break;
        case ProductStatus.purchased:
          buttonText = 'Subscribed';
          break;
        default:
          break;
      }
    }
    if (!userModel.isSignedIn()) {
      buttonText = 'Please Sign In';
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Text to speech")),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: MarkdownBody(
                    data: '''# High-Quality Text-to-Speech Voices
                        \n* Per viewer voices
                        \n* Access to all Twitch supported languages
                        \n* No more robot speech!''',
                    styleSheet: MarkdownStyleSheet(
                      listBullet: Theme.of(context).textTheme.titleLarge,
                      p: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ElevatedButton(
                    child: const Text("Play sample message"),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(
                  height: 16,
                )
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: userModel.isSignedIn() &&
                            purchases.storeState == StoreState.available &&
                            product!.status == ProductStatus.purchasable
                        ? () => purchases.buy(product!)
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(0),
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: Colors.transparent),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '${product != null ? '${product.price}/mo   ' : ''}Cancel at any time.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
