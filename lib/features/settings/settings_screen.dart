import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models/contact.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/section_label.dart';
import '../auth/auth_controller.dart';
import '../contacts/add_contact_screen.dart';
import '../contacts/contacts_controller.dart';
import '../profile/profile_controller.dart';
import 'sos_settings_controller.dart';

/// TELA 4 — Configurar SOS.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const defaultMessageLabel = 'Mensagem customizada para o botão de alerta';
  static const maxMessageLength = 255;

  Future<void> _editMessage(BuildContext context) async {
    final profile = context.read<ProfileController>();
    final auth = context.read<AuthRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _EditMessageDialog(initial: profile.profile.sosMessage),
    );
    if (text == null) return;
    try {
      await profile.saveSosMessage(auth, text);
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  static Future<void> _toggle(BuildContext context, String id, bool enabled) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ContactsController>().setAlertEnabled(id, enabled);
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactsController>();
    final loggedIn = context.watch<AuthController>().loggedIn;
    final settingsController = context.watch<SosSettingsController>();
    final settings = settingsController.settings;
    final message = context.watch<ProfileController>().profile.sosMessage;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          const PageHeader('Configurar SOS', subtitle: 'Configure os parâmetros e alertas de segurança'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionLabel('Contatos de alerta ativos'),
                    if (loggedIn)
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const AddContactScreen()),
                        ),
                        child: const Text('+ ADICIONAR', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
                if (!loggedIn)
                  const AppCard(
                    child: Text(
                      'Entre na sua conta (aba Perfil) para gerenciar seus contatos.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                for (final c in contacts.contacts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.cyan,
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          switch (c.consentStatus) {
                            ConsentStatus.confirmed => 'Receberá WhatsApp e Localização',
                            ConsentStatus.refused => 'O contato recusou receber alertas',
                            ConsentStatus.pending => 'Aguardando consentimento do contato',
                          },
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: c.alertEnabled,
                        onChanged: (v) => _toggle(context, c.id, v),
                      ),
                    ),
                  ),
                const SectionLabel('Mensagem de socorro'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.isEmpty ? defaultMessageLabel : '"$message"',
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const Text(
                        'Enviada com o link da sua localização quando você toca no S.O.S.',
                        style: TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                      const Divider(color: Colors.white12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${message.length} / $maxMessageLength caracteres',
                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                          ),
                          if (loggedIn)
                            GestureDetector(
                              onTap: () => _editMessage(context),
                              child: const Text(
                                'ALTERAR',
                                style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SectionLabel('Informações adicionais'),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.cyan,
                    secondary: const Icon(Icons.shield_outlined, color: AppColors.red),
                    title: const Text('Alerta Silencioso', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Sem som ou luz de tela ao ativar SOS', style: TextStyle(fontSize: 11)),
                    value: settings.silentAlert,
                    onChanged: settingsController.setSilentAlert,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditMessageDialog extends StatefulWidget {
  const _EditMessageDialog({required this.initial});

  final String initial;

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Mensagem de socorro'),
        content: TextField(
          controller: _text,
          maxLength: SettingsScreen.maxMessageLength,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Vazio usa a mensagem padrão'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, _text.text), child: const Text('Salvar')),
        ],
      );
}
