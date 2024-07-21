import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:todoer/models/group.dart';
import 'package:todoer/models/task.dart';

class TaskForm extends StatefulWidget {
  final Task? currentTask;
  final List<Group> groups;

  const TaskForm({
    super.key,
    this.currentTask,
    required this.groups,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  late List<Group> _lastGroups;

  @override
  void initState() {
    super.initState();
    _lastGroups = widget.currentTask?.groups ?? [];
  }

  _patchGroups(List<Group> newGroups) {
    var todayGroupAdded =
        !_lastGroups.any((g) => g.systemType == GroupSystemType.today) &&
            newGroups.any((g) => g.systemType == GroupSystemType.today);
    var hasWeekGroup =
        newGroups.any((g) => g.systemType == GroupSystemType.week);
    if (todayGroupAdded && !hasWeekGroup) {
      newGroups.add(widget.groups.firstWhere(
        (g) => g.systemType == GroupSystemType.week,
      ));
    }

    var weekGroupRemoved =
        _lastGroups.any((g) => g.systemType == GroupSystemType.week) &&
            !newGroups.any((g) => g.systemType == GroupSystemType.week);
    if (weekGroupRemoved) {
      newGroups.removeWhere((g) => g.systemType == GroupSystemType.today);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(20)),
      child: FormBuilder(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FormBuilderTextField(
              name: 'title',
              decoration: const InputDecoration(labelText: 'Название задачи'),
              validator: FormBuilderValidators.required(),
              textInputAction: TextInputAction.send,
              autofocus: true,
              valueTransformer: (value) => value?.trim(),
              initialValue: widget.currentTask?.title,
              onSubmitted: (_) => submit(context),
            ),
            FormBuilderCheckbox(
              name: 'isProject',
              title: const Text('Сделать проектом'),
              initialValue: widget.currentTask?.isProject ?? false,
            ),
            FormBuilderFilterChip<Group>(
              name: 'groups',
              showCheckmark: false,
              options: widget.groups
                  .map((group) => FormBuilderChipOption(
                        value: group,
                        child: Text(group.title),
                      ))
                  .toList(),
              spacing: 5,
              initialValue: widget.currentTask?.groups ?? [],
              onChanged: (values) {
                _patchGroups(values!);
                setState(() {
                  _lastGroups = values;
                });
              },
              valueTransformer: (values) => values!.map((g) => g.id).toList(),
            ),
            FormBuilderTextField(
              name: 'link',
              decoration: const InputDecoration(labelText: 'Ссылка'),
              validator: FormBuilderValidators.url(
                requireTld: true,
                allowUnderscore: true,
                requireProtocol: true,
              ),
              textInputAction: TextInputAction.send,
              valueTransformer: (value) => value?.trim() ?? '',
              initialValue: widget.currentTask?.link,
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.currentTask != null)
                    FilledButton.tonal(
                      onPressed: () => submit(context, delete: true),
                      style: ButtonStyle(
                          foregroundColor:
                              WidgetStateProperty.all(Colors.white),
                          backgroundColor: WidgetStateProperty.all(
                              const Color.fromARGB(255, 224, 86, 77))),
                      child: const Text('Удалить'),
                    ),
                  if (widget.currentTask != null) const SizedBox(width: 10),
                  FilledButton.tonal(
                    onPressed: () => submit(context),
                    child: Text(
                        widget.currentTask == null ? 'Создать' : 'Обновить'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void submit(BuildContext context, {bool delete = false}) {
    if (delete) {
      Navigator.pop(context, {'delete': true});
    } else {
      var isValid = _formKey.currentState!.saveAndValidate();
      if (isValid) {
        var values = {..._formKey.currentState!.value};

        if (values['link'] == '') {
          values['link'] = null;
        }

        values['groups'] = ((values['groups'] as List<int>?) ?? [])
            .map((id) => widget.groups.firstWhere((g) => g.id == id))
            .toList();

        Navigator.pop(context, values);
      }
    }
  }
}
