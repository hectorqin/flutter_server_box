import 'package:flutter/services.dart';
import 'package:toolbox/data/res/misc.dart';

class BgRun {
  const BgRun._();

  static const _channel = MethodChannel('${Miscs.pkgName}/app_retain');

  static void moveToBg() {
    _channel.invokeMethod('sendToBackground');
  }

  static void startService() {
    _channel.invokeMethod('startService');
  }
}
