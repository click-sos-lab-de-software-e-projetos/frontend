import 'package:flutter/material.dart';
import '../state.dart';
import '../ui.dart';

/// TELA 7 — Configurações de Perfil.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final a = AppState.I;
  late final name = TextEditingController(text: a.name), email = TextEditingController(text: a.email), phone = TextEditingController(text: a.phone);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: kBg),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Configurações de Perfil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          sectionLabel('Nome'), field('Nome do usuário', name),
          sectionLabel('E-mail'), field('E-mail do usuário', email, type: TextInputType.emailAddress),
          sectionLabel('Telefone'), field('Telefone do usuário', phone, type: TextInputType.phone),
          const SizedBox(height: 24),
          outlineButton('Salvar', () {
            a.name = name.text; a.email = email.text; a.phone = phone.text;
            a.update();
            Navigator.pop(context);
          }),
        ]),
      );
}
