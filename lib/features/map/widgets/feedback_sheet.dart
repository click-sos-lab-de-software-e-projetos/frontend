import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../data/models/region_feedback.dart';
import '../../../data/models/risk_region.dart';
import '../../../data/repositories/region_repository.dart';
import '../../../data/repositories/repository_exception.dart';

/// Opens the feedback form for [region]. Returns true when it was sent.
Future<bool> showFeedbackSheet(BuildContext context, RiskRegion region) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (_) => FeedbackSheet(region: region),
    ) ??
    false;

class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key, required this.region});

  final RiskRegion region;

  static const pendingNotice = 'Seu relato fica pendente de análise e não muda o mapa.';

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final _text = TextEditingController();
  FeedbackCategory? _category;
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final feedback = RegionFeedback(_category!, _text.text);
    final invalid = feedback.error;
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await context.read<RegionRepository>().sendFeedback(widget.region.id, feedback);
      if (mounted) Navigator.pop(context, true);
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
              Text(
                'Feedback sobre ${widget.region.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(FeedbackSheet.pendingNotice, style: TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in FeedbackCategory.values)
                    ChoiceChip(
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
                maxLength: RegionFeedback.maxLength,
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: _category == FeedbackCategory.other ? 'Descreva o problema' : 'Detalhes (opcional)',
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
                    : const Text('Enviar'),
              ),
            ],
          ),
        ),
      );
}
