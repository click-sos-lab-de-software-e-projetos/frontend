# Alerta Seguro (Flutter)

## Como rodar
1. `flutter create .` (gera as pastas android/ios na raiz deste projeto, sem sobrescrever lib/)
2. `flutter pub get`
3. `dart run build_runner build --delete-conflicting-outputs`  (gera lib/api.g.dart do Retrofit)
4. Aplique android_snippets/AndroidManifest_trecho.xml e coloque sua chave do Google Maps.
5. iOS: adicione `NSLocationWhenInUseUsageDescription` no Info.plist e a chave em AppDelegate.
6. Troque a baseUrl em lib/api.dart. Sem backend, o app usa dados fictícios.

## Telas
1 Mapa (calor) · 2 Registro de Ocorrência · 3 Emergência/SOS · 4 Configurar SOS
5 Perfil · 6 Login · 7 Configurações de Perfil · 8 Registrar contato de confiança

## Contrato esperado do backend
GET /occurrences?lat&lng&radius -> [{lat,lng,severity(1-3),type}]
POST /occurrences, POST /alerts, POST /auth/login
