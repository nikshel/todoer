import 'package:event_bus/event_bus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todoer/blocs/events.dart';
import 'package:todoer/models/note.dart';
import 'package:todoer/repositories/notes.dart';

class NotesState {
  final bool isLoading;
  final List<Note> notes;
  final int? selectedNoteId;
  final bool isVirtualNoteSelected;

  const NotesState({
    required this.isLoading,
    required this.notes,
    this.selectedNoteId,
    this.isVirtualNoteSelected = false,
  });

  factory NotesState.initial() {
    return const NotesState(isLoading: false, notes: <Note>[]);
  }

  NotesState copyWith({
    bool? isLoading,
    List<Note>? notes,
    int? selectedNoteId,
    bool? isVirtualNoteSelected,
    bool clearSelectedNoteId = false,
  }) {
    return NotesState(
      isLoading: isLoading ?? this.isLoading,
      notes: notes ?? this.notes,
      selectedNoteId:
          clearSelectedNoteId ? null : (selectedNoteId ?? this.selectedNoteId),
      isVirtualNoteSelected:
          isVirtualNoteSelected ?? this.isVirtualNoteSelected,
    );
  }
}

class NotesCubit extends Cubit<NotesState> {
  final NotesRepository notesRepository;

  NotesCubit({required this.notesRepository, required EventBus eventBus})
      : super(NotesState.initial()) {
    eventBus.on<AuthEvent>().listen(_onAuthEvent);
  }

  void _onAuthEvent(AuthEvent event) {
    if (event.newAuthState.authorized) {
      loadNotes();
    } else {
      emit(NotesState.initial());
    }
  }

  Future<void> loadNotes() async {
    emit(state.copyWith(isLoading: true));
    final List<Note> items = await notesRepository.fetchNotes();
    final int? currentId = state.selectedNoteId;
    final bool hasCurrentId =
        currentId != null && items.any((Note n) => n.id == currentId);
    emit(
      state.copyWith(
        isLoading: false,
        notes: items,
        isVirtualNoteSelected: false,
        selectedNoteId: hasCurrentId ? currentId : (items.isEmpty ? null : items.first.id),
        clearSelectedNoteId: items.isEmpty,
      ),
    );
  }

  void selectNote(int? noteId) {
    if (noteId == null) {
      if (!state.notes.any((Note n) => n.isVirtual)) return;
      emit(state.copyWith(
          isVirtualNoteSelected: true, clearSelectedNoteId: true));
      return;
    }
    if (!state.notes.any((Note n) => n.id == noteId)) return;
    emit(state.copyWith(
        selectedNoteId: noteId, isVirtualNoteSelected: false));
  }

  void addVirtualNote() {
    if (state.notes.any((Note n) => n.isVirtual)) {
      emit(state.copyWith(
          isVirtualNoteSelected: true, clearSelectedNoteId: true));
      return;
    }
    final Note virtualNote = Note(
      id: null,
      title: '',
      content: '',
      createdAt: DateTime.now().toUtc(),
    );
    final List<Note> updated = [virtualNote, ...state.notes];
    emit(state.copyWith(
      notes: updated,
      isVirtualNoteSelected: true,
      clearSelectedNoteId: true,
    ));
  }

  Future<void> saveNote({
    int? id,
    required String title,
    required String content,
  }) async {
    if (id == null) {
      final Note created =
          await notesRepository.createNote(title: title, content: content);
      final List<Note> updated = state.notes
          .map((Note n) => n.isVirtual ? created : n)
          .toList();
      emit(state.copyWith(
        notes: updated,
        selectedNoteId: created.id,
        isVirtualNoteSelected: false,
      ));
    } else {
      final Note updated =
          await notesRepository.updateNote(id, title: title, content: content);
      final List<Note> updatedNotes =
          state.notes.map((Note n) => n.id == id ? updated : n).toList();
      emit(state.copyWith(notes: updatedNotes));
    }
  }

  Future<void> createNote(
      {required String title, required String content}) async {
    await saveNote(id: null, title: title, content: content);
  }

  Future<void> deleteNote(int noteId) async {
    await notesRepository.deleteNote(noteId);
    await loadNotes();
  }

  void removeEmptyVirtualNote() {
    final List<Note> updated = state.notes
        .where((Note n) => !(n.isVirtual && n.title.isEmpty && n.content.isEmpty))
        .toList();
    if (updated.length == state.notes.length) return;
    emit(state.copyWith(notes: updated));
  }
}
