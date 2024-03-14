import 'package:flutter/material.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:todoer/pages/task_tree.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PageController pageController = PageController();
  SideMenuController sideMenu = SideMenuController();

  @override
  void initState() {
    sideMenu.addListener((index) {
      pageController.jumpToPage(index);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                title: 'Users',
                onTap: (index, _) {
                  sideMenu.changePage(index);
                },
                icon: const Icon(Icons.supervisor_account),
              ),
              SideMenuItem(
                title: 'Проекты',
                onTap: (index, _) {
                  sideMenu.changePage(index);
                },
                icon: const Icon(Icons.file_copy_rounded),
              ),
            ],
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              children: [
                Container(
                  color: Colors.white,
                  child: const Center(
                    child: Text(
                      'Users',
                      style: TextStyle(fontSize: 35),
                    ),
                  ),
                ),
                const TaskTreePage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
