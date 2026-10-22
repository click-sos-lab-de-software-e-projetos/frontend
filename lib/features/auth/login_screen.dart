import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/repositories/repository_exception.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/outline_action_button.dart';
import '../../shared/widgets/section_label.dart';
import '../profile/profile_controller.dart';
import 'auth_controller.dart';

/// TELA 6 — Login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final _email = TextEditingController(text: context.read<ProfileController>().profile.email);
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final profile = context.read<ProfileController>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final user = await context.read<AuthController>().login(email: _email.text.trim(), password: _password.text);
      profile.replace(user);
      if (mounted) Navigator.pop(context);
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().loading;
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.bg),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Entrar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const Text('Acesse para ver seus contatos de confiança.', style: TextStyle(color: Colors.white54)),
            const SectionLabel('E-mail'),
            AppTextField('seu@email.com', _email, keyboardType: TextInputType.emailAddress),
            const SectionLabel('Senha'),
            AppTextField('••••••••', _password, obscure: true),
            const SizedBox(height: 24),
            loading ? const Center(child: CircularProgressIndicator()) : OutlineActionButton('Entrar', _login),
          ],
        ),
      ),
    );
  }
}
