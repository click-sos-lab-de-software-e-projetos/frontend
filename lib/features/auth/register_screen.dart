import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/utils/phone.dart';
import '../../data/repositories/repository_exception.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/outline_action_button.dart';
import '../../shared/widgets/section_label.dart';
import '../profile/profile_controller.dart';
import 'auth_controller.dart';

/// Cadastro (AUTH-01). Pops with `true` after creating the account and logging in.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const minPasswordLength = 8;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = context.read<ProfileController>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final user = await context.read<AuthController>().register(
            name: _name.text,
            email: _email.text,
            phone: toE164(_phone.text),
            password: _password.text,
          );
      profile.replace(user);
      if (mounted) Navigator.pop(context, true);
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().loading;
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.bg),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Criar conta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SectionLabel('Nome completo'),
              AppTextField(
                'Seu nome',
                _name,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
              ),
              const SectionLabel('E-mail'),
              AppTextField(
                'seu@email.com',
                _email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v ?? '').contains('@') ? null : 'Informe um e-mail válido.',
              ),
              const SectionLabel('Telefone (com DDD)'),
              AppTextField(
                '(11) 90000-0000',
                _phone,
                keyboardType: TextInputType.phone,
                validator: (v) => isValidPhone(v ?? '') ? null : 'Informe um telefone válido.',
              ),
              const SectionLabel('Senha'),
              AppTextField(
                'Mínimo de ${RegisterScreen.minPasswordLength} caracteres',
                _password,
                obscure: true,
                validator: (v) => (v ?? '').length < RegisterScreen.minPasswordLength
                    ? 'A senha precisa ter ao menos ${RegisterScreen.minPasswordLength} caracteres.'
                    : null,
              ),
              const SizedBox(height: 24),
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : OutlineActionButton('Criar conta', _register),
            ],
          ),
        ),
      ),
    );
  }
}
