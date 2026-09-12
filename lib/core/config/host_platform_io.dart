import 'dart:io' as io;

class HostPlatform {
  const HostPlatform._();

  static bool get isMobile => io.Platform.isAndroid || io.Platform.isIOS;
  static bool get isAndroid => io.Platform.isAndroid;
  static bool get isIOS => io.Platform.isIOS;
}
