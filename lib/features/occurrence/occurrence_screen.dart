import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/location_service.dart';
import '../../data/repositories/repository_exception.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/outline_action_button.dart';
import '../../shared/widgets/section_label.dart';
import '../map/occurrences_controller.dart';
import 'occurrence_form_controller.dart';

/// TELA 2 — Registro de Ocorrência.
class OccurrenceScreen extends StatefulWidget {
  const OccurrenceScreen({super.key});

  @override
  State<OccurrenceScreen> createState() => _OccurrenceScreenState();
}

class _OccurrenceScreenState extends State<OccurrenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _form = OccurrenceFormController();
  bool _saving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _useLocation() async {
    final p = await context.read<LocationService>().currentPosition();
    if (!mounted) return;
    if (p == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Localização indisponível.')));
      return;
    }
    _form.useLocation(p);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _form.time ?? TimeOfDay.now());
    if (t != null) _form.setTime(t);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDate: _form.date ?? now,
    );
    if (d != null) _form.setDate(d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<OccurrencesController>().report(_form.buildReport());
      if (mounted) Navigator.pop(context);
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.bg),
        body: Form(
          key: _formKey,
          child: ListenableBuilder(
            listenable: _form,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Registro de Ocorrência', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const Text(
                    'Preencha os campos abaixo para registrar uma ocorrência.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SectionLabel('Local'),
                  AppTextField('Insira o endereço do ocorrido', _form.address, validator: _form.validateAddress),
                  TextButton.icon(
                    onPressed: _useLocation,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Usar localização atual'),
                  ),
                  const SectionLabel('Data / Hora'),
                  FormField<void>(
                    validator: (_) => _form.validateDateTime(),
                    builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await _pickTime();
                                  field.didChange(null);
                                },
                                child: Text(_form.time?.format(context) ?? '00:00'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await _pickDate();
                                  field.didChange(null);
                                },
                                child: Text(
                                  _form.date == null
                                      ? 'DD/MM/AA'
                                      : '${_form.date!.day}/${_form.date!.month}/${_form.date!.year % 100}',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 12),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SectionLabel('Ocorrido'),
                  DropdownButtonFormField<String>(
                    initialValue: _form.type,
                    hint: const Text('Selecionar opção...'),
                    dropdownColor: AppColors.card,
                    validator: _form.validateType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items:
                        OccurrenceFormController.types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: _form.setType,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Atenção!\nRecomendamos fortemente que contate o 190 em casos de emergência. Nosso trabalho é apenas alertar sobre situações e locais de risco, o que NÃO substitui o trabalho da polícia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 30),
                  _saving ? const Center(child: CircularProgressIndicator()) : OutlineActionButton('Salvar', _save),
                ],
              ),
            ),
          ),
        ),
      );
}
