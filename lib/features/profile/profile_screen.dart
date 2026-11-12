import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/whatsapp_service.dart';
import '../../data/models/contact.dart';
import '../../data/repositories/repository_exception.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/outline_action_button.dart';
import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../contacts/add_contact_screen.dart';
import '../contacts/contacts_controller.dart';
import 'edit_profile_screen.dart';
import 'privacy_screen.dart';
import 'profile_controller.dart';

/// TELA 5 — Perfil. Deslogado mostra só login, cadastro, contatos (bloqueados) e privacidade.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const loggedOut = 'Você não está conectado.';

  static void _go(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

  static String _consentLabel(ConsentStatus status) => switch (status) {
        ConsentStatus.confirmed => 'Consentimento confirmado',
        ConsentStatus.refused => 'Recusou receber alertas',
        ConsentStatus.pending => 'Aguardando consentimento',
      };

  static Future<void> _sendConsentRequest(BuildContext context, Contact contact) async {
    final whatsApp = context.read<WhatsAppService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final text = await context.read<ContactsController>().consentInvite(contact.id);
      if (!await whatsApp.open(contact.phone, text)) {
        messenger.showSnackBar(const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')));
      }
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  static String removeWarning(Contact c) => '${c.name} deixa de receber seus alertas. Se precisar adicioná-lo de novo, '
      'ele terá que consentir novamente.';

  static Future<void> _removeContact(BuildContext context, Contact contact) async {
    final contacts = context.read<ContactsController>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Remover ${contact.name}?'),
        content: Text(removeWarning(contact)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Remover', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await contacts.remove(contact.id);
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;
    final loggedIn = context.watch<AuthController>().loggedIn;
    // The page fills at least the screen so the privacy link sits at the bottom.
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Seu Perfil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        if (loggedIn)
                          IconButton(
                            tooltip: 'Editar perfil',
                            onPressed: () => _go(context, const EditProfileScreen()),
                            icon: const Icon(Icons.edit, color: AppColors.cyan),
                          ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cyan, width: 3),
                          ),
                          child: const Icon(Icons.person_outline, size: 50, color: AppColors.cyan),
                        ),
                        const SizedBox(height: 10),
                        if (loggedIn) ...[
                          Text(profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(profile.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(profile.phone, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ] else
                          const Text(ProfileScreen.loggedOut, style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _TrustedContacts(),
                  const SizedBox(height: 20),
                  if (loggedIn)
                    OutlineActionButton(
                      'Desconectar do Dispositivo',
                      context.read<AuthController>().logout,
                      color: AppColors.red,
                    )
                  else ...[
                    OutlineActionButton('Fazer login', () => _go(context, const LoginScreen())),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: () => _go(context, const RegisterScreen()),
                        style: TextButton.styleFrom(foregroundColor: Colors.white70),
                        child: const Text('Registrar-se'),
                      ),
                    ),
                  ],
                  const Spacer(),
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: () => _go(context, const PrivacyScreen()),
                      child: const Text(
                        'Privacidade e dados',
                        style: TextStyle(color: AppColors.cyan, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Highlighted section: the contacts are who receives the S.O.S.
class _TrustedContacts extends StatelessWidget {
  const _TrustedContacts();

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactsController>().contacts;
    final loggedIn = context.watch<AuthController>().loggedIn;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.cyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loggedIn ? 'Contatos de confiança (${contacts.length})' : 'Contatos de confiança',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              if (loggedIn)
                TextButton(
                  onPressed: () => ProfileScreen._go(context, const AddContactScreen()),
                  child: const Text('+ ADICIONAR', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              'Eles recebem sua localização quando você aciona o S.O.S.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          if (!loggedIn)
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Faça login para visualizar seus contatos de confiança cadastrados.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final c in contacts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ProfileScreen._go(context, AddContactScreen(contact: c)),
                  child: AppCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.cyan.withValues(alpha: .15),
                          child: Text(c.initial, style: const TextStyle(color: AppColors.cyan)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                '${c.phone} · ${ProfileScreen._consentLabel(c.consentStatus)}',
                                style: const TextStyle(fontSize: 11, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                        if (c.hasConsent)
                          IconButton(
                            tooltip: 'Remover contato',
                            icon: const Icon(Icons.close, color: AppColors.red),
                            onPressed: () => ProfileScreen._removeContact(context, c),
                          )
                        else
                          IconButton(
                            tooltip: 'Enviar pedido de consentimento',
                            icon: const Icon(Icons.send, color: AppColors.cyan),
                            onPressed: () => ProfileScreen._sendConsentRequest(context, c),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
