import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:todoer/models/storage.dart';
import 'package:todoer/models/task.dart';
import 'package:todoer/widgets/task_tree.dart';
import 'package:todoer/widgets/utils.dart';

class TaskTreePage extends StatelessWidget {
  final bool inWork;

  const TaskTreePage({
    super.key,
    this.inWork = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        child: DragAndDropTreeView(
          isReadOnly: inWork,
          shouldShow: (task) =>
              !inWork ||
              (task.status == TaskStatus.inWork ||
                  task
                      .getAllChildren()
                      .any((t) => t.status == TaskStatus.inWork)),
          onAddPressed: (task) async => await createTask(context, task.id),
        ),
        onKeyEvent: (event) async {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            await createTask(context);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async => await createTask(context),
      ),
    );
  }

  Future<void> createTask(BuildContext context, [int? parentId]) async {
    var formResult = await showTaskForm(context);
    if (formResult == null || !context.mounted) {
      return;
    }
    var tree = Provider.of<TreeStorage>(context, listen: false);
    await tree.createTask(
      title: formResult['title'],
      isProject: formResult['isProject'],
      parentId: parentId,
    );
  }
}
