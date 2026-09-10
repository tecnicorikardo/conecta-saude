# Relatório de Teste Funcional — Conecta Saúde

**Data do teste:** 9 de setembro de 2026, entre 22:01 e 22:20 (horário da sessão)  
**Aplicação:** Conecta Saúde — Sistema Integrado de Comunicação Hospitalar SUS  
**Ambiente:** `https://conecta-hospital.web.app`  
**Executor:** Manus AI

## 1. Conclusão executiva

A aplicação apresentou funcionamento geral satisfatório nos fluxos de autenticação, painel inicial, comunicados, conversas diretas, conversas em grupo, notificações, canais, Ouvidoria, Central de Emergência e controle de acesso por perfil. O teste ponta a ponta de mensagens em grupo foi concluído com sucesso: três mensagens enviadas por Ricardo apareceram no histórico de Paula e produziram contador de três conversas não lidas.

Foram identificados **dois problemas relevantes**. O carregamento dos comunicados é intermitente e, em algumas navegações, a tela exibe inicialmente “Nenhum comunicado disponível” antes de carregar os três comunicados. Além disso, o painel administrativo informa **24 eventos de auditoria no dia**, enquanto a tela de Log de Auditoria informa **0 registros**. Essa divergência precisa ser investigada antes de considerar o módulo de conformidade confiável.

Também foram observados dois pontos de usabilidade ou consistência de dados. A tecla Enter não enviou a mensagem; foi necessário usar o botão de envio. A terceira mensagem do grupo apareceu sem o caractere inicial `[` no histórico do remetente e do destinatário, embora as duas primeiras tenham preservado o prefixo.

Os testes não dispararam chamados de emergência, não registraram denúncias, não aprovaram acessos, não publicaram comunicados e não alteraram participantes ou configurações de grupos. Foram enviados apenas conteúdos marcados como teste nas conversas autorizadas.

## 2. Escopo e critérios

O escopo cobriu autenticação positiva e negativa, perfis de funcionário, coordenação e direção, carregamento do painel, comunicados, notificações, conversas diretas, grupos, criação de grupo, canais institucionais, Ouvidoria, Central de Emergência, gestão de pessoal, aprovações, denúncias, auditoria e área administrativa.

A avaliação de latência foi realizada por observação do tempo entre as ações do navegador e a atualização visível da interface. Esses tempos são **aproximados**, pois incluem a rodada de interação do navegador e não representam uma medição isolada de rede, banco de dados ou servidor.

## 3. Matriz de resultados

| Área | Teste realizado | Resultado | Classificação |
|---|---|---|---|
| Login de funcionário | Ricardo Martins Santos | Login e painel operacional carregados | Aprovado |
| Login operacional alternativo | Paula Souza | Login e painel operacional carregados | Aprovado |
| Login de coordenação | Dr. Roberto Vasconcelos | Painel de coordenação e gestão de pessoal acessíveis | Aprovado |
| Login de direção | Carlos Eduardo Mendes | Painel de direção, denúncias, auditoria e administração acessíveis | Aprovado |
| Usuário inativo | `inativo@conectasaude.dev` | Acesso negado com a mensagem “Acesso desativado. Entre em contato com o RH.” | Aprovado |
| Painel inicial | Atalhos, perfil, conversas, canais e comunicados | Componentes carregaram; houve carregamento assíncrono variável | Parcial |
| Comunicados | Lista inicial e tela “Comunicados Oficiais” | Três comunicados foram exibidos após estabilização | Aprovado com ressalva |
| Conversa direta | Ricardo para Dr. Roberto | Mensagem persistida e notificação recebida pela coordenação | Aprovado |
| Grupo existente | Grupo “Maqueiros CCO”, três participantes | Dados do grupo, participantes e controles carregaram | Aprovado |
| Mensagens em grupo | Três mensagens de teste enviadas por Ricardo | Mensagens persistiram e foram recebidas por Paula | Aprovado com ressalva |
| Recebimento em grupo | Paula abriu Conversas e o grupo | Contador de três não lidas e histórico com as três mensagens | Aprovado |
| Criação de grupo | Fluxo “Nova Conversa > Grupo” | Campos de nome, participantes, autoexclusão de 24 horas e botão de criação presentes; criação não confirmada | Inspecionado |
| Canais | Lista de canais e canal “Avisos da Direção Geral” | Leitura disponível; publicação corretamente restrita a coordenação e direção | Aprovado |
| Notificações | Tela de notificações e banner de mensagem recebida | Tela vazia quando não havia notificações; banner de recebimento funcionou | Aprovado |
| Ouvidoria | Abertura do formulário de manifestação | Tipos, assunto, detalhes, anonimato e envio presentes; nenhum registro criado | Inspecionado |
| Emergência | Central de Emergência | Estado normal, contatos e botão de disparo presentes; nenhum chamado disparado | Inspecionado |
| Gestão de pessoal | Lista de colaboradores e aba de aprovações | Lista exibida; uma solicitação aguardava validação; nenhuma decisão tomada | Aprovado |
| Denúncias | Ouvidoria e Moderação da Direção | Filtros presentes; nenhuma denúncia registrada | Aprovado |
| Auditoria | Resumo administrativo versus tela de logs | Resumo indicou 24 eventos; tela indicou 0 registros | **Falha** |
| Relatórios | Card administrativo de Relatórios de Leitura | O acesso não foi confirmado de forma inequívoca no teste por índice de interface | Requer reteste |
| Perfil e tema | Perfil operacional e de direção | Dados funcionais, status, temas visuais e notificações push exibidos | Aprovado |

