import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:todoer/models/storage.dart';
import 'package:todoer/widgets/create_task_form.dart';
import 'package:todoer/widgets/task_tree.dart';

class TaskTreePage extends StatelessWidget {
  const TaskTreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        child: DragAndDropTreeView(
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
    var formResult = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (_) => CreateTaskForm(),
    );
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
