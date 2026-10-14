import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// One benchmark run: a model, a thread count, a provider and a corpus.
class RunSpec {
  RunSpec({
    required this.model,
    this.threads = 2,
    this.provider = 'cpu',
    this.corpus = 'en',
    this.lang = 'en',
    this.sid = 0,
    this.limit = 0,
    this.maxNumSentences = 1,
    this.runtime = 'sherpa',
  });

  factory RunSpec.fromJson(Map<String, dynamic> j) => RunSpec(
        model: j['model'] as String,
        threads: (j['threads'] as num?)?.toInt() ?? 2,
        provider: j['provider'] as String? ?? 'cpu',
        corpus: j['corpus'] as String? ?? 'en',
        lang: j['lang'] as String? ?? 'en',
        sid: (j['sid'] as num?)?.toInt() ?? 0,
        limit: (j['limit'] as num?)?.toInt() ?? 0,
        maxNumSentences: (j['max_num_sentences'] as num?)?.toInt() ?? 1,
        runtime: j['runtime'] as String? ?? 'sherpa',
      );

  final String model;
  final int threads;
  final String provider;
  final String corpus;
  final String lang;
  final int sid;
  final int limit;
  final int maxNumSentences;

  /// `sherpa` (sherpa_onnx, full text-to-speech pipeline) or `ort` (raw
  /// acoustic model through flutter_onnxruntime; see ort_bench.dart).
  final String runtime;

  Map<String, dynamic> toJson() => {
        'model': model,
        'threads': threads,
        'provider': provider,
        'corpus': corpus,
        'lang': lang,
        'sid': sid,
        'limit': limit,
        'max_num_sentences': maxNumSentences,
        'runtime': runtime,
      };

  @override
  String toString() => '$runtime $model t=$threads $provider $corpus';
}

/// Everything the worker isolate needs; must be sendable between isolates.
class WorkerArgs {
  WorkerArgs(this.spec, this.modelsDir, this.lines, this.port);

  final RunSpec spec;
  final String modelsDir;
  final List<String> lines;
  final SendPort port;
}

String modelKind(String name) {
  if (name.startsWith('kokoro')) return 'kokoro';
  if (name.startsWith('kitten')) return 'kitten';
  if (name.contains('supertonic')) return 'supertonic';
  if (name.startsWith('matcha')) return 'matcha';
  if (name.startsWith('vits') || name.contains('piper')) return 'vits';
  throw ArgumentError('unknown model type for $name');
}

List<FileSystemEntity> _walk(String root) =>
    Directory(root).listSync(recursive: true, followLinks: false);

String _find(String root, List<String> names) {
  final all = _walk(root);
  for (final n in names) {
    for (final e in all) {
      if (e is File && e.uri.pathSegments.last == n) return e.path;
    }
  }
  return '';
}

String _findDir(String root, String name) {
  for (final e in _walk(root)) {
    if (e is Directory &&
        e.uri.pathSegments.where((s) => s.isNotEmpty).last == name) {
      return e.path;
    }
  }
  return '';
}

int dirSize(String root) => _walk(root)
    .whereType<File>()
    .fold(0, (sum, f) => sum + f.lengthSync());

/// Builds a sherpa-onnx config from a model directory extracted from the
/// sherpa-onnx `tts-models` release (see scripts/download_models.sh).
sherpa.OfflineTtsConfig buildConfig(String root, RunSpec spec) {
  final kind = modelKind(spec.model);
  var model = const sherpa.OfflineTtsModelConfig();
  switch (kind) {
    case 'kokoro':
      final lex = [
        _find(root, ['lexicon-us-en.txt']),
        _find(root, ['lexicon-zh.txt']),
      ].where((p) => p.isNotEmpty).join(',');
      model = sherpa.OfflineTtsModelConfig(
        kokoro: sherpa.OfflineTtsKokoroModelConfig(
          model: _find(root, ['model.int8.onnx', 'model.onnx']),
          voices: _find(root, ['voices.bin']),
          tokens: _find(root, ['tokens.txt']),
          dataDir: _findDir(root, 'espeak-ng-data'),
          lexicon: lex,
        ),
        numThreads: spec.threads,
        provider: spec.provider,
        debug: false,
      );
    case 'kitten':
      model = sherpa.OfflineTtsModelConfig(
        kitten: sherpa.OfflineTtsKittenModelConfig(
          model: _find(root, [
            'model.int8.onnx',
            'model.fp32.onnx',
            'model.fp16.onnx',
            'model.onnx',
          ]),
          voices: _find(root, ['voices.bin']),
          tokens: _find(root, ['tokens.txt']),
          dataDir: _findDir(root, 'espeak-ng-data'),
        ),
        numThreads: spec.threads,
        provider: spec.provider,
        debug: false,
      );
    case 'vits':
      final onnx = _walk(root)
          .whereType<File>()
          .firstWhere((f) => f.path.endsWith('.onnx'))
          .path;
      model = sherpa.OfflineTtsModelConfig(
        vits: sherpa.OfflineTtsVitsModelConfig(
          model: onnx,
          tokens: _find(root, ['tokens.txt']),
          dataDir: _findDir(root, 'espeak-ng-data'),
        ),
        numThreads: spec.threads,
        provider: spec.provider,
        debug: false,
      );
    case 'supertonic':
      model = sherpa.OfflineTtsModelConfig(
        supertonic: sherpa.OfflineTtsSupertonicModelConfig(
          durationPredictor: _find(root,
              ['duration_predictor.int8.onnx', 'duration_predictor.onnx']),
          textEncoder:
              _find(root, ['text_encoder.int8.onnx', 'text_encoder.onnx']),
          vectorEstimator: _find(
              root, ['vector_estimator.int8.onnx', 'vector_estimator.onnx']),
          vocoder: _find(root, ['vocoder.int8.onnx', 'vocoder.onnx']),
          ttsJson: _find(root, ['tts.json']),
          unicodeIndexer: _find(root, ['unicode_indexer.bin']),
          voiceStyle: _find(root, ['voice.bin']),
        ),
        numThreads: spec.threads,
        provider: spec.provider,
        debug: false,
      );
    default:
      throw ArgumentError('unsupported model type $kind');
  }
  return sherpa.OfflineTtsConfig(
    model: model,
    maxNumSenetences: spec.maxNumSentences,
  );
}

