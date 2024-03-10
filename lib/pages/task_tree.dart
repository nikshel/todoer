import 'package:flutter/material.dart';
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
      body: const DragAndDropTreeView(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          var formResult = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            builder: (_) => CreateTaskForm(),
          );
          if (formResult == null) {
            return;
          }
          var tree = Provider.of<TreeStorage>(context, listen: false);
          await tree.createTask(formResult['title']);
        },
      ),
    );
  }
}
