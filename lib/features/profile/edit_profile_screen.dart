import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/utils/phone.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/outline_action_button.dart';
import '../../shared/widgets/section_label.dart';
import 'change_password_screen.dart';
import 'profile_controller.dart';

/// TELA 7 — Configurações de Perfil. Saves name and phone on the account.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const emailNotice = 'O e-mail não pode ser alterado.';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _profile = context.read<ProfileController>().profile;
  late final _name = TextEditingController(text: _profile.name);
  late final _email = TextEditingController(text: _profile.email);
  late final _phone = TextEditingController(text: _profile.phone);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<ProfileController>().saveProfile(
            context.read<AuthRepository>(),
            name: _name.text,
            phone: _phone.text,
          );
      if (mounted) Navigator.pop(context);
    } on RepositoryException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.bg),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Configurações de Perfil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SectionLabel('Nome'),
              AppTextField(
                'Nome do usuário',
                _name,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
              ),
              const SectionLabel('E-mail'),
              AppTextField('E-mail do usuário', _email, enabled: false),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(EditProfileScreen.emailNotice, style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              const SectionLabel('Telefone (com DDD)'),
              AppTextField(
                '(11) 90000-0000',
                _phone,
                keyboardType: TextInputType.phone,
                validator: (v) => isValidPhone(v ?? '') ? null : 'Informe um telefone válido.',
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!, style: const TextStyle(color: AppColors.red)),
                ),
              const SizedBox(height: 24),
              OutlineActionButton('Salvar', _saving ? null : _save),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
                ),
                child: const Text('Trocar senha'),
              ),
            ],
          ),
        ),
      );
}
