import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:todoer/models/task.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'utils.dart';

enum TreeTileAction {
  expandPressed,
  statusSwitchPressed,
  inWorkPressed,
  addPressed,
  editPressed,
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
            onAction: onAction,
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
        child: ListTile(
          hoverColor: const Color.fromARGB(255, 239, 239, 239),
          onTap: () {},
          leading: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                icon: Icon(icons[entry.node.status]),
                color:
                    entry.node.status == TaskStatus.inWork ? Colors.blue : null,
                onPressed: onAction == null
                    ? null
                    : () => onAction!(
                        TreeTileAction.statusSwitchPressed, entry.node)),
            if (entry.node.isProject)
              const Padding(
                padding: EdgeInsets.only(left: 7, right: 7),
                child: Icon(Icons.folder),
              ),
          ]),
          title: Expanded(
            child: GestureDetector(
              onTap: () => onAction!(TreeTileAction.expandPressed, entry.node),
              onDoubleTap: () => onAction == null
                  ? null
                  : onAction!(TreeTileAction.editPressed, entry.node),
              child: Text(
                entry.node.title,
                style: TextStyle(
                    decoration: entry.node.status == TaskStatus.done
                        ? TextDecoration.lineThrough
                        : null,
                    color: entry.node.status == TaskStatus.done
                        ? Colors.grey
                        : null),
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.node.link != null)
                IconButton(
                  onPressed: () => launchUrlString(
                    entry.node.link!,
                    mode: LaunchMode.platformDefault,
                  ),
                  icon: const Icon(Icons.link),
                ),
              if (entry.node.status == TaskStatus.inWork)
                IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: onAction == null
                      ? null
                      : () =>
                          onAction!(TreeTileAction.inWorkPressed, entry.node),
                ),
              if (!entry.node.isLeaf)
                FolderButton(
                  openedIcon: const Icon(Icons.expand_more),
                  closedIcon: const Icon(Icons.chevron_right),
                  isOpen: entry.node.isLeaf ? null : entry.isExpanded,
                  onPressed: () =>
                      onAction!(TreeTileAction.expandPressed, entry.node),
                ),
              if (!isReadOnly)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: onAction == null
                      ? null
                      : () => onAction!(TreeTileAction.addPressed, entry.node),
                ),
            ],
          ),
        ));

    if (decoration != null) {
      content = DecoratedBox(
        decoration: decoration!,
        child: content,
      );
    }

    if (showIndentation) {
      return TreeIndentation(
        entry: entry,
        guide: const ConnectingLinesGuide(indent: 40),
        child: content,
      );
    }

    return content;
  }
}