## 4. Teste de envio de mensagens e latência observada

O teste foi deliberadamente controlado, com três mensagens no grupo, para evitar geração de spam ou carga artificial em um ambiente institucional. As mensagens utilizadas foram identificadas com o prefixo `[TESTE FUNCIONAL]`.

| Operação | Resultado observado | Tempo aproximado observado |
|---|---|---:|
| Mensagem de grupo 1/3 | O texto apareceu no histórico após o clique no botão de envio | 8 s |
| Mensagem de grupo 2/3 | O texto apareceu no histórico após o clique no botão de envio | 8 s |
| Mensagem de grupo 3/3 | O texto apareceu no histórico após o clique no botão de envio | 6 s |
| Mensagem direta Ricardo → Dr. Roberto | A mensagem persistiu e gerou notificação no painel da coordenação | até 18 s na rodada observada |
| Recepção por Paula | Banner de grupo e contador de três não lidas apareceram após o login | cerca de 9 s até o painel |
| Histórico de Paula | As três mensagens foram exibidas no grupo | confirmado na abertura da conversa |

A aplicação demonstrou entrega funcional, mas o teste não permite afirmar uma taxa máxima de mensagens por segundo. O resultado representa a velocidade percebida no fluxo manual e não um teste de estresse. Para uma medição de capacidade, seria necessário um ambiente de homologação e uma ferramenta de carga autorizada.

O envio por tecla Enter não foi concluído automaticamente. Após pressionar Enter, o texto permaneceu no campo e o envio exigiu o botão “Enviar mensagem”. Caso o requisito do produto seja enviar com Enter, esse comportamento deve ser corrigido ou documentado claramente.

## 5. Verificação de grupos

O grupo “Maqueiros CCO” informou três participantes: Ricardo Martins Santos, Paula Souza e Thiago Duarte. A tela de dados do grupo exibiu opções para editar o nome, ativar mensagens temporárias de 24 horas, adicionar participantes, sair do grupo e excluir o grupo.

O fluxo de criação de grupo apresentou campos para nome, participantes, autoexclusão em 24 horas e confirmação “Criar Grupo”. A criação não foi confirmada, pois isso deixaria um grupo adicional no ambiente e não era necessário para provar o funcionamento do fluxo existente.

As três mensagens de teste permanecem no histórico do grupo e a mensagem direta permanece na conversa com Dr. Roberto. Elas não foram removidas, porque a exclusão de dados é uma ação potencialmente destrutiva e não foi autorizada de forma específica.

## 6. Controle de acesso e segurança funcional

