import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todoer/models/task.dart';

const tasksTable = 'tasks';

class TreeStorage extends ChangeNotifier {
  final Database _db;

  TreeStorage(this._db);

  Future<List<Task>> getRoots() async {
    var res = await _db.query(tasksTable, orderBy: 'parent_id, idx');

    var tasksById = <int, Task>{};
    for (var rawTask in res) {
      var task = _makeTask(rawTask);
      tasksById[task.id] = task;
    }

    var roots = <Task>[];
    for (var rawTask in res) {
      var taskId = rawTask['id'] as int;
      var task = tasksById[taskId];
      assert(task != null);

      var parentId = rawTask['parent_id'] as int?;
      var parent = parentId == null ? null : tasksById[parentId];
      var targetChildren = parent?.children ?? roots;

      assert(targetChildren.length == task!.index, 'Incorrect task idx');
      task!.parent = parent;
      targetChildren.add(task);
    }
    return roots;
  }

  Future<void> createTask({
    required String title,
    required bool isProject,
    int? parentId,
  }) async {
    await _db.transaction((txn) async {
      var res = await txn.query(
        tasksTable,
        columns: ['MAX(idx) AS max_idx'],
        where: 'parent_id IS ?',
        whereArgs: [parentId],
      );
      int maxIdx = (res[0]['max_idx'] as int?) ?? -1;

      await txn.insert(tasksTable, {
        'title': title,
        'is_project': isProject ? 1 : 0,
        'parent_id': parentId,
        'idx': maxIdx + 1,
      });
    }, exclusive: true);

    notifyListeners();
  }

  Future<void> updateTask(
    int taskId, {
    required String title,
    required bool isProject,
  }) async {
    await _db.update(
      tasksTable,
      {
        'title': title,
        'is_project': isProject ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );

    notifyListeners();
  }

  Future<void> setTaskStatus(int taskId, TaskStatus status) async {
    String where;
    List<Object?> args;

    switch (status) {
      case TaskStatus.open:
        (where, args) = _getOpenQuery(taskId);
        break;
      case TaskStatus.inWork:
        (where, args) = _getInWorkQuery(taskId);
        break;
      case TaskStatus.done:
        (where, args) = _getDoneQuery(taskId);
        break;
      default:
        throw Exception('Unknown status $status');
    }

    await _db.update(
      tasksTable,
      {'status': status.name},
      where: where,
      whereArgs: args,
    );

    notifyListeners();
  }

  (String, List<Object?>) _getOpenQuery(int taskId) {
    //?
    var (idsSubquery, args) = _getOwnWithParentsIdsQuery(taskId);
    return (
      'id IN ($idsSubquery) AND (id = ? OR status = ?)',
      args + [taskId, TaskStatus.done.name],
    );
  }

  (String, List<Object?>) _getDoneQuery(int taskId) {
    var (idsSubquery, args) = _getOwnWithChildrenIdsQuery(taskId);
    return ('id IN ($idsSubquery)', args);
  }

  (String, List<Object?>) _getInWorkQuery(int taskId) {
    var (idsSubquery, args) = _getOwnWithParentsIdsQuery(taskId);
    return ('id IN ($idsSubquery)', args);
  }

  Future<void> removeTask(int taskId) async {
    await _db.transaction((txn) async {
      var res = await txn.rawQuery('''
        DELETE FROM $tasksTable
        WHERE id = ?
        RETURNING parent_id, idx
      ''', [taskId]);
      var parentId = res[0]['parent_id'] as int?;
      var idx = res[0]['idx'] as int;

      await txn.rawUpdate('''
        UPDATE $tasksTable
        SET idx = idx - 1
        WHERE parent_id IS ? AND idx > ?
      ''', [parentId, idx]); // todo shifts
    });
    notifyListeners();
  }

  Future<void> moveTask(int taskId, int? newParentId, int newIdx) async {
    _db.transaction((txn) async {
      var res = await txn.query(
        tasksTable,
        columns: ['parent_id', 'idx'],
        where: 'id = ?',
        whereArgs: [taskId],
      );
      var currentParentId = res[0]['parent_id'] as int?;
      var currentIdx = res[0]['idx'] as int;
      if (newParentId == currentParentId && currentIdx < newIdx) {
        newIdx--;
      }

      var batch = txn.batch();
      batch
        ..rawUpdate('''
            UPDATE $tasksTable
            SET idx = -1
            WHERE id = ?
          ''', [taskId])
        ..rawUpdate('''
            UPDATE $tasksTable
            SET idx = idx - 1000000
            WHERE parent_id IS ? AND idx > ?
            ''', [currentParentId, currentIdx])
        ..rawUpdate('''
            UPDATE $tasksTable
            SET idx = idx + 999999
            WHERE parent_id IS ? AND idx < -1
            ''', [currentParentId])
        ..rawUpdate('''
            UPDATE $tasksTable
            SET idx = idx + 1000000
            WHERE parent_id IS ? AND idx >= ?
          ''', [newParentId, newIdx])
        ..rawUpdate('''
            UPDATE $tasksTable
            SET idx = idx - 999999
            WHERE parent_id IS ? AND idx >= 1000000
            ''', [newParentId])
        ..rawUpdate('''
            UPDATE $tasksTable
            SET parent_id = ?, idx = ?
            WHERE id = ?
            ''', [newParentId, newIdx, taskId]);
      await batch.apply(noResult: true);
    }, exclusive: true);

    notifyListeners();
  }

  (String, List<Object?>) _getOwnWithChildrenIdsQuery(int taskId) {
    return (
      '''
      WITH RECURSIVE
      subtasks(task_id) AS (
        SELECT ?
        UNION ALL
        SELECT tasks.id
        FROM subtasks
        JOIN tasks ON tasks.parent_id = subtasks.task_id
      )
      SELECT task_id FROM subtasks
      ''',
      [taskId],
    );
  }

  (String, List<Object?>) _getOwnWithParentsIdsQuery(int taskId) {
    return (
      '''
      WITH RECURSIVE
      subtasks(task_id, parent_id) AS (
        SELECT ?, (SELECT parent_id FROM tasks WHERE id = ?)
        UNION ALL
        SELECT tasks.id, tasks.parent_id
        FROM subtasks
        JOIN tasks ON tasks.id = subtasks.parent_id
      )
      SELECT task_id FROM subtasks
      ''',
      [taskId, taskId],
    );
  }

  Task _makeTask(Map<String, Object?> values) {
    return Task(
      id: values['id'] as int,
      title: values['title'] as String,
      isProject: values['is_project'] as int == 1,
      status: TaskStatus.values.byName(values['status'] as String),
      startSince: values['start_since_dt'] == null
          ? null
          : DateTime.parse(values['start_since_dt'] as String),
      index: values['idx'] as int,
    );
  }
}
