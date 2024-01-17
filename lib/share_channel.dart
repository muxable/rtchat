import 'package:flutter/services.dart';

class ShareChannel {
  void Function(String)? onDataReceived;

  ShareChannel() {
     // If sharing resumes the app we will check to see if we received any shared data
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg?.contains("resumed") ?? false) {
        getSharedText().then((String data) {
          // Nothing was shared with us :(
          if (data.isEmpty) {
            return;
          }
          // We got something! Inform our listener.
          onDataReceived?.call(data);
        });
      }
      return;
    });
  }
  
  static const _channel = MethodChannel('com.rtirl.chat/share');
   Future<String> getSharedText() async {
    return await _channel.invokeMethod<String>('getSharedData') ?? '';
  }
}
