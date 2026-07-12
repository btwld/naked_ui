export 'screenshot_environment_stub.dart'
    if (dart.library.io) 'screenshot_environment_io.dart'
    if (dart.library.js_interop) 'screenshot_environment_web.dart';
