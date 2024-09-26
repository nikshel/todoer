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

  TreeCubit(this._repository, this._eventBus) : super(TreeState([], [])) {
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
    await _refreshState(tree);
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
    await _refreshState(tree);
  }

  Future<void> setTaskStatus(int taskId, TaskStatus status) async {
    var tree = await _repository.setTaskStatus(taskId, status);
    _refreshState(tree);
  }

  Future<void> removeTask(int taskId) async {
    var tree = await _repository.removeTask(taskId);
    await _refreshState(tree);
  }

  Future<void> moveTask(int taskId, int? newParentId, int newIdx) async {
    var tree = await _repository.moveTask(taskId, newParentId, newIdx);
    await _refreshState(tree);
  }

  _onAuthEvent(AuthEvent event) {
    if (event.newAuthState.authorized) {
      _refreshState();
    } else {
      emit(TreeState([], []));
    }
  }

  Future<void> _refreshState([List<Task>? roots]) async {
    roots = roots ?? await _repository.getRoots();
    var groups = _repository.getGroups();
    emit(TreeState(roots, groups));
  }
}
