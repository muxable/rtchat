// One worker owns each loaded graph. Model weights never cross isolate ports.
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_onnx/flutter_onnx.dart';
import 'package:flutter_onnx_cpu/flutter_onnx_cpu.dart';

const _channel = MethodChannel('on_device_tts/graphs');
final _graphs = <int, _GraphWorker>{};
int _nextGraph = 0;
bool _installed = false;

void installGraphHandler() {
  if (_installed) return;
  _channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'open':
        final args = call.arguments;
        final path = args is String ? args : (args as Map)['path'] as String;
        final threads = args is Map ? args['threads'] as int : 2;
        final graph = await _GraphWorker.open(path, threads);
        final id = ++_nextGraph;
        _graphs[id] = graph;
        return id;
      case 'run':
        final args = call.arguments as Map;
        final graph = _graphs[args['id']];
        if (graph == null) throw StateError('Unknown speech graph');
        return graph.run(args['inputs'] as Map);
      case 'close':
        _graphs.remove(call.arguments)?.close();
        return null;
      default:
        throw MissingPluginException(call.method);
    }
  });
  _installed = true;
}

class _GraphWorker {
  final ReceivePort _replies = ReceivePort();
  final _ready = Completer<SendPort>();
  final _pending = <int, Completer<Map>>{};
  late final Isolate _isolate;
  late final SendPort _commands;
  int _sequence = 0;
  bool _closed = false;

  static Future<_GraphWorker> open(String path, int threads) async {
    final worker = _GraphWorker();
    worker._replies.listen(worker._receive);
    try {
      worker._isolate = await Isolate.spawn(
        _serveGraph,
        (path, threads, worker._replies.sendPort),
        onExit: worker._replies.sendPort,
        onError: worker._replies.sendPort,
      );
      worker._commands = await worker._ready.future;
      return worker;
    } catch (_) {
      worker._replies.close();
      rethrow;
    }
  }

  void _receive(dynamic message) {
    if (message is SendPort) {
      _ready.complete(message);
    } else if (message is (int, Map?, String?)) {
      final waiter = _pending.remove(message.$1);
      if (message.$2 != null) {
        waiter?.complete(message.$2!);
      } else {
        waiter?.completeError(StateError(message.$3!));
      }
    } else {
      _closed = true;
      final error = StateError(
        message is List ? message.first.toString() : 'Speech graph exited',
      );
      if (!_ready.isCompleted) _ready.completeError(error);
      for (final waiter in _pending.values) {
        waiter.completeError(error);
      }
      _pending.clear();
      _replies.close();
    }
  }

  Future<Map> run(Map inputs) {
    if (_closed) throw StateError('Speech graph is closed');
    final id = ++_sequence;
    final waiter = _pending[id] = Completer<Map>();
    _commands.send((id, inputs));
    return waiter.future;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _isolate.kill(priority: Isolate.immediate);
  }
}

void _serveGraph((String, int, SendPort) request) async {
  final (path, threads, parent) = request;
  final graph = OnnxSession.fromBytes(File(path).readAsBytesSync());
  // A tiny difference in predicted duration can change the integer PCM
  // length. Use the same Dart arithmetic for this graph on both platforms.
  final backend =
      graph.outputs.containsKey('duration')
          ? null
          : NativeCpuBackend(maxThreads: threads);
  final commands = ReceivePort();
  parent.send(commands.sendPort);
  await for (final dynamic message in commands) {
    final (id, inputs) = message as (int, Map);
    try {
      final feeds = <String, Tensor>{};
      for (final e in inputs.entries) {
        final spec = e.value as Map;
        final data = spec['data'] as TypedData;
        feeds[e.key as String] = Tensor.fromBytes(
          switch (data) {
            Int64List() => TensorType.int64,
            Float32List() => TensorType.float32,
            _ =>
              throw ArgumentError(
                'Unsupported speech tensor: ${data.runtimeType}',
              ),
          },
          (spec['shape'] as List).cast<int>(),
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
      final outputs = await graph.runAsync(feeds, backend: backend);
      final output = outputs.values.single;
      parent.send((
        id,
        {'shape': output.shape, 'data': output.values as Float32List},
        null,
      ));
    } catch (error) {
      parent.send((id, null, error.toString()));
    }
  }
}