int _nowUs() => DateTime.now().microsecondsSinceEpoch;

double _rssMb() => ProcessInfo.currentRss / (1024 * 1024);
double _maxRssMb() => ProcessInfo.maxRss / (1024 * 1024);

double _quantile(List<double> xs, double q) {
  final s = [...xs]..sort();
  final pos = (s.length - 1) * q;
  final lo = pos.floor(), hi = pos.ceil();
  return s[lo] + (s[hi] - s[lo]) * (pos - lo);
}

/// Worker isolate entry point. Synthesis is a blocking FFI call, so it runs
/// here and streams every callback chunk back to the UI isolate, which is
/// exactly how the app would feed a player while synthesis continues.
///
/// Messages sent on [WorkerArgs.port]:
///   {'type': 'loaded', ...}
///   {'type': 'start', 'i': i, 't_us': ...}
///   {'type': 'chunk', 'i': i, 't_us': ..., 'samples': TransferableTypedData}
///   {'type': 'done', 'i': i, ...}
///   {'type': 'result', ...} or {'type': 'error', ...}
void benchWorker(WorkerArgs a) {
  final port = a.port;
  try {
    sherpa.initBindings();
    final root = '${a.modelsDir}/${a.spec.model}';
    if (!Directory(root).existsSync()) {
      throw StateError('model directory not found: $root');
    }
    final rssBase = _rssMb();
    final t0 = _nowUs();
    final tts = sherpa.OfflineTts(buildConfig(root, a.spec));
    final loadS = (_nowUs() - t0) / 1e6;
    final rssLoaded = _rssMb();
    port.send({
      'type': 'loaded',
      'load_s': loadS,
      'sample_rate': tts.sampleRate,
      'num_speakers': tts.numSpeakers,
    });

    final kind = modelKind(a.spec.model);
    sherpa.GeneratedAudio gen(
        String text, int Function(Float32List, double)? onProgress) {
      return tts.generateWithConfig(
        text: text,
        config: sherpa.OfflineTtsGenerationConfig(
          sid: a.spec.sid,
          speed: 1.0,
          extra: kind == 'supertonic' ? {'lang': a.spec.lang} : const {},
        ),
        onProgress: onProgress,
      );
    }

    // Warm-up: the first call allocates memory arenas.
    gen(a.lines.first, null);

    final per = <Map<String, dynamic>>[];
    for (var i = 0; i < a.lines.length; i++) {
      final text = a.lines[i];
      var chunks = 0;
      double? firstChunkS;
      final start = _nowUs();
      port.send({'type': 'start', 'i': i, 't_us': start});
      final audio = gen(text, (samples, progress) {
        final now = _nowUs();
        chunks++;
        firstChunkS ??= (now - start) / 1e6;
        port.send({
          'type': 'chunk',
          'i': i,
          't_us': now,
          'samples': TransferableTypedData.fromList([samples]),
        });
        return 1; // keep going
      });
      final synthS = (_nowUs() - start) / 1e6;
      final audioS = audio.samples.length / math.max(audio.sampleRate, 1);
      per.add({
        'synth_s': synthS,
        'first_chunk_s': firstChunkS ?? synthS,
        'num_chunks': chunks,
        'audio_s': audioS,
        'chars': text.length,
      });
      port.send({'type': 'done', 'i': i, 'of': a.lines.length});
    }
    tts.free();

    final synth = per.map((p) => p['synth_s'] as double).toList();
    final first = per.map((p) => p['first_chunk_s'] as double).toList();
    final audioTotal =
        per.fold<double>(0, (s, p) => s + (p['audio_s'] as double));
    port.send({
      'type': 'result',
      'load_s': loadS,
      'rss_base_mb': rssBase,
      'rss_after_load_mb': rssLoaded,
      'rss_max_mb': _maxRssMb(),
      'disk_bytes': dirSize(root),
      'messages': per.length,
      'ttfa_median_s': _quantile(first, 0.5),
      'ttfa_p90_s': _quantile(first, 0.9),
      'synth_median_s': _quantile(synth, 0.5),
      'synth_p90_s': _quantile(synth, 0.9),
      'rtf': synth.fold<double>(0, (s, x) => s + x) / audioTotal,
      'audio_total_s': audioTotal,
      'chunks_per_message_max':
          per.map((p) => p['num_chunks'] as int).reduce(math.max),
      'per_message': per,
    });
  } catch (e, st) {
    port.send({'type': 'error', 'error': '$e', 'stack': '$st'});
  }
}
