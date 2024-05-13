enum TaskStatus {
  open,
  inWork,
  done,
}

class Task {
  final int id;
  final String title;
  final TaskStatus status;
  final DateTime? startSince;
  final String? link;
  final bool isProject;
  final int index;

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
  });

  Iterable<Task> getAllChildren() sync* {
    // TODO optimize
    for (var c in children) {
      yield c;
      yield* c.getAllChildren();
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Task $id "$title" $status ${parent?.id} $index';
  }
}
