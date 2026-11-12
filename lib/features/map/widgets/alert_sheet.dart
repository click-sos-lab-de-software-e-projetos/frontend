import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/services/geo_point.dart';
import '../../../data/models/community_alert.dart';
import '../../../data/repositories/region_repository.dart';
import '../../../data/repositories/repository_exception.dart';

/// Opens the form that creates an alert at [position]. Returns the created alert, or null.
Future<CommunityAlert?> showAlertSheet(BuildContext context, GeoPoint position) => showModalBottomSheet<CommunityAlert>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (_) => AlertSheet(position: position),
    );

class AlertSheet extends StatefulWidget {
  const AlertSheet({super.key, required this.position});

  final GeoPoint position;

  static const notice = 'O alerta fica no mapa, na sua localização atual, por 24 horas. Ninguém vê quem criou.';

  @override
  State<AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<AlertSheet> {
  final _text = TextEditingController();
  AlertCategory? _category;
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final alert = NewAlert(_category!, widget.position, _text.text);
    final invalid = alert.error;
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final created = await context.read<RegionRepository>().createAlert(alert);
      if (mounted) Navigator.pop(context, created);
    } on RepositoryException catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('O que está acontecendo aqui?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(AlertSheet.notice, style: TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in AlertCategory.values)
                    ChoiceChip(
                      avatar: Icon(c.icon, size: 18),
                      label: Text(c.label),
                      selected: _category == c,
                      onSelected: _sending ? null : (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                enabled: !_sending,
                maxLength: NewAlert.maxLength,
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: _category == AlertCategory.other ? 'Descreva o problema' : 'Detalhes (opcional)',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: AppColors.red)),
                ),
              FilledButton(
                onPressed: _category == null || _sending ? null : _send,
                child: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Alertar aqui'),
              ),
            ],
          ),
        ),
      );
}
