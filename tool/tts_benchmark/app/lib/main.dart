import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'bench.dart';

/// On-device TTS benchmark for rtchat (#1500).
///
/// Reads `bench_config.json` from the app's data directory (Android:
/// /sdcard/Android/data/com.rtirl.tts_benchmark_app/files, iOS: the app's
/// Documents folder), runs each entry against the models in `models/`, and
/// appends one JSON line per run to `results.jsonl`. See ../README.md.
void main() => runApp(const BenchApp());

class BenchApp extends StatelessWidget {
  const BenchApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TTS benchmark',
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
        home: const BenchPage(),
      );
}

class BenchPage extends StatefulWidget {
  const BenchPage({super.key});

  @override
  State<BenchPage> createState() => _BenchPageState();
}

const _exampleConfig = {
  'one_run_per_launch': false,
  'runs': [
    {'model': 'kitten-nano-en-v0_8-int8', 'threads': 2, 'corpus': 'en'},
    {'model': 'vits-piper-en_US-libritts_r-medium-int8', 'threads': 2},
  ],
};

class _BenchPageState extends State<BenchPage> {
  final _log = <String>[];
  Directory? _base;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _say(String s) {
    // ignore: avoid_print
    print('TTSBENCH $s');
    if (mounted) setState(() => _log.add(s));
  }

  Future<void> _init() async {
    final base = Platform.isAndroid
        ? (await getExternalStorageDirectory())!
        : await getApplicationDocumentsDirectory();
    _base = base;
    _say('data dir: ${base.path}');
    final cfg = File('${base.path}/bench_config.json');
    if (!cfg.existsSync()) {
      await File('${base.path}/bench_config.example.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert(_exampleConfig));
      _say('no bench_config.json; wrote bench_config.example.json');
      return;
    }
    final config = jsonDecode(await cfg.readAsString()) as Map<String, dynamic>;
    if (config['auto_start'] != false) await _run(config);
  }

  Future<List<String>> _corpus(String name, int limit) async {
    final text = await rootBundle.loadString('assets/corpus/$name.txt');
    final lines =
        text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    return (limit > 0 ? lines.take(limit) : lines).toList();
  }

  Set<int> _doneRuns(File results) {
    if (!results.existsSync()) return {};
    return results
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .map((l) => (jsonDecode(l) as Map<String, dynamic>)['run_index'])
        .whereType<int>()
        .toSet();
  }

  Future<void> _run(Map<String, dynamic> config) async {
    if (_running) return;
    setState(() => _running = true);
    final base = _base!;
    final runs = (config['runs'] as List)
        .map((r) => RunSpec.fromJson(r as Map<String, dynamic>))
        .toList();
    final onePerLaunch = config['one_run_per_launch'] == true;
    final results = File('${base.path}/results.jsonl');
    final done = _doneRuns(results);

    for (var i = 0; i < runs.length; i++) {
      if (done.contains(i)) continue;
      final r = await _runOne(i, runs[i], '${base.path}/models');
      await results.writeAsString('${jsonEncode(r)}\n',
          mode: FileMode.append, flush: true);
      final summary = Map.of(r)..remove('per_message');
      _say('RESULT ${jsonEncode(summary)}');
      if (onePerLaunch) {
        // A fresh process per run gives a clean peak-RSS reading. The host
        // script (scripts/run_android.sh) relaunches the app for the next run.
        _say('EXIT');
        exit(0);
      }
    }
    _say('DONE');
    setState(() => _running = false);
  }

  Future<Map<String, dynamic>> _runOne(
      int index, RunSpec spec, String modelsDir) async {
    _say('run $index: $spec');
    final lines = await _corpus(spec.corpus, spec.limit);
    final header = {
      'run_index': index,
      ...spec.toJson(),
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'cpus': Platform.numberOfProcessors,
    };
    final port = ReceivePort();
    final starts = <int, int>{};
    final firstChunkMain = <int, double>{};
    final completer = Completer<Map<String, dynamic>>();

    // Everything below runs on the UI isolate while the worker synthesizes:
    // it is where a player would receive and enqueue each chunk.
    port.listen((msg) {
      final m = msg as Map;
      switch (m['type']) {
        case 'loaded':
          _say('  loaded in ${(m['load_s'] as double).toStringAsFixed(2)}s, '
              'sr=${m['sample_rate']} speakers=${m['num_speakers']}');
        case 'start':
          starts[m['i'] as int] = m['t_us'] as int;
        case 'chunk':
          final i = m['i'] as int;
          (m['samples'] as TransferableTypedData).materialize();
          firstChunkMain.putIfAbsent(i,
              () => (DateTime.now().microsecondsSinceEpoch - starts[i]!) / 1e6);
        case 'done':
          final i = m['i'] as int;
          if (i % 10 == 9) _say('  ${i + 1}/${m['of']}');
        case 'result':
        case 'error':
          completer.complete(Map<String, dynamic>.from(m));
      }
    });

    final isolate = await Isolate.spawn(
        benchWorker, WorkerArgs(spec, modelsDir, lines, port.sendPort));
    final r = await completer.future;
    port.close();
    isolate.kill();

    if (r.remove('type') == 'error') _say('  ERROR ${r['error']}');
    final mainFirst = firstChunkMain.values.toList()..sort();
    return {
      ...header,
      if (mainFirst.isNotEmpty)
        'ttfa_ui_isolate_median_s': mainFirst[mainFirst.length ~/ 2],
      ...r,
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('TTS benchmark')),
        floatingActionButton: _running || _base == null
            ? null
            : FloatingActionButton(
                onPressed: () async {
                  final f = File('${_base!.path}/bench_config.json');
                  final cfg = f.existsSync()
                      ? jsonDecode(await f.readAsString())
                          as Map<String, dynamic>
                      : _exampleConfig;
                  await _run(cfg);
                },
                child: const Icon(Icons.play_arrow),
              ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final l in _log)
              Text(l, style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
      );
}
