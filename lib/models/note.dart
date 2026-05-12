import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  bool get isVirtual => id == null;

  factory Note.fromJson(Map<String, dynamic> json) {
    final String rawCreatedAt = json['created_at'] as String;
    return Note(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(rawCreatedAt).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id];
}