O usuário inativo foi bloqueado corretamente após o login, o que confirma a aplicação da condição de acesso desativado. O perfil de funcionário não recebeu controle de publicação no canal “Avisos da Direção Geral”, cuja interface informa que apenas coordenação e direção podem publicar. O perfil de coordenação recebeu acesso a gestão de pessoal e aprovações. O perfil de direção recebeu acesso adicional a denúncias, auditoria e relatórios administrativos.

Os fluxos de emergência e Ouvidoria foram apenas inspecionados. Nenhum chamado, denúncia ou manifestação foi enviado. Essa decisão preservou a integridade dos registros institucionais.

## 7. Defeitos e riscos encontrados

### 7.1 Divergência entre contador e log de auditoria — prioridade alta

O resumo administrativo exibiu **24 Auditoria Hoje**. Ao abrir “Log de Auditoria”, a tela exibiu **0 registros** e “Nenhum log encontrado”. Como a auditoria é uma função de conformidade, a divergência pode indicar filtro incorreto, consulta incompleta, falha de carregamento ou inconsistência entre fontes de dados.

**Recomendação:** validar a consulta do resumo e a consulta da tela de logs usando o mesmo intervalo de data, o mesmo fuso horário e a mesma fonte de dados. Criar um teste automatizado que execute uma ação administrativa de homologação e confirme sua presença no log.

### 7.2 Carregamento intermitente dos comunicados — prioridade média

Em diferentes retornos ao painel, a interface mostrou inicialmente “Nenhum comunicado disponível no momento”. Após nova atualização ou espera adicional, os três comunicados apareceram. O comportamento sugere estado de carregamento não representado ou renderização antes da conclusão da consulta.

**Recomendação:** exibir um estado explícito de carregamento, diferenciar “carregando” de “lista vazia” e revisar o tratamento de erro e atualização do estado dos comunicados.

### 7.3 Possível tratamento incorreto de caractere inicial em mensagem — prioridade média

A terceira mensagem foi enviada com o prefixo `[TESTE FUNCIONAL]`, mas apareceu como `TESTE FUNCIONAL]` no histórico, sem o caractere `[` inicial. O comportamento foi observado tanto na visão do remetente quanto na visão de Paula.

**Recomendação:** testar caracteres especiais no componente de entrada, serialização, sanitização e renderização de mensagens. A correção deve preservar o conteúdo original sem interpretar o texto como marcação.

### 7.4 Comportamento da tecla Enter — prioridade baixa ou média

A tecla Enter não enviou a mensagem durante o teste. O envio por botão funcionou. A severidade depende do requisito de interação definido para o produto.

**Recomendação:** decidir explicitamente entre Enter para enviar e Shift+Enter para quebra de linha. Implementar o comportamento escolhido e cobri-lo com teste de interface.

### 7.5 Reteste do módulo de Relatórios de Leitura

O item “Relatórios de Leitura” foi exibido na área administrativa, mas sua abertura não foi confirmada de modo inequívoco pelo mecanismo de interação usado no teste. Isso não prova que o módulo esteja quebrado, mas indica necessidade de verificação manual ou de um seletor de interface mais estável.

## 8. Recomendações de acompanhamento

A primeira correção recomendada é investigar a divergência da auditoria, pois ela pode afetar rastreabilidade e conformidade. Em seguida, deve-se corrigir o estado de carregamento dos comunicados e validar a preservação de caracteres nas mensagens. Depois, recomenda-se repetir o teste de Relatórios de Leitura e executar uma rodada de carga em homologação, com métricas de tempo de resposta, taxa de erro, throughput e entrega de notificações.

Também é recomendável manter mensagens de teste com um identificador padronizado e uma rotina de limpeza autorizada para ambientes de homologação. No ambiente atual, as mensagens foram mantidas para permitir conferência posterior e não houve exclusão de dados.

## 9. Estado final

O navegador foi deixado na tela de login, sem sessão autenticada. Nenhum chamado de emergência, denúncia, aprovação, publicação de comunicado, criação de grupo ou alteração de participantes foi efetivado durante a execução.

## Referências

[1]: https://conecta-hospital.web.app "Conecta Saúde — Sistema Integrado de Comunicação Hospitalar SUS"
