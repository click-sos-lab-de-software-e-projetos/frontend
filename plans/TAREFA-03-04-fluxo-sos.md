# TAREFA-03-04: Fluxo S.O.S com status do envio (Regra 02 · Regra 04 · SOSM-03 a SOSM-05)

**Goal:** disparar o S.O.S. com um toque (cancelável por 5 s), tratar a localização com clareza e acompanhar o envio pelo servidor (`PENDENTE` → `ENVIADO`/`ERRO`), com WhatsApp só como alternativa.
**Source:** `backend/plans/what-needs-to-be-done.md`, Tarefas 2, 3 e 4 (frontend) + respostas de 10/11. Inclui 3 passos de backend (B1–B3).
**Feature flag:** none — o projeto não usa LaunchDarkly.

## Decisões
- Fluxo: **um toque** no botão → (só se a permissão nunca foi pedida) explicação da localização → contagem de **5 s** com "Cancelar" → localização → `POST /sos/alertas` → painel de status. Decidido em 10/11: sem segurar 3 s e sem a pessoa precisar escrever.
- A mensagem é configurada em **Ajustes**, nunca no botão, e fica **salva no backend por pessoa** (`usuarios.mensagem_sos`, até 255). `""` no `PATCH /auth/me` volta para a padrão.
- O app nunca envia `mensagem` no `POST /sos/alertas`: o backend usa a mensagem salva da pessoa e, sem ela, a padrão da Regra 02. O alerta guarda uma cópia da mensagem usada (mudar Ajustes depois não altera alertas antigos).
- "Alerta Silencioso" continua só no app (fora do escopo).
- Aviso de privacidade fixo na tela de Emergência, abaixo do botão: "Sua localização será enviada só aos seus contatos ativos que aceitaram. O alerta fica guardado por 180 dias e depois é anonimizado."
- Localização negada, negada para sempre ou GPS desligado: mostrar o motivo, botão para abrir as configurações e opção de enviar só pelo WhatsApp, sem localização. Sem localização não há `POST` (o backend exige coordenadas).
- Status: `GET /sos/alertas/{id}` a cada 3 s, até `ENVIADO` ou `ERRO`. Depois de 2 min sem resposta final, para e mostra "ainda enviando".
- WhatsApp (`wa.me`) vira botão secundário no painel de status (SOSM-05). Texto: a mensagem salva ou, vazia, "[Alerta Seguro] Preciso de ajuda urgente!", + link do mapa.

## Out of scope
- `GET /sos/alertas` (histórico) — opcional no backend, não existe.
- Cancelar um alerta já enviado.
- Persistir o último alerta entre aberturas do app.

## ✅ Step B1 (backend): coluna `usuarios.mensagem_sos`
- **Files**: `backend/migrations/versions/0011_mensagem_sos_usuario.py` (novo), `backend/src/app/db/models.py`, `backend/tests/integracao/test_migracoes_*.py`, `test_modelos_orm.py`.
- **Test (red)**: integração — a coluna existe, é opcional e tem limite `LIMITE_MENSAGEM_SOS`; upgrade/downgrade. Mirror `test_migracoes_alertas.py`.
- **Implement (green)**: migração 0011 + campo `mensagem_sos` em `Usuario`.
- **Demo**: `alembic upgrade head` no banco de teste.
- **Depends on**: none.

## ✅ Step B2 (backend): ler e salvar no perfil
- **Files**: `backend/src/app/schemas/auth.py` (`UsuarioResposta.mensagem_sos`, `AtualizarPerfilRequisicao.mensagem_sos`), `backend/src/app/services/auth.py`, `tests/test_schemas_auth.py`, `tests/integracao/test_api_auth.py`.
- **Test (red)**: `GET /auth/me` traz `mensagem_sos` (null por padrão); `PATCH` salva o texto aparado; `""` (ou só espaços) grava NULL; mais de 255 → 422; `null` → 422 (como os outros campos).
- **Implement (green)**: reusar o tipo `MensagemLivre` de `schemas/sos.py`; o serviço `atualizar_perfil` converte vazio em NULL.
- **Demo**: `PATCH /auth/me {"mensagem_sos": "..."}` no Swagger.
- **Depends on**: B1.

