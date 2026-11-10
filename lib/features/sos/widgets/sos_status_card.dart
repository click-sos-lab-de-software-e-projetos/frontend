import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../sos_controller.dart';

/// Shows where the last alert is: countdown, sending, delivered or failed.
class SosStatusCard extends StatelessWidget {
  const SosStatusCard({
    super.key,
    required this.state,
    required this.onCancel,
    required this.onWhatsApp,
    required this.onDismiss,
  });

  final SosState state;
  final VoidCallback onCancel;

  /// `null` hides the WhatsApp fallback (no active contact).
  final VoidCallback? onWhatsApp;
  final VoidCallback onDismiss;

  static const sending = 'Enviando o alerta…';
  static const pending = 'Alerta registrado. Enviando aos seus contatos…';
  static const sent = 'Alerta enviado aos seus contatos.';
  static const failed = 'Não foi possível enviar pelo servidor. Use o WhatsApp.';
  static const stillSending = 'O servidor ainda está enviando. Se preferir, use o WhatsApp.';
  static const whatsApp = 'Enviar também pelo WhatsApp';

  static String countdown(int seconds) => 'Enviando em $seconds…';

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (state.phase) {
      SosPhase.idle => (null, Colors.white, ''),
      SosPhase.countdown => (Icons.timer_outlined, Colors.white, countdown(state.secondsLeft)),
      SosPhase.sending => (null, Colors.white, sending),
      SosPhase.pending => (null, Colors.white, pending),
      SosPhase.sent => (Icons.check_circle, Colors.greenAccent, sent),
      SosPhase.failed => (Icons.error_outline, AppColors.red, failed),
      SosPhase.stillSending => (Icons.hourglass_bottom, Colors.amber, stillSending),
      SosPhase.error => (Icons.error_outline, AppColors.red, state.error ?? ''),
    };
    final spinning = state.phase == SosPhase.sending || state.phase == SosPhase.pending;
    final finished = !spinning && state.phase != SosPhase.countdown;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (spinning)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
          if (state.phase == SosPhase.countdown)
            TextButton(onPressed: onCancel, child: const Text('Cancelar'))
          else ...[
            if (onWhatsApp != null && state.phase != SosPhase.sending)
              OutlinedButton.icon(
                onPressed: onWhatsApp,
                icon: const Icon(Icons.chat_outlined),
                label: const Text(whatsApp),
              ),
            if (finished) TextButton(onPressed: onDismiss, child: const Text('Fechar')),
          ],
        ],
      ),
    );
  }
}
