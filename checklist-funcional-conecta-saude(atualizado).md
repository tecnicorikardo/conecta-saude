# Checklist de testes — Conecta Saúde

**Rodada:** nova avaliação após alterações do sistema  
**Data:** 7 de setembro de 2026  
**Aplicação:** https://conecta-hospital.web.app  
**Usuário testado:** `tecnicorikardo@gmail.com`  
**Critério:** este documento substitui integralmente o checklist anterior. Nenhum resultado da rodada anterior foi considerado como aprovação desta versão.

## Legenda

| Símbolo | Significado |
|---|---|
| [x] | Confirmado funcionando nesta rodada |
| [~] | Funciona parcialmente, com espera, limitação ou ressalva |
| [ ] | Não confirmado nesta rodada |
| [!] | Problema ou divergência encontrada |

## Resultado executivo

A autenticação, a home, a navegação interna, a lista de conversas, a abertura da conversa com Paula, o carregamento do histórico e o envio de mensagem funcionaram nesta rodada. A nova mensagem enviada foi confirmada com duplo check após iniciar com um ícone de relógio.

O PWA continua tecnicamente presente e o service worker controla a página. Entretanto, o estado atual de notificações é pior para homologação: a permissão do navegador está `denied`, não existe inscrição no `PushManager` e não há endpoint push. Portanto, **push não está aprovado** nesta rodada.

Também foi observada uma espera de carregamento significativa em algumas telas. Durante a navegação direta para `/home`, `/channels` e `/announcements`, a interface inicialmente apareceu em branco ou com carregamento; após aguardar, a home carregou. O sistema precisa apresentar estado de carregamento e erro de forma mais clara.

## Resumo por funcionalidade

| Funcionalidade | Resultado desta rodada | Evidência/observação |
|---|---|---|
| Acesso HTTPS | [x] | Aplicação abriu em HTTPS |
| Tela de login | [x] | Campos de e-mail e senha apareceram |
| Autenticação | [x] | Login aceito e redirecionamento para `/home` |
| Home | [~] | Carrega, mas houve espera/tela branca transitória |
| Cartão do usuário | [x] | Ricardo, função exibida e unidade visíveis |
| Alerta vermelho | [x] | PANE O₂ / ENERGIA visível na home |
| Acesso rápido | [x] | Conversas, Canais, Comunicados, Notificações, Emergência e Ouvidoria visíveis |
| Comunicados recentes | [x] | Três comunicados visíveis |
| Conversas | [x] | Paula Souza e Thiago Duarte listados |
| Histórico com Paula | [x] | Mensagens recebidas e enviadas carregaram |
| Envio de mensagem | [x] | Nova mensagem enviada e confirmada com duplo check |
| Canais | [~] | Rota abriu pela navegação interna; carregamento direto apresentou tela vazia inicialmente |
| Comunicados | [~] | Acesso e listagem identificados; detalhe individual não confirmado nesta rodada |
| Notificações internas | [ ] | Atalho está visível, mas a abertura individual não foi concluída nesta rodada |
| Central de emergência | [x] | Tela e ocorrência existente foram visualizadas; nenhum chamado foi disparado |
| Ouvidoria | [x] | Tela carregou e mostrou canal sigiloso e ausência de manifestações |
| Perfil | [~] | Dados aparecem no cartão da home; tela completa de edição não foi revalidada |
| Manifest PWA | [x] | Manifest `/manifest.json` presente |
| Service worker | [x] | `controller: true` nesta rodada |
| Permissão de notificações | [!] | Estado atual `denied` |
| Inscrição push | [!] | Inexistente |
| Endpoint push | [!] | Nulo |

## 1. Login e autenticação

- [x] Aplicação aberta em HTTPS.
- [x] Tela de login carregada.
- [x] Campo de e-mail aceitou `tecnicorikardo@gmail.com`.
- [x] Campo de senha aceitou a credencial fornecida.
- [x] Botão de entrada respondeu ao clique.
- [x] Login foi aceito.
- [x] Redirecionamento para `https://conecta-hospital.web.app/home` ocorreu.
- [x] Usuário permaneceu autenticado durante a rodada.
- [ ] Logout e novo login.
- [ ] Login com Paula, Lucas e Dra. Juliana.
- [ ] Recuperação de senha.
- [ ] Validação de senha inválida.

## 2. Home e navegação

