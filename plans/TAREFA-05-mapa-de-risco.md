# TAREFA-05: Mapa de risco real (`/mapa/regioes`)

**Goal:** trocar o mapa de calor falso por círculos de distritos vindos de `GET /mapa/regioes`.
**Source:** `backend/plans/what-needs-to-be-done.md` (Tarefa 5) + respostas da Yume.
**Feature flag:** none — app acadêmico sem LaunchDarkly.

## Decisões
- Logado: círculos com `centroide`, `raio_metros` e `cor_hex` da API. Deslogado: mapa sem círculos + aviso "Entre na sua conta para ver as regiões de risco" (a rota exige token).
- Centro: posição atual só se `checkAccess()` já for `granted`; o mapa nunca pede permissão (MAPM-03). Senão, Praça da Sé.
- Consulta com `raio=10000` (máximo do backend). Recarrega sozinho quando a câmera para (`onCameraIdle`), com espera de 500 ms e só se o centro andou mais de 2 km desde a última consulta. Resposta antiga é descartada (contador de geração, como o `SosController`).
- Tocar num círculo abre um cartão com nome do distrito, score e faixa (Baixo < 34, Médio 34–66, Alto ≥ 67).
- Legenda verde/amarelo/vermelho no cartão do topo.
- Botão "Registrar ocorrência" fica como está; a Tarefa 6 troca pelo feedback por região.

## Out of scope
- Feedback por região (Tarefa 6).
- Restrições da chave do Maps no Google Cloud (MAPM-01): só documentar no README.

## ✅ Step 1: Modelo e repositório de regiões
- **Files**: novo `lib/data/models/risk_region.dart` (`RiskRegion` com `id`, `name`, `center` `GeoPoint`, `score`, `color` (`Color` de `cor_hex`), `radiusMeters`, getter `band`), novo `lib/data/repositories/region_repository.dart` (`RegionRepository.fetchNearby(lat, lng, {radiusMeters = 10000})`, `HttpRegionRepository`, `FakeRegionRepository` com alguns distritos de SP em volta do ponto), `repositories.dart` ganha `regions`.
- **Test (red)**: `test/data/repositories/region_repository_test.dart` (unit) — GET `/mapa/regioes` com `latitude/longitude/raio`, parse de `#RRGGBB`, 401 → `UnauthorizedException`, outras falhas → `RepositoryException`. `models_test`: faixas 33/34/66/67. Mirror `alert_repository_test.dart`.
- **Implement (green)**: Dio + `RepositoryException.fromDio`, como `HttpAlertRepository`. Cor inválida → `FormatException`.
- **Refactor**: tirar `fetchNearby` do `OccurrenceRepository` (rota inexistente) e do teste; `Occurrence` só fica se ainda for usado pelo report.
- **Demo**: teste verde.
- **Depends on**: none

## ✅ Step 2: `MapController` carrega regiões com regras de login, centro e recarga
- **Files**: novo `lib/features/map/map_controller.dart` (substitui o carregamento do `OccurrencesController`, que fica só com `report`), `app.dart`.
- **Test (red)**: `test/features/map/map_controller_test.dart` — deslogado não chama a API e expõe `needsLogin`; com permissão já dada centraliza na posição, sem permissão usa Praça da Sé e `requests == 0`; `cameraIdle` perto (< 2 km) não recarrega, longe recarrega após 500 ms; resposta antiga não sobrescreve a nova; logout limpa as regiões; login recarrega. Mirror `sos_controller_test.dart`.
- **Implement (green)**: `ChangeNotifier` com `regions`, `loading`, `error`, `selected`, `select(id)`; ouve `Session`.
- **Refactor**: n/a
- **Demo**: teste verde.
- **Depends on**: Step 1

## ✅ Step 3: Tela do mapa com círculos, legenda, aviso e cartão da região
- **Files**: `lib/features/map/map_screen.dart`, `widgets/heat_circles.dart` → `widgets/region_circles.dart`, novo `widgets/region_card.dart`.
- **Test (red)**: `test/features/map/map_screen_test.dart` (widget) — deslogado mostra o aviso; logado gera um `Circle` por região com cor e raio da API (ler `GoogleMap.circles`); falha mostra a mensagem com "Tentar de novo"; selecionar região mostra nome, score e faixa; `myLocationEnabled` só com permissão.
- **Implement (green)**: `onCameraIdle` → `controller.cameraIdle(pos)`; `Circle.consumeTapEvents` + `onTap` → `select`.
- **Refactor**: apagar `heat_circles.dart`.
- **Demo**: `flutter run` em modo demo: distritos coloridos, tocar mostra o cartão; arrastar o mapa carrega novas regiões.
- **Depends on**: Step 2

## ✅ Step 4: Docs
- **Files**: `README.md` (tabela de rotas, MAPM-01/MAPM-03), `backend/plans/what-needs-to-be-done.md` (Tarefa 5 frontend).
- **Demo**: `dart format`, `flutter analyze`, `flutter test` verdes.
- **Depends on**: Step 3

## Open questions / assumptions
- `GoogleMap` em widget test não renderiza o mapa nativo; os testes leem as props do widget (`circles`, `myLocationEnabled`).
- A API devolve no máximo 50 regiões; com 10 km isso cobre a maior parte da cidade.
