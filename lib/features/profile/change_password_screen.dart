import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/outline_action_button.dart';
import '../../shared/widgets/section_label.dart';
import '../auth/register_screen.dart';

/// Troca de senha: exige a senha atual (`POST /auth/me/senha`).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  static const done = 'Senha alterada.';

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const _min = RegisterScreen.minPasswordLength;

  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AuthRepository>().changePassword(current: _current.text, next: _next.text);
      messenger.showSnackBar(const SnackBar(content: Text(ChangePasswordScreen.done)));
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
              const Text('Alterar senha', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SectionLabel('Senha atual'),
              AppTextField(
                'Sua senha atual',
                _current,
                obscure: true,
                validator: (v) => (v ?? '').isEmpty ? 'Informe a senha atual.' : null,
              ),
              const SectionLabel('Nova senha'),
              AppTextField(
                'Mínimo de $_min caracteres',
                _next,
                obscure: true,
                validator: (v) => (v ?? '').length < _min ? 'A senha precisa ter ao menos $_min caracteres.' : null,
              ),
              const SectionLabel('Confirme a nova senha'),
              AppTextField(
                'Repita a nova senha',
                _confirm,
                obscure: true,
                validator: (v) => v == _next.text ? null : 'As senhas não conferem.',
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!, style: const TextStyle(color: AppColors.red)),
                ),
              const SizedBox(height: 24),
              OutlineActionButton('Trocar senha', _saving ? null : _submit),
            ],
          ),
        ),
      );
}
