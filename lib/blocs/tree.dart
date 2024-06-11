import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:todoer/models/group.dart';
import 'package:todoer/repositories/tree.dart';
import 'package:todoer/models/task.dart';

class TreeState {
  final List<Task> rootTasks;
  final List<Group> groups;

  TreeState(this.rootTasks, this.groups);
}

class TreeCubit extends Cubit<TreeState> {
  final TreeRepository repository;

  TreeCubit(this.repository) : super(TreeState([], [])) {
    _refreshState();
  }

  Future<void> createTask({
    required String title,
    required bool isProject,
    required String? link,
    required int? parentId,
    required List<Group> groups,
  }) async {
    await repository.createTask(
        title: title,
        isProject: isProject,
        link: link,
        parentId: parentId,
        groups: groups);
    await _refreshState();
  }

  Future<void> updateTask(
    int taskId, {
    required String title,
    required bool isProject,
    required String? link,
    required List<Group> groups,
  }) async {
    await repository.updateTask(
      taskId,
      title: title,
      isProject: isProject,
      link: link,
      groups: groups,
    );
    await _refreshState();
  }

  Future<void> setTaskStatus(int taskId, TaskStatus status) async {
    await repository.setTaskStatus(taskId, status);
    _refreshState();
  }

  Future<void> removeTask(int taskId) async {
    await repository.removeTask(taskId);
    await _refreshState();
  }

  Future<void> moveTask(int taskId, int? newParentId, int newIdx) async {
    await repository.moveTask(taskId, newParentId, newIdx);
    await _refreshState();
  }

  Future<void> _refreshState() async {
    var roots = await repository.getRoots();
    var groups = await repository.getGroups();
    emit(TreeState(roots, groups));
  }
}
