import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:todoer/models/task.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'utils.dart';

enum TreeTileAction {
  expandPressed,
  statusSwitchPressed,
  reopenPressed,
  addPressed,
  editPressed,
  removePressed,
}

class DragAndDropTreeTile extends StatelessWidget {
  const DragAndDropTreeTile({
    super.key,
    required this.entry,
    required this.onNodeAccepted,
    required this.onAction,
    this.isReadOnly = false,
  });

  final TreeEntry<Task> entry;
  final TreeDragTargetNodeAccepted<Task> onNodeAccepted;
  final bool isReadOnly;
  final void Function(TreeTileAction, Task) onAction;

  @override
  Widget build(BuildContext context) {
    final IndentGuide indentGuide = DefaultIndentGuide.of(context);
    final BorderSide borderSide = BorderSide(
      color: Theme.of(context).colorScheme.outline,
      width: indentGuide is AbstractLineGuide ? indentGuide.thickness : 2.0,
    );

    return TreeDragTarget<Task>(
      node: entry.node,
      onNodeAccepted: onNodeAccepted,
      builder: (BuildContext context, TreeDragAndDropDetails<Task>? details) {
        Decoration? decoration;

        if (details != null) {
          // Add a border to indicate in which portion of the target's height
          // the dragging node will be inserted.
          decoration = BoxDecoration(
            border: mapDropPosition(
              details,
              whenAbove: () => Border(top: borderSide),
              whenInside: () => Border.fromBorderSide(borderSide),
              whenBelow: () => Border(bottom: borderSide),
            ),
          );
        }

        return TreeDraggable<Task>(
          node: entry.node,
          longPressDelay: const Duration(milliseconds: 150),
          childWhenDragging: Opacity(
            opacity: .5,
            child: IgnorePointer(
              child: TreeTile(
                entry: entry,
                isReadOnly: isReadOnly,
              ),
            ),
          ),
          feedback: IntrinsicWidth(
            child: Material(
              elevation: 4,
              child: TreeTile(
                entry: entry,
                isReadOnly: true,
                showIndentation: false,
              ),
            ),
          ),
          child: TreeTile(
            entry: entry,
            isReadOnly: isReadOnly,
            onAction: onAction,
            decoration: decoration,
          ),
        );
      },
    );
  }
}

enum TreeTileMenuOption {
  addTask,
  reopenTask,
  removeTask,
}

class TreeTile extends StatelessWidget {
  const TreeTile({
    super.key,
    required this.entry,
    this.isReadOnly = false,
    this.onAction,
    this.decoration,
    this.showIndentation = true,
  });

  final TreeEntry<Task> entry;
  final bool isReadOnly;
  final void Function(TreeTileAction, Task)? onAction;

  final Decoration? decoration;
  final bool showIndentation;

  static final icons = <TaskStatus, IconData>{
    TaskStatus.open: Icons.circle_outlined,
    TaskStatus.inWork: Icons.play_arrow,
    TaskStatus.done: Icons.check,
  };

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Row(
        children: [
          IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              icon: Icon(icons[entry.node.status]),
              color:
                  entry.node.status == TaskStatus.inWork ? Colors.blue : null,
              onPressed: onAction == null
                  ? null
                  : () => onAction!(
                      TreeTileAction.statusSwitchPressed, entry.node)),
          if (entry.node.isProject)
            const Padding(
              padding: EdgeInsets.only(left: 3, right: 7),
              child: Icon(Icons.folder),
            ),
          Expanded(
            child: GestureDetector(
              onTap: () => onAction!(TreeTileAction.expandPressed, entry.node),
              onDoubleTap: () => onAction == null
                  ? null
                  : onAction!(TreeTileAction.editPressed, entry.node),
              behavior: HitTestBehavior.translucent,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    entry.node.title,
                    style: TextStyle(
                        fontSize: 15,
                        decoration: entry.node.status == TaskStatus.done
                            ? TextDecoration.lineThrough
                            : null,
                        color: entry.node.status == TaskStatus.done
                            ? Colors.grey
                            : null),
                  ),
                  if (!entry.node.isLeaf)
                    FolderButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(3),
                      openedIcon: const Icon(Icons.expand_more),
                      closedIcon: const Icon(Icons.chevron_right),
                      isOpen: entry.node.isLeaf ? null : entry.isExpanded,
                      onPressed: () =>
                          onAction!(TreeTileAction.expandPressed, entry.node),
                    ),
                ],
              ),
            ),
          ),
          if (entry.node.link != null)
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(3),
              onPressed: () => launchUrlString(
                entry.node.link!,
                mode: LaunchMode.platformDefault,
              ),
              icon: const Icon(Icons.link),
            ),
          if (!isReadOnly)
            PopupMenuButton<TreeTileMenuOption>(
              onSelected: (menuOption) => (switch (menuOption) {
                TreeTileMenuOption.addTask =>
                  onAction!(TreeTileAction.addPressed, entry.node),
                TreeTileMenuOption.reopenTask =>
                  onAction!(TreeTileAction.reopenPressed, entry.node),
                TreeTileMenuOption.removeTask =>
                  onAction!(TreeTileAction.removePressed, entry.node),
              }),
              child: const Icon(Icons.more_vert),
              itemBuilder: (context) => <PopupMenuEntry<TreeTileMenuOption>>[
                if (entry.node.status == TaskStatus.inWork)
                  const PopupMenuItem<TreeTileMenuOption>(
                    value: TreeTileMenuOption.reopenTask,
                    child: Text('Переоткрыть'),
                  ),
                const PopupMenuItem<TreeTileMenuOption>(
                  value: TreeTileMenuOption.addTask,
                  child: Text('Добавить подзадачу'),
                ),
                const PopupMenuItem<TreeTileMenuOption>(
                  value: TreeTileMenuOption.removeTask,
                  child: Text('Удалить'),
                ),
              ],
            ),
        ],
      ),
    );

    if (decoration != null) {
      content = DecoratedBox(
        decoration: decoration!,
        child: content,
      );
    }

    if (showIndentation) {
      return TreeIndentation(
        entry: entry,
        guide: const ConnectingLinesGuide(indent: 33),
        child: content,
      );
    }

    return content;
  }
}
