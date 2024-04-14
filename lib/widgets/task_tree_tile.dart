import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:todoer/models/task.dart';

import 'utils.dart';

class DragAndDropTreeTile extends StatelessWidget {
  const DragAndDropTreeTile({
    super.key,
    required this.entry,
    required this.onNodeAccepted,
    this.borderSide = BorderSide.none,
    this.isReadOnly = false,
    required this.onFolderPressed,
    required this.onCheckboxPressed,
    required this.onInWorkPressed,
    required this.onAddPressed,
    required this.onDeletePressed,
  });

  final TreeEntry<Task> entry;
  final TreeDragTargetNodeAccepted<Task> onNodeAccepted;
  final BorderSide borderSide;
  final bool isReadOnly;
  final VoidCallback? onFolderPressed;
  final void Function(Task, bool)? onCheckboxPressed;
  final void Function(Task)? onInWorkPressed;
  final void Function(Task) onAddPressed;
  final void Function(Task) onDeletePressed;

  @override
  Widget build(BuildContext context) {
    // var storage = Provider.of<TreeStorage>(context, listen: false);
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
                isReadOnly: isReadOnly,
                showIndentation: false,
              ),
            ),
          ),
          child: TreeTile(
            entry: entry,
            isReadOnly: isReadOnly,
            onFolderPressed: entry.node.isLeaf ? null : onFolderPressed,
            onCheckboxPressed: onCheckboxPressed,
            onInWorkPressed: onInWorkPressed,
            onAddPressed: onAddPressed,
            onDeletePressed: onDeletePressed,
            decoration: decoration,
          ),
        );
      },
    );
  }
}

class TreeTile extends StatelessWidget {
  const TreeTile({
    super.key,
    required this.entry,
    this.isReadOnly = false,
    this.onFolderPressed,
    this.onCheckboxPressed,
    this.onInWorkPressed,
    this.onAddPressed,
    this.onDeletePressed,
    this.decoration,
    this.showIndentation = true,
  });

  final TreeEntry<Task> entry;
  final bool isReadOnly;
  final VoidCallback? onFolderPressed;
  final void Function(Task, bool)? onCheckboxPressed;
  final void Function(Task)? onInWorkPressed;
  final void Function(Task)? onAddPressed;
  final void Function(Task)? onDeletePressed;
  final Decoration? decoration;
  final bool showIndentation;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Row(
        children: [
          Checkbox(
            shape: const CircleBorder(),
            value: entry.node.done,
            onChanged: onCheckboxPressed == null
                ? null
                : (value) => onCheckboxPressed!(entry.node, value!),
          ),
          if (entry.node.isProject)
            const Padding(
              padding: EdgeInsets.only(left: 5, right: 7),
              child: Icon(Icons.folder),
            ),
          Expanded(
            child: GestureDetector(
              onTap: onFolderPressed,
              child: Text(
                entry.node.title,
                style: TextStyle(
                    decoration:
                        entry.node.done ? TextDecoration.lineThrough : null,
                    color: entry.node.done ? Colors.grey : null),
              ),
            ),
          ),
          if (!entry.node.isLeaf)
            FolderButton(
              openedIcon: const Icon(Icons.expand_more),
              closedIcon: const Icon(Icons.chevron_right),
              isOpen: entry.node.isLeaf ? null : entry.isExpanded,
              onPressed: onFolderPressed,
            ),
          if (!entry.node.done)
            IconButton(
              icon: Icon(
                Icons.play_arrow,
                color: entry.node.isInWork ? Colors.blue : null,
              ),
              onPressed: onInWorkPressed == null
                  ? null
                  : () => onInWorkPressed!(entry.node),
            ),
          if (!isReadOnly)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed:
                  onAddPressed == null ? null : () => onAddPressed!(entry.node),
            ),
          if (!isReadOnly)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDeletePressed == null
                  ? null
                  : () => onDeletePressed!(entry.node),
            )
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