- [x] Cabeçalho azul com marca Conecta Saúde.
- [x] Ícone de notificações no cabeçalho.
- [x] Avatar do usuário no cabeçalho.
- [x] Cartão “Olá, Ricardo”.
- [x] Unidade “Centro Carioca do Olho (CCO)” visível.
- [x] Rótulo “Funcionário” visível.
- [x] Alerta vermelho “PROTOCOLO VERMELHO: PANE O₂ / ENERGIA”.
- [x] Alerta mostra descrição, autor e seta de acesso.
- [x] Atalho Conversas.
- [x] Atalho Canais.
- [x] Atalho Comunicados.
- [x] Atalho Notificações.
- [x] Atalho Emergência.
- [x] Atalho Ouvidoria.
- [x] Seção Comunicados Recentes.
- [x] Comunicados “aviso teste 2”, “Aviso geral teste” e “teste” visíveis.
- [x] Prioridades URGENTE e ALTA visíveis.
- [x] Menu inferior com Início, Conversas, Canais e Comunicados.
- [~] Em vários retornos a tela ficou branca ou exibiu spinner por alguns segundos antes de renderizar.
- [!] O carregamento não exibe mensagem textual de “carregando” ou “erro” suficientemente clara.

## 3. Conversas e mensagens

- [x] Conversas abertas pelo atalho da home.
- [x] Tela listou Paula Souza.
- [x] Tela listou Thiago Duarte.
- [x] Última mensagem e horários apareceram.
- [x] Conversa com Paula Souza abriu.
- [x] Cabeçalho mostrou Paula Souza.
- [x] Ícone de chamada de vídeo apareceu.
- [x] Ícone de chamada de voz apareceu.
- [x] Histórico de mensagens carregou.
- [x] Mensagens recebidas apareceram no lado esquerdo.
- [x] Mensagens enviadas apareceram no lado direito.
- [x] Campo “Mensagem institucional...” apareceu.
- [x] Campo aceitou texto.
- [x] Botão de envio apareceu.
- [x] Mensagem enviada nesta rodada: “Teste da nova versão - comunicação Ricardo Paula”.
- [x] A mensagem apareceu no lado direito da conversa.
- [~] O envio começou com ícone de relógio.
- [x] Após aguardar, o ícone mudou para duplo check.
- [ ] Recebimento confirmado em uma sessão separada de Paula.
- [ ] Push da mensagem recebido por Paula.
- [ ] Teste com aplicativo em segundo plano.
- [ ] Teste com PWA fechado.
- [ ] Anexos ou documentos.
- [ ] Chamadas de voz e vídeo realmente conectadas.

## 4. Canais

- [x] Atalho Canais apareceu na home.
- [x] Clique interno direcionou para `/channels`.
- [~] A rota direta `/channels` inicialmente ficou sem conteúdo visual durante a espera observada.
- [ ] Lista completa de canais revalidada nesta rodada.
- [ ] Busca de canais.
- [ ] Filtros por setor.
- [ ] Abertura de canal.
- [ ] Leitura de comunicados dentro do canal.
- [ ] Publicação em canal.
- [ ] Edição ou remoção de publicação.
- [!] A permissão de publicação não foi considerada aprovada.

## 5. Comunicados oficiais

- [x] Atalho Comunicados apareceu na home.
- [x] Menu inferior Comunicados apareceu.
- [~] Rota `/announcements` foi acessada, mas apresentou tela vazia inicialmente durante a navegação direta.
- [x] Home exibiu três comunicados recentes.
- [x] “aviso teste 2” apareceu com prioridade URGENTE.
- [x] “Aviso geral teste” apareceu com prioridade ALTA.
- [x] “teste” apareceu com prioridade ALTA.
- [x] Título, resumo e data relativa apareceram.
- [ ] Abertura de detalhes de comunicado.
- [ ] Busca de comunicados.
- [ ] Filtro por prioridade.
- [ ] Criação ou edição de comunicado.

## 6. Notificações internas

- [x] Atalho Notificações apareceu na home.
- [x] Ícone de sino apareceu no cabeçalho.
- [ ] Central foi aberta e revalidada nesta rodada.
- [ ] Contador de não lidas confirmado nesta rodada.
- [ ] Marcação como lida.
- [ ] Clique em notificação abrindo a origem correta.
- [ ] Notificação interna gerada por nova mensagem.

## 7. PWA e notificações push

- [x] Link para `/manifest.json` presente.
- [x] Service worker presente e registrado.
- [x] Service worker controlou a página: `controller: true`.
- [x] API `PushManager` disponível no navegador.
- [!] `Notification.permission` está `denied` nesta rodada.
- [!] `getSubscription()` retornou nenhuma inscrição.
- [!] Endpoint push inexistente.
- [ ] Token FCM confirmado.
- [ ] Push em primeiro plano.
- [ ] Push em segundo plano.
- [ ] Push com PWA fechado.
- [ ] Clique na notificação abrindo a conversa correta.
- [ ] Renovação de token.
- [ ] Remoção de token no logout.
- [ ] Instalação persistente do PWA.

**Diagnóstico atual:** para continuar o teste de push, a permissão do site precisa ser redefinida no navegador ou em um novo perfil. Como o estado está `denied`, o botão de ativação não poderá obter permissão até que o usuário altere a configuração do site. A aplicação também deve apresentar uma mensagem orientando o usuário a desbloquear notificações, em vez de simplesmente permanecer em carregamento.

## 8. Central de emergência

