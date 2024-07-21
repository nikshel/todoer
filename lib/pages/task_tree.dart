import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:todoer/blocs/tree.dart';
import 'package:todoer/models/task.dart';
import 'package:todoer/widgets/task_tree.dart';
import 'package:todoer/widgets/utils.dart';

class TaskTreePage extends StatelessWidget {
  final bool isReadOnly;
  final bool Function(Task)? filter;

  const TaskTreePage({
    super.key,
    this.isReadOnly = false,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        child: TaskTreeView(
          isReadOnly: isReadOnly,
          shouldShow: (task) =>
              filter == null ||
              filter!(task) ||
              task.getAllChildren().any(filter!),
          onAddPressed: (task) async => await createTask(context, task.id),
        ),
        onKeyEvent: (event) async {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            await createTask(context);
          }
        },
      ),
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async => await createTask(context),
            ),
    );
  }

  Future<void> createTask(BuildContext context, [int? parentId]) async {
    var treeCubit = context.read<TreeCubit>();
    var formResult = await showTaskForm(context);
    if (formResult == null) {
      return;
    }

    await treeCubit.createTask(
      title: formResult['title'],
      isProject: formResult['isProject'],
      link: formResult['link'],
      parentId: parentId,
      groups: formResult['groups'],
    );
  }
}
