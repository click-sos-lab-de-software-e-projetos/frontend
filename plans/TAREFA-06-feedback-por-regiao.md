# TAREFA-06: Feedback comunitário por região

**Goal:** trocar "Registro de ocorrência" por um feedback ligado ao distrito tocado no mapa (`POST /mapa/regioes/{id}/feedbacks`).
**Source:** `backend/plans/what-needs-to-be-done.md` (Tarefa 6) + respostas da Yume.
**Feature flag:** none — app acadêmico sem LaunchDarkly.

## Decisões
- Entrada: botão "Enviar feedback" no `RegionCard`. O botão flutuante "Registrar ocorrência" sai.
- Formulário em bottom sheet: nome do distrito, chips das 6 categorias (Iluminação, Assalto, Assédio, Pouco movimento, Falta de policiamento, Outro), texto opcional de até 500 caracteres (obrigatório em "Outro"), aviso fixo "Seu relato fica pendente de análise e não muda o mapa.", botão "Enviar" desabilitado sem categoria ou enquanto envia.
- Sucesso: fecha a folha e mostra o snackbar "Obrigado! Seu relato fica pendente de análise e não muda o mapa." O mapa não muda (sem recarga, sem mexer em score ou cor).
- Erro: a folha continua aberta com a mensagem da API (404 → "Região não encontrada."; 422 → "Confira a categoria e o texto (até 500 caracteres)."; 401 → sessão expirada, já tratada pelo interceptor).
- Apagar: `features/occurrence/`, `OccurrencesController`, `OccurrenceRepository`, `OccurrenceReport` e os testes deles; tirar `occurrences` de `Repositories`/`TestDeps`/`app.dart`; tirar `/occurrences` do README.

## Out of scope
- Listar ou moderar feedbacks.
- Fotos.

## ✅ Step 1: Modelo e repositório de feedback
- **Files**: novo `lib/data/models/region_feedback.dart` (enum `FeedbackCategory` com o valor da API e o rótulo; `RegionFeedback(category, text)` com `toJson` sem `texto` quando vazio; validação "Outro exige texto" e limite de 500), `lib/data/repositories/region_repository.dart` ganha `sendFeedback(regionId, feedback)` em `Http`/`Fake` (o fake guarda os envios).
- **Test (red)**: `test/data/repositories/region_repository_test.dart` — POST em `/mapa/regioes/{id codificado}/feedbacks` com `{"categoria": "ILUMINACAO", "texto": ...}`; texto vazio não vai no corpo; 404/422 viram mensagens claras. `models_test`: "Outro" sem texto é inválido; 501 caracteres é inválido. Mirror os testes de `updateSosMessage`.
- **Implement (green)**: Dio + `RepositoryException.fromDio`, como `HttpAuthRepository.updateSosMessage`.
- **Refactor**: n/a
- **Demo**: teste verde.
- **Depends on**: none

## ✅ Step 2: Folha de feedback
- **Files**: novo `lib/features/map/widgets/feedback_sheet.dart` (`showFeedbackSheet(context, region)` → `Future<bool>` enviado ou não).
- **Test (red)**: `test/features/map/feedback_sheet_test.dart` (widget) — mostra o distrito e o aviso de pendência; "Enviar" desabilitado sem categoria; "Outro" sem texto mostra o erro e não envia; enviar Iluminação com texto chama o repositório com a região certa e fecha; falha mantém a folha aberta com a mensagem.
- **Implement (green)**: `StatefulWidget` com `ChoiceChip`s e `TextField(maxLength: 500)`, lendo `RegionRepository` do Provider (adicionar `Provider<RegionRepository>` em `app.dart`; o `MapController` passa a ler dele).
- **Refactor**: n/a
- **Demo**: teste verde.
- **Depends on**: Step 1

## ✅ Step 3: Botão no cartão do distrito, sem mudar o mapa; remover ocorrência
- **Files**: `widgets/region_card.dart` (botão "Enviar feedback"), `map_screen.dart` (abre a folha; snackbar de obrigado; sem FAB), arquivos de ocorrência apagados, `repositories.dart`, `test/helpers/test_app.dart`, `README.md`.
- **Test (red)**: `test/features/map/map_screen_test.dart` — tocar num distrito → "Enviar feedback" → enviar mostra o snackbar; as regiões e os círculos continuam iguais e não há nova chamada a `fetchNearby`; não existe mais "Registrar ocorrência".
- **Implement (green)**: como acima.
- **Refactor**: apagar o código de ocorrência e os testes dele.
- **Demo**: `flutter run` em modo demo: tocar num distrito, enviar feedback e ver o snackbar com o mapa igual.
- **Depends on**: Step 2

## ✅ Step 4: Docs e CI
- **Files**: `README.md` (rota de feedback; remover `/occurrences`), `backend/plans/what-needs-to-be-done.md` (Tarefa 6 frontend).
- **Demo**: `dart format`, `flutter analyze`, `flutter test` verdes.
- **Depends on**: Step 3

## Open questions / assumptions
- `lib/screens/` (código legado sem uso) não é tocado.
