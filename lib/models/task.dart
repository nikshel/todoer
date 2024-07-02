import 'package:equatable/equatable.dart';
import 'package:todoer/models/group.dart';

enum TaskStatus {
  open,
  inWork,
  done,
}

// TODO fix immutable
// ignore: must_be_immutable
class Task extends Equatable {
  final int id;
  final String title;
  final TaskStatus status;
  final DateTime? startSince;
  final String? link;
  final bool isProject;
  final int index;

  final List<Group> groups;

  Task? parent; // TODO late final
  final List<Task> children = [];

  bool get isLeaf => children.isEmpty;

  Task({
    required this.id,
    required this.title,
    required this.status,
    required this.startSince,
    required this.link,
    required this.isProject,
    required this.index,
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
