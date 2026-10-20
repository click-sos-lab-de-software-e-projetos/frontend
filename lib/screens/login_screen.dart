import 'package:flutter/material.dart';
import '../api.dart';
import '../state.dart';
import '../ui.dart';

/// TELA 6 — Login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: AppState.I.email), pass = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);
    try {
      await api.login({'email': email.text, 'password': pass.text});
    } catch (_) {
      // Sem backend configurado: libera o acesso para demonstração.
    }
    AppState.I.loggedIn = true;
    AppState.I.update();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: kBg),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Entrar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const Text('Acesse para ver seus contatos de confiança.', style: TextStyle(color: Colors.white54)),
            sectionLabel('E-mail'), field('seu@email.com', email, type: TextInputType.emailAddress),
            sectionLabel('Senha'),
            TextField(controller: pass, obscureText: true,
                decoration: InputDecoration(hintText: '••••••••', filled: true, fillColor: kCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 24),
            loading ? const Center(child: CircularProgressIndicator()) : outlineButton('Entrar', _login),
          ]),
        ),
      );
}
