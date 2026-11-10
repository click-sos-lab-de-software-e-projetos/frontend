# Alerta Seguro — Frontend (Flutter)

Aplicativo mobile de segurança colaborativa: **mapa de risco** por distrito
(dados criminais da SSP-SP) com feedback da comunidade + **botão SOS** que envia sua localização para
contatos de confiança via WhatsApp.

> Projeto acadêmico — Laboratório de Software e Projetos.
> Há um plano de refatoração em andamento: veja [`plans/refactor-structure.md`](plans/refactor-structure.md).

## Funcionalidades (telas)

| # | Tela | Arquivo |
|---|------|---------|
| 1 | Mapa de risco por distrito | `lib/features/map/map_screen.dart` |
| 2 | Feedback por distrito (folha sobre o mapa) | `lib/features/map/widgets/feedback_sheet.dart` |
| 3 | Emergência / SOS (um toque, 5 s para cancelar) | `lib/features/sos/sos_screen.dart` |
| 4 | Configurar SOS | `lib/features/settings/settings_screen.dart` |
| 5 | Perfil | `lib/features/profile/profile_screen.dart` |
| 6 | Login | `lib/features/auth/login_screen.dart` |
| 7 | Configurações de perfil | `lib/features/profile/edit_profile_screen.dart` (+ `change_password_screen.dart`) |
| 8 | Registrar / editar contato de confiança | `lib/features/contacts/add_contact_screen.dart` |
| — | Cadastro | `lib/features/auth/register_screen.dart` |
| — | Privacidade e dados | `lib/features/profile/privacy_screen.dart` |

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

> **MAPM-01:** no Google Cloud, restrinja a chave ao app (pacote + SHA-1 no
> Android, bundle id no iOS, domínio na web) e só às APIs do Maps que o app usa.

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
| Mensagem de socorro (Ajustes) | `PATCH /auth/me` (`mensagem_sos`, até 255; vazio volta à padrão) |
| Editar perfil / trocar senha | `PATCH /auth/me` (`nome_completo`, `telefone_pessoal`), `POST /auth/me/senha` |
| Excluir conta | `DELETE /auth/me` (`{ senha }`) |
| Contatos de confiança (máx. 3 ativos) | `GET/POST /contatos`, `PATCH/DELETE /contatos/{id}` |
| Alerta SOS | `POST /sos/alertas` (`latitude`, `longitude`), `GET /sos/alertas/{id}` |
| Mapa de risco | `GET /mapa/regioes?latitude&longitude&raio=10000` |
| Feedback do distrito | `POST /mapa/regioes/{id}/feedbacks` (`categoria`, `texto`) |

- O token JWT fica no armazenamento seguro do aparelho (`SecureTokenStore`): ao abrir o app, a sessão é restaurada na hora e o perfil é buscado em `GET /auth/me` em segundo plano. Ele vale 24 h; quando a API responde 401, a sessão é encerrada e o token apagado. Falha de rede mantém o token. No modo demo (`USE_FAKE_API=true`) o token fica só na memória.
- S.O.S: um toque inicia uma contagem de 5 s com "Cancelar"; depois o app lê a localização e cria o alerta sem `mensagem` — o backend usa a mensagem salva em Ajustes ou a padrão. O status é consultado a cada 3 s (até 2 min) e o painel mostra enviando, enviado, erro ou "ainda enviando".
- Antes do primeiro pedido de localização o app explica o motivo. Com permissão negada ou GPS desligado, oferece abrir as configurações ou enviar só pelo WhatsApp (sem link). O WhatsApp (`wa.me`) também fica como opção secundária no painel de status.
- O backend exige ao menos um contato ativo **com consentimento**; sem isso, a mensagem de erro da API é exibida.
- Mapa: um círculo por distrito, com centro, raio e cor (`cor_hex`) da API; tocar mostra nome, score e faixa (Baixo < 34, Médio 34–66, Alto ≥ 67). A rota exige login: deslogado, o mapa fica sem círculos e pede para entrar. Ao parar de mover a câmera, recarrega se o centro andou mais de 2 km.
- O mapa nunca pede permissão de localização (MAPM-03): usa a posição só se ela já foi liberada (ex.: pelo S.O.S); senão centraliza na Praça da Sé.
- Feedback comunitário (MAP-04): no cartão do distrito, "Enviar feedback" abre uma folha com a categoria (Iluminação, Assalto, Assédio, Pouco movimento, Falta de policiamento, Outro) e um texto opcional de até 500 caracteres (obrigatório em "Outro"). O relato fica pendente de análise e não muda o score nem a cor do mapa.
- Privacidade (Regra 08): "Privacidade e dados" no Perfil (também deslogado) explica o que é guardado, a retenção de 180 dias e a anonimização; o diálogo "Por que a localização?" do S.O.S leva a essa tela. Logado, "Excluir conta" pede duas confirmações (aviso + senha); depois a sessão é encerrada, o token apagado e o Login abre com "Conta excluída.".
- Contatos: tocar no contato no Perfil abre "Editar contato" (nome, telefone e "Remover contato", com confirmação). Trocar o telefone de quem já aceitou ou recusou pede confirmação, porque o consentimento é pedido de novo e o contato não recebe alertas até aceitar.
- Configurações de perfil: salva nome e telefone (E.164) na conta, enviando só o que mudou. O e-mail aparece só para leitura. "Trocar senha" exige a senha atual, a nova (mín. 8) e a confirmação; senha atual errada mostra "Senha atual incorreta.".

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
│   ├── auth/  contacts/  map/
│   └── profile/  settings/  sos/
└── shared/widgets/           # componentes visuais reutilizáveis
test/                         # espelha a estrutura de lib/ (+ test/helpers)
plans/                        # planos de implementação/refatoração
```

## Contrato esperado do backend (rascunho)

| Método | Rota | Corpo / parâmetros | Resposta |
|--------|------|--------------------|----------|
| `POST` | `/alerts` | `{ lat, lng, message, userId }` | — |
| `POST` | `/auth/login` | `{ email, password }` | objeto do usuário/token |

## Aviso

O Alerta Seguro **não substitui a polícia**. Em emergências, ligue **190**.
