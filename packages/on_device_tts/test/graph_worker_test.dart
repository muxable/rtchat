import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/src/onnx/graph_worker.dart';

const codec = StandardMethodCodec();

Future<dynamic> call(String method, Object? args) {
  final reply = Completer<ByteData?>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'on_device_tts/graphs',
        codec.encodeMethodCall(MethodCall(method, args)),
        reply.complete,
      );
  return reply.future.then((bytes) => codec.decodeEnvelope(bytes!));
}

Map<String, Object> tensor(List<int> shape, TypedData data) => {
  'shape': shape,
  'data': data,
};

Future<Map> runGraph(int handle, Map<String, Map> inputs) async =>
    await call('run', {'id': handle, 'inputs': inputs}) as Map;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installGraphHandler);

  test(
    'loads, reuses and closes a graph over the native channel codec',
    () async {
      final dir = await Directory.systemTemp.createTemp('graph-worker');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/double.onnx');
      // ONNX Add(x, x), FLOAT[2].
      await file.writeAsBytes(
        base64Decode(
          'CA46OgoOCgF4CgF4EgF5IgNBZGQSBmRvdWJsZVoPCgF4EgoKCAgBEgQKAggCYg8KAXkSCgoICAESBAoCCAJCBAoAEBI=',
        ),
      );
      final id = await call('open', file.path) as int;
      await expectLater(
        runGraph(id, {
          'x': tensor([2], Uint8List(8)),
        }),
        throwsA(isA<PlatformException>()),
      );
      for (final n in [2.0, -3.5]) {
        final y = await runGraph(id, {
          'x': tensor([2], Float32List.fromList([n, 1])),
        });
        expect(y['shape'], [2]);
        expect(y['data'], [2 * n, 2]);
      }
      await call('close', id);
      await expectLater(runGraph(id, {}), throwsA(isA<PlatformException>()));
      await expectLater(
        call('open', '${dir.path}/missing'),
        throwsA(isA<PlatformException>()),
      );
    },
  );

  final referenceDir = Platform.environment['SUPERTONIC_PARITY_DIR'];
  test(
    'all reference utterances match Supertone sample by sample',
    () async {
      final root = Directory(referenceDir!);
      final manifest =
          jsonDecode(await File('${root.path}/manifest.json').readAsString())
              as Map;
      final model = manifest['model_dir'] as String;
      final sessions = <String, int>{};
      addTearDown(() async {
        for (final id in sessions.values) {
          await call('close', id);
        }
      });
      for (final name in [
        'duration_predictor',
        'text_encoder',
        'vector_estimator',
        'vocoder',
      ]) {
        sessions[name] = await call('open', '$model/onnx/$name.onnx') as int;
      }
      final cases = (manifest['cases'] as List).cast<Map>();
      expect(cases, isNotEmpty);
      for (final example in cases) {
        final tensors = example['tensors'] as Map;
        Map<String, Object> fixture(String name) {
          final spec = tensors[name] as Map;
          final bytes = File('${root.path}/${spec['file']}').readAsBytesSync();
          return tensor(
            (spec['shape'] as List).cast<int>(),
            spec['dtype'] == 'int64'
                ? Int64List.sublistView(bytes)
                : Float32List.sublistView(bytes),
          );
        }

        final styles =
            jsonDecode(
                  await File(
                    '$model/voice_styles/${example['voice']}.json',
                  ).readAsString(),
                )
                as Map;
        Map<String, Object> style(String name) {
          final spec = styles[name] as Map;
          Iterable<double> flatten(dynamic v) sync* {
            if (v is List) {
              for (final item in v) {
                yield* flatten(item);
              }
            } else {
              yield (v as num).toDouble();
            }
          }

          return tensor(
            (spec['dims'] as List).cast<int>(),
            Float32List.fromList(flatten(spec['data']).toList()),
          );
        }

        final ids = fixture('text_ids'), noise = fixture('noise');
        Map<String, Object> ones(List<int> shape) =>
            tensor(shape, Float32List(shape.last)..fillRange(0, shape.last, 1));
        final mask = ones([1, 1, (ids['shape'] as List).last as int]);
        final ttl = style('style_ttl');
        final watch = Stopwatch()..start();
        final duration = await runGraph(sessions['duration_predictor']!, {
          'text_ids': ids,
          'text_mask': mask,
          'style_dp': style('style_dp'),
        });
        final seconds =
            (duration['data'] as Float32List).single /
            (example['speed'] as num);
        expect(
          seconds,
          closeTo((fixture('duration')['data'] as Float32List).single, 1e-4),
        );
        final emb = await runGraph(sessions['text_encoder']!, {
          'text_ids': ids,
          'text_mask': mask,
          'style_ttl': ttl,
        });
        final latentMask = ones([1, 1, (noise['shape'] as List).last as int]);
        Map latent = noise;
        final steps = example['steps'] as int;
        Map scalar(num v) => tensor([1], Float32List.fromList([v.toDouble()]));
        for (var step = 0; step < steps; step++) {
          latent = await runGraph(sessions['vector_estimator']!, {
            'noisy_latent': latent,
            'text_emb': emb,
            'style_ttl': ttl,
            'text_mask': mask,
            'latent_mask': latentMask,
            'current_step': scalar(step),
            'total_step': scalar(steps),
          });
        }
        final wav = await runGraph(sessions['vocoder']!, {'latent': latent});
        final samples = wav['data'] as Float32List;
        final ref = Float32List.sublistView(
          await File('${root.path}/${example['pcm']}').readAsBytes(),
        );
        final length =
            Float32List.fromList([
              seconds * (example['sample_rate'] as int),
            ]).single.toInt();
        expect(length, ref.length);
        expect(samples.length, greaterThanOrEqualTo(length));
        var maxError = 0.0;
        for (var i = 0; i < ref.length; i++) {
          maxError = math.max(maxError, (samples[i] - ref[i]).abs());
        }
        expect(maxError, lessThan(1e-3), reason: example['name'] as String);
        // ignore: avoid_print
        print(
          'Supertonic ${example['name']}: $length samples, maximum PCM error $maxError, synthesis ${watch.elapsed}.',
        );
      }
    },
    skip:
        referenceDir == null
            ? 'Set SUPERTONIC_PARITY_DIR to the Python oracle output'
            : false,
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
