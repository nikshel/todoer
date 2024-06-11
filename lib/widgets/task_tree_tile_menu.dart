import 'package:flutter/material.dart';

enum TaskTreeTileMenuOption {
  add,
  edit,
  reopen,
  remove,
}

class TaskTreeTileMenuButton extends StatelessWidget {
  final void Function(TaskTreeTileMenuOption) onOptionSelected;

  final List<(TaskTreeTileMenuOption, IconData, String)> _options;

  TaskTreeTileMenuButton({
    super.key,
    required this.onOptionSelected,
    required bool showReopenOption,
    required bool showAddOption,
  }) : _options = [
          if (showAddOption)
            (TaskTreeTileMenuOption.add, Icons.add, 'Добавить подзадачу'),
          if (showReopenOption)
            (TaskTreeTileMenuOption.reopen, Icons.replay, 'Переоткрыть'),
          (TaskTreeTileMenuOption.edit, Icons.edit, 'Редактировать'),
          (TaskTreeTileMenuOption.remove, Icons.delete, 'Удалить'),
        ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TaskTreeTileMenuOption>(
        position: PopupMenuPosition.under,
        tooltip: 'Меню',
        onSelected: onOptionSelected,
        child: const Icon(Icons.more_vert),
        itemBuilder: (context) => _options
            .map((o) => PopupMenuItem<TaskTreeTileMenuOption>(
                  value: o.$1,
                  child: Row(
                    children: [
                      Icon(o.$2),
                      const SizedBox(width: 5),
                      Text(o.$3),
                    ],
                  ),
                ))
            .toList());
  }
}
