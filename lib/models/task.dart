class Task {
  final int id;
  final String title;
  final bool done;

  Task? parent; // TODO late final
  final int index;
  final List<Task> children = [];
  bool get isLeaf => children.isEmpty;

  Task({
    required this.id,
    required this.title,
    required this.done,
    required this.index,
  });

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
