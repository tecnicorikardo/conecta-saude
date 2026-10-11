# Registro de alterações e investigação de falhas — 11/10/2026

## Finalidade e limite desta rodada

Registrar o que foi alterado, como foi verificado e onde investigar uma eventual regressão. Este documento é o ponto de consulta para as correções discutidas em `report.md` e para os ajustes realizados anteriormente no mesmo dia.

A rodada inicial registrou a investigação sem alterar funcionalidades. Após a autorização para continuar, foram feitas as correções pontuais da seção 8, preservando os fluxos existentes. A publicação dessa nova rodada ainda não foi realizada.

Não constam senhas, tokens, conexões de banco ou chaves neste registro. O `report.md` original foi preservado.

## Versões publicadas

| Commit | Alteração | Componentes |
|---|---|---|
| `33b9e8d` | Agrupamento de cargos e aprovação de enfermeiro como NV3 | Aplicativo e API |
| `cec357b` | Cadastro em etapas, visibilidade dos campos e contraste de denúncias | Aplicativo |
| `8430a59` | Motivos aceitos nas denúncias e retorno de sucesso/erro | Aplicativo e API |
| `ef29bfb` | Acesso da Direção à edição de cargo e nível do colaborador | Aplicativo |
| `2fdde73` | Rolagem de grupos no desktop e inclusão da Direção Geral nos contatos | Aplicativo e API |
| `d7224da` | Vínculo de autenticação, limpeza local e arquivamento de rejeições | Aplicativo e API |

Aplicativo: `https://conecta-hospital.web.app`.

API: `https://conecta-saude-backende.onrender.com`.

Na última publicação, o Render confirmou o commit `d7224dad8b3c446dd7668a3992bb4bb36a8ce00e` como `Deploy succeeded|Live`. O arquivo publicado `main.dart.js` coincidiu por SHA-256 com o build local e `/health` respondeu HTTP 200. Esses resultados são registros da verificação realizada na entrega, não garantia permanente de disponibilidade.

## 1. Autenticação — `d7224da`

**Antes:** quando o UID Firebase não era encontrado, a API podia buscar pelo e-mail e substituir o UID associado ao cadastro.

**Depois:** tanto o middleware quanto a verificação de login buscam somente pelo UID Firebase já vinculado. Uma coincidência de e-mail não altera a identidade da conta. Contas inativas continuam bloqueadas; a verificação de login identifica rejeições registradas na auditoria.

**Arquivos alterados:**

- `backend/src/middleware/authenticate.ts`: função `authenticate`.
- `backend/src/modules/auth/auth.controller.ts`: função `verifyToken`.

**Se o login parar:** distinguir token inválido, usuário sem UID correspondente, cadastro pendente, rejeitado ou desativado. Conferir o UID da identidade Firebase e o UID do cadastro por um procedimento administrativo autorizado. Não recolocar o vínculo por e-mail como solução automática. A correção não migrou nem reescreveu UIDs existentes.

**Evidência:** testes de e-mail confirmado e não confirmado não vinculam conta; conta ativa vinculada mantém acesso. O WebSocket já consultava por UID e não foi alterado nesta etapa.

## 2. Histórico de conversas — `d7224da`

**Antes:** `clearConversation` apagava as mensagens da conversa no servidor para todos os participantes. O aplicativo também ocultava erros da solicitação. O marcador local era compartilhado por conversa, sem separar contas no mesmo dispositivo.

**Depois:** a API verifica participação e registra `limpar_conversa_local`, sem apagar mensagens. O aplicativo só grava a ocultação após a API responder com sucesso. O marcador fica separado por conta e conversa, neste dispositivo. A confirmação informa que as mensagens dos demais participantes são preservadas.

**Arquivos alterados:**

