import 'package:flutter/material.dart';

// placeholder
const voices = [
  'Neural2-A',
  'Standard-A',
  'Standard-B',
  'Standard-C',
  'Standard-D',
  'Standard-E',
  'Standard-F',
  'Standard-G',
  'Standard-H',
  'Standard-I',
  'Standard-J',
  'WaveNet-A',
  'WaveNet-B',
  'WaveNet-C',
  'WaveNet-D',
  'WaveNet-E',
  'WaveNet-F',
  'WaveNet-G'
];

class VoicesScreen extends StatelessWidget {
  const VoicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voices')),
      body: ListView.builder(
        itemBuilder: (BuildContext context, int index) => ListTile(
          title: Text(voices[index]),
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Play sample',
          ),
          onTap: () {},
        ),
        itemCount: voices.length,
      ),
    );
  }
}
