# Últimos erros — autenticação, canais e comunicados

Data: 09/10/2026. Conta investigada: supervisao.cco@conectasaude.dev.

## Nova entrega — exclusão de canais e comunicados

Regra escolhida pelo usuário: autor pode excluir seu próprio conteúdo em qualquer nível (inclusive NV4 após mudança de cargo); Direção pode excluir qualquer conteúdo. Criar conteúdo continua restrito aos níveis 1/2/3.

- Implementadas rotas DELETE autenticadas com validação de autoria/Direção no servidor.
- Exclusão lógica com `ativo=false`; preserva histórico, mensagens e leituras no banco. Listagens omitem itens excluídos e rotas diretas rejeitam acesso a eles.
- API informa `canDelete` para mostrar botões somente quando permitido. Confirmação antes de excluir, bloqueio de cliques repetidos e erro exibido no diálogo sem fechá-lo.
- A exclusão individual registra usuário e conteúdo na auditoria. Consultas iniciadas antes da exclusão não recolocam o item na lista local.
- Testes: **63 aprovados no servidor**, incluindo autorização, exclusão, conteúdo inativo e repetição; **3 testes Flutter aprovados** para confirmação/cancelamento/erro. Análise Flutter dos módulos alterados sem problemas. Backend compilado com sucesso.
- Publicação desta funcionalidade: em preparação; atualizar este registro após conferir Render e Firebase.

### Limpeza solicitada explicitamente: “exclusão de todos, deixar zerado”

Executada em produção em 09/10/2026: **19 canais e 18 comunicados** passaram de ativos para inativos em uma transação. Consulta após a operação confirmou **0 canais ativos e 0 comunicados ativos**. Não houve exclusão física; nenhum usuário ou conversa privada foi removido.

Operação administrativa executada por Codex a pedido do usuário desta conversa, sem atribuí-la falsamente a uma conta logada do aplicativo. Comprovante local com os IDs afetados e horários em `scratch/exclusao-canais-comunicados-2026-10-09.json`; ele permite identificar exatamente os registros para eventual recuperação. A identidade da conta de Supervisão no banco foi comparada com a API de produção antes da operação. Nenhum teste remoto com Direção foi realizado.

## Situação final desta investigação

**Bloqueio de autorização NV3 corrigido em produção.** O Render executava `db9771b`, que restringia as publicações até Coordenação (NV2). Foi publicado `cfbd7602725b10999fef4f87d0430db7aa0b91b2`, que inclui a liberação de Supervisão. A verificação remota posterior confirmou que a Supervisão passa pela autorização nas duas rotas. Não houve alteração de cargo/cadastro nem criação de conteúdo de teste em produção.

### Publicação e verificação final — 09/10/2026

- Serviço: `conecta-saude-backende` (`srv-daesrpgu01pc73ftdoc0`).
- Deploy: `dep-db4n9e0m7kps73amjqa0`, acionado manualmente pelo painel às 20:11:52 (GMT-3).
- Resultado observado no painel: **Deploy succeeded | Live**, duração de 1min39s, serviço no ar às 20:13:31.
- Registros confirmaram compilação concluída, inicialização Firebase e conexão PostgreSQL bem-sucedidas.
- Sessão nova exclusivamente de `supervisao.cco@conectasaude.dev`: `GET /api/auth/me` retornou **200**, nível **3**, ativo **true**.
- `POST /api/channels` com `{}`: **422**, campo `nome` obrigatório; antes retornava 403.
- `POST /api/announcements` com `{}`: **422**, campos `titulo` e `mensagem` obrigatórios; antes retornava 403.
- O 422 é intencional neste diagnóstico: comprova passagem pela autorização sem gravar conteúdo ou enviar notificações. Não representa teste completo de persistência em produção. A criação válida foi testada localmente com serviços externos simulados.
- Nenhum teste remoto realizado com Direção. O usuário pode atualizar o aplicativo e realizar sua publicação normal com Supervisão.
- Os comentários, testes e documentos locais desta investigação permanecem no workspace; o deploy utilizou o commit remoto já existente, não essas alterações locais ainda não versionadas.
- Os registros de instalação também apontaram 31 vulnerabilidades de dependências (13 moderadas, 15 altas e 3 críticas). Não impediram o build e não foram investigadas ou corrigidas nesta tarefa; revisão de dependências permanece separada do erro de autorização.

## Histórico da investigação (antes da publicação)

## 1. HTTP 403 ao criar canais e comunicados

### Evidências

- A API publicada respondeu `GET /api/auth/me` com HTTP 200, nível 3 e conta ativa.
- A mesma sessão recebeu HTTP 403 em `POST /api/channels` e `POST /api/announcements`, ambos com a mensagem: “Você não possui permissão para realizar esta ação.”
- Os dois POSTs usaram `{}`. O comportamento correto para uma Supervisão autorizada é HTTP 422, pois faltam campos obrigatórios. Esse procedimento testa a autorização sem criar canais/comunicados ou disparar notificações.
- Localmente, ambas as rotas usam `requireHierarquia(HierarquiaNivel.SUPERVISAO)`, e os controllers também aceitam o nível 3.
- Os testes novos executam as rotas e o middleware reais, simulando Firebase, banco e auditoria. Neles a Supervisão chega à validação e também consegue criar com formulário válido.

### Diagnóstico

