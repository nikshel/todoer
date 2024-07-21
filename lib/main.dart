import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todoer/blocs/tree.dart';
import 'package:todoer/db/open.dart';
import 'package:todoer/repositories/tree.dart';
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
  var treeRepository = TreeRepository(db);

  runApp(MyApp(treeRepository: treeRepository));
}

class MyApp extends StatelessWidget {
  final TreeRepository treeRepository;

  const MyApp({super.key, required this.treeRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => TreeCubit(treeRepository),
        child: const MyHomePage(title: 'easy_sidemenu Demo'),
      ),
    );
  }
}
