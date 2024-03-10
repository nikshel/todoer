import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:todoer/models/task.dart';

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
