class Task {
  final int id;
  final String title;
  final bool done;
  final DateTime? startSince;
  final bool isProject;
  final int index;

  Task? parent; // TODO late final
  final List<Task> children = [];

  bool get isLeaf => children.isEmpty;
  bool get isInWork =>
      !done && startSince != null && DateTime.timestamp().isAfter(startSince!);

  Task({
    required this.id,
    required this.title,
    required this.done,
    required this.startSince,
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
    return 'Task $id "$title" ${parent?.id} $index';
  }
}
