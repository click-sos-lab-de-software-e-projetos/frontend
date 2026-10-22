# Alerta Seguro — Frontend (Flutter)

Aplicativo mobile de segurança colaborativa: **mapa de calor** de ocorrências
reportadas pela comunidade + **botão SOS** que envia sua localização para
contatos de confiança via WhatsApp.

> Projeto acadêmico — Laboratório de Software e Projetos.
> Há um plano de refatoração em andamento: veja [`plans/refactor-structure.md`](plans/refactor-structure.md).

## Funcionalidades (telas)

| # | Tela | Arquivo |
|---|------|---------|
| 1 | Mapa de calor | `lib/screens/map_screen.dart` |
| 2 | Registro de ocorrência | `lib/screens/occurrence_screen.dart` |
| 3 | Emergência / SOS (segurar 3 s) | `lib/screens/sos_screen.dart` |
| 4 | Configurar SOS | `lib/screens/settings_screen.dart` |
| 5 | Perfil | `lib/screens/profile_screen.dart` |
| 6 | Login | `lib/screens/login_screen.dart` |
| 7 | Configurações de perfil | `lib/screens/edit_profile_screen.dart` |
| 8 | Registrar contato de confiança | `lib/screens/add_contact_screen.dart` |

## Stack

- Flutter (Dart `>=3.3.0 <4.0.0`), Material 3, tema escuro
- [`google_maps_flutter`](https://pub.dev/packages/google_maps_flutter) — mapa
- [`geolocator`](https://pub.dev/packages/geolocator) — localização
- [`dio`](https://pub.dev/packages/dio) — cliente HTTP
- [`url_launcher`](https://pub.dev/packages/url_launcher) — abre o WhatsApp (`wa.me`)

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`flutter doctor` sem erros)
- Android Studio (emulador), Xcode (iOS) **ou** Google Chrome (web)
- Uma chave da **Google Maps API** (Maps SDK for Android / iOS e, para web, Maps JavaScript API)

## Como rodar

### 1. Instalar o Flutter

- **macOS (Homebrew):** `brew install --cask flutter`
- **Windows / Linux:** siga o [guia oficial](https://docs.flutter.dev/get-started/install).

Depois confira o ambiente:

```bash
flutter --version
flutter doctor        # mostra o que falta (Android SDK, Xcode, Chrome...)
```

### 2. Baixar o projeto e as dependências

```bash
git clone https://github.com/click-sos-lab-de-software-e-projetos/frontend.git
cd frontend
flutter pub get
```

As pastas de plataforma (`android/`, `ios/`, `web/`, ...) já estão no repositório,
então **não** é preciso rodar `flutter create .` nem `build_runner`.

### 3. Escolher um dispositivo e executar

```bash
flutter devices                # lista emuladores, simuladores e navegadores disponíveis
flutter run                    # roda no dispositivo padrão
flutter run -d <id>            # roda em um dispositivo específico (ex.: emulator-5554)
flutter run -d chrome          # roda no navegador (não precisa de Android SDK/Xcode)
```

| Plataforma | O que precisa |
|------------|---------------|
| Android | Android Studio com um emulador criado (ou celular com depuração USB) |
| iOS | macOS + Xcode com um simulador (ou iPhone) |
| Web (Chrome) | Apenas o Google Chrome instalado |

Com o app rodando, use **`r`** para *hot reload*, **`R`** para *hot restart* e
**`q`** para encerrar.

> **Web:** para o mapa aparecer no navegador, carregue a API JavaScript do Google
> Maps em `web/index.html`, dentro do `<head>`:
> `<script src="https://maps.googleapis.com/maps/api/js?key=SUA_CHAVE"></script>`.
> Sem isso, a aba **Mapa** mostra um erro (`Cannot read properties of undefined
> (reading 'maps')`), mas as demais telas funcionam.

### Configuração obrigatória para o mapa e a localização

O manifesto Android ainda **não** tem as permissões nem a chave do Maps
(ver plano, passo 1). Até isso ser corrigido, faça localmente:

**Android** — copie o conteúdo de `android_snippets/AndroidManifest_trecho.xml`
para `android/app/src/main/AndroidManifest.xml` (permissões `INTERNET`,
`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, bloco `<queries>` do WhatsApp e
`<meta-data android:name="com.google.android.geo.API_KEY" .../>`).

**iOS** — em `ios/Runner/Info.plist` adicione `NSLocationWhenInUseUsageDescription`
e registre a chave em `ios/Runner/AppDelegate.swift` com `GMSServices.provideAPIKey("SUA_CHAVE")`.

> ⚠️ Nunca faça commit da sua chave do Google Maps.

### Backend

A URL da API está fixa em `lib/api.dart` (`baseUrl`). Troque pela URL do seu backend.
**Sem backend, o app funciona em modo demonstração**: o mapa usa ocorrências
fictícias e o login aceita qualquer credencial.

## Testes e análise

```bash
flutter analyze
flutter test
```

## Estrutura do projeto

```
lib/
├── main.dart          # MaterialApp, tema e navegação inferior
├── api.dart           # cliente HTTP (Dio) e endpoints
├── services.dart      # localização, WhatsApp, link do Google Maps
├── state.dart         # modelos e estado global (AppState)
├── ui.dart            # cores e componentes visuais reutilizáveis
└── screens/           # uma tela por arquivo
android_snippets/      # trecho de AndroidManifest a aplicar (temporário)
test/                  # testes (smoke test da navegação)
plans/                 # planos de implementação/refatoração
```

A estrutura alvo (por *features*, com repositórios e controllers) está descrita
em [`plans/refactor-structure.md`](plans/refactor-structure.md).

## Contrato esperado do backend (rascunho)

| Método | Rota | Corpo / parâmetros | Resposta |
|--------|------|--------------------|----------|
| `GET`  | `/occurrences` | `?lat&lng&radius` (metros) | `[{ lat, lng, severity (1-3), type }]` |
| `POST` | `/occurrences` | `{ address, lat, lng, type, datetime }` | — |
| `POST` | `/alerts` | `{ lat, lng, message, userId }` | — |
| `POST` | `/auth/login` | `{ email, password }` | objeto do usuário/token |

## Aviso

O Alerta Seguro **não substitui a polícia**. Em emergências, ligue **190**.
