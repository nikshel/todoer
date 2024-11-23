import 'dart:async';

import 'package:todoer/client.dart';
import 'package:todoer/models/group.dart';
import 'package:todoer/models/task.dart';
import 'package:todoer/repositories/local_storage.dart';

class TreeRepository {
  static const List<Group> _groups = [
    Group(id: 1, title: 'Сегодня', systemType: GroupSystemType.today),
    Group(id: 2, title: 'Неделя', systemType: GroupSystemType.week),
    Group(id: 3, title: 'Ожидание', systemType: GroupSystemType.waiting),
  ];

  static const String _cacheKey = 'tasktree';

  final TodoerClient _client;
  final LocalStorageRepository _localStorage;

  TreeRepository(this._client, this._localStorage);

  Future<List<Task>> getRoots({required bool allowCached}) async {
    if (allowCached) {
      var cachedTree = await _getCachedRoots();
      if (cachedTree != null) {
        return cachedTree;
      }
    }

    var tree = await _client.getTasksTree();
    return _processTreeResponse(tree);
  }

  clearRootsCache() async {
    _localStorage.deleteCacehedValue(_cacheKey);
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
    return _processTreeResponse(tree);
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
    return _processTreeResponse(tree);
  }

  Future<List<Task>> setTaskStatus(int taskId, TaskStatus status) async {
    var tree = await _client.setTaskStatus(taskId, status.value);
    return _processTreeResponse(tree);
  }

  Future<List<Task>> removeTask(int taskId) async {
    var tree = await _client.deleteTask(taskId);
    return _processTreeResponse(tree);
  }

  Future<List<Task>> moveTask(int taskId, int? newParentId, int newIdx) async {
    var tree = await _client.moveTask(taskId, newParentId, newIdx);
    return _processTreeResponse(tree);
  }

  List<Group> getGroups() {
    return _groups;
  }

  Future<List<Task>?> _getCachedRoots() async {
    List<dynamic>? tree = await _localStorage.getCachedValue('tasktree');
    if (tree == null) {
      return null;
    }
    try {
      return _processTreeResponse(tree);
    } on Exception catch (e) {
      // ignore: avoid_print
      print(e);
      return null;
    }
  }

  List<Task> _processTreeResponse(List<dynamic> rawTasks) {
    var tree = _parseTree(rawTasks);
    _localStorage.setCachedValue(_cacheKey, rawTasks);
    return tree;
  }

  List<Task> _parseTree(List<dynamic> rawTasks, [Task? parent]) {
    return rawTasks.map((rawTask) {
      var rawChildren = (rawTask['children'] as List<dynamic>);
      var task = _makeTask(rawTask, parent);
      task.children.addAll(_parseTree(rawChildren, task));
      return task;
    }).toList();
  }

  Task _makeTask(Map<dynamic, dynamic> values, Task? parent) {
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
