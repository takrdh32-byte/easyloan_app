import 'package:flutter/services.dart';

class CloneLabBridge {
  static const _channel = MethodChannel('com.clonelab.app/native');

  static Future<String> getEngineVersion() async {
    return await _channel.invokeMethod('getEngineVersion');
  }

  static Future<int> createClone({required String appPackage}) async {
    return await _channel.invokeMethod('createClone', {
      'package': appPackage,
    });
  }
}