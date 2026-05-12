import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';
import 'package:todoer/blocs/notes.dart';
import 'package:todoer/models/note.dart';
import 'package:todoer/utils.dart';
import 'package:todoer/widgets/menuable.dart';

final List<SpaceShortcutEvent> _notesSpaceShortcutEvents = <SpaceShortcutEvent>[
  formatOrderedNumberToList,
  formatHyphenToBulletList,
  SpaceShortcutEvent(
    character: '=',
    handler: (QuillText node, QuillController controller) =>
        _applyEqualsHeadingPrefix(controller, '='),
  ),
  SpaceShortcutEvent(
    character: '==',
    handler: (QuillText node, QuillController controller) =>
        _applyEqualsHeadingPrefix(controller, '=='),
  ),
  SpaceShortcutEvent(
    character: '===',
    handler: (QuillText node, QuillController controller) =>
        _applyEqualsHeadingPrefix(controller, '==='),
  ),
];

bool _applyEqualsHeadingPrefix(QuillController controller, String phrase) {
  final int level = _countLeadingEquals(phrase);
  if (level < 1 || level > 3) {
    return false;
  }
  final Attribute<int?> headerAttribute = level == 1
      ? Attribute.h1
      : level == 2
      ? Attribute.h2
      : Attribute.h3;
  _replacePrefixWithBlockHeader(controller, phrase, headerAttribute);
  return true;
}

void _replacePrefixWithBlockHeader(
  QuillController controller,
  String phrase,
  Attribute<int?> headerAttribute,
) {
  controller.replaceText(
    controller.selection.baseOffset - phrase.length,
    phrase.length,
    '\n',
    null,
  );
  _moveEditorCursorBy(-phrase.length, controller);
  controller
    ..formatSelection(headerAttribute)
    ..replaceText(controller.selection.baseOffset + 1, 1, '', null);
}

void _moveEditorCursorBy(int chars, QuillController controller) {
  final TextSelection selection = controller.selection;
  controller.updateSelection(
    controller.selection.copyWith(
      baseOffset: selection.baseOffset + chars,
      extentOffset: selection.baseOffset + chars,
    ),
    ChangeSource.local,
  );
}

