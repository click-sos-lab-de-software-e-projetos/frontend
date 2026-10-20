import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../api.dart';
import '../services.dart';
import '../state.dart';
import '../ui.dart';

/// TELA 2 — Registro de Ocorrência.
class OccurrenceScreen extends StatefulWidget {
  const OccurrenceScreen({super.key});
  @override
  State<OccurrenceScreen> createState() => _OccurrenceScreenState();
}

class _OccurrenceScreenState extends State<OccurrenceScreen> {
  final addr = TextEditingController();
  LatLng? pos;
  TimeOfDay? time;
  DateTime? date;
  String? type;
  static const types = ['Agressão', 'Discriminação', 'Assédio', 'Outro'];

  Future<void> _useLocation() async {
    final p = await currentPosition();
    if (p == null) return;
    setState(() { pos = p; addr.text = 'Localização atual (${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)})'; });
  }

  Future<void> _save() async {
    final body = {
      'address': addr.text, 'lat': pos?.latitude, 'lng': pos?.longitude, 'type': type,
      'datetime': '${date?.toIso8601String().substring(0, 10)} ${time?.format(context)}',
    };
    try { await api.postOccurrence(body); } catch (_) {}
    if (pos != null) AppState.I.occurrences.add(Occurrence(pos!, 3, type ?? 'Ocorrência'));
    AppState.I.update();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: kBg),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Registro de Ocorrência', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const Text('Preencha os campos abaixo para registrar uma ocorrência.', style: TextStyle(color: Colors.white54, fontSize: 13)),
          sectionLabel('Local'),
          field('Insira o endereço do ocorrido', addr),
          TextButton.icon(onPressed: _useLocation, icon: const Icon(Icons.my_location, size: 18), label: const Text('Usar localização atual')),
          sectionLabel('Data / Hora'),
          Row(children: [
            Expanded(child: OutlinedButton(
                onPressed: () async { final t = await showTimePicker(context: context, initialTime: TimeOfDay.now()); setState(() => time = t); },
                child: Text(time?.format(context) ?? '00:00'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDate: DateTime.now());
                  setState(() => date = d);
                },
                child: Text(date == null ? 'DD/MM/AA' : '${date!.day}/${date!.month}/${date!.year % 100}'))),
          ]),
          sectionLabel('Ocorrido'),
          DropdownButtonFormField<String>(
            value: type, hint: const Text('Selecionar opção...'), dropdownColor: kCard,
            decoration: InputDecoration(filled: true, fillColor: kCard, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            items: types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => type = v),
          ),
          const SizedBox(height: 20),
          const Text('Atenção!\nRecomendamos fortemente que contate o 190 em casos de emergência. Nosso trabalho é apenas alertar sobre situações e locais de risco, o que NÃO substitui o trabalho da polícia.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 30),
          outlineButton('Salvar', _save),
        ]),
      );
}
