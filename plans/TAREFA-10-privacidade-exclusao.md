# TAREFA-10: Privacidade e exclusão de conta

**Goal:** Tela "Privacidade e dados" (retenção de 180 dias e anonimização) acessível pelo Perfil, com "Excluir conta" (confirmação dupla + senha) que apaga a conta, encerra a sessão e abre o Login.
**Source:** `backend/plans/what-needs-to-be-done.md` (Tarefa 10, Regra 08 · YUME-03) + respostas da Yume.
**Feature flag:** none — app de faculdade, sem LaunchDarkly.

## Decisões
- Botão "Privacidade e dados" no Perfil, visível também deslogado.
- "Excluir conta" no fim da tela de privacidade, só logado.
- Confirmação dupla: (1) diálogo com o que será apagado; (2) diálogo pedindo a senha (o backend exige).
- Depois: sessão encerrada (token apagado), volta à primeira tela e abre o Login com "Conta excluída.".
- LGPD da localização: o diálogo "Por que a localização?" já cumpre; ganha "Ver política de privacidade".

## Out of scope
- Backend (`DELETE /auth/me` com `{senha}` já existe: 400 senha incorreta, 409 alerta em envio).
- Exportar dados; agendar a rotina de anonimização.

## Step 1 ✅: Repositório exclui a conta
- **Files**: `lib/data/repositories/auth_repository.dart`, `test/data/repositories/auth_repository_test.dart`
- **Test (red)**: (unit) `deleteAccount(password)` faz DELETE `/auth/me` com `{senha}`; 400 → "Senha incorreta."; 409 usa o `detail` do backend. Fake: conta cadastrada confere a senha e é apagada (pode ser cadastrada de novo); sem login → `UnauthorizedException`. Mirror `changePassword`.
- **Implement (green)**: método na interface, Http e Fake.
- **Refactor**: n/a
- **Demo**: testes passando.
- **Depends on**: none

## Step 2 ✅: AuthController.deleteAccount encerra a sessão
- **Files**: `lib/features/auth/auth_controller.dart`, `test/features/auth/auth_controller_test.dart`
- **Test (red)**: (unit) sucesso chama o repositório e limpa a sessão; falha relança e mantém a sessão. Mirror "logout clears the session".
- **Implement (green)**: `deleteAccount(password)` via `_busy`, `_session.clear()` só após sucesso (o `Session.clear` já apaga o token salvo — Tarefa 9).
- **Refactor**: n/a
- **Demo**: testes passando.
- **Depends on**: Step 1

## Step 3 ✅: Tela de privacidade
- **Files**: novo `lib/features/profile/privacy_screen.dart`, `profile_screen.dart` (botão), novo `test/features/profile/privacy_screen_test.dart`
- **Test (red)**: (widget) deslogado, o Perfil abre a tela com o texto de retenção (180 dias, anonimização, o que é apagado ao excluir) e sem "Excluir conta"; logado mostra "Excluir conta".
- **Implement (green)**: `PrivacyScreen` com seções curtas (o que guardamos, por quanto tempo, quem vê, exclusão); textos como `static const` para os testes.
- **Refactor**: n/a
- **Demo**: modo demo — Perfil > Privacidade e dados.
- **Depends on**: none

## Step 4 ✅: Excluir conta com confirmação dupla
- **Files**: `privacy_screen.dart`, `privacy_screen_test.dart`
- **Test (red)**: (widget) Cancelar no 1º diálogo não chama a API; senha errada mostra "Senha incorreta." no 2º diálogo e mantém logado; senha certa exclui, fica deslogado, abre o Login e mostra "Conta excluída.".
- **Implement (green)**: diálogo 1 (Cancelar / Continuar); diálogo 2 `StatefulWidget` com campo de senha, erro inline e botão "Excluir" travado enquanto envia; no sucesso `popUntil(isFirst)`, push `LoginScreen`, snackbar.
- **Refactor**: n/a
- **Demo**: modo demo — cadastrar conta, excluir com a senha, ver o Login; o mesmo e-mail pode ser cadastrado de novo.
- **Depends on**: Steps 2–3

## Step 5 ✅: Link na explicação da localização
- **Files**: `lib/features/sos/sos_screen.dart`, `test/features/sos/sos_screen_test.dart`
- **Test (red)**: (widget) o diálogo "Por que a localização?" tem "Ver política de privacidade", que abre `PrivacyScreen`.
- **Implement (green)**: terceiro botão no diálogo; fecha o diálogo sem pedir permissão e abre a tela.
- **Refactor**: n/a
- **Demo**: tocar no SOS sem permissão e abrir a política.
- **Depends on**: Step 3

## Step 6 ✅: Docs
- README e checklist do backend (Tarefa 10 frontend).
- **Depends on**: Steps 1–5

## Open questions / assumptions
- Conta demo não cadastrada no fake aceita qualquer senha (como o login demo).
- 409 (S.O.S em envio) aparece no 2º diálogo, com a conta mantida.
