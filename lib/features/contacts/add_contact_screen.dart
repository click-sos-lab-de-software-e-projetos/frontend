import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/outline_action_button.dart';
import '../../shared/widgets/section_label.dart';
import 'contacts_controller.dart';

/// TELA 8 — Registrar contato de confiança.
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  static String? _required(String? v, String message) => (v ?? '').trim().isEmpty ? message : null;

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ContactsController>().add(name: _name.text, phone: _phone.text, relation: _relation.text);
    Navigator.pop(context);
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
                const Text(
                  'Registrar contato de confiança',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SectionLabel('Nome'),
                AppTextField('Nome do contato', _name, validator: (v) => _required(v, 'Informe o nome.')),
                const SectionLabel('Telefone (com DDD, WhatsApp)'),
                AppTextField(
                  'Telefone para contato',
                  _phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => _required(v, 'Informe o telefone.'),
                ),
                const SectionLabel('Parentesco'),
                AppTextField('Ex.: Cônjuge, Mãe, Amigo', _relation),
                const SizedBox(height: 24),
                OutlineActionButton('Adicionar', _add),
              ],
            ),
          ),
        ),
      );
}
