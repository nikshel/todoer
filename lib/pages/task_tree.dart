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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        child: const DragAndDropTreeView(),
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

  Future<void> createTask(BuildContext context) async {
    var formResult = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (_) => CreateTaskForm(),
    );
    if (formResult == null || !context.mounted) {
      return;
    }
    var tree = Provider.of<TreeStorage>(context, listen: false);
    await tree.createTask(formResult['title']);
  }
}
