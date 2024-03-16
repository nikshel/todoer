import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todoer/db/open.dart';
import 'package:todoer/models/storage.dart';
import 'package:window_manager/window_manager.dart';

import 'pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(800, 800),
        minimumSize: Size(400, 400),
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  var db = await openDatabase();
  var storage = TreeStorage(db);

  runApp(MyApp(storage: storage));
}

class MyApp extends StatelessWidget {
  final TreeStorage storage;

  const MyApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: ChangeNotifierProvider<TreeStorage>.value(
          value: storage,
          child: const MyHomePage(title: 'easy_sidemenu Demo'),
        ));
  }
}