## ✅ Step B3 (backend): alerta usa a mensagem salva
- **Files**: `backend/src/app/services/alertas.py`, `tests/integracao/test_api_sos*.py`.
- **Test (red)**: `POST /sos/alertas` sem `mensagem` grava a `mensagem_sos` da pessoa no alerta; sem as duas, grava NULL (worker usa a padrão); com `mensagem` no corpo, ela vence.
- **Implement (green)**: em `criar_alerta`, `dados.mensagem or usuario.mensagem_sos or None`.
- **Demo**: o WhatsApp do contato recebe a mensagem configurada.
- **Depends on**: B2. Commit e push do backend aqui; README cita a 0011.

## ✅ Step 1: Repositório devolve o id e consulta o status
- **Files**: `lib/data/repositories/alert_repository.dart`, `lib/data/models/sos_alert.dart` (novo `AlertStatus` com `pending/sent/failed` e `attempts`), `test/data/repositories/alert_repository_test.dart`, `test/data/models/models_test.dart`.
- **Test (red)**: unit — `send` devolve o `id` da resposta 201; `status(id)` faz `GET /sos/alertas/{id}` e converte `status_envio`/`tentativas`; 404 vira `RepositoryException`; resposta sem `id` vira erro. Mirror os testes com `StubDioAdapter` existentes.
- **Implement (green)**: `send` retorna `Future<String>`; novo `status(String id)`. `FakeAlertRepository` gera ids e devolve status programáveis.
- **Refactor**: n/a.
- **Demo**: testes verdes.
- **Depends on**: none.

## ✅ Step 2: SosController envia e acompanha o status
- **Files**: `lib/features/sos/sos_controller.dart`, `lib/app/app.dart`, `test/features/sos/sos_controller_test.dart`.
- **Test (red)**: unit — `start()` publica `countdown` (5 → 0) e depois `sending` → `pending` → `sent`; `cancel()` durante a contagem não chama o servidor; `failed` encerra; sem resposta final dentro do limite vira `stillSending`; erro do `POST` (ex.: sem contato com consentimento) vira `error` com a mensagem do backend; nunca envia `mensagem`. Contagem, intervalo e limite injetáveis para o teste ser rápido.
- **Implement (green)**: `SosController` vira `ChangeNotifier` com um estado imutável (fase, id, mensagem de erro); polling com `Timer`, cancelado em `dispose` e ao recomeçar. `whatsAppText(position?)` (mensagem salva no perfil ou texto padrão local) e `targets` (contatos ativos) para o botão secundário. Deixa de depender do `SosSettingsController`; o texto do WhatsApp vem do perfil.
- **Refactor**: remover `SosOutcome`.
- **Demo**: testes verdes.
- **Depends on**: Step 1.

## ✅ Step 3: Acesso à localização com motivo
- **Files**: `lib/core/services/location_service.dart`, `test/core/services/location_service_test.dart` (novo, só o fake).
- **Test (red)**: unit — `FakeLocationService` informa o acesso (`granted`, `notAsked`, `denied`, `deniedForever`, `serviceOff`), troca para `granted` em `requestAccess` quando configurado e registra `openSettings`.
- **Implement (green)**: novos `checkAccess`, `requestAccess`, `openSettings` na interface. `GeolocatorLocationService` mapeia `Geolocator.checkPermission`, `requestPermission`, `isLocationServiceEnabled`, `openAppSettings`/`openLocationSettings`. `currentPosition` continua igual (o mapa usa).
- **Refactor**: n/a.
- **Demo**: testes verdes.
- **Depends on**: none.

