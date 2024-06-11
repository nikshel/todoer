import 'package:equatable/equatable.dart';

enum GroupSystemType {
  today,
  week,
  waiting,
}

class Group extends Equatable {
  final int id;
  final String title;
  final GroupSystemType systemType;

  const Group({
    required this.id,
    required this.title,
    required this.systemType,
  });

  @override
  List<Object?> get props => [id];
}
