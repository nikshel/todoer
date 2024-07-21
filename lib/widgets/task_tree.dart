import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:provider/provider.dart';
import 'package:todoer/blocs/tree.dart';
import 'package:todoer/models/task.dart';

import 'task_tree_tile.dart';
import 'utils.dart';

bool allow(Task _) => true;

class TaskTreeView extends StatefulWidget {
  const TaskTreeView({
    super.key,
    this.isReadOnly = false,
    this.shouldShow = allow,
    required this.onAddPressed,
  });

  final void Function(Task) onAddPressed;
  final bool Function(Task) shouldShow;
  final bool isReadOnly;

  @override
  State<TaskTreeView> createState() => _TaskTreeViewState();
}

class _TaskTreeViewState extends State<TaskTreeView> {
  late TreeController<Task> treeController;
  late TreeCubit treeCubit;

  static final nextStatus = <TaskStatus, TaskStatus>{
    TaskStatus.open: TaskStatus.inWork,
    TaskStatus.inWork: TaskStatus.done,
    TaskStatus.done: TaskStatus.open,
  };

  _TaskTreeViewState() {
    treeController = TreeController<Task>(
      roots: [],
      childrenProvider: (Task node) => node.children.where(widget.shouldShow),
      parentProvider: (Task node) => node.parent,
      defaultExpansionState: true,
    );
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();

    treeCubit = context.watch<TreeCubit>();
    var roots = treeCubit.state.rootTasks.where(widget.shouldShow);
    setState(() {
      treeController.roots = roots;
    });
  }

  @override
  void dispose() {
    treeController.dispose();
    super.dispose();
  }

  void _onNodeAccepted(TreeDragAndDropDetails<Task> details) async {
    Task? newParent;
    int newIndex = 0;

    mapDropPosition(
      details,
      whenAbove: () {
        // Insert the dragged node as the previous sibling of the target node.
        newParent = details.targetNode.parent;
        newIndex = details.targetNode.index;
      },
      whenInside: () {
        // Insert the dragged node as the last child of the target node.
        newParent = details.targetNode;
        newIndex = details.targetNode.children.length;
      },
      whenBelow: () {
        // Insert the dragged node as the next sibling of the target node.
        newParent = details.targetNode.parent;
        newIndex = details.targetNode.index + 1;
      },
    );

    await treeCubit.moveTask(details.draggedNode.id, newParent?.id, newIndex);
  }

  void _onTileAction(TreeTileAction action, Task task) async {
    switch (action) {
      case TreeTileAction.expandPressed:
        treeController.toggleExpansion(task);

      case TreeTileAction.statusSwitchPressed:
        await treeCubit.setTaskStatus(task.id, nextStatus[task.status]!);

      case TreeTileAction.reopenPressed:
        await treeCubit.setTaskStatus(task.id, TaskStatus.open);

      case TreeTileAction.addPressed:
        treeController.expand(task);
        widget.onAddPressed(task);

      case TreeTileAction.editPressed:
        var formResult = await showTaskForm(context, task);
        if (formResult != null && context.mounted) {
          if (formResult.containsKey('delete')) {
            await treeCubit.removeTask(task.id);
          } else {
            await treeCubit.updateTask(
              task.id,
              title: formResult['title'],
              isProject: formResult['isProject'],
              link: formResult['link'],
              groups: formResult['groups'],
            );
          }
        }

      case TreeTileAction.removePressed:
        await treeCubit.removeTask(task.id);

      default:
        throw Exception('Unknown action $action');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedTreeView<Task>(
      treeController: treeController,
      transitionBuilder: (context, child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: 1,
        child: child,
      ),
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.only(bottom: 100),
      nodeBuilder: (BuildContext context, TreeEntry<Task> entry) {
        return DragAndDropTreeTile(
          entry: entry,
          isReadOnly: widget.isReadOnly,
          onNodeAccepted: _onNodeAccepted,
          onAction: _onTileAction,
        );
      },
    );
  }
}
