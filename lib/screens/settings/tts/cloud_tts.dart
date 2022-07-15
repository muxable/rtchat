import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CloudTTSScreen extends StatelessWidget {
  const CloudTTSScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Text to speech")),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(0),
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Colors.transparent),
                  ),
                ),
                child: Text(
                  'Subscribe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('\$5.00/mo  Cancel at any time.'),
            ),
          ],
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: MarkdownBody(
              data: '''# High-Quality Text-to-Speech Voices
                  \n* It will make your life better
                  \n* Access to billions of languages
                  \n* Trillions of languages
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
    );
  }
}
