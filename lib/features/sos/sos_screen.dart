import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/location_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../shared/widgets/app_card.dart';
import '../profile/privacy_screen.dart';
import 'sos_controller.dart';
import 'widgets/sos_button.dart';
import 'widgets/sos_status_card.dart';
import 'widgets/whatsapp_sheet.dart';

/// TELA 3 — Emergência: um toque envia o alerta depois de 5 s, que podem ser cancelados.
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  static const privacy = 'Sua localização será enviada só aos seus contatos ativos que aceitaram. '
      'O alerta fica guardado por 180 dias e depois é anonimizado.';
  static const whyLocation = 'Para seus contatos saberem onde você está, o alerta leva a sua localização. '
      'Ela só é lida quando você toca no S.O.S.';
  static const whatsAppOnly = 'Enviar só pelo WhatsApp';

  static String deniedReason(LocationAccess access) => switch (access) {
        LocationAccess.serviceOff => 'A localização do aparelho está desligada. Ligue-a para enviar o alerta.',
        LocationAccess.deniedForever =>
          'O app não tem permissão de localização. Libere nas configurações para enviar o alerta.',
        _ => 'Sem permissão de localização o alerta não pode ser enviado pelo servidor.',
      };

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  Future<void> _onTap() async {
    final sos = context.read<SosController>();
    final location = context.read<LocationService>();
    var access = await location.checkAccess();
    if (!mounted) return;
    if (access == LocationAccess.canAsk) {
      if (!await _explainLocation()) return;
      access = await location.requestAccess();
      if (!mounted) return;
    }
    if (access == LocationAccess.granted) {
      await sos.start();
    } else {
      await _locationUnavailable(access);
    }
  }

  Future<bool> _explainLocation() async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Por que a localização?'),
          content: const Text(SosScreen.whyLocation),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c, false);
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()));
              },
              child: const Text('Ver política de privacidade'),
            ),
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Agora não')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Continuar')),
          ],
        ),
      ) ??
      false;

  Future<void> _locationUnavailable(LocationAccess access) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Localização indisponível'),
        content: Text(SosScreen.deniedReason(access)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'settings'), child: const Text('Abrir configurações')),
          TextButton(onPressed: () => Navigator.pop(c, 'whatsapp'), child: const Text(SosScreen.whatsAppOnly)),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'settings') await context.read<LocationService>().openSettings(access);
    if (choice == 'whatsapp') await _whatsApp(withLocation: false);
  }

  Future<void> _whatsApp({bool withLocation = true}) {
    final sos = context.read<SosController>();
    return showWhatsAppSheet(
      context,
      whatsApp: context.read<WhatsAppService>(),
      targets: sos.targets,
      text: sos.whatsAppText(withLocation: withLocation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosController>();
    final state = sos.state;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
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
            const SizedBox(height: 24),
            const Text('EMERGÊNCIA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Seu alerta será enviado pelo WhatsApp aos seus contatos de confiança',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 16),
            SosButton(
              onPressed: sos.busy ? null : _onTap,
              label: state.phase == SosPhase.countdown ? '${state.secondsLeft}' : 'SOS',
            ),
            const SizedBox(height: 16),
            if (state.phase != SosPhase.idle)
              SosStatusCard(
                state: state,
                onCancel: sos.cancel,
                onWhatsApp: sos.targets.isEmpty ? null : _whatsApp,
                onDismiss: sos.dismiss,
              )
            else
              const AppCard(
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, color: AppColors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Toque para enviar. Você tem 5 segundos para cancelar.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              SosScreen.privacy,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