- `backend/src/modules/conversations/conversations.controller.ts`: `clearConversation`; verificação de participação também adicionada a `deleteConversation` antes de seus ramos individual/grupo.
- `app/lib/features/chat/data/conversation_history_store.dart`: persistência do marcador local.
- `app/lib/features/chat/presentation/providers/chat_provider.dart`: carregamento, filtragem e limpeza do histórico local.
- `app/lib/features/chat/presentation/pages/chat_page.dart`: texto da confirmação.

**Persistência:** a chave é `chat_cleared_at_<userId>:<conversationId>`. O mapa em memória segue a mesma separação. Marcadores antigos sem identificação da conta não são reaplicados; por isso, mensagens ocultadas pela implementação antiga podem voltar a aparecer. Nenhuma mensagem é recuperada se já tiver sido apagada anteriormente do servidor.

**Se a limpeza falhar:** verificar a resposta de `POST /api/conversations/:id/clear`, a participação do usuário e a disponibilidade do armazenamento local. Falha de API ou de gravação local deve ser apresentada como erro, sem confirmação falsa de sucesso.

**Se uma conversa não puder ser excluída:** verificar se a conta é participante. A exclusão de conversa individual por um participante continua desativando a conversa compartilhada; esta etapa corrigiu o acesso de terceiros, não implementou exclusão individual por pessoa.

**Evidência:** testes confirmam que limpeza não chama exclusão de mensagens, não participantes recebem recusa e o marcador de uma conta não afeta outra. No Chrome, o aviso foi aberto e cancelado; nenhuma limpeza real foi executada nessa validação.

## 3. Rejeição de cadastros — `d7224da`

**Antes:** o Firebase era apagado antes do cadastro no banco. A exclusão do cadastro podia falhar por vínculos de auditoria, deixando as duas fontes inconsistentes.

**Depois:** a rejeição conserva o cadastro inativo, limpa seu token de notificações e grava a decisão em transação. O registro `rejeitar_cadastro`, com `entidade=user` e o ID do cadastro em `entidadeId`, identifica a solicitação encerrada. O cadastro sai da lista de pendentes e a aprovação comum de uma solicitação já rejeitada é recusada. Depois da transação, a API tenta desativar a identidade Firebase e revogar suas sessões.

**Arquivos alterados:**

- `backend/src/modules/users/users.controller.ts`: `getPendingUsers`, `approveUser` e `rejectUser`.
- `backend/src/modules/auth/auth.controller.ts`: mensagem de cadastro rejeitado em `verifyToken`.

**Banco:** esta etapa não adicionou colunas, não executou migração e não apagou usuários ou auditorias. A decisão de rejeição depende do registro de auditoria existente. Esse registro deve ser preservado.

**Se o cadastro desaparecer da lista pendente:** conferir se há uma rejeição registrada para seu ID. Isso é o comportamento esperado após rejeitar.

**Se houver erro ao rejeitar:** verificar permissão do gestor, setor do cadastro e se ele ainda está pendente. Uma falha na transação impede a alteração posterior no Firebase. Se o Firebase falhar depois da transação, o cadastro continua inativo na API e o servidor registra o aviso de indisponibilidade do bloqueio adicional.

**Se for necessário reconsiderar uma rejeição:** isso exige procedimento administrativo próprio. Não há novo fluxo de reconsideração nesta etapa; uma reativação somente no banco pode deixar a identidade Firebase desativada. Não apagar auditoria para simular aprovação.

**Evidência:** testes abrangem preservação de registros, ordem banco/Firebase, indisponibilidade do Firebase, falha de banco, exclusão da fila pendente, recusa de aprovação após rejeição e restrição da Coordenação ao próprio centro.

## 4. Ajustes anteriores do mesmo dia

