import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:provider/provider.dart';
import 'package:todoer/models/storage.dart';
import 'package:todoer/models/task.dart';

import 'task_tree_tile.dart';
import 'utils.dart';

bool allow(Task _) => true;

class DragAndDropTreeView extends StatefulWidget {
  const DragAndDropTreeView({
    super.key,
    this.isReadOnly = false,
    this.shouldShow = allow,
    required this.onAddPressed,
  });

  final void Function(Task) onAddPressed;
  final bool Function(Task) shouldShow;
  final bool isReadOnly;

  @override
  State<DragAndDropTreeView> createState() => _DragAndDropTreeViewState();
}

class _DragAndDropTreeViewState extends State<DragAndDropTreeView> {
  TreeController<Task>? treeController;
  late TreeStorage storage;
  Task? expandOnUpdate;

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();

    storage = Provider.of<TreeStorage>(context);
    var roots = await storage.getRoots();

    if (treeController == null) {
      setState(() {
        treeController = TreeController<Task>(
          roots: roots.where(widget.shouldShow),
          childrenProvider: (Task node) =>
              node.children.where(widget.shouldShow),
          parentProvider: (Task node) => node.parent,
        );
        treeController!.expandAll();
      });
    } else {
      setState(() {
        treeController!.roots = roots.where(widget.shouldShow);
      });
    }
  }

  @override
  void dispose() {
    treeController?.dispose();
    super.dispose();
  }

  void onNodeAccepted(TreeDragAndDropDetails<Task> details) async {
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

        // Ensure that the dragged node is visible after reordering.

        expandOnUpdate = details.targetNode;
        // setState(() {
        // treeController!.setExpansionState(details.targetNode, true);
        // });
      },
      whenBelow: () {
        // Insert the dragged node as the next sibling of the target node.
        newParent = details.targetNode.parent;
        newIndex = details.targetNode.index + 1;
      },
    );

    await storage.moveTask(details.draggedNode.id, newParent?.id, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (treeController == null) {
      return const SizedBox.shrink();
    }

    final IndentGuide indentGuide = DefaultIndentGuide.of(context);
    final BorderSide borderSide = BorderSide(
      color: Theme.of(context).colorScheme.outline,
      width: indentGuide is AbstractLineGuide ? indentGuide.thickness : 2.0,
    );

    return AnimatedTreeView<Task>(
      treeController: treeController!,
      transitionBuilder: (context, child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: 1,
        child: child,
      ),
      duration: const Duration(milliseconds: 200),
      nodeBuilder: (BuildContext context, TreeEntry<Task> entry) {
        return DragAndDropTreeTile(
          entry: entry,
          isReadOnly: widget.isReadOnly,
          borderSide: borderSide,
          onNodeAccepted: onNodeAccepted,
          onFolderPressed: () => treeController!.toggleExpansion(entry.node),
          onCheckboxPressed: (task, value) async =>
              await storage.makeTaskDone(entry.node.id, value),
          onInWorkPressed: (task) async =>
              await storage.makeTaskInWork(task.id, !task.isInWork),
          onAddPressed: (task) {
            treeController!.expand(task);
            widget.onAddPressed(task);
          },
          onEditPressed: (task) async {
            var formResult = await showTaskForm(context, entry.node);
            if (formResult != null && context.mounted) {
              if (formResult.containsKey('delete')) {
                await storage.removeTask(task.id);
              } else {
                await storage.updateTask(
                  task.id,
                  title: formResult['title'],
                  isProject: formResult['isProject'],
                );
              }
            }
          },
        );
      },
    );
  }
}
