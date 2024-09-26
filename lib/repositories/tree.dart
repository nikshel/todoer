import 'dart:async';

import 'package:todoer/client.dart';
import 'package:todoer/models/group.dart';
import 'package:todoer/models/task.dart';

class TreeRepository {
  final TodoerClient _client;
  static const List<Group> _groups = [
    Group(id: 1, title: 'Сегодня', systemType: GroupSystemType.today),
    Group(id: 2, title: 'Неделя', systemType: GroupSystemType.week),
    Group(id: 3, title: 'Ожидание', systemType: GroupSystemType.waiting),
  ];

  TreeRepository(this._client);

  Future<List<Task>> getRoots() async {
    var tree = await _client.getTasksTree();
    return _parseTree(tree);
  }

  Future<List<Task>> createTask({
    required String title,
    required bool isProject,
    required String? link,
    required int? parentId,
    required List<Group> groups,
  }) async {
    var tree = await _client.createTask(
      title: title,
      isProject: isProject,
      link: link,
      parentId: parentId,
      systemTags: groups.map((g) => g.systemType.name).toList(),
    );
    return _parseTree(tree);
  }

  Future<List<Task>> updateTask(
    int taskId, {
    required String title,
    required bool isProject,
    required String? link,
    required List<Group> groups,
  }) async {
    var tree = await _client.updateTask(
      taskId,
      title: title,
      isProject: isProject,
      link: link,
      systemTags: groups.map((g) => g.systemType.name).toList(),
    );
    return _parseTree(tree);
  }

  Future<List<Task>> setTaskStatus(int taskId, TaskStatus status) async {
    var tree = await _client.setTaskStatus(taskId, status.value);
    return _parseTree(tree);
  }

  Future<List<Task>> removeTask(int taskId) async {
    var tree = await _client.deleteTask(taskId);
    return _parseTree(tree);
  }

  Future<List<Task>> moveTask(int taskId, int? newParentId, int newIdx) async {
    var tree = await _client.moveTask(taskId, newParentId, newIdx);
    return _parseTree(tree);
  }

  List<Group> getGroups() {
    return _groups;
  }

  List<Task> _parseTree(List<dynamic> rawTasks, [Task? parent]) {
    return rawTasks.map((rawTask) {
      var rawChildren = (rawTask['children'] as List<dynamic>);
      var task = _makeTask(rawTask, parent);
      task.children.addAll(_parseTree(rawChildren, task));
      return task;
    }).toList();
  }

  Task _makeTask(Map<String, Object?> values, Task? parent) {
    return Task(
      id: values['id'] as int,
      title: values['title'] as String,
      isProject: values['is_project'] as bool,
      status: statusFromStr(values['status'] as String),
      link: values['link'] == null ? null : values['link'] as String,
      index: values['order'] as int,
      groups: List<String>.from(values['system_tags'] as List)
          .map((tag) => _groups.firstWhere((g) => g.systemType.name == tag))
          .toList(),
      parent: parent,
    );
  }
}
