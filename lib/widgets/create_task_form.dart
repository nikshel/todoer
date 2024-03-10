import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class CreateTaskForm extends StatelessWidget {
  final _formKey = GlobalKey<FormBuilderState>();

  CreateTaskForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: FormBuilder(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FormBuilderTextField(
                name: 'title',
                decoration: const InputDecoration(labelText: 'Название задачи'),
                validator: FormBuilderValidators.required(),
                textInputAction: TextInputAction.send,
                autofocus: true,
                valueTransformer: (value) => value?.trim(),
                onSubmitted: (_) => submit(context),
              ),
              Container(
                alignment: Alignment.bottomRight,
                child: FilledButton.tonal(
                  onPressed: () => submit(context),
                  child: const Text('Создать'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void submit(BuildContext context) {
    var isValid = _formKey.currentState!.saveAndValidate();
    if (isValid) {
      Navigator.pop(context, _formKey.currentState!.value);
    }
  }
}
