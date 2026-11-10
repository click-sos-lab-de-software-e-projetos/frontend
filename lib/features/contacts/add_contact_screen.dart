import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/utils/phone.dart';
import '../../data/models/contact.dart';
import '../../data/repositories/repository_exception.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/outline_action_button.dart';
import '../../shared/widgets/section_label.dart';
import 'contacts_controller.dart';

/// TELA 8 — Registrar contato de confiança. With a [contact], edits or removes it.
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key, this.contact});

  final Contact? contact;

  static const reconsentWarning = 'O consentimento será pedido de novo; o contato não recebe alertas até aceitar.';

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.contact?.name);
  late final _phone = TextEditingController(text: widget.contact?.phone);
  bool _saving = false;

  Contact? get _editing => widget.contact;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
          ],
        ),
      ) ??
      false;

  Future<void> _run(Future<void> Function(ContactsController contacts) action) async {
    final contacts = context.read<ContactsController>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await action(contacts);
      if (mounted) Navigator.pop(context);
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final phone = toE164(_phone.text);
    final editing = _editing;
    if (editing == null) {
      return _run((c) => c.add(name: _name.text, phone: phone));
    }
    final answered = editing.consentStatus != ConsentStatus.pending;
    if (phone != editing.phone &&
        answered &&
        !await _confirm('Trocar o telefone?', AddContactScreen.reconsentWarning, 'Continuar')) {
      return;
    }
    if (mounted) await _run((c) => c.edit(editing.id, name: _name.text, phone: phone));
  }

  Future<void> _remove() async {
    final editing = _editing!;
    if (_saving || !await _confirm('Remover ${editing.name}?', 'Ele deixa de receber seus alertas.', 'Remover')) {
      return;
    }
    if (mounted) await _run((c) => c.remove(editing.id));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.bg),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _editing == null ? 'Registrar contato de confiança' : 'Editar contato',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SectionLabel('Nome'),
                AppTextField(
                  'Nome do contato',
                  _name,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
                ),
                const SectionLabel('Telefone (com DDD, WhatsApp)'),
                AppTextField(
                  'Telefone para contato',
                  _phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Informe o telefone.'
                      : isValidPhone(v!)
                          ? null
                          : 'Telefone inválido.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'O contato só recebe alertas depois de confirmar o consentimento.',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
                const SizedBox(height: 24),
                if (_saving)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  OutlineActionButton(_editing == null ? 'Adicionar' : 'Salvar', _submit),
                  if (_editing != null) ...[
                    const SizedBox(height: 12),
                    OutlineActionButton('Remover contato', _remove, color: AppColors.red),
                  ],
                ],
              ],
            ),
          ),
        ),
      );
}
