import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'bench.dart';

/// Runs the raw acoustic model with onnxruntime directly (the official
/// onnxruntime-android / onnxruntime-objc builds via `flutter_onnxruntime`),
/// so execution providers that the sherpa-onnx builds don't ship (XNNPACK,
/// NNAPI, CoreML) can be compared on the same model file.
///
/// There is no phonemizer here: each message is mapped character by
/// character onto the model's token table. The audio is gibberish, but the
/// sequence lengths match real messages, which is what drives the cost.
Future<Map<String, dynamic>> runOrtBenchmark(
    RunSpec spec, String modelsDir, List<String> lines) async {
  final root = '$modelsDir/${spec.model}';
  final kind = modelKind(spec.model);
  final files = Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .toList();
  File find(bool Function(String) test) =>
      files.firstWhere((f) => test(f.uri.pathSegments.last));
  final modelFile = find((n) => n.endsWith('.onnx'));
  final tokens = <String, int>{};
  for (final line in find((n) => n == 'tokens.txt').readAsLinesSync()) {
    final i = line.lastIndexOf(' ');
    if (i < 0) continue;
    // The space token is written as " 16", so the symbol may be empty.
    tokens[i == 0 ? ' ' : line.substring(0, i)] =
        int.parse(line.substring(i + 1));
  }

  Float32List? style;
  if (kind == 'kitten' || kind == 'kokoro') {
    final bytes = find((n) => n == 'voices.bin').readAsBytesSync();
    style = Float32List.fromList(
        bytes.buffer.asFloat32List(bytes.offsetInBytes, 256).toList());
  }

  List<int> ids(String text) {
    final chars = text.toLowerCase().split('');
    final space = tokens[' '] ?? 0;
    final body = chars.map((c) => tokens[c] ?? space).toList();
    if (kind == 'vits') {
      // Piper: ^ _ x _ y _ ... $
      final pad = tokens['_'] ?? 0;
      return [
        tokens['^'] ?? 1,
        pad,
        for (final t in body) ...[t, pad],
        tokens['\$'] ?? 2,
      ];
    }
    return [0, ...body, 0];
  }

  final providers = <OrtProvider>[
    switch (spec.provider) {
      'xnnpack' => OrtProvider.XNNPACK,
      'nnapi' => OrtProvider.NNAPI,
      'coreml' => OrtProvider.CORE_ML,
      _ => OrtProvider.CPU,
    },
    if (spec.provider != 'cpu') OrtProvider.CPU,
  ];
  final ort = OnnxRuntime();
  final available = await ort.getAvailableProviders();
  final rssBase = ProcessInfo.currentRss / 1048576;
  final sw = Stopwatch()..start();
  final session = await ort.createSession(
    modelFile.path,
    options: OrtSessionOptions(
      intraOpNumThreads: spec.threads,
      providers: providers,
      // XNNPACK has its own thread pool; ORT recommends 1 intra-op thread
      // when it is used.
      sessionConfigs: spec.provider == 'xnnpack'
          ? {'session.intra_op.allow_spinning': '0'}
          : null,
    ),
  );
  final loadS = sw.elapsedMicroseconds / 1e6;
  final rssLoaded = ProcessInfo.currentRss / 1048576;
  final sampleRate = kind == 'vits' ? 22050 : 24000;

  Future<(double, double, int)> infer(String text) async {
    final t = ids(text);
    final inputs = <String, OrtValue>{};
    for (final name in session.inputNames) {
      inputs[name] = switch (name) {
        'input_ids' || 'tokens' || 'input' =>
          await OrtValue.fromList(Int64List.fromList(t), [1, t.length]),
        'input_lengths' => await OrtValue.fromList(Int64List.fromList([t.length]), [1]),
        'scales' => await OrtValue.fromList(Float32List.fromList([0.667, 1.0, 0.8]), [3]),
        'sid' => await OrtValue.fromList(Int64List.fromList([spec.sid]), [1]),
        'style' => await OrtValue.fromList(style!, [1, 256]),
        'speed' => await OrtValue.fromList(Float32List.fromList([1.0]), [1]),
        _ => throw StateError('unexpected input $name'),
      };
    }
    final s = Stopwatch()..start();
    final out = await session.run(inputs);
    final runS = s.elapsedMicroseconds / 1e6;
    final audio = out[session.outputNames.first]!;
    final n = audio.shape.fold<int>(1, (a, b) => a * b);
    final fetch = Stopwatch()..start();
    await audio.asFlattenedList();
    final fetchS = fetch.elapsedMicroseconds / 1e6;
    for (final v in [...inputs.values, ...out.values]) {
      await v.dispose();
    }
    return (runS, fetchS, n);
  }

  await infer(lines.first); // warm-up
  final run = <double>[], fetch = <double>[];
  var audioTotal = 0.0;
  for (final text in lines) {
    final (r, f, n) = await infer(text);
    run.add(r);
    fetch.add(f);
    audioTotal += n / sampleRate;
  }
  await session.close();

  double q(List<double> xs, double p) {
    final s = [...xs]..sort();
    return s[math.min(s.length - 1, (s.length * p).floor())];
  }

  return {
    'runtime': 'ort',
    'ort_available_providers': available.map((p) => p.name).toList(),
    'load_s': loadS,
    'rss_base_mb': rssBase,
    'rss_after_load_mb': rssLoaded,
    'rss_max_mb': ProcessInfo.maxRss / 1048576,
    'messages': lines.length,
    'synth_median_s': q(run, 0.5),
    'synth_p90_s': q(run, 0.9),
    'fetch_median_s': q(fetch, 0.5),
    'rtf': run.fold<double>(0, (a, b) => a + b) / audioTotal,
    'audio_total_s': audioTotal,
  };
}
