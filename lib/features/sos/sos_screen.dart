import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/whatsapp_service.dart';
import '../../shared/widgets/app_card.dart';
import 'sos_controller.dart';
import 'widgets/sos_button.dart';

/// TELA 3 — Emergência (segurar o botão SOS por 3 segundos).
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  Future<void> _fire() async {
    final whatsApp = context.read<WhatsAppService>();
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await context.read<SosController>().trigger();
    if (!mounted) return;
    if (outcome.alertError != null) messenger.showSnackBar(SnackBar(content: Text(outcome.alertError!)));
    if (outcome.targets.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Ative ao menos um contato em Ajustes.')));
      return;
    }
    // WhatsApp requires a user tap to send each message.
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enviar alerta por WhatsApp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final c in outcome.targets)
              ListTile(
                leading: const Icon(Icons.send, color: AppColors.cyan),
                title: Text(c.name),
                subtitle: Text(c.phone),
                onTap: () => whatsApp.open(c.phone, outcome.message),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: const Text(
                '● CANAL DE SOCORRO PROTEGIDO',
                style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            const Text('EMERGÊNCIA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              child: Text(
                'Seu sinal será emitido para as autoridades e contatos de confiança',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 30),
            SosButton(onTriggered: _fire),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: AppCard(
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, color: AppColors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pressione por 3 segundos para iniciar o protocolo de rastreamento e envio.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
