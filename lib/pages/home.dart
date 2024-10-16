import 'package:flutter/material.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:todoer/blocs/auth.dart';
import 'package:todoer/blocs/tree.dart';
import 'package:todoer/models/group.dart';
import 'package:todoer/models/task.dart';
import 'package:todoer/pages/login.dart';
import 'package:todoer/pages/task_tree.dart';
import 'package:todoer/widgets/update_checker.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PageController pageController = PageController();
  SideMenuController sideMenu = SideMenuController();
  String appVersion = '';

  static Map<GroupSystemType, IconData> groupIcons = {
    GroupSystemType.today: Icons.today,
    GroupSystemType.week: Icons.calendar_month,
    GroupSystemType.waiting: Icons.hourglass_empty,
  };

  @override
  void initState() {
    sideMenu.addListener((index) {
      pageController.animateToPage(index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastEaseInToSlowEaseOut);
    });
    super.initState();

    PackageInfo.fromPlatform().then((info) => setState(() {
          appVersion = info.version;
        }));
  }

  _showHelp() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Управление'),
              content: const Text("""
- Один клик по задаче открывает или закрывает поддерево
- Двойной клик по задаче открывает редактор задачи
- Клик с удержанием на задачe включает drag-and-drop
- Клик ПКМ по задаче открывает контекстное меню
- Клик по иконке статуса задачи меняет статус по циклу open->inwork->close->open.
  При этом корректируются статусы дочерних и родительских задач, чтобы не было противоречий.
  Перейти из inwork в open можно через меню задачи
              """),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(builder: (context, authState) {
      return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text('Todoer v$appVersion'),
            centerTitle: true,
            actions: [
              UpdateChecker(currentTag: appVersion),
              IconButton(
                  icon: const Icon(Icons.help_outline), onPressed: _showHelp),
              if (authState.authorized)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => context.read<AuthCubit>().logout(),
                ),
            ],
          ),
          body: !authState.authorized
              ? const LoginPage()
              : BlocBuilder<TreeCubit, TreeState>(
                  builder: (context, treeState) => Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SideMenu(
                            controller: sideMenu,
                            style: SideMenuStyle(
                              openSideMenuWidth: 150,
                              displayMode: SideMenuDisplayMode.auto,
                              hoverColor: Colors.green[100],
                              selectedColor: Colors.green,
                              selectedTitleTextStyle:
                                  const TextStyle(color: Colors.white),
                              selectedIconColor: Colors.white,
                            ),
                            items: [
                              SideMenuItem(
                                title: 'В работе',
                                onTap: (index, _) {
                                  sideMenu.changePage(index);
                                },
                                icon: const Icon(Icons.rowing),
                              ),
                              ...treeState.groups.map((group) => SideMenuItem(
                                    title: group.title,
                                    onTap: (index, _) {
                                      sideMenu.changePage(index);
                                    },
                                    icon: Icon(groupIcons[group.systemType]),
                                  )),
                              SideMenuItem(
                                title: 'Проекты',
                                onTap: (index, _) {
                                  sideMenu.changePage(index);
                                },
                                icon: const Icon(Icons.format_list_bulleted),
                              ),
                            ],
                          ),
                          Expanded(
                            child: PageView(
                              controller: pageController,
                              scrollDirection: Axis.vertical,
                              children: [
                                TaskTreePage(
                                  isReadOnly: true,
                                  filter: (task) =>
                                      task.status == TaskStatus.inWork,
                                ),
                                ...treeState.groups.map((group) => TaskTreePage(
                                      isReadOnly: true,
                                      filter: (task) => [
                                        task,
                                        ...task.getAllParents()
                                      ].any((t) => t.groups.contains(group)),
                                    )),
                                const TaskTreePage(),
                              ],
                            ),
                          ),
                        ],
                      )));
    });
  }
}
