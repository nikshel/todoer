import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:todoer/blocs/auth.dart';
import 'package:todoer/client.dart';
import 'package:todoer/repositories/local_storage.dart';
import 'package:todoer/repositories/token.dart';
import 'package:window_manager/window_manager.dart';

import 'package:todoer/blocs/notes.dart';
import 'package:todoer/blocs/tree.dart';
import 'package:todoer/repositories/notes.dart';
import 'package:todoer/repositories/tree.dart';
import 'package:todoer/utils.dart';

import 'pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    await windowManager.ensureInitialized();

    if (Platform.isWindows) {
      registerWindowsScheme('todoer');
    }

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

  var todoerUrl = Uri.parse(const String.fromEnvironment("TODOER_URL",
      defaultValue: 'https://todoer.nikshel.ru'));
  var todoerClient = TodoerClient(todoerUrl.toString());
  var localStorageRepository = await LocalStorageRepository.create();

  runApp(MyApp(
    treeRepository: TreeRepository(todoerClient, localStorageRepository),
    notesRepository: NotesRepository(todoerClient),
    tokenRepository: TokenRepository('${todoerUrl.host}:${todoerUrl.port}'),
    todoerClient: todoerClient,
    todoerUrl: todoerUrl,
  ));
}

class MyApp extends StatelessWidget {
  final TreeRepository treeRepository;
  final NotesRepository notesRepository;
  final TokenRepository tokenRepository;
  final TodoerClient todoerClient;
  final EventBus eventBus = EventBus();
  final Uri todoerUrl;

  MyApp({
    super.key,
    required this.treeRepository,
    required this.notesRepository,
    required this.tokenRepository,
    required this.todoerClient,
    required this.todoerUrl,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => TreeCubit(treeRepository, eventBus),
            lazy: false,
          ),
          BlocProvider(
            create: (context) =>
                NotesCubit(notesRepository: notesRepository, eventBus: eventBus),
            lazy: false,
          ),
          BlocProvider(
            create: (context) =>
                AuthCubit(tokenRepository, eventBus, todoerClient, todoerUrl),
          ),
        ],
        child: const MyHomePage(title: 'easy_sidemenu Demo'),
      ),
    );
  }
}
