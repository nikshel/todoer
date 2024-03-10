import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:provider/provider.dart';
import 'package:todoer/models/storage.dart';
import 'package:todoer/models/task.dart';

extension on TreeDragAndDropDetails<Task> {
  /// Splits the target node's height in three and checks the vertical offset
  /// of the dragging node, applying the appropriate callback.
  T mapDropPosition<T>({
    required T Function() whenAbove,
    required T Function() whenInside,
    required T Function() whenBelow,
  }) {
    final double oneThirdOfTotalHeight = targetBounds.height * 0.3;
    final double pointerVerticalOffset = dropPosition.dy;

    if (pointerVerticalOffset < oneThirdOfTotalHeight) {
      return whenAbove();
    } else if (pointerVerticalOffset < oneThirdOfTotalHeight * 2) {
      return whenInside();
    } else {
      return whenBelow();
    }
  }
}

class DragAndDropTreeView extends StatefulWidget {
  const DragAndDropTreeView({super.key});

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
          roots: roots,
          childrenProvider: (Task node) => node.children,
          parentProvider: (Task node) => node.parent,
        );
        treeController!.expandAll();
      });
    } else {
      setState(() {
        treeController!.roots = roots;
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

    details.mapDropPosition(
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
      return const Text('loading');
    }

    final IndentGuide indentGuide = DefaultIndentGuide.of(context);
    final BorderSide borderSide = BorderSide(
      color: Theme.of(context).colorScheme.outline,
      width: indentGuide is AbstractLineGuide ? indentGuide.thickness : 2.0,
    );

    return AnimatedTreeView<Task>(
      treeController: treeController!,
      nodeBuilder: (BuildContext context, TreeEntry<Task> entry) {
        return DragAndDropTreeTile(
          entry: entry,
          borderSide: borderSide,
          onNodeAccepted: onNodeAccepted,
          onFolderPressed: () => treeController!.toggleExpansion(entry.node),
          storage: storage,
        );
      },
      duration: const Duration(milliseconds: 300),
    );
  }
}

class DragAndDropTreeTile extends StatelessWidget {
  const DragAndDropTreeTile({
    super.key,
    required this.entry,
    required this.onNodeAccepted,
    this.borderSide = BorderSide.none,
    this.onFolderPressed,
    required this.storage,
  });

  final TreeEntry<Task> entry;
  final TreeDragTargetNodeAccepted<Task> onNodeAccepted;
  final BorderSide borderSide;
  final VoidCallback? onFolderPressed;
  final TreeStorage storage;

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
            border: details.mapDropPosition(
              whenAbove: () => Border(top: borderSide),
              whenInside: () => Border.fromBorderSide(borderSide),
              whenBelow: () => Border(bottom: borderSide),
            ),
          );
        }

        return TreeDraggable<Task>(
          node: entry.node,
          childWhenDragging: Opacity(
            opacity: .5,
            child: IgnorePointer(
              child: TreeTile(
                entry: entry,
                storage: storage,
              ),
            ),
          ),
          feedback: IntrinsicWidth(
            child: Material(
              elevation: 4,
              child: TreeTile(
                entry: entry,
                storage: storage,
                showIndentation: false,
                onFolderPressed: () {},
              ),
            ),
          ),
          child: TreeTile(
            entry: entry,
            storage: storage,
            onFolderPressed: entry.node.isLeaf ? null : onFolderPressed,
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
            child: Text('Node ${entry.node.title} (${entry.node.id})'),
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