| Área | Arquivos principais | Ponto de investigação |
|---|---|---|
| Cargo e nível no cadastro (`33b9e8d`) | `app/lib/core/constants/hospital_roles.dart`; `backend/src/modules/auth/auth.controller.ts`; `backend/src/modules/users/users.controller.ts` | Enfermeiro é NV3; Coordenação é NV2; operacional é NV4. Cadastro público continua pendente de aprovação. Reativações preservam o nível administrativo. |
| Cadastro em etapas e contraste (`cec357b`) | `app/lib/features/auth/presentation/pages/register_page.dart`; `app/lib/features/reports/presentation/pages/reports_page.dart` | Verificar etapas, dependência hospital/setor/nível/cargo e cores nos modos claro/escuro. |
| Envio de denúncias (`8430a59`) | `backend/src/modules/reports/reports.routes.ts`; `app/lib/features/reports/data/repositories/reports_repository.dart`; `app/lib/features/reports/presentation/pages/reports_page.dart` | Erro 422: conferir motivo, título e descrição; o formulário deve exibir o motivo da falha e preservar o preenchimento. |
| Edição de colaborador pela Direção (`ef29bfb`) | `app/lib/features/employees/presentation/pages/employee_detail_page.dart`; `app/lib/features/employees/presentation/widgets/employee_form_dialog.dart` | Botão depende de nível 1 da conta logada; perfil deve atualizar após salvar. |
| Criação de grupos no computador (`2fdde73`) | `app/lib/features/chat/presentation/pages/new_conversation_page.dart`; `app/lib/features/chat/data/repositories/conversation_repository.dart`; `backend/src/modules/users/users.controller.ts`; `backend/src/modules/users/users.schema.ts` | Formulário inteiro rolável; busca de contatos com `contactable=true` inclui colegas e Direção Geral. O criador não é contado como pessoa a selecionar. |

Para obter a lista completa e exata de arquivos de cada entrega: `git show --stat <commit>`; para examinar uma alteração específica: `git show <commit> -- <arquivo>`.

## 5. Validação registrada da etapa de segurança

- Backend: 101 testes passaram, incluindo 14 casos em `backend/src/__tests__/security_account_history.test.ts`.
- Aprovação existente: testes em `backend/src/__tests__/registration_approval.test.ts` adaptados à transação e aprovados.
- Aplicativo: 3 testes passaram em `app/test/conversation_history_store_test.dart`.
- TypeScript: `npx tsc --noEmit` sem erros.
- Flutter: análise dos quatro arquivos envolvidos sem problemas; build web release concluído.
- Publicação: Firebase Hosting concluído e Render com commit correspondente em estado Live.

Os testes novos usaram mocks e armazenamento local simulado. Não criaram cadastros, rejeições ou mensagens em produção. O build mostrou o aviso preexistente de fonte Cupertino ausente.

## 6. Investigação e eventual recuperação

1. Registrar tela, conta/perfil usado, horário, ação e resposta da API, sem senhas ou tokens.
2. Identificar o commit e o arquivo pela tabela deste documento.
3. Comparar a versão publicada com a versão esperada; aplicativo e API são publicados separadamente.
4. Reproduzir com mocks ou ambiente isolado antes de modificar dados reais.
5. Preferir correção pontual acompanhada de teste que reproduza a falha.

Uma reversão de `d7224da` desfaz várias proteções ao mesmo tempo: pode restaurar vínculo por e-mail, exclusão global de histórico e rejeição com exclusão de registros. Por isso, não utilizar a reversão integral como resposta automática a um problema isolado. Qualquer recuperação deve registrar arquivos, commit, validação e publicações efetuadas.

Reverter código não recupera mensagens apagadas anteriormente, não limpa marcadores locais automaticamente e não reativa identidades já desativadas no Firebase. Não executar seed, exclusão de auditoria ou limpeza de usuários como procedimento de recuperação.

## 7. Revisão adicional do relatório — situação dos achados