O usuário informou que o Deploy 22 está Live com o commit `db9771b`, no repositório `tecnicorikardo/conecta-saude`, branch `main`. A inspeção desse commit no Git confirmou `requireHierarquia(HierarquiaNivel.COORDENACAO)` em ambas as rotas de criação e verificações de Coordenação no controller de comunicados. Assim, o NV3 é barrado antes da criação, exatamente como observado na API. Os commits posteriores, incluindo `bec85d7`, contêm a liberação de Supervisão. O status 200 do aquecimento apenas confirma disponibilidade; não confirma a versão nem a permissão.

Na nova consulta ao navegador, o Render estava autenticado, mas o workspace acessível mostrou apenas o serviço `helogourmet-backend`. Foi solicitado o link direto do serviço correto. Os dados do Deploy 22 são informação fornecida pelo usuário; ainda não foram verificados diretamente na página desse serviço. Nenhuma ação foi realizada no serviço diferente. Não foram realizados testes remotos com Direção, conforme solicitado pelo usuário.

Após receber o link direto `https://dashboard.render.com/web/srv-daesrpgu01pc73ftdoc0`, a página foi aberta no Chrome conectado. O Render respondeu **Access denied — You don’t have access to srv-daesrpgu01pc73ftdoc0**. Portanto, a sessão acessível ao agente não possui acesso a esse serviço. É necessário entrar nesse navegador com a conta que já tem acesso ao serviço para realizar a publicação. Nenhum deploy foi acionado; não houve nova validação da API, pois a versão não foi alterada.

### O que foi feito

- Reproduzido o erro nas duas rotas usando a conta informada e sem conteúdo real.
- Adicionados nove testes de regressão em `backend/src/__tests__/publication_routes.test.ts`: passagem dos níveis 1/2/3, bloqueio do nível 4, conta inativa e sessão ausente, criação de canal com fallback de setor, bloqueio de outro setor e criação de comunicado sem token de notificações.
- Criado `backend/src/scripts/diagnose_publication_permissions.ts` para repetir a checagem após a publicação. Usa token fornecido por variável de ambiente, não imprime credenciais nem publica conteúdo.
- Mantidos intactos os dois scripts de teste que já existiam como arquivos não versionados no início do trabalho. Eles não foram executados, pois criam registros reais.

### Procedimento de resolução (etapas 1 a 4 concluídas)

1. Acessar o link direto de `conecta-saude-backende` no painel Render, com a conta/workspace que tem acesso ao serviço.
2. Conferir repositório, branch, commit e histórico de publicação; comparar com o código que já contém a autorização de Supervisão (inclusive o commit local histórico `bec85d7`).
3. Publicar a versão correta do servidor e conferir os registros de compilação/inicialização. A consulta remota ao GitHub confirmou `main` em `cfbd7602725b10999fef4f87d0430db7aa0b91b2`, que já inclui a correção. Portanto, ela já está no repositório remoto; falta aplicar a publicação no serviço correto. Publicar somente o aplicativo no Firebase não atualiza a API Render.
4. Repetir o diagnóstico com a conta de Supervisão: `/auth/me` deve retornar nível 3 ativo; os POSTs vazios devem retornar 422, e não 403.
5. Validar uma criação real em ambiente de teste. A criação com persistência foi validada localmente com serviços simulados, não em produção.

## 2. Perfil local em cache e identificadores diferentes

O console enviado citou o identificador `07ecaefe-b793-43e1-aed6-71a16fd415e5`. Na consulta atual da conta informada, a API devolveu `8bf2d1b7-642a-4857-9718-aadce56bf3a4`. O aviso de rede confirma que o aplicativo recorreu ao cache naquela ocasião. Isso é um indício de perfil antigo ou ambientes/cadastros distintos, não prova de qual alteração ocorreu. Atualizar o perfil/reautenticar após conferir a publicação ajuda a alinhar a interface. O 403 também ocorreu com uma sessão nova, portanto cache sozinho não explica o bloqueio reproduzido.

## 3. Timeout para obter token FCM

O log mostra timeout de 10 segundos e token de notificações nulo. Esse token é diferente do token de autenticação. A criação dos conteúdos não exige FCM do autor e o envio de push ocorre depois da resposta de criação. Portanto, esse aviso não é a causa do 403 reproduzido. Configuração VAPID, service worker e conectividade de push não foram alterados nem validados nesta investigação; problema permanece separado.

## 4. Aviso de instalação PWA

O navegador informa que `beforeinstallprompt` foi interceptado sem chamada posterior de `prompt()`. Trata-se do fluxo de instalação do aplicativo, sem evidência de relação com as permissões da API. Não foi alterado. O registro bem-sucedido do service worker é informativo.

## 5. Comentários para iniciantes

Conforme o recorte escolhido pelo usuário, iniciada a documentação de autenticação, canais e comunicados. Os comentários explicam a ordem das verificações, hierarquia, cache, formulários, estado Riverpod, JSON, chamadas assíncronas e erros. Criado `GUIA_AUTENTICACAO_CANAIS_COMUNICADOS.md` com caminho de leitura e glossário. Esta entrega documenta os trechos centrais; não comenta cada linha de todo o projeto.

## Validação

- `npm test` em `backend`: **38 testes aprovados, 7 arquivos**, incluindo os 9 novos testes.
- `npm run build` em `backend`: **aprovado** (geração Prisma e compilação TypeScript; não executa migrações).
- `git diff --check`: sem erros de whitespace.
- Alterações Flutter consistem apenas em comentários; não houve mudança funcional nem build Flutter nesta etapa.
- Deploy `dep-db4n9e0m7kps73amjqa0` concluído e autorização NV3 verificada em produção nas duas rotas. Não houve teste de criação real em produção, para evitar conteúdo e notificações de teste.
