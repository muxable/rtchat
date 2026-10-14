import 'package:flutter_test/flutter_test.dart';
import 'package:tts_benchmark_app/bench.dart';

void main() {
  test('model kind is derived from the release archive name', () {
    expect(modelKind('kokoro-int8-multi-lang-v1_1'), 'kokoro');
    expect(modelKind('kitten-nano-en-v0_8-int8'), 'kitten');
    expect(modelKind('vits-piper-en_US-libritts_r-medium'), 'vits');
    expect(
        modelKind('sherpa-onnx-supertonic-3-tts-int8-2026-05-11'), 'supertonic');
  });

  test('run spec round-trips through json', () {
    final spec = RunSpec.fromJson({'model': 'kitten-micro-en-v0_8'});
    expect(spec.threads, 2);
    expect(RunSpec.fromJson(spec.toJson()).toJson(), spec.toJson());
  });
}
