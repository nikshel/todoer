import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:todoer/models/group.dart';
import 'package:todoer/models/task.dart';

class TaskForm extends StatelessWidget {
  final _formKey = GlobalKey<FormBuilderState>();
  final Task? currentTask;
  final List<Group> groups;

  TaskForm({
    super.key,
    this.currentTask,
    required this.groups,
  });

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
              initialValue: currentTask?.title,
              onSubmitted: (_) => submit(context),
            ),
            FormBuilderCheckbox(
              name: 'isProject',
              title: const Text('Сделать проектом'),
              initialValue: currentTask?.isProject ?? false,
            ),
            FormBuilderFilterChip(
              name: 'groups',
              options: groups
                  .map((group) => FormBuilderChipOption(
                        value: group.id,
                        child: Text(group.title),
                      ))
                  .toList(),
              initialValue: currentTask?.groups.map((g) => g.id).toList(),
              spacing: 5,
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
              initialValue: currentTask?.link,
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
                  if (currentTask != null)
                    FilledButton.tonal(
                      onPressed: () => submit(context, delete: true),
                      style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                          backgroundColor: MaterialStateProperty.all(
                              const Color.fromARGB(255, 224, 86, 77))),
                      child: const Text('Удалить'),
                    ),
                  if (currentTask != null) const SizedBox(width: 10),
                  FilledButton.tonal(
                    onPressed: () => submit(context),
                    child: Text(currentTask == null ? 'Создать' : 'Обновить'),
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
            .map((id) => groups.firstWhere((g) => g.id == id))
            .toList();

        Navigator.pop(context, values);
      }
    }
  }
}
