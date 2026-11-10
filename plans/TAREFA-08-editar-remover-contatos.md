# TAREFA-08: Editar e remover contatos

**Goal:** No Perfil, tocar num contato abre "Editar contato" (nome, telefone, "Remover contato"); trocar o telefone de quem já respondeu ao consentimento pede confirmação.
**Source:** `backend/plans/what-needs-to-be-done.md` (Tarefa 8) + respostas da Yume.
**Feature flag:** none — app de faculdade, sem LaunchDarkly.

## Decisões
- Tocar no cartão do contato (Perfil) abre a tela de edição; "Remover contato" fica no fim dela.
- Telefone novo + contato com consentimento aceito **ou** recusado → diálogo "O consentimento será pedido de novo; o contato não recebe alertas até aceitar." (Cancelar / Salvar). Pendente → salva direto.
- Remover → diálogo "Remover {nome}? Ele deixa de receber seus alertas." (Cancelar / Remover).
- Não abre o WhatsApp sozinho depois da troca; o botão de pedido de consentimento do Perfil já cobre.

## Out of scope
- Backend (rotas `PATCH`/`DELETE /contatos/{id}` já existem e já limpam o consentimento).
- Ativar/desativar alerta (fica em Configurar SOS).

## Step 1 ✅: Fake limpa o consentimento ao trocar telefone
- **Files**: `lib/data/repositories/contact_repository.dart`, `test/data/repositories/contact_repository_test.dart`
- **Test (red)**: (unit) `FakeContactRepository.update` com telefone diferente devolve contato sem `consentedAt`/`refusedAt`; só nome mantém. Mirror grupo `FakeContactRepository`.
- **Implement (green)**: no fake, se `phone` mudou, recria o `Contact` sem datas (como o backend). `HttpContactRepository.update` já existe.
- **Refactor**: n/a
- **Demo**: teste passando; modo demo reflete o comportamento real.
- **Depends on**: none

## Step 2 ✅: ContactsController.edit envia só o que mudou
- **Files**: `lib/features/contacts/contacts_controller.dart`, `test/features/contacts/contacts_controller_test.dart`
- **Test (red)**: (unit) `edit(id, name:, phone:)` apara, manda só campos alterados, troca o contato pela resposta e notifica; sem mudança não chama a API. Mirror `setAlertEnabled`/`add`.
- **Implement (green)**: compara com o contato atual, chama `_repository.update`, `_replace`.
- **Refactor**: n/a
- **Demo**: testes passando.
- **Depends on**: Step 1

## Step 3 ✅: Tela de edição + aviso de novo consentimento
- **Files**: `lib/features/contacts/add_contact_screen.dart` (ganha `contact` opcional → modo edição: título "Editar contato", campos preenchidos, botão "Salvar"), `lib/features/profile/profile_screen.dart` (cartão com `onTap`), `test/features/contacts/add_contact_screen_test.dart`
- **Test (red)**: (widget) tocar no contato do Perfil abre a edição preenchida; mudar o nome salva e volta com o nome novo; telefone novo de contato que aceitou mostra o diálogo — Cancelar não salva, Salvar salva e o status vira "Aguardando consentimento"; contato pendente com telefone novo salva sem diálogo.
- **Implement (green)**: `AddContactScreen({this.contact})`; `_submit` chama `add` ou `edit`; `static const reconsentWarning`; diálogo só quando `toE164(phone) != contact.phone && consentStatus != pending`.
- **Refactor**: extrair `_confirm(context, title, body, action)` se o Step 4 reutilizar.
- **Demo**: modo demo — Perfil > toque em "Contato Exemplo" > troque o telefone > confirme > status volta a pendente.
- **Depends on**: Step 2

## Step 4 ✅: Remover com confirmação
- **Files**: `add_contact_screen.dart`, `test/features/contacts/add_contact_screen_test.dart`
- **Test (red)**: (widget) "Remover contato" abre diálogo; Cancelar mantém; Remover apaga no servidor, fecha a tela e some do Perfil; erro do repositório mostra snackbar e mantém a tela.
- **Implement (green)**: botão vermelho só no modo edição; usa `ContactsController.remove`.
- **Refactor**: n/a
- **Demo**: modo demo — remover um contato e ver a lista diminuir.
- **Depends on**: Step 3

## Step 5 ✅: Docs
- README (tela 8 e rota `PATCH`/`DELETE /contatos/{id}`) e checklist do backend (Tarefa 8, inclusive o item "Nada novo" do backend).
- **Depends on**: Steps 3–4

## Open questions / assumptions
- O cartão inteiro é tocável; os ícones de WhatsApp/pedido continuam com suas ações.
- Contato que recusou também recebe o aviso (o backend apaga a recusa).
