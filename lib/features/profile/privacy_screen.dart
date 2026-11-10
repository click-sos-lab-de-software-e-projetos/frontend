import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/repositories/repository_exception.dart';
import '../../shared/widgets/outline_action_button.dart';
import '../../shared/widgets/section_label.dart';
import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';

/// Privacidade e dados (Regra 08 · YUME-03): retenção, anonimização e exclusão de conta.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const stored = 'Sua conta (nome, e-mail e telefone), seus contatos de confiança, '
      'os alertas S.O.S com localização e mensagem, e os relatos que você envia no mapa.';
  static const retention = 'Alertas e localização ficam guardados por 180 dias. Depois disso, o alerta '
      'é anonimizado: as coordenadas e a mensagem são apagadas, e ficam só o status e as datas, '
      'para estatística.';
  static const access = 'Sua localização vai só aos contatos ativos que aceitaram receber alertas. '
      'Os relatos do mapa não mostram quem enviou. Só a responsável pelo projeto acessa os dados '
      'de produção.';
  static const deletion = 'Ao excluir a conta, apagamos seus dados, contatos e relatos. Os alertas '
      'ficam anonimizados, sem dono. Não dá para desfazer.';
  static const deleteWarning = 'Seus dados, contatos e relatos serão apagados e os alertas, '
      'anonimizados. Você sai do app. Não dá para desfazer.';
  static const deleted = 'Conta excluída.';

  Future<void> _delete(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir conta?'),
        content: const Text(deleteWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Continuar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final done = await showDialog<bool>(context: context, builder: (_) => const _PasswordDialog());
    if (done != true) return;
    navigator.popUntil((route) => route.isFirst);
    navigator.push(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
    messenger.showSnackBar(const SnackBar(content: Text(deleted)));
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthController>().loggedIn;
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.bg),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Privacidade e dados', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SectionLabel('O que guardamos'),
          const Text(stored),
          const SectionLabel('Por quanto tempo'),
          const Text(retention),
          const SectionLabel('Quem vê'),
          const Text(access),
          const SectionLabel('Exclusão da conta'),
          const Text(deletion),
          if (loggedIn) ...[
            const SizedBox(height: 24),
            OutlineActionButton('Excluir conta', () => _delete(context), color: AppColors.red),
          ],
        ],
      ),
    );
  }
}

/// Second confirmation: the backend needs the password. Pops `true` once deleted.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) return setState(() => _error = 'Informe sua senha.');
    setState(() => _error = null);
    try {
      await context.read<AuthController>().deleteAccount(_password.text);
      if (mounted) Navigator.pop(context, true);
    } on RepositoryException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().loading;
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('Confirme com sua senha'),
      content: TextField(
        controller: _password,
        obscureText: true,
        autofocus: true,
        decoration: InputDecoration(hintText: 'Senha', errorText: _error),
      ),
      actions: [
        TextButton(onPressed: busy ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(
          onPressed: busy ? null : _submit,
          child: const Text('Excluir', style: TextStyle(color: AppColors.red)),
        ),
      ],
    );
  }
}
