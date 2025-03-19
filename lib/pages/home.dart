import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:todoer/models/task.dart';

import 'package:todoer/utils.dart';
import 'package:todoer/blocs/auth.dart';
import 'package:todoer/blocs/tree.dart';
import 'package:todoer/models/group.dart';
import 'package:todoer/pages/login.dart';
import 'package:todoer/pages/task_tree.dart';
import 'package:todoer/widgets/update_checker.dart';
import 'package:todoer/contrib/vertical_tab_bar_view/vertical_tab_bar_view.dart';
import 'package:todoer/widgets/menuable.dart';

enum HomeMenuOption {
  deleteDone,
}

class TabBarItem {
  final IconData icon;
  final String title;

  const TabBarItem(
    this.icon,
    this.title,
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late TabController tabController;
  int currentTabIndex = 0;
  bool showDone = false;

  String appVersion = '';

  static const Map<GroupSystemType, IconData> groupIcons = {
    GroupSystemType.today: Icons.today,
    GroupSystemType.week: Icons.calendar_month,
    GroupSystemType.waiting: Icons.hourglass_empty,
  };
  static const List<TabBarItem> startTabBarItems = [];
  static const List<TabBarItem> endTabBarItems = [
    TabBarItem(Icons.format_list_bulleted, 'Проекты'),
  ];

  @override
  void initState() {
    super.initState();

    PackageInfo.fromPlatform().then((info) => setState(() {
          appVersion = info.version;
        }));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var groupsCount = context.watch<TreeCubit>().state.groups.length;
    var tabsCount =
        startTabBarItems.length + groupsCount + endTabBarItems.length;

    setState(() {
      currentTabIndex = min(currentTabIndex, tabsCount);
      tabController = TabController(
        initialIndex: currentTabIndex,
        length: tabsCount,
        vsync: this,
      );
    });
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

  void _showDeleteDoneTasksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Подтверждение'),
        content:
            const Text('Вы уверены, что хотите удалить все сделанные задачи?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<TreeCubit>().removeAllDoneTasks();
              Navigator.pop(dialogContext);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Widget _makeTabBarView(
      {required bool isVertical, required List<Widget> children}) {
    if (isVertical) {
      return VerticalTabBarView(
        controller: tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      );
    } else {
      return TabBarView(
        controller: tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      );
    }
  }

  _switchTab(int index) {
    tabController.animateTo(index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastEaseInToSlowEaseOut);
    setState(() {
      currentTabIndex = index;
    });
  }

  List<TabBarItem> _getTabBarItems() {
    return [
      ...startTabBarItems,
      ...context.read<TreeCubit>().state.groups.map((group) => TabBarItem(
            groupIcons[group.systemType]!,
            group.title,
          )),
      ...endTabBarItems
    ];
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
                        if (isLandscape(context))
                          NavigationRail(
                            onDestinationSelected: _switchTab,
                            selectedIndex: currentTabIndex,
                            labelType: NavigationRailLabelType.all,
                            backgroundColor: const Color(0xffecefe6),
                            destinations: _getTabBarItems()
                                .map((item) => NavigationRailDestination(
                                      icon: Icon(item.icon, size: 30),
                                      label: Text(item.title),
                                      padding: const EdgeInsets.only(
                                        top: 5,
                                        bottom: 5,
                                      ),
                                    ))
                                .toList(),
                          ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text('Скрыть сделанные'),
                                  ),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                        value: !showDone,
                                        onChanged: (value) {
                                          setState(() {
                                            showDone = !value;
                                          });
                                        }),
                                  ),
                                  Menuable<HomeMenuOption>(
                                    options: const [
                                      (
                                        HomeMenuOption.deleteDone,
                                        Icons.delete,
                                        'Удалить сделанные'
                                      ),
                                    ],
                                    onOptionSelected: (option) {
                                      if (option == HomeMenuOption.deleteDone) {
                                        _showDeleteDoneTasksDialog(context);
                                      }
                                    },
                                    builder: (context, openMenu) => IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () =>
                                          openMenu(const Offset(0, 30)),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(thickness: 1, height: 1),
                              Expanded(
                                child: _makeTabBarView(
                                  isVertical: isLandscape(context),
                                  children: [
                                    ...treeState.groups
                                        .map((group) => TaskTreePage(
                                              isReadOnly: true,
                                              filter: (task) =>
                                                  (showDone ||
                                                      task.status !=
                                                          TaskStatus.done) &&
                                                  [
                                                    task,
                                                    ...task.getAllParents()
                                                  ].any((t) =>
                                                      t.groups.contains(group)),
                                            )),
                                    TaskTreePage(
                                        filter: (task) =>
                                            showDone ||
                                            task.status != TaskStatus.done),
                                  ]
                                      .map((widget) => RefreshIndicator(
                                            onRefresh: () => Future.wait([
                                              HapticFeedback.heavyImpact(),
                                              context
                                                  .read<TreeCubit>()
                                                  .updateRoots()
                                            ]),
                                            child: widget,
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
        bottomNavigationBar: isLandscape(context) || !authState.authorized
            ? null
            : BlocBuilder<TreeCubit, TreeState>(
                builder: (context, treeState) => NavigationBar(
                      onDestinationSelected: _switchTab,
                      selectedIndex: currentTabIndex,
                      destinations: _getTabBarItems()
                          .map((item) => NavigationDestination(
                                label: item.title,
                                icon: Icon(item.icon),
                              ))
                          .toList(),
                    )),
      );
    });
  }
}
