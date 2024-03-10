import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todoer/db/open.dart';
import 'package:todoer/models/storage.dart';
import 'package:todoer/pages/task_tree.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  var db = await openDatabase();
  var storage = TreeStorage(db);

  windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(400, 800),
      minimumSize: Size(400, 800),
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(MyApp(storage: storage));
}

class MyApp extends StatelessWidget {
  final TreeStorage storage;

  const MyApp({super.key, required this.storage});

  // This widget is the root of your application.
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
          child: const TaskTreePage(),
        ));
  }

  // static TreeStorage makeTreeStorage() {
  //   var tree = TreeStorage();
  //   var t1 = tree.createTask("Root");
  //   var t2 = tree.createTask("Child 1", t1);
  //   tree.createTask("Child 2", t2);
  //   tree.createTask("Child 23", t1);

  //   return tree;
  // }
}
