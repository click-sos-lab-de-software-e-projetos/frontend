import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Contact {
  String name, relation, phone;
  bool alertEnabled;
  Contact(this.name, this.relation, this.phone, {this.alertEnabled = true});
}

class Occurrence {
  final LatLng pos;
  final int severity; // 1..3
  final String type;
  Occurrence(this.pos, this.severity, this.type);
}

class AppState extends ChangeNotifier {
  static final AppState I = AppState._();
  AppState._();

  String name = 'Maj. Camila Santos', email = 'camila.santos@defesa.gov.br', phone = '+55 (11) 98230-1122';
  String protectionId = '#AS-98302';
  bool loggedIn = false, silentAlert = true;
  String sosMessage = '[Alerta Seguro] Preciso de ajuda urgente! Minha localização em tempo real foi ativada em:';
  final List<Contact> contacts = [
    Contact('Ricardo Santos', 'Cônjuge', '(11) 99122-3847'),
    Contact('Ana Santos (Mãe)', 'Familiar', '(11) 98111-9988', alertEnabled: false),
  ];
  final List<Occurrence> occurrences = [];

  void update() => notifyListeners();
}
