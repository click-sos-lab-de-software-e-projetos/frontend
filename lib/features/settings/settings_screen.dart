import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models/sos_settings.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/section_label.dart';
import '../contacts/contacts_controller.dart';
import 'sos_settings_controller.dart';

/// TELA 4 — Configurar SOS.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editMessage(BuildContext context) async {
    final settings = context.read<SosSettingsController>();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _EditMessageDialog(initial: settings.settings.message),
    );
    if (text != null && text.trim().isNotEmpty) settings.setMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactsController>();
    final settingsController = context.watch<SosSettingsController>();
    final settings = settingsController.settings;
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
                const SectionLabel('Contatos de alerta ativos'),
                for (final c in contacts.contacts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.cyan,
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Receberá WhatsApp e Localização', style: TextStyle(fontSize: 11)),
                        value: c.alertEnabled,
                        onChanged: (v) => contacts.setAlertEnabled(c.id, v),
                      ),
                    ),
                  ),
                const SectionLabel('Mensagem de socorro'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"${settings.message} [link do mapa]"',
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const Divider(color: Colors.white12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${settings.message.length} / ${SosSettings.maxMessageLength} caracteres',
                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                          ),
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
        content: TextField(controller: _text, maxLength: SosSettings.maxMessageLength, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, _text.text), child: const Text('Salvar')),
        ],
      );
}
