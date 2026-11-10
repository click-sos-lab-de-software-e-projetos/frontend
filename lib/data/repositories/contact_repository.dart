import 'package:dio/dio.dart';

import '../models/contact.dart';
import 'repository_exception.dart';

abstract interface class ContactRepository {
  Future<List<Contact>> list();

  /// Throws [RepositoryException] with the backend message when the limit of
  /// active contacts is reached.
  Future<Contact> create({required String name, required String phone});

  Future<Contact> update(String id, {String? name, String? phone, bool? alertEnabled});

  Future<void> delete(String id);

  /// Single-use link to the consent page, to send to the contact. Creating a
  /// new link invalidates the previous one.
  Future<String> requestConsentLink(String id);
}

const maxActiveContacts = 3;
const _limitMessage = 'Limite de $maxActiveContacts contatos ativos atingido.';
const _alreadyConsentedMessage = 'Este contato já confirmou o consentimento.';

class HttpContactRepository implements ContactRepository {
  HttpContactRepository(this._dio);

  final Dio _dio;

  static Contact _parse(Object? data) => Contact.fromJson(Map<String, dynamic>.from(data! as Map));

  Future<T> _call<T>(Future<T> Function() request, String fallback, {String conflict = _limitMessage}) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) throw RepositoryException(conflict, cause: e);
      if (e.response?.statusCode == 404) throw RepositoryException('Contato não encontrado.', cause: e);
      throw RepositoryException.fromDio(e, fallback);
    }
  }

  @override
  Future<List<Contact>> list() => _call(
        () async {
          final r = await _dio.get<List<dynamic>>('/contatos');
          return (r.data ?? const []).map(_parse).toList(growable: false);
        },
        'Não foi possível carregar os contatos.',
      );

  @override
  Future<Contact> create({required String name, required String phone}) => _call(
        () async {
          final r =
              await _dio.post<Map<String, dynamic>>('/contatos', data: {'nome': name, 'telefone_whatsapp': phone});
          return _parse(r.data);
        },
        'Não foi possível adicionar o contato.',
      );

  @override
  Future<Contact> update(String id, {String? name, String? phone, bool? alertEnabled}) => _call(
        () async {
          final r = await _dio.patch<Map<String, dynamic>>(
            '/contatos/$id',
            data: {
              if (name != null) 'nome': name,
              if (phone != null) 'telefone_whatsapp': phone,
              if (alertEnabled != null) 'ativo': alertEnabled,
            },
          );
          return _parse(r.data);
        },
        'Não foi possível atualizar o contato.',
      );

  @override
  Future<void> delete(String id) =>
      _call(() => _dio.delete<void>('/contatos/$id'), 'Não foi possível remover o contato.');

  @override
  Future<String> requestConsentLink(String id) => _call(
        () async {
          final r = await _dio.post<Map<String, dynamic>>('/contatos/$id/consentimento');
          return r.data!['url'] as String;
        },
        'Não foi possível gerar o link de consentimento.',
        conflict: _alreadyConsentedMessage,
      );
}

/// In-memory contacts with the same active-contact limit as the backend.
/// New contacts start without consent, like on the server.
class FakeContactRepository implements ContactRepository {
  FakeContactRepository([List<Contact> initial = const []]) : _contacts = [...initial];

  final List<Contact> _contacts;
  int _seq = 0;

  int get _active => _contacts.where((c) => c.alertEnabled).length;

  @override
  Future<List<Contact>> list() async => List.unmodifiable(_contacts);

  @override
  Future<Contact> create({required String name, required String phone}) async {
    if (_active >= maxActiveContacts) throw const RepositoryException(_limitMessage);
    final contact = Contact(id: 'fake-contato-${_seq++}', name: name, phone: phone);
    _contacts.add(contact);
    return contact;
  }

  @override
  Future<Contact> update(String id, {String? name, String? phone, bool? alertEnabled}) async {
    final i = _contacts.indexWhere((c) => c.id == id);
    if (i < 0) throw const RepositoryException('Contato não encontrado.');
    if (alertEnabled == true && !_contacts[i].alertEnabled && _active >= maxActiveContacts) {
      throw const RepositoryException(_limitMessage);
    }
    final current = _contacts[i];
    final updated = current.copyWith(name: name, phone: phone, alertEnabled: alertEnabled);
    // Like the backend, a new phone needs a new consent.
    return _contacts[i] = phone == null || phone == current.phone
        ? updated
        : Contact(id: id, name: updated.name, phone: updated.phone, alertEnabled: updated.alertEnabled);
  }

  @override
  Future<void> delete(String id) async => _contacts.removeWhere((c) => c.id == id);

  @override
  Future<String> requestConsentLink(String id) async {
    final contact = _contacts.where((c) => c.id == id).firstOrNull;
    if (contact == null) throw const RepositoryException('Contato não encontrado.');
    if (contact.hasConsent) throw const RepositoryException(_alreadyConsentedMessage);
    return 'https://consentimento.example/#token=fake-$id';
  }
}
