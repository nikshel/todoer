import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:todoer/models/task.dart';

class TaskForm extends StatelessWidget {
  final _formKey = GlobalKey<FormBuilderState>();
  final Task? currentTask;

  TaskForm({
    super.key,
    this.currentTask,
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
                              Color.fromARGB(255, 224, 86, 77))),
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
        Navigator.pop(context, _formKey.currentState!.value);
      }
    }
  }
}
