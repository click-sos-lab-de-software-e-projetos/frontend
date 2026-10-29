import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/outline_action_button.dart';
import '../../shared/widgets/section_label.dart';
import 'profile_controller.dart';

/// TELA 7 — Configurações de Perfil.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _profile = context.read<ProfileController>().profile;
  late final _name = TextEditingController(text: _profile.name);
  late final _email = TextEditingController(text: _profile.email);
  late final _phone = TextEditingController(text: _profile.phone);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    context.read<ProfileController>().update(name: _name.text, email: _email.text, phone: _phone.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.bg),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Configurações de Perfil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SectionLabel('Nome'),
            AppTextField('Nome do usuário', _name),
            const SectionLabel('E-mail'),
            AppTextField('E-mail do usuário', _email, keyboardType: TextInputType.emailAddress),
            const SectionLabel('Telefone'),
            AppTextField('Telefone do usuário', _phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            OutlineActionButton('Salvar', _save),
          ],
        ),
      );
}
