import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:todoer/models/storage.dart';
import 'package:todoer/models/task.dart';

class TreeTile extends StatelessWidget {
  const TreeTile({
    super.key,
    required this.entry,
    this.onFolderPressed,
    this.decoration,
    this.showIndentation = true,
    required this.storage,
  });

  final TreeEntry<Task> entry;
  final VoidCallback? onFolderPressed;
  final Decoration? decoration;
  final bool showIndentation;
  final TreeStorage storage;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Row(
        children: [
          FolderButton(
            openedIcon: const Icon(Icons.expand_more),
            closedIcon: const Icon(Icons.chevron_right),
            isOpen: entry.node.isLeaf ? null : entry.isExpanded,
            onPressed: onFolderPressed,
          ),
          Checkbox(
            // shape: CircleBorder(),
            value: entry.node.done,
            onChanged: (value) async =>
                await storage.makeTaskDone(entry.node.id, value!),
          ),
          Expanded(
            child: Text(
              entry.node.title,
              style: TextStyle(
                  decoration:
                      entry.node.done ? TextDecoration.lineThrough : null,
                  color: entry.node.done ? Colors.grey : null),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async => await storage.removeTask(entry.node.id),
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
        child: content,
      );
    }

    return content;
  }
}
