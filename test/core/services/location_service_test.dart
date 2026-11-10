import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FakeLocationService grants on request when configured and records settings opened', () async {
    final location = FakeLocationService((lat: 1, lng: 2))..access = LocationAccess.canAsk;

    expect(await location.checkAccess(), LocationAccess.canAsk);
    expect(await location.requestAccess(), LocationAccess.granted);
    expect(await location.checkAccess(), LocationAccess.granted);

    await location.openSettings(LocationAccess.serviceOff);
    expect(location.openedSettings, [LocationAccess.serviceOff]);
  });

  test('FakeLocationService keeps a refusal when the person says no', () async {
    final location = FakeLocationService()
      ..access = LocationAccess.canAsk
      ..afterRequest = LocationAccess.denied;
    expect(await location.requestAccess(), LocationAccess.denied);
    expect(location.requests, 1);
  });
}