| Achado | Conferência atual | Estado |
|---|---|---|
| Funcionários fictícios quando a API falha | `EmployeesRepositoryImpl.listUsers` retorna fallback em erros e respostas inesperadas | Corrigido e testado; ver seção 8 |
| Erro de emergência interpretado como ausência de alerta | `EmergencyRepositoryImpl.getActiveEmergency` retorna `null` no catch | Corrigido e testado; ver seção 8 |
| Ações de auditoria rotuladas incorretamente | `_parseAction` mapeia `criar_canal` para denúncia e usa usuário editado como default | Corrigido e testado; ver seção 9 |
| Protocolo de denúncia com ID curto | Tela usa `reportId.substring(0, 8)` sem proteger tamanho | Corrigido e testado; ver seção 8 |
| Cursor de mensagens por UUID | `listMessages` filtra `id < cursor` e ordena por `criadoEm` | Corrigido e testado; ver seção 9 |
| Rotas async sem encaminhamento de rejeições | Rotas de unidades, emergência e `/api/me` têm handlers sem `asyncHandler` | Corrigido e testado; ver seção 8 |
| Escrita de state após fechamento da tela de canal | `ChannelMessagesNotifier` contém awaits sem checagem posterior de mounted | Corrigido e testado; ver seção 9 |

Os demais achados do `report.md` permanecem como itens de revisão. As vulnerabilidades de dependências não foram recontadas nesta rodada. Nenhuma rotação de senha/chave, remoção de legado ou alteração de funcionalidades foi feita nesta rodada de documentação.

## 8. Continuação autorizada — respostas de erro e informações exibidas

**Publicação:** incluída na entrega final junto da seção 9; confirmação registrada na seção 10 após publicação.

### Colaboradores

- Arquivo: `app/lib/features/employees/data/repositories/employees_repository_impl.dart`, método `listUsers`.
- Removida a lista de funcionários fictícios que aparecia em falhas de API. Respostas inválidas, sessão expirada, falta de permissão e falha de conexão agora retornam erro ao fluxo existente. Listas vazias confirmadas continuam válidas.
- Diagnóstico: conferir resposta de `GET /api/users` e estado da sessão; não restabelecer dados de demonstração como solução de indisponibilidade.

### Emergência

- Arquivos: `app/lib/features/emergency/data/repositories/emergency_repository_impl.dart`, `app/lib/features/emergency/presentation/providers/emergency_provider.dart` e `app/lib/features/emergency/presentation/pages/emergency_page.dart`.
- Erro ao consultar alerta ativo deixa de virar ausência de alerta. Estado normal exige resposta válida. A tela informa status não confirmado, permite tentar novamente e mantém o último alerta recebido quando a atualização falha.
- Adicionadas verificações de tela ativa após requisições para evitar atualização depois de fechamento. Emissão, resolução e permissões foram preservadas.
- Diagnóstico: conferir `GET /api/emergency/active`; o aviso significa falta de confirmação, não resolução do alerta.

### Protocolo de denúncia

- Arquivo: `app/lib/features/reports/presentation/pages/reports_page.dart`.
- IDs menores que oito caracteres não quebram mais a apresentação de sucesso. IDs normais mantêm o formato anterior.
- Diagnóstico: conferir ID retornado no envio e apresentação do protocolo, sem reenviar uma denúncia já criada apenas para gerar protocolo.

### Respostas de erro nas rotas

- Arquivos: `backend/src/modules/units/units.routes.ts`, `backend/src/modules/emergency/emergency.routes.ts` e `backend/src/app.ts`.
- Aplicado o `asyncHandler` existente aos handlers de unidades, emergência e `/api/me`. Rejeições passam ao tratamento central de erros, evitando requisições aguardando timeout. Validação e permissões continuam nos controladores existentes.
- Diagnóstico: conferir status HTTP e log do servidor; erros 403, 404 e 422 continuam representando permissão, inexistência e validação.

### Verificação

- Backend: 111 testes aprovados e TypeScript sem erros. Dez testes novos exercitam rotas HTTP reais com dependências simuladas.
- Aplicativo: 18 testes aprovados para falhas de API, emergência, denúncias e preservação do histórico local. Análise Flutter dos arquivos envolvidos sem problemas.
- Novos testes: `backend/src/__tests__/async_error_routes.test.ts`, `app/test/api_failure_feedback_test.dart`, `app/test/emergency_status_feedback_test.dart`; ampliado `app/test/reports_submission_test.dart`.
- Build web release concluído; somente o aviso preexistente de fonte Cupertino ausente.
- Nenhum dado de produção foi criado, alterado ou excluído pelos testes. Não houve migração de banco, alteração de níveis ou de regras de aprovação nesta rodada.
- Auditoria, cursor de mensagens e atualização de estado em canais foram concluídos na seção 9.

