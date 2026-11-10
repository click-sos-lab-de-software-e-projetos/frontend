import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../data/models/contact.dart';

/// WhatsApp needs a tap per contact to send each message (SOSM-05 fallback).
Future<void> showWhatsAppSheet(
  BuildContext context, {
  required WhatsAppService whatsApp,
  required List<Contact> targets,
  required String text,
}) =>
    showModalBottomSheet<void>(
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
            if (targets.isEmpty)
              const Text('Ative ao menos um contato em Ajustes.', style: TextStyle(color: Colors.white70)),
            for (final c in targets)
              ListTile(
                leading: const Icon(Icons.send, color: AppColors.cyan),
                title: Text(c.name),
                subtitle: Text(c.phone),
                onTap: () => whatsApp.open(c.phone, text),
              ),
          ],
        ),
      ),
    );
