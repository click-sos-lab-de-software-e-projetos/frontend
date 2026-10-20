import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../services.dart';
import '../state.dart';
import '../ui.dart';

/// TELA 3 — Emergência (segurar o botão SOS por 3 segundos).
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  late final AnimationController ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..addStatusListener((s) {
        if (s == AnimationStatus.completed) _fire();
      });
  final app = AppState.I;

  Future<void> _fire() async {
    ctrl.reset();
    final targets = app.contacts.where((c) => c.alertEnabled).toList();
    final pos = await currentPosition();
    final text = '${app.sosMessage} ${pos != null ? mapsLink(pos) : '(localização indisponível)'}';
    try {
      await api.postAlert({'lat': pos?.latitude, 'lng': pos?.longitude, 'message': text, 'userId': app.protectionId});
    } catch (_) {}
    if (!mounted) return;
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ative ao menos um contato em Ajustes.')));
      return;
    }
    // O WhatsApp exige um toque do usuário para enviar cada mensagem.
    showModalBottomSheet(
      context: context, backgroundColor: kCard,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Enviar alerta por WhatsApp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final c in targets)
            ListTile(
              leading: const Icon(Icons.send, color: kCyan),
              title: Text(c.name), subtitle: Text(c.phone),
              onTap: () => openWhatsApp(c.phone, text),
            ),
        ]),
      ),
    );
  }

  @override
  void dispose() { ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
            child: const Text('● CANAL DE SOCORRO PROTEGIDO', style: TextStyle(color: kCyan, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          const Text('EMERGÊNCIA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Text('Seu sinal será emitido para as autoridades e contatos de confiança',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTapDown: (_) => ctrl.forward(),
            onTapUp: (_) => ctrl.reset(),
            onTapCancel: () => ctrl.reset(),
            child: AnimatedBuilder(
              animation: ctrl,
              builder: (_, __) => SizedBox(
                width: 230, height: 230,
                child: Stack(alignment: Alignment.center, children: [
                  Container(width: 200 + 30 * ctrl.value, height: 200 + 30 * ctrl.value,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: kRed.withOpacity(.12 + .1 * ctrl.value))),
                  SizedBox(width: 170, height: 170, child: CircularProgressIndicator(value: ctrl.value, strokeWidth: 4, color: Colors.white, backgroundColor: Colors.transparent)),
                  Container(width: 150, height: 150,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: kRed, boxShadow: [BoxShadow(color: kRed.withOpacity(.6), blurRadius: 40)]),
                      alignment: Alignment.center,
                      child: const Text('SOS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900))),
                ]),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: box(child: Row(children: const [
              Icon(Icons.notifications_active_outlined, color: kRed),
              SizedBox(width: 12),
              Expanded(child: Text('Pressione por 3 segundos para iniciar o protocolo de rastreamento e envio.', style: TextStyle(color: Colors.white70, fontSize: 13))),
            ])),
          ),
        ]),
      );
}
