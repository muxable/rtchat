import 'dart:isolate';

void isolateMain(SendPort sendPort) {
  print("Hello from the isolate");
  sendPort.send("Isolate message");
}