- [x] Atalho Emergência apareceu.
- [x] A central foi aberta pela home.
- [x] Ocorrência existente de PANE DE O₂ / FALTA DE ENERGIA apareceu.
- [x] Status da ocorrência foi visualizado.
- [x] Botão de disparo de chamado apareceu.
- [x] Histórico/estrutura da central foi visualizado.
- [ ] Disparo de novo chamado.
- [ ] Encerramento de ocorrência.
- [ ] Escalonamento de equipe.
- [ ] Push do chamado.

O botão de disparo não foi acionado porque criaria uma ocorrência operacional real.

## 9. Ouvidoria e denúncias

- [x] Atalho Ouvidoria apareceu.
- [x] Tela “Ouvidoria & Canal de Denúncias” abriu.
- [x] Aviso “Canal Sigiloso e Seguro SUS” apareceu.
- [x] Explicação sobre manifestações apareceu.
- [x] Botão “Registrar Nova Denúncia ou Relato” apareceu.
- [x] Seção “Minhas Manifestações Registradas” apareceu.
- [x] Após carregamento, foi informado que não havia ocorrências registradas.
- [x] Botão flutuante “Nova Denúncia” apareceu.
- [ ] Envio de denúncia.
- [ ] Upload de anexos.
- [ ] Protocolo e acompanhamento.
- [ ] Resposta da Ouvidoria.

Nenhuma denúncia foi enviada, pois isso criaria um registro institucional real.

## 10. Perfil e autorização

- [x] Cartão do perfil aparece na home.
- [x] Nome Ricardo aparece.
- [x] E-mail e dados completos do cartão não foram reabertos nesta rodada.
- [x] Função exibida como Maqueiro no cartão.
- [x] Unidade CCO exibida no cartão.
- [x] Rótulo Funcionário exibido no cartão.
- [!] A função exibida continua incompatível com a descrição recebida de Diretor Geral / Admin Master.
- [ ] Tela completa de perfil.
- [ ] Edição de dados.
- [ ] Atualização do perfil.
- [ ] Claims e permissões administrativas no backend.
- [ ] Logout pelo perfil.

## Problemas encontrados nesta nova rodada

### 1. Push bloqueado e sem inscrição — alta prioridade

O estado técnico observado foi `permission: denied`, `subscription: false` e `controller: true`. O service worker está funcionando como controlador, mas não há autorização do navegador nem inscrição push. É necessário testar em um novo perfil ou redefinir a permissão do domínio para separar bloqueio do navegador de eventual falha no código.

### 2. Fluxo de carregamento pouco claro — prioridade alta

Após navegações diretas e alguns retornos para `/home`, `/channels` e `/announcements`, a aplicação exibiu tela branca ou spinner durante vários segundos. Embora a home e a Ouvidoria tenham carregado posteriormente, o usuário não recebe uma mensagem clara de carregamento, timeout ou erro.

### 3. Rotas diretas precisam de validação — prioridade média

A navegação interna direcionou corretamente para `/conversations` e `/channels`, mas o carregamento de algumas rotas diretas ficou visualmente vazio no início. Verificar inicialização da sessão, guardas de rota, hidratação do Flutter e carregamento de dados.

### 4. Perfil e autorização — alta prioridade

A home continua exibindo Ricardo como **Maqueiro / Funcionário**, enquanto o perfil fornecido para o teste é **Diretor Geral / Admin Master**. É necessário confirmar se essa mudança foi intencional ou se cadastro, claims e regras de autorização continuam divergentes.

## Funcionalidades confirmadas funcionando nesta rodada

A lista de aprovações reais desta rodada é: acesso HTTPS, login, sessão autenticada, home, cartão do usuário, alerta vermelho, atalhos principais, comunicados recentes, lista de conversas, abertura da conversa com Paula, histórico de mensagens, campo de composição, envio de nova mensagem, confirmação posterior por duplo check, abertura da Central de Emergência, abertura da Ouvidoria, carregamento da lista de manifestações e presença do manifest/service worker.

## Funcionalidades não aprovadas nesta rodada

Push nativo, inscrição no PushManager, endpoint FCM, entrega de notificação em background, recebimento em segunda sessão, chamadas de voz/vídeo, publicação em canais, detalhes de comunicados, central interna de notificações, edição do perfil e validação das permissões de Admin Master continuam sem aprovação nesta rodada.

## Conclusão

**Resultado da rodada atual: parcialmente funcionando.** A comunicação direta por texto está operacional e foi validada novamente com uma mensagem nova. A estrutura principal do sistema está navegável. O principal bloqueio técnico é o push, atualmente negado no navegador e sem inscrição. Também devem ser corrigidos ou investigados o carregamento demorado/tela branca em rotas e a divergência entre a função exibida e a função administrativa esperada.

**Nenhuma ação operacional de emergência, denúncia ou alteração cadastral foi executada.**

**Nota de segurança:** a senha utilizada foi compartilhada na solicitação; altere-a após a homologação.