## 9. Conclusão das três correções pendentes

- **Auditoria:** `app/lib/features/administration/data/repositories/audit_repository.dart` e `app/lib/features/administration/presentation/pages/audit_logs_page.dart`. Criação de canal agora tem categoria própria; ações de denúncia emitidas pela API são reconhecidas; login falho é identificado. Ações desconhecidas exibem OUTRA AÇÃO, preservando o nome original na descrição, em vez de afirmar edição de usuário. Nenhum log existente foi alterado. Teste: `app/test/audit_action_test.dart`.
- **Histórico de mensagens:** `backend/src/modules/messages/messages.controller.ts`. Cursor continua sendo o ID, mas sua data é consultada dentro da conversa autorizada. Paginação filtra por data anterior e desempata pelo ID; ordenação usa os mesmos campos. Preserva ordem de exibição, marcação de leitura e janela de 24 horas. Cursor inexistente ou de outra conversa retorna 400. Testes: `backend/src/__tests__/messages_pagination.test.ts`. Se houver falha, verificar cursor e conversa enviados; não voltar à comparação global de UUIDs.
- **Fechamento de canal:** `app/lib/features/channels/presentation/providers/channels_provider.dart`. Carregamento, atualização periódica e envio verificam se o notifier continua ativo depois de aguardar a API, incluindo erros. Fechar a tela não cancela uma mensagem que já foi enviada ao servidor; impede escrita em estado descartado. Testes: `app/test/channel_disposal_test.dart`.
- **Validação:** backend com 115 testes aprovados e TypeScript sem erros. Aplicativo com 22 testes focados aprovados e 39 testes aprovados ao executar todos os arquivos exceto `schedule_work_status_test.dart`. Análise dos arquivos envolvidos sem problemas; build web release concluído.
- **Limitação encontrada na suíte completa:** três testes em `app/test/schedule_work_status_test.dart` falham nas expectativas de plantão extra, conta inativa e dia de folga. Tanto esse arquivo quanto `app/lib/features/auth/domain/entities/user_entity.dart` permaneceram iguais à versão anterior, com última alteração em `c6aa229`. A revisão não modificou regras de escala/serviço para fazer esses testes passarem. Essa divergência permanece documentada para revisão própria.
- **Escopo:** os sete achados específicos da seção 7 foram tratados. Isso não significa encerramento de todos os itens do relatório original: dependências, legado, credenciais e demais sugestões continuam exigindo avaliação própria. Não houve migração nem alteração de dados de produção.

## 10. Publicação final confirmada

- Correções da seção 8: commit `041361f`. Correções da seção 9: commit `3294e8c20101fb53eb9cc1f30b59edf73cc04897`.
- Render confirmou `3294e8c` em `Deploy succeeded|Live`. A verificação de `/health` retornou HTTP 200.
- Firebase Hosting confirmou a publicação em `https://conecta-hospital.web.app`. O SHA-256 do `main.dart.js` publicado coincide com o build local: `d5693b8127eb85cdbee6b3bcbaecfffb8867ff0ae75db98c8b43ee7e97eb359e`.
- Chrome desktop: Central de Emergência carregada, estado normal confirmado pela consulta, histórico e controles visíveis. Nenhum chamado de emergência foi criado. Evidência visual local: `C:/Users/Ricardo/.codex/visualizations/2026/10/11/01a12a97-b7a3-7291-8a6d-440d097ff3b3/emergencia-publicacao-final.png`.
- Este registro final é um commit somente de documentação posterior ao código publicado. Os arquivos locais `report.md` e os dois scripts de teste do responsável foram preservados e não incluídos nos commits.
