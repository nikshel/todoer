import 'dart:async';

import 'package:todoer/client.dart';
import 'package:todoer/models/note.dart';

class NotesRepository {
  final TodoerClient _client;

  NotesRepository(this._client);

  Future<List<Note>> fetchNotes() async {
    final List<dynamic> raw = await _client.getNotes();
    return raw.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Note> createNote({
    required String title,
    required String content,
  }) async {
    final Map<String, dynamic> raw = await _client.createNote(
      title: title,
      content: content,
    );
    return Note.fromJson(raw);
  }

  Future<Note> updateNote(
    int noteId, {
    required String title,
    required String content,
  }) async {
    final Map<String, dynamic> raw = await _client.updateNote(
      noteId,
      title: title,
      content: content,
    );
    return Note.fromJson(raw);
  }

  Future<void> deleteNote(int noteId) async {
    await _client.deleteNote(noteId);
  }
}