int _countLeadingEquals(String value) {
  int count = 0;
  for (int i = 0; i < value.length; i++) {
    if (value[i] == '=') {
      count++;
    } else {
      break;
    }
  }
  return count;
}

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});
  static const double _newNoteButtonAreaHeight = 66;
  static const double _newNoteHeaderHeightCompact = 48;
  static const double _sidebarWidthMin = 112;
  static const double _sidebarWidthMax = 260;
  static const double _sidebarWidthMaxPortraitNav = 176;
  static const double _sidebarWidthFraction = 0.32;
  static const double _compactSidebarBreakpoint = 190;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesCubit, NotesState>(
      builder: (context, state) {
        final Note? selectedNote = state.isVirtualNoteSelected
            ? state.notes.where((n) => n.isVirtual).firstOrNull
            : state.selectedNoteId != null
            ? state.notes.where((n) => n.id == state.selectedNoteId).firstOrNull
            : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool usesHorizontalTabBar = !isLandscape(context);
            final double sidebarWidth = (constraints.maxWidth *
                    _sidebarWidthFraction)
                .clamp(
                  _sidebarWidthMin,
                  usesHorizontalTabBar
                      ? _sidebarWidthMaxPortraitNav
                      : _sidebarWidthMax,
                );
            final bool isCompactSidebar = usesHorizontalTabBar ||
                sidebarWidth < _compactSidebarBreakpoint;
            final double newNoteHeaderHeight = isCompactSidebar
                ? _newNoteHeaderHeightCompact
                : _newNoteButtonAreaHeight;
            return ClipRect(
              child: Row(
                children: [
                  SizedBox(
                    width: sidebarWidth,
                    child: Stack(
                      children: [
                        if (state.isLoading && state.notes.isEmpty)
                          const Center(child: CircularProgressIndicator())
                        else if (state.notes.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                'Нет заметок',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: isCompactSidebar ? 12 : 14,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            primary: false,
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.only(top: newNoteHeaderHeight),
                            itemCount: state.notes.length,
                            itemBuilder: (context, index) {
                              final Note note = state.notes[index];
                              final bool isSelected = note.isVirtual
                                  ? state.isVirtualNoteSelected
                                  : note.id == state.selectedNoteId;
                              final bool shouldCollapse =
                                  note.isVirtual &&
                                  !isSelected &&
                                  note.title.isEmpty &&
                                  note.content.isEmpty;
                              return _NoteListItem(
                                key: ValueKey(note.id),
                                note: note,
                                isSelected: isSelected,
                                isCompact: isCompactSidebar,
                                shouldCollapse: shouldCollapse,
                                onTap: () => context
                                    .read<NotesCubit>()
                                    .selectNote(note.id),
                                onDelete: note.id != null
                                    ? () => context
                                        .read<NotesCubit>()
                                        .deleteNote(note.id!)
                                    : null,
                                onCollapseComplete: () => context
                                    .read<NotesCubit>()
                                    .removeEmptyVirtualNote(),
                              );
                            },
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: ColoredBox(
                            color: Theme.of(context).colorScheme.surface,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompactSidebar ? 6 : 12,
                                    vertical: isCompactSidebar ? 5 : 8,
                                  ),
                                  child: FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                      padding: isCompactSidebar
                                          ? EdgeInsets.zero
                                          : null,
                                      minimumSize: isCompactSidebar
                                          ? const Size(40, 36)
                                          : null,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: isCompactSidebar
                                          ? VisualDensity.compact
                                          : null,
                                    ),
                                    onPressed: () => context
                                        .read<NotesCubit>()
                                        .addVirtualNote(),
                                    child: isCompactSidebar
                                        ? const Icon(Icons.add, size: 22)
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              const Icon(Icons.add, size: 18),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  'Новая заметка',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const Divider(thickness: 1, height: 1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: selectedNote == null
                        ? const Center(
                            child: Text(
                              'Выберите заметку',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : _NoteViewer(
                            key: ValueKey(selectedNote.id),
                            note: selectedNote,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NoteListItem extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final bool isCompact;
  final bool shouldCollapse;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback onCollapseComplete;

  const _NoteListItem({
    super.key,
    required this.note,
    required this.isSelected,
    required this.isCompact,
    required this.shouldCollapse,
    required this.onTap,
    required this.onDelete,
    required this.onCollapseComplete,
  });

  @override
  State<_NoteListItem> createState() => _NoteListItemState();
}

class _NoteListItemState extends State<_NoteListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sizeFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: 1.0,
    );
    _sizeFactor = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_NoteListItem old) {
    super.didUpdateWidget(old);
    if (widget.shouldCollapse && !old.shouldCollapse) {
      _controller.reverse().then((_) {
        if (mounted) widget.onCollapseComplete();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeFactor,
      child: Menuable<String>(
        options: const [('delete', Icons.delete, 'Удалить')],
        onOptionSelected: (_) => widget.onDelete?.call(),
        builder: (context, openMenu) => ListTile(
          dense: widget.isCompact,
          visualDensity: widget.isCompact
              ? VisualDensity.compact
              : VisualDensity.standard,
          contentPadding: widget.isCompact
              ? const EdgeInsets.symmetric(horizontal: 8)
              : null,
          title: Text(
            widget.note.title.isEmpty ? 'Без названия' : widget.note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.note.title.isEmpty
                ? TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: widget.isCompact ? 12 : null,
                  )
                : widget.isCompact
                ? const TextStyle(fontSize: 13)
                : null,
          ),
          selected: widget.isSelected,
          selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _NoteViewer extends StatefulWidget {
  final Note note;

  const _NoteViewer({super.key, required this.note});

  @override
  State<_NoteViewer> createState() => _NoteViewerState();
}

class _NoteViewerState extends State<_NoteViewer> {
  late final TextEditingController _titleController;
  late final QuillController _quillController;
  late final FocusNode _editorFocusNode;
  Timer? _debounceTimer;

  static const Duration _debounceDuration = Duration(milliseconds: 500);

  static const EdgeInsets _editorContentPadding = EdgeInsets.symmetric(
    vertical: 10,
  );
  static const double _editorHeading1FontSize = 22;
  static const double _editorHeading2FontSize = 19;
  static const double _editorHeading3FontSize = 17;

  static final _mdToDelta = MarkdownToDelta(
    markdownDocument: md.Document(
      encodeHtml: false,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    ),
  );
  static final _deltaToMd = DeltaToMarkdown();

  static Delta _buildInitialDelta(String content) {
    if (content.isEmpty) {
      final Delta empty = Delta();
      empty.insert('\n');
      return empty;
    }
    return _mdToDelta.convert(content);
  }

  DefaultStyles _buildEditorHeadingStyles() {
    final DefaultStyles base = DefaultStyles.getInstance(context);
    return DefaultStyles(
      h1: base.h1!.copyWith(
        style: base.h1!.style.copyWith(fontSize: _editorHeading1FontSize),
      ),
      h2: base.h2!.copyWith(
        style: base.h2!.style.copyWith(fontSize: _editorHeading2FontSize),
      ),
      h3: base.h3!.copyWith(
        style: base.h3!.style.copyWith(fontSize: _editorHeading3FontSize),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _editorFocusNode = FocusNode(debugLabel: 'notes_editor_focus');
    final Delta delta = _buildInitialDelta(widget.note.content);
    _quillController = QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _quillController.addListener(_onContentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _editorFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _quillController.removeListener(_onContentChanged);
    _quillController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _saveNote);
  }

  void _onContentChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _saveNote);
  }

  void _saveNote() {
    final String markdown = _deltaToMd.convert(
      _quillController.document.toDelta(),
    );
    context.read<NotesCubit>().saveNote(
      id: widget.note.id,
      title: _titleController.text,
      content: markdown,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: const InputDecoration(
              hintText: 'Заголовок',
              border: InputBorder.none,
            ),
            autofocus: widget.note.isVirtual,
            onChanged: (_) => _onTitleChanged(),
          ),
          const Divider(height: 1),
          //   QuillSimpleToolbar(
          //     controller: _quillController,
          //     config: const QuillSimpleToolbarConfig(
          //       //   multiRowsDisplay: false,
          //       showFontFamily: false,
          //       showFontSize: false,
          //       showSubscript: false,
          //       showSuperscript: false,
          //       showInlineCode: true,
          //       showColorButton: false,
          //       showBackgroundColorButton: false,
          //       showClearFormat: true,
          //     ),
          //   ),
          const Divider(height: 1),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _editorFocusNode.requestFocus(),
              child: QuillEditor.basic(
                controller: _quillController,
                focusNode: _editorFocusNode,
                config: QuillEditorConfig(
                  padding: _editorContentPadding,
                  showCursor: true,
                  paintCursorAboveText: true,
                  customStyles: _buildEditorHeadingStyles(),
                  characterShortcutEvents: standardCharactersShortcutEvents,
                  spaceShortcutEvents: _notesSpaceShortcutEvents,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