## ✅ Step 4: Um toque dispara com contagem cancelável
- **Files**: `lib/features/sos/widgets/sos_button.dart`, `lib/features/sos/sos_screen.dart`, `test/features/sos/sos_button_test.dart`, `test/features/sos/sos_screen_test.dart`.
- **Test (red)**: widget — um toque mostra "Enviando em 5…" e "Cancelar"; "Cancelar" não chama o servidor; deixar a contagem acabar envia o alerta; o aviso de privacidade aparece na tela. `holdSos` vira `tapSos`.
- **Implement (green)**: `SosButton` troca o segurar 3 s por `onTap` (sem animação de progresso); a tela mostra a contagem a partir do estado do controller. Texto do card inferior muda para "Toque para enviar…".
- **Refactor**: remover o código de animação de segurar.
- **Demo**: um toque, 5 s, alerta enviado.
- **Depends on**: Steps 2 e 3.

## ✅ Step 5: Explicar e tratar a permissão de localização
- **Files**: `sos_screen.dart`, `test/features/sos/sos_screen_test.dart`.
- **Test (red)**: widget — `notAsked` mostra a explicação antes de pedir (antes da contagem); `denied`/`deniedForever`/`serviceOff` mostram o motivo certo, "Abrir configurações" chama `openSettings` e "Enviar só pelo WhatsApp" abre a lista de contatos sem link do mapa; nenhum caso chama o servidor.
- **Implement (green)**: textos por motivo no próprio `sos_screen.dart`; a lista de WhatsApp vira um widget reutilizável.
- **Refactor**: n/a.
- **Demo**: com permissão negada, o app explica e oferece o WhatsApp.
- **Depends on**: Step 4.

## ✅ Step 6: Painel de status com WhatsApp secundário
- **Files**: `sos_screen.dart`, `lib/features/sos/widgets/sos_status_card.dart` (novo), `test/features/sos/sos_screen_test.dart`.
- **Test (red)**: widget — após enviar mostra "Enviando…"; muda para "Alerta enviado aos contatos" / "Não foi possível enviar" / "Ainda enviando…" conforme o fake; erro do backend aparece no painel; "Enviar também pelo WhatsApp" abre a lista e `wa.me` com o texto e o link.
- **Implement (green)**: card abaixo do botão, observando o `SosController`.
- **Refactor**: tirar o `showModalBottomSheet` antigo.
- **Demo**: tocar → ver a contagem e o status mudar.
- **Depends on**: Step 5.

## ✅ Step 7: Ajustes lê e salva a mensagem no backend + docs
- **Files**: `lib/data/models/user_profile.dart` (`sosMessage`), `lib/data/repositories/auth_repository.dart` (`updateSosMessage` → `PATCH /auth/me`), `lib/features/profile/profile_controller.dart`, `lib/features/settings/settings_screen.dart`, remover `message`/`setMessage` de `sos_settings*.dart`, testes de modelos, repositório, Ajustes e controller; `README.md`; `backend/plans/what-needs-to-be-done.md`.
- **Test (red)**: unit — `fromApi` lê `mensagem_sos`; `updateSosMessage` envia `{"mensagem_sos": texto}` e devolve o perfil. Widget — Ajustes mostra a mensagem salva ou "Mensagem padrão do Alerta Seguro" quando vazia; o contador é `/255`; salvar chama a API e atualiza a prévia; erro mostra snackbar; deslogada não permite editar.
- **Implement (green)**: Ajustes passa a ler `ProfileController.profile.sosMessage` e salvar via `AuthRepository`; o perfil é atualizado com a resposta.
- **Refactor**: `SosSettings` fica só com `silentAlert`.
- **Demo**: mudar a mensagem em Ajustes, tocar o S.O.S. e o contato recebe o novo texto.
- **Depends on**: Step 6 e B3.

## Open questions / assumptions
- O texto de privacidade acima é proposta minha; não há texto aprovado no repositório.
- Sem link do mapa no WhatsApp quando não há localização: "(localização indisponível)".
- Neon precisa da migração 0011 (o deploy no Render roda `alembic upgrade head`).
- Logada sem contatos ativos: o `POST` responde erro (Regra 03) e o painel mostra a mensagem do backend.
