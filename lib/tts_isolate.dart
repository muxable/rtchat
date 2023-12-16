import 'dart:isolate';

@pragma("vm:entry-point")
void isolateMain(SendPort sendPort) {
  print("Hello from the isolate");
  sendPort.send("Isolate message");
}
