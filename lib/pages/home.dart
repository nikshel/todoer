import 'dart:math';

import 'package:flutter/material.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vertical_tab_bar_view/vertical_tab_bar_view.dart';

import 'package:todoer/utils.dart';
import 'package:todoer/blocs/auth.dart';
import 'package:todoer/blocs/tree.dart';
import 'package:todoer/models/group.dart';
import 'package:todoer/models/task.dart';
import 'package:todoer/pages/login.dart';
import 'package:todoer/pages/task_tree.dart';
import 'package:todoer/widgets/update_checker.dart';

class TabBarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String title;

  const TabBarItem(
    this.icon,
    this.selectedIcon,
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
  SideMenuController sideMenuController = SideMenuController();

  String appVersion = '';

  static const Map<GroupSystemType, IconData> groupIcons = {
    GroupSystemType.today: Icons.today,
    GroupSystemType.week: Icons.calendar_month,
    GroupSystemType.waiting: Icons.hourglass_empty,
  };
  static const Map<GroupSystemType, IconData> groupSelecterIcons = {
    GroupSystemType.today: Icons.today_outlined,
    GroupSystemType.week: Icons.calendar_month_outlined,
    GroupSystemType.waiting: Icons.hourglass_empty_outlined,
  };
  static const List<TabBarItem> startTabBarItems = [
    TabBarItem(Icons.rowing, Icons.rowing_outlined, 'В работе'),
  ];
  static const List<TabBarItem> endTabBarItems = [
    TabBarItem(Icons.format_list_bulleted, Icons.format_list_bulleted_outlined,
        'Проекты'),
  ];

  @override
  void initState() {
    sideMenuController.addListener(_switchTab);
    super.initState();

    PackageInfo.fromPlatform().then((info) => setState(() {
          appVersion = info.version;
        }));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var groupsCount = context.watch<TreeCubit>().state.groups.length;
    var tabsCount = 2 + groupsCount;

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
            groupSelecterIcons[group.systemType]!,
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
                        if (isDesktop)
                          SideMenu(
                            controller: sideMenuController,
                            style: SideMenuStyle(
                              openSideMenuWidth: 150,
                              displayMode: SideMenuDisplayMode.auto,
                              hoverColor: Colors.green[100],
                              selectedColor: Colors.green,
                              selectedTitleTextStyle:
                                  const TextStyle(color: Colors.white),
                              selectedIconColor: Colors.white,
                            ),
                            items: _getTabBarItems()
                                .map(
                                  (item) => SideMenuItem(
                                    title: item.title,
                                    onTap: (index, _) {
                                      sideMenuController.changePage(index);
                                    },
                                    icon: Icon(item.icon),
                                  ),
                                )
                                .toList(),
                          ),
                        Expanded(
                          child: _makeTabBarView(
                            isVertical: isDesktop,
                            children: [
                              TaskTreePage(
                                  isReadOnly: true,
                                  filter: (task) =>
                                      task.status == TaskStatus.inWork),
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
                    )),
        bottomNavigationBar: isDesktop
            ? null
            : BlocBuilder<TreeCubit, TreeState>(
                builder: (context, treeState) => NavigationBar(
                      onDestinationSelected: _switchTab,
                      selectedIndex: currentTabIndex,
                      destinations: _getTabBarItems()
                          .map((item) => NavigationDestination(
                                label: item.title,
                                icon: Icon(item.icon),
                                selectedIcon: Icon(item.selectedIcon),
                              ))
                          .toList(),
                    )),
      );
    });
  }
}
