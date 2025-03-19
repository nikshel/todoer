import 'package:event_bus/event_bus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todoer/blocs/events.dart';

import 'package:todoer/models/group.dart';
import 'package:todoer/repositories/tree.dart';
import 'package:todoer/models/task.dart';

class TreeState {
  final List<Task> rootTasks;
  final List<Group> groups;

  TreeState(this.rootTasks, this.groups);
}

class TreeCubit extends Cubit<TreeState> {
  final TreeRepository _repository;
  final EventBus _eventBus;

  TreeCubit(this._repository, this._eventBus)
      : super(TreeState([], _repository.getGroups())) {
    _eventBus.on<AuthEvent>().listen(_onAuthEvent);
  }

  Future<void> createTask({
    required String title,
    required bool isProject,
    required String? link,
    required int? parentId,
    required List<Group> groups,
  }) async {
    var tree = await _repository.createTask(
        title: title,
        isProject: isProject,
        link: link,
        parentId: parentId,
        groups: groups);
    await _emitState(tree);
  }

  Future<void> updateTask(
    int taskId, {
    required String title,
    required bool isProject,
    required String? link,
    required List<Group> groups,
  }) async {
    var tree = await _repository.updateTask(
      taskId,
      title: title,
      isProject: isProject,
      link: link,
      groups: groups,
    );
    await _emitState(tree);
  }

  Future<void> setTaskStatus(int taskId, TaskStatus status) async {
    var tree = await _repository.setTaskStatus(taskId, status);
    _emitState(tree);
  }

  Future<void> removeTask(int taskId) async {
    var tree = await _repository.removeTask(taskId);
    await _emitState(tree);
  }

  Future<void> removeAllDoneTasks() async {
    var tree = await _repository.removeAllDoneTasks();
    await _emitState(tree);
  }

  Future<void> moveTask(int taskId, int? newParentId, int newIdx) async {
    var tree = await _repository.moveTask(taskId, newParentId, newIdx);
    await _emitState(tree);
  }

  _onAuthEvent(AuthEvent event) async {
    if (event.newAuthState.authorized) {
      await updateRoots(allowCached: true);
      updateRoots();
    } else {
      await _repository.clearRootsCache();
      _emitState([]);
    }
  }

  Future<void> updateRoots({bool allowCached = false}) async {
    var roots = await _repository.getRoots(allowCached: allowCached);
    _emitState(roots);
  }

  Future<void> _emitState(List<Task> roots) async {
    var groups = _repository.getGroups();
    emit(TreeState(roots, groups));
  }
}
