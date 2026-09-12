// Stub for non-IO platforms. The app is currently built for mobile targets and uses
// the standard platform import path for runtime detection.
class HostPlatform {
  const HostPlatform._();

  static bool get isMobile => true;
}
