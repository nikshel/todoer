import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:todoer/models/task.dart';
import 'package:todoer/widgets/task_form.dart';

T mapDropPosition<T>(
  TreeDragAndDropDetails<Task> details, {
  required T Function() whenAbove,
  required T Function() whenInside,
  required T Function() whenBelow,
}) {
  final double oneThirdOfTotalHeight = details.targetBounds.height * 0.3;
  final double pointerVerticalOffset = details.dropPosition.dy;

  if (pointerVerticalOffset < oneThirdOfTotalHeight) {
    return whenAbove();
  } else if (pointerVerticalOffset < oneThirdOfTotalHeight * 2) {
    return whenInside();
  } else {
    return whenBelow();
  }
}

Future<Map<String, dynamic>?> showTaskForm(
  BuildContext context, [
  Task? current,
]) async {
  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => TaskForm(currentTask: current),
  );
}
