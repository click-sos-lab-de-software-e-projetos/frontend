import 'package:flutter/material.dart';
import '../state.dart';
import '../ui.dart';

/// TELA 4 — Configurar SOS.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final app = AppState.I;

  @override
  void initState() {
    super.initState();
    app.addListener(() => mounted ? setState(() {}) : null);
  }

  Future<void> _editMessage() async {
    final c = TextEditingController(text: app.sosMessage);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Mensagem de socorro'),
        content: TextField(controller: c, maxLength: 160, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () { app.sosMessage = c.text; app.update(); Navigator.pop(context); }, child: const Text('Salvar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(padding: const EdgeInsets.only(bottom: 20), children: [
          header('Configurar SOS', 'Configure os parâmetros e alertas de segurança'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              sectionLabel('Contatos de alerta ativos'),
              for (final c in app.contacts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: box(
                    pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero, activeColor: kCyan,
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Receberá WhatsApp e Localização', style: TextStyle(fontSize: 11)),
                      value: c.alertEnabled,
                      onChanged: (v) { c.alertEnabled = v; app.update(); },
                    ),
                  ),
                ),
              sectionLabel('Mensagem de socorro'),
              box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('"${app.sosMessage} [link do mapa]"', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const Divider(color: Colors.white12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${app.sosMessage.length} / 160 caracteres', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  GestureDetector(onTap: _editMessage, child: const Text('ALTERAR', style: TextStyle(color: kCyan, fontSize: 11, fontWeight: FontWeight.w700))),
                ]),
              ])),
              sectionLabel('Informações adicionais'),
              box(
                pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero, activeColor: kCyan,
                  secondary: const Icon(Icons.shield_outlined, color: kRed),
                  title: const Text('Alerta Silencioso', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Sem som ou luz de tela ao ativar SOS', style: TextStyle(fontSize: 11)),
                  value: app.silentAlert,
                  onChanged: (v) { app.silentAlert = v; app.update(); },
                ),
              ),
            ]),
          ),
        ]),
      );
}
