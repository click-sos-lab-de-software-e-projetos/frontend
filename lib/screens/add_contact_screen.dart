import 'package:flutter/material.dart';
import '../state.dart';
import '../ui.dart';

/// TELA 8 — Registrar contato de confiança.
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});
  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final name = TextEditingController(), phone = TextEditingController(), rel = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: kBg),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Registrar contato de confiança', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          sectionLabel('Nome'), field('Nome do contato', name),
          sectionLabel('Telefone (com DDD, WhatsApp)'), field('Telefone para contato', phone, type: TextInputType.phone),
          sectionLabel('Parentesco'), field('Ex.: Cônjuge, Mãe, Amigo', rel),
          const SizedBox(height: 24),
          outlineButton('Adicionar', () {
            if (name.text.isEmpty || phone.text.isEmpty) return;
            AppState.I.contacts.add(Contact(name.text, rel.text.isEmpty ? 'Contato' : rel.text, phone.text));
            AppState.I.update();
            Navigator.pop(context);
          }),
        ]),
      );
}
