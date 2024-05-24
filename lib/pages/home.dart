import 'package:flutter/material.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:todoer/models/group.dart';
import 'package:todoer/models/storage.dart';
import 'package:todoer/models/task.dart';
import 'package:todoer/pages/task_tree.dart';

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
  List<Group> groups = [];

  static Map<GroupSystemType, IconData> groupIcons = {
    GroupSystemType.today: Icons.today,
    GroupSystemType.week: Icons.calendar_month,
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var storage = Provider.of<TreeStorage>(context);
    storage.getGroups().then((groups) => setState(() {
          this.groups = groups;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Todoer v$appVersion'),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SideMenu(
            controller: sideMenu,
            style: SideMenuStyle(
              openSideMenuWidth: 150,
              displayMode: SideMenuDisplayMode.auto,
              hoverColor: Colors.green[100],
              selectedColor: Colors.green,
              selectedTitleTextStyle: const TextStyle(color: Colors.white),
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
              ...groups.map((group) => SideMenuItem(
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
                  filter: (task) => task.status == TaskStatus.inWork,
                ),
                ...groups.map((group) => TaskTreePage(
                      isReadOnly: true,
                      filter: (task) => task.groups.contains(group),
                    )),
                const TaskTreePage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
