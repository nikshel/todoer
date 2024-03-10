import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todoer/models/task.dart';

const TASKS_TABLE = 'tasks';

class TreeStorage extends ChangeNotifier {
  final Database _db;

  TreeStorage(this._db);

  Future<List<Task>> getRoots() async {
    var res = await _db.query(TASKS_TABLE, orderBy: 'parent_id, idx');

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

  Future<void> createTask(String title, [int? parentId]) async {
    await _db.transaction((txn) async {
      var res = await txn.query(
        TASKS_TABLE,
        columns: ['MAX(idx) AS max_idx'],
        where: 'parent_id IS ?',
        whereArgs: [parentId],
      );
      int maxIdx = (res[0]['max_idx'] as int?) ?? -1;

      await txn.insert(TASKS_TABLE, {
        'title': title,
        'done': 0,
        'parent_id': parentId,
        'idx': maxIdx + 1,
      });
    }, exclusive: true);

    notifyListeners();
  }

  Future<void> makeTaskDone(int taskId, bool done) async {
    await _db.update(
      TASKS_TABLE,
      {'done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );

    notifyListeners();
  }

  Future<void> removeTask(int taskId) async {
    await _db.transaction((txn) async {
      var res = await txn.rawQuery('''
        DELETE FROM $TASKS_TABLE
        WHERE id = ?
        RETURNING parent_id, idx
      ''', [taskId]);
      var parentId = res[0]['parent_id'] as int?;
      var idx = res[0]['idx'] as int;

      await txn.rawUpdate('''
        UPDATE $TASKS_TABLE
        SET idx = idx - 1
        WHERE parent_id IS ? AND idx > ?
      ''', [parentId, idx]); // todo shifts
    });
    notifyListeners();
  }

  Future<void> moveTask(int taskId, int? newParentId, int newIdx) async {
    _db.transaction((txn) async {
      var res = await txn.query(
        TASKS_TABLE,
        columns: ['parent_id', 'idx'],
        where: 'id = ?',
        whereArgs: [taskId],
      );
      var currentParentId = res[0]['parent_id'] as int?;
      var currentIdx = res[0]['idx'] as int;

      // var batch = txn.batch();
      // batch
      print('START $taskId $newIdx');
      var all = await txn.query(TASKS_TABLE);
      for (var element in all) {
        print(element);
      }

      await txn.rawUpdate('''
          UPDATE $TASKS_TABLE
          SET idx = -1
          WHERE id = ?
        ''', [taskId]);
      await txn.rawUpdate('''
          UPDATE $TASKS_TABLE
          SET idx = idx - 1000000
          WHERE parent_id IS ? AND idx > ?
          ''', [currentParentId, currentIdx]);

      await txn.rawUpdate('''
          UPDATE $TASKS_TABLE
          SET idx = idx + 999999
          WHERE parent_id IS ? AND idx < -1
          ''', [currentParentId]);
      print('after -1');
      all = await txn.query(TASKS_TABLE);
      for (var element in all) {
        print(element);
      }

      if (newParentId == currentParentId && currentIdx < newIdx) {
        newIdx--;
      }

      await txn.rawUpdate('''
          UPDATE $TASKS_TABLE
          SET idx = idx + 1000000
          WHERE parent_id IS ? AND idx >= ?
          ''', [newParentId, newIdx]);

      await txn.rawUpdate('''
          UPDATE $TASKS_TABLE
          SET idx = idx - 999999
          WHERE parent_id IS ? AND idx >= 1000000
          ''', [newParentId]);
      // await batch.commit();

      print('after +1');
      all = await txn.query(TASKS_TABLE);
      for (var element in all) {
        print(element);
      }

      await txn.rawUpdate('''
        UPDATE $TASKS_TABLE
        SET parent_id = ?, idx = ?
        WHERE id = ?
        ''', [newParentId, newIdx, taskId]);
    }, exclusive: true);
    notifyListeners();
  }

  Task _makeTask(Map<String, Object?> values) {
    return Task(
      id: values['id'] as int,
      title: values['title'] as String,
      done: values['done'] as int == 1,
      index: values['idx'] as int,
    );
  }
}
