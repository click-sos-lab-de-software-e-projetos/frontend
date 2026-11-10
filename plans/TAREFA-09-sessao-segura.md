# TAREFA-09: Sessão segura (Regra 09 · SOSM-01)

**Goal:** guardar o token no armazenamento seguro do aparelho e restaurar a sessão ao abrir o app.
**Source:** `backend/plans/what-needs-to-be-done.md`, Tarefa 9 (frontend) + respostas de 10/11.
**Feature flag:** none — o projeto não usa LaunchDarkly.

## Decisões
- Restauração otimista: `main` lê o token antes do `runApp` e já inicia a `Session`. O SOS funciona na hora, mesmo com o Render dormindo.
- `/auth/me` roda em segundo plano para preencher o perfil.
- Só 401 apaga o token (o `AuthInterceptor` já limpa a `Session`; a limpeza passa a apagar o armazenamento). Falha de rede ou timeout mantém o token.
- Modo demo (`USE_FAKE_API=true`) usa armazenamento em memória: o token falso nunca vai para o aparelho.

## Out of scope
- Refresh token (o backend não tem; o token vale 24 h).
- Tela de carregamento ou login obrigatório: o login continua na aba Perfil.
- Ler o `exp` do JWT localmente.

## Step 1: Session grava, apaga e restaura o token
- **Files**: `lib/core/network/token_store.dart` (novo), `lib/core/network/session.dart`, `test/core/network/session_test.dart` (novo).
- **Test (red)**: unit — `start` grava o token no store; `clear` apaga; `restore` com token salvo deixa a sessão ativa; `restore` sem token mantém inativa. Usa `MemoryTokenStore`. Mirror `test/features/profile/profile_controller_test.dart`.
- **Implement (green)**: interface `TokenStore` (`read`, `write`, `delete`) + `MemoryTokenStore`. `Session({TokenStore? store})`, padrão em memória; `start`/`clear` continuam síncronos e disparam a escrita sem bloquear; novo `Future<void> restore()`.
- **Refactor**: n/a.
- **Demo**: testes verdes.
- **Depends on**: none.

## Step 2: Armazenamento seguro no app real
- **Files**: `pubspec.yaml` (`flutter_secure_storage`), `token_store.dart` (`SecureTokenStore`), `lib/app/dependencies.dart`, `lib/main.dart`, `test/core/network/token_store_test.dart` (novo).
- **Test (red)**: unit — `SecureTokenStore` grava, lê e apaga usando `FlutterSecureStorage.setMockInitialValues`.
- **Implement (green)**: `AppDependencies.fromEnv` cria a `Session` com `SecureTokenStore` quando a API é real; o demo fica em memória. `main` chama `WidgetsFlutterBinding.ensureInitialized()` e `await dependencies.session.restore()` antes do `runApp`.
- **Refactor**: n/a.
- **Demo**: fazer login, fechar o app e abrir: continua logada.
- **Depends on**: Step 1.

## Step 3: Perfil carregado ao abrir com sessão restaurada
- **Files**: `lib/features/profile/profile_controller.dart`, `lib/app/app.dart`, `test/features/profile/profile_controller_test.dart`.
- **Test (red)**: unit — com sessão ativa, `load` busca `/auth/me` e troca o perfil; com `UnauthorizedException`, o perfil fica vazio e a exceção não escapa; com erro de rede, mantém a sessão.
- **Implement (green)**: `ProfileController` recebe o `AuthRepository` opcional e ganha `load()`. No `AlertaApp`, o provider chama `load()` quando a sessão já está ativa na criação.
- **Refactor**: n/a.
- **Demo**: abrir o app logada mostra nome e e-mail na aba Perfil.
- **Depends on**: Step 2.

## Step 4: Documentação
- **Files**: `README.md` (stack e "sessão salva no aparelho"), `backend/plans/what-needs-to-be-done.md` (marcar os itens da Tarefa 9).
- **Test**: n/a.
- **Depends on**: Step 3.

## Open questions / assumptions
- Na web, `flutter_secure_storage` usa WebCrypto + localStorage: aceitável para o MVP.
- Android: a versão atual do `flutter_secure_storage` exige `minSdk` ≥ 23; conferir `android/app/build.gradle*` ao adicionar.
