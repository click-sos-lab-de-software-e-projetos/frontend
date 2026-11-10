# Alerta Seguro — Frontend (Flutter)

Aplicativo mobile de segurança colaborativa: **mapa de calor** de ocorrências
reportadas pela comunidade + **botão SOS** que envia sua localização para
contatos de confiança via WhatsApp.

> Projeto acadêmico — Laboratório de Software e Projetos.
> Há um plano de refatoração em andamento: veja [`plans/refactor-structure.md`](plans/refactor-structure.md).

## Funcionalidades (telas)

| # | Tela | Arquivo |
|---|------|---------|
| 1 | Mapa de calor | `lib/features/map/map_screen.dart` |
| 2 | Registro de ocorrência | `lib/features/occurrence/occurrence_screen.dart` |
| 3 | Emergência / SOS (segurar 3 s) | `lib/features/sos/sos_screen.dart` |
| 4 | Configurar SOS | `lib/features/settings/settings_screen.dart` |
| 5 | Perfil | `lib/features/profile/profile_screen.dart` |
| 6 | Login | `lib/features/auth/login_screen.dart` |
| 7 | Configurações de perfil | `lib/features/profile/edit_profile_screen.dart` |
| 8 | Registrar contato de confiança | `lib/features/contacts/add_contact_screen.dart` |
| — | Cadastro | `lib/features/auth/register_screen.dart` |

## Stack

- Flutter (Dart `>=3.3.0 <4.0.0`), Material 3, tema escuro
- [`google_maps_flutter`](https://pub.dev/packages/google_maps_flutter) — mapa
- [`geolocator`](https://pub.dev/packages/geolocator) — localização
- [`dio`](https://pub.dev/packages/dio) — cliente HTTP
- [`provider`](https://pub.dev/packages/provider) — injeção de dependências e estado (`ChangeNotifier`)
- [`url_launcher`](https://pub.dev/packages/url_launcher) — abre o WhatsApp (`wa.me`)
- [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) — guarda o token (Keychain no iOS, armazenamento criptografado no Android)

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
então **não** é preciso rodar `flutter create .`.

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

### Chave do Google Maps

As permissões de localização/internet e o bloco `<queries>` do WhatsApp já estão
configurados. Falta apenas informar **localmente** a sua chave do Maps:

**Android** — em `android/local.properties` (arquivo ignorado pelo git):

```properties
MAPS_API_KEY=SUA_CHAVE
```

**iOS** — crie `ios/Flutter/Secrets.xcconfig` (ignorado pelo git):

```
MAPS_API_KEY=SUA_CHAVE
```

> ⚠️ Nunca faça commit da sua chave do Google Maps.

### Backend

Por padrão o app roda em **modo demonstração** (`USE_FAKE_API=true`): os
repositórios falsos (`lib/data/repositories/*` → `Fake*Repository`) ficam só na
memória, o login aceita qualquer e-mail/senha não vazios e, depois dele, aparecem
dois contatos de exemplo.

Para usar o [backend](https://github.com/click-sos-lab-de-software-e-projetos/backend)
local, suba a API (veja o README dele) e rode:

```bash
# Emulador Android (10.0.2.2 é o computador; é o padrão de API_BASE_URL)
flutter run --dart-define=USE_FAKE_API=false

# Simulador iOS / desktop
flutter run --dart-define=USE_FAKE_API=false --dart-define=API_BASE_URL=http://localhost:8000/api/v1

# Chrome: o backend precisa liberar a origem com CORS_ORIGIN_REGEX=http://localhost:\d+
flutter run -d chrome --dart-define=USE_FAKE_API=false --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

O build de debug do Android permite HTTP sem TLS só para isso; em produção use HTTPS.

O que já usa a API:

| Funcionalidade | Rotas |
|----------------|-------|
| Cadastro, login e perfil | `POST /auth/cadastro`, `POST /auth/login`, `GET /auth/me` |
| Contatos de confiança (máx. 3 ativos) | `GET/POST /contatos`, `PATCH/DELETE /contatos/{id}` |
| Alerta SOS | `POST /sos/alertas` (`latitude`, `longitude`, `mensagem`) |

- O token JWT fica no armazenamento seguro do aparelho (`SecureTokenStore`): ao abrir o app, a sessão é restaurada na hora e o perfil é buscado em `GET /auth/me` em segundo plano. Ele vale 24 h; quando a API responde 401, a sessão é encerrada e o token apagado. Falha de rede mantém o token. No modo demo (`USE_FAKE_API=true`) o token fica só na memória.
- O alerta só é registrado no servidor com login e localização. O backend exige ao menos um contato ativo **com consentimento**; ainda não há rota para registrar o consentimento, então a mensagem de erro da API é exibida e o envio manual por WhatsApp continua disponível.
- Mapa e ocorrências (`/occurrences`) ainda não existem no backend: use o modo demonstração para vê-los.
- A edição de perfil continua só local (não há rota de atualização).

## Testes e análise

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Os mesmos comandos rodam no GitHub Actions (`.github/workflows/ci.yml`) a cada
pull request e a cada push na `main`.

## Estrutura do projeto

```
lib/
├── main.dart                 # ponto de entrada: monta as dependências e o app
├── app/
│   ├── app.dart              # MaterialApp + MultiProvider
│   ├── dependencies.dart     # escolhe repositórios reais ou falsos (Env)
│   ├── shell.dart            # navegação inferior
│   └── theme.dart            # cores e tema
├── core/
│   ├── config/env.dart       # variáveis --dart-define
│   ├── network/              # Dio (api_client.dart) sessão com o token (session.dart) e onde ele é guardado (token_store.dart)
│   └── services/             # localização e WhatsApp
├── data/
│   ├── models/               # modelos imutáveis (fromJson/toJson)
│   ├── repositories/         # interface + implementação HTTP + fake
│   └── fakes/demo_seed.dart  # dados de demonstração
├── features/                 # uma pasta por funcionalidade (tela + controller)
│   ├── auth/  contacts/  map/  occurrence/
│   └── profile/  settings/  sos/
└── shared/widgets/           # componentes visuais reutilizáveis
test/                         # espelha a estrutura de lib/ (+ test/helpers)
plans/                        # planos de implementação/refatoração
```

## Contrato esperado do backend (rascunho)

| Método | Rota | Corpo / parâmetros | Resposta |
|--------|------|--------------------|----------|
| `GET`  | `/occurrences` | `?lat&lng&radius` (metros) | `[{ lat, lng, severity (1-3), type }]` |
| `POST` | `/occurrences` | `{ address, lat, lng, type, datetime }` (`datetime` em ISO-8601 UTC) | — |
| `POST` | `/alerts` | `{ lat, lng, message, userId }` | — |
| `POST` | `/auth/login` | `{ email, password }` | objeto do usuário/token |

## Aviso

O Alerta Seguro **não substitui a polícia**. Em emergências, ligue **190**.
