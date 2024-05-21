enum GroupSystemType {
  today,
  week,
}

class Group {
  final int id;
  final String title;
  final GroupSystemType systemType;

  Group({
    required this.id,
    required this.title,
    required this.systemType,
  });

  @override
  bool operator ==(Object other) {
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
