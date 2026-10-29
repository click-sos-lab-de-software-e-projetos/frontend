import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/whatsapp_service.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/outline_action_button.dart';
import '../../shared/widgets/section_label.dart';
import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import '../contacts/add_contact_screen.dart';
import '../contacts/contacts_controller.dart';
import 'edit_profile_screen.dart';
import 'profile_controller.dart';

/// TELA 5 — Perfil (com aviso de login quando deslogado).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static void _go(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;
    final contacts = context.watch<ContactsController>().contacts;
    final auth = context.watch<AuthController>();
    return SafeArea(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seu Perfil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                IconButton(
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
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cyan, width: 3)),
                  child: const Icon(Icons.person_outline, size: 50, color: AppColors.cyan),
                ),
                const SizedBox(height: 10),
                Text(profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(
                  'ID DE PROTEÇÃO: ${profile.protectionId}',
                  style: const TextStyle(color: AppColors.cyan, fontSize: 10),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Dados cadastrais'),
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('E-mail', style: TextStyle(color: Colors.white54)),
                      Text(profile.email),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Telefone', style: TextStyle(color: Colors.white54)),
                      Text(profile.phone),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SectionLabel('Contatos de confiança (${contacts.length})'),
                    TextButton(
                      onPressed: () => _go(context, const AddContactScreen()),
                      child: const Text('+ ADICIONAR', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                if (!auth.loggedIn) ...[
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
                  ),
                  const SizedBox(height: 10),
                  OutlineActionButton('Fazer Login', () => _go(context, const LoginScreen())),
                ] else
                  for (final c in contacts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
                                    '${c.relation} · ${c.phone}',
                                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat, color: AppColors.cyan),
                              onPressed: () => context.read<WhatsAppService>().open(c.phone, 'Olá!'),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 16),
                OutlineActionButton('Desconectar do Dispositivo', auth.logout, color: AppColors.red),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
