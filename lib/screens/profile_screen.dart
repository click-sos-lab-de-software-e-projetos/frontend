import 'package:flutter/material.dart';
import '../state.dart';
import '../ui.dart';
import '../services.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'add_contact_screen.dart';

/// TELA 5 — Perfil (com aviso de login quando deslogado).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final app = AppState.I;

  @override
  void initState() {
    super.initState();
    app.addListener(() => mounted ? setState(() {}) : null);
  }

  void _go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Seu Perfil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              IconButton(onPressed: () => _go(const EditProfileScreen()), icon: const Icon(Icons.edit, color: kCyan)),
            ]),
          ),
          Center(child: Column(children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kCyan, width: 3)),
              child: const Icon(Icons.person_outline, size: 50, color: kCyan),
            ),
            const SizedBox(height: 10),
            Text(app.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('ID DE PROTEÇÃO: ${app.protectionId}', style: const TextStyle(color: kCyan, fontSize: 10)),
          ])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              sectionLabel('Dados cadastrais'),
              box(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('E-mail', style: TextStyle(color: Colors.white54)), Text(app.email)])),
              const SizedBox(height: 8),
              box(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Telefone', style: TextStyle(color: Colors.white54)), Text(app.phone)])),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                sectionLabel('Contatos de confiança (${app.contacts.length})'),
                TextButton(onPressed: () => _go(const AddContactScreen()), child: const Text('+ ADICIONAR', style: TextStyle(fontSize: 11))),
              ]),
              if (!app.loggedIn) ...[
                box(child: Row(children: const [
                  Icon(Icons.lock_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Faça login para visualizar seus contatos de confiança cadastrados.', style: TextStyle(fontSize: 12, color: Colors.white70))),
                ])),
                const SizedBox(height: 10),
                outlineButton('Fazer Login', () => _go(const LoginScreen())),
              ] else
                for (final c in app.contacts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: box(child: Row(children: [
                      CircleAvatar(backgroundColor: kCyan.withOpacity(.15), child: Text(c.name.substring(0, 1), style: const TextStyle(color: kCyan))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${c.relation} · ${c.phone}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                      ])),
                      IconButton(icon: const Icon(Icons.chat, color: kCyan), onPressed: () => openWhatsApp(c.phone, 'Olá!')),
                    ])),
                  ),
              const SizedBox(height: 16),
              outlineButton('Desconectar do Dispositivo', () { app.loggedIn = false; app.update(); }, color: kRed),
              const SizedBox(height: 20),
            ]),
          ),
        ]),
      );
}
