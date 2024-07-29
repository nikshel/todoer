import 'dart:io';

bool get isDesktop =>
    Platform.isMacOS || Platform.isLinux || Platform.isWindows;
