import 'package:flutter/material.dart';

import '../../core/services/geo_point.dart';
import '../../data/models/occurrence_report.dart';

class OccurrenceFormController extends ChangeNotifier {
  static const types = ['Agressão', 'Discriminação', 'Assédio', 'Outro'];

  final address = TextEditingController();
  GeoPoint? position;
  DateTime? date;
  TimeOfDay? time;
  String? type;

  void useLocation(GeoPoint p) {
    position = p;
    address.text = 'Localização atual (${p.lat.toStringAsFixed(4)}, ${p.lng.toStringAsFixed(4)})';
    notifyListeners();
  }

  void setDate(DateTime? value) {
    date = value;
    notifyListeners();
  }

  void setTime(TimeOfDay? value) {
    time = value;
    notifyListeners();
  }

  void setType(String? value) {
    type = value;
    notifyListeners();
  }

  String? validateAddress(String? v) =>
      (v ?? '').trim().isEmpty ? 'Informe o endereço ou use a localização atual.' : null;

  String? validateType(String? v) => v == null ? 'Selecione o tipo de ocorrência.' : null;

  String? validateDateTime() => date == null || time == null ? 'Informe a data e a hora.' : null;

  /// The report to send. Only call after the form validated.
  OccurrenceReport buildReport() {
    final d = date!, t = time!;
    return OccurrenceReport(
      address: address.text.trim(),
      lat: position?.lat,
      lng: position?.lng,
      type: type!,
      dateTime: DateTime(d.year, d.month, d.day, t.hour, t.minute),
    );
  }

  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }
}
