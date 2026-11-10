# TAREFA-07: Perfil editável via API

**Goal:** "Configurações de Perfil" salva nome e telefone com `PATCH /auth/me`, mostra o e-mail só para leitura e ganha "Trocar senha" (`POST /auth/me/senha`).
**Source:** `backend/plans/what-needs-to-be-done.md` (Tarefa 7) + respostas da Yume.
**Feature flag:** none — app de faculdade, sem LaunchDarkly.

## Decisões
- E-mail visível, desabilitado, com "O e-mail não pode ser alterado."
- Envia só os campos alterados; sem mudança, só fecha a tela.
- Telefone validado no app com `isValidPhone`/`toE164` (`lib/core/utils/phone.dart`), igual ao cadastro.
- Trocar senha: tela própria aberta pelo editar perfil; senha atual + nova (mín. 8) + confirmação; 400 → "Senha atual incorreta."

## Out of scope
- Fluxo de troca de e-mail.
- Encerrar outras sessões depois da troca de senha (backend mantém tokens válidos).
- `lib/screens/` (legado).

## Step 1 ✅: Repositório edita perfil e troca senha
- **Files**: `lib/data/repositories/auth_repository.dart`, `test/data/repositories/auth_repository_test.dart`
- **Test (red)**: (unit, Dio mockado) `updateProfile` faz PATCH `/auth/me` só com `nome_completo`/`telefone_pessoal` informados e devolve o perfil; 422 → "Confira o nome e o telefone (formato +55...)."; `changePassword` faz POST `/auth/me/senha` com `senha_atual`/`senha_nova`; 400 → `WrongPasswordException` ("Senha atual incorreta."). Fake: `updateProfile` persiste para a conta logada (visto por `me()`); `changePassword` rejeita senha atual errada em conta cadastrada. Mirror testes de `updateSosMessage`.
- **Implement (green)**: novos métodos na interface `AuthRepository`, `HttpAuthRepository` e `FakeAuthRepository` (fake guarda edições por conta, como `_messages`; atualiza a senha em `_accounts`). Nova `WrongPasswordException extends RepositoryException`, como `EmailInUseException`.
- **Refactor**: talvez unificar `_messages` num mapa de perfis editados no fake.
- **Demo**: testes passando.
- **Depends on**: none

## Step 2 ✅: ProfileController salva no servidor
- **Files**: `lib/features/profile/profile_controller.dart`, `test/features/profile/profile_controller_test.dart`
- **Test (red)**: (unit) `saveProfile(auth, name:, phone:)` aparar campos, envia só o que difere do perfil atual, troca o perfil pela resposta; sem diferença não chama a API. Remove o `update` local (e o teste "updates trimmed fields" vira o novo). Mirror `saveSosMessage`.
- **Implement (green)**: `saveProfile` compara com `_profile`, normaliza telefone com `toE164`, chama `auth.updateProfile`, `replace`. Apagar `update`.
- **Refactor**: n/a
- **Demo**: testes passando.
- **Depends on**: Step 1

## Step 3 ✅: Tela de edição usa a API
- **Files**: `lib/features/profile/edit_profile_screen.dart`, novo `test/features/profile/edit_profile_screen_test.dart`
- **Test (red)**: (widget, `pumpTestApp` com `TestDeps(loggedIn: true)`) e-mail aparece desabilitado com o aviso; telefone inválido mostra erro e não chama a API; salvar nome novo chama a API, fecha a tela e o Perfil mostra o nome novo; erro do repositório fica na tela e o botão volta a habilitar. Mirror `test/features/settings/settings_screen_test.dart`.
- **Implement (green)**: `Form` com validação de nome (não vazio) e telefone; botão "Salvar" desabilitado enquanto envia; `try/on RepositoryException` mostra mensagem; e-mail via `AppTextField` desabilitado (adicionar `enabled` se não existir).
- **Refactor**: n/a
- **Demo**: modo demo — editar nome, salvar, ver nome novo no Perfil; sair e entrar de novo mantém.
- **Depends on**: Step 2

## Step 4 ✅: Trocar senha
- **Files**: novo `lib/features/profile/change_password_screen.dart`, `edit_profile_screen.dart` (link "Trocar senha"), novo `test/features/profile/change_password_screen_test.dart`
- **Test (red)**: (widget) senha nova < 8 ou confirmação diferente mostram erro sem chamar a API; senha atual errada mostra "Senha atual incorreta." e a tela fica aberta; sucesso fecha e mostra snackbar "Senha alterada.".
- **Implement (green)**: tela com 3 campos obscuros, validação usando `RegisterScreen.minPasswordLength`, chama `auth.changePassword`.
- **Refactor**: n/a
- **Demo**: modo demo — cadastrar conta, trocar senha, sair, entrar com a nova.
- **Depends on**: Step 1

## Step 5 ✅: Docs
- README (tela 7 e rotas `/auth/me`, `/auth/me/senha`) e checklist do backend (Tarefa 7 frontend).
- **Depends on**: Steps 3–4

## Open questions / assumptions
- Nome: backend aceita até `LIMITE_NOME_COMPLETO`; o app só valida "não vazio" e deixa o 422 explicar o resto.
- Conta demo não cadastrada no fake aceita qualquer senha atual (como o login demo).
