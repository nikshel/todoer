import 'package:equatable/equatable.dart';
import 'package:todoer/models/group.dart';

enum TaskStatus {
  open('open'),
  inWork('in_work'),
  done('done');

  final String value;

  const TaskStatus(this.value);
}

TaskStatus statusFromStr(String str) {
  if (str == 'in_work') return TaskStatus.inWork;
  return TaskStatus.values.byName(str);
}

class Task extends Equatable {
  final int id;
  final String title;
  final TaskStatus status;
  final String? link;
  final bool isProject;
  final int index;

  final List<Group> groups;

  final Task? parent;
  final List<Task> children = [];

  bool get isLeaf => children.isEmpty;

  Task({
    required this.id,
    required this.title,
    required this.status,
    required this.link,
    required this.isProject,
    required this.index,
    required this.parent,
    required this.groups,
  });

  Iterable<Task> getAllChildren() sync* {
    // TODO optimize
    for (var c in children) {
      yield c;
      yield* c.getAllChildren();
    }
  }

  Iterable<Task> getAllParents() sync* {
    if (parent == null) {
      return;
    }
    yield parent!;
    yield* parent!.getAllParents();
  }

  @override
  String toString() {
    return 'Task $id "$title" $status ${parent?.id} $index';
  }

  @override
  List<Object?> get props => [id];
}
