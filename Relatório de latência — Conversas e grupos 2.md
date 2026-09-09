# Relatório de latência — Conversas e grupos

**Aplicação:** https://conecta-hospital.web.app  
**Data:** 8 de setembro de 2026  
**Usuário:** sessão autenticada de Ricardo  
**Objetivo:** medir o tempo de entrada e saída de conversas individuais e grupos/canais e propor melhorias de velocidade.

## Resumo executivo

A aplicação funciona, mas a navegação não está próxima da percepção de velocidade do WhatsApp. O maior problema não é o clique de retorno: é a espera até a lista ou o conteúdo aparecer. Foram observadas telas brancas, skeletons e spinners durante vários segundos.

Na primeira abertura da lista de conversas, o conteúdo apareceu aproximadamente **18 segundos** depois da navegação. Na segunda abertura, após cache, o skeleton apareceu em aproximadamente **5 segundos** e os dados ficaram disponíveis em aproximadamente **13 segundos**. A lista de canais/grupos levou aproximadamente **17 segundos** para completar. Abrir a conversa de Paula levou aproximadamente **9 segundos**; abrir o grupo “Avisos da Direção Geral” levou aproximadamente **8 segundos**.

Para uma experiência comparável ao WhatsApp, a interface deve mostrar o destino imediatamente, reaproveitar dados já carregados e atualizar o conteúdo em segundo plano. O objetivo prático deve ser: feedback visual em menos de 200 ms, lista inicial em até 1–2 s quando houver cache e conteúdo completo em até 2–3 s em rede normal.

## Medições realizadas

| Fluxo | Início observado | Conteúdo utilizável | Tempo aproximado | Estado visual |
|---|---:|---:|---:|---|
| Entrada na lista de conversas — 1ª amostra | 06:58:36 | 06:58:54 | **18 s** | Tela branca antes da lista |
| Entrada na conversa com Paula | 06:59:11 | 06:59:20 | **9 s** | Spinner central até carregar histórico |
| Saída da conversa para a lista | 06:59:30 | imediatamente visível | **< 1 s de renderização** | Lista reapareceu após voltar |
| Entrada na lista de canais/grupos | 06:59:41 | 06:59:58 | **17 s** | Filtros apareceram antes dos cards; spinner persistiu |
| Entrada no grupo “Avisos da Direção Geral” | 07:00:12 | 07:00:20 | **8 s** | Spinner central até o conteúdo vazio do canal |
| Saída do grupo para a lista de canais | 07:00:34 | imediatamente visível | **< 1 s de renderização** | Lista de canais reapareceu |
| Entrada na lista de conversas — 2ª amostra | 07:00:46 | 07:00:59 | **13 s** | Skeleton em ~5 s; dados em ~13 s |

Os tempos são observações de usuário no navegador de teste, não são uma medição de laboratório com rede controlada. Ainda assim, a magnitude é suficiente para caracterizar um gargalo perceptível.

## O que foi validado

A lista de conversas exibiu “Maqueiro”, “Thiago Duarte” e “Paula Souza”. A conversa com Paula carregou o histórico, o campo de mensagem e as mensagens anteriores. A lista de canais exibiu os filtros CCO e Emergência, além dos canais “Avisos da Direção Geral”, “Equipe CCO — Bloco Cirúrgico e Consultórios” e “canal teste”. O grupo “Avisos da Direção Geral” abriu e mostrou o estado vazio do canal e a regra de publicação restrita à Coordenação e Direção.

A saída visual pelo botão de retorno funcionou rapidamente nos dois módulos. O teste mediu abertura e fechamento de tela/grupo; **não foi executada uma operação administrativa de entrar ou sair da associação de membros**, porque isso poderia alterar dados reais de grupo. Portanto, se “entrada e saída” significar associação de membro, esse fluxo ainda precisa de teste controlado em homologação.

## Comparação com uma experiência rápida como WhatsApp

| Indicador de percepção | Aplicação atual | Meta recomendada |
|---|---:|---:|
| Feedback após tocar | spinner ou tela branca | resposta visual em até 200 ms |
| Lista com cache | aproximadamente 13 s | até 1–2 s |
| Lista sem cache | aproximadamente 18 s | até 2–3 s |
| Abertura de conversa | aproximadamente 9 s | cabeçalho imediato; histórico inicial em até 1–2 s |
| Abertura de grupo | aproximadamente 8 s | cabeçalho imediato; mensagens em até 1–2 s |
| Saída visual | inferior a 1 s após retorno | inferior a 300 ms percebidos |

A comparação não significa que o sistema precise copiar a arquitetura do WhatsApp. Significa que o usuário deve perceber resposta imediata, mesmo quando a sincronização com o backend ainda está em andamento.

## Diagnóstico provável

### 1. Carregamento bloqueante antes da renderização

A tela parece aguardar dados remotos antes de exibir uma estrutura utilizável. Isso explica a tela branca na primeira abertura e o spinner prolongado ao abrir conversa ou grupo.

**Melhoria:** renderizar o AppBar, título, botão de voltar e estrutura da tela imediatamente. Carregar histórico, membros e mensagens depois, sem bloquear a navegação.

### 2. Falta de cache local ou cache não aproveitado

A segunda entrada em conversas apresentou skeleton e ainda levou aproximadamente 13 segundos. A aplicação provavelmente refaz consultas completas ou aguarda listeners/queries antes de mostrar a lista.

**Melhoria:** manter em memória a lista de conversas e canais; persistir o último estado localmente; exibir os dados anteriores imediatamente; sincronizar alterações em segundo plano.

### 3. Reconsulta excessiva ao abrir cada tela

A abertura de Paula e do grupo parece iniciar novas consultas para histórico e metadados. O tempo de 8–9 segundos é alto para uma tela que já possui o identificador do destino.

**Melhoria:** carregar primeiro as últimas 20–50 mensagens, paginar mensagens antigas e buscar membros/detalhes em paralelo. Não carregar todo o histórico antes de pintar a tela.

### 4. Ausência de paginação e limites claros

Se a conversa busca o histórico completo ou muitas subcoleções antes de renderizar, o tempo crescerá conforme a base aumenta.

**Melhoria:** usar paginação por cursor, `limit(20)` ou `limit(50)`, ordenação por data e carregamento incremental ao rolar para cima.

### 5. Atualização de estado no retorno

O retorno foi visualmente rápido, mas a lista pode estar sendo reconstruída ou recarregada em vez de preservada.

**Melhoria:** utilizar uma pilha de rotas mantendo a tela anterior viva; evitar destruir e recriar providers/listeners ao abrir detalhes; cancelar listeners somente quando necessário.

## Plano técnico recomendado

### Prioridade 1 — sensação de velocidade

Pintar a tela de destino imediatamente; manter AppBar e navegação disponíveis; trocar tela branca por skeleton leve; mostrar última lista conhecida; usar uma mensagem de erro após timeout em vez de spinner indefinido.

### Prioridade 2 — cache e sincronização

Implementar cache em memória para conversas, canais e última conversa aberta. Persistir somente dados não sensíveis ou aplicar proteção adequada. Ao voltar para uma lista, reutilizar o estado anterior e atualizar em background.

### Prioridade 3 — consultas Firebase/Firestore

Verificar se existem consultas sem índice, múltiplas consultas sequenciais, listeners duplicados, leitura de documentos completos e buscas sem `limit`. Paralelizar consultas independentes e criar índices necessários.

### Prioridade 4 — histórico incremental

Abrir a conversa com as mensagens mais recentes primeiro. Buscar mensagens antigas por paginação. Não esperar membros, contadores, presença, notificações e histórico completo para mostrar a tela.

### Prioridade 5 — mensagens em tempo real

Usar listener apenas para mensagens novas depois que o primeiro lote foi exibido. Evitar refazer toda a coleção a cada nova mensagem. Atualizar somente o item alterado na lista de conversas.

### Prioridade 6 — telemetria

Adicionar medições internas, sem dados sensíveis, para registrar: `tap_to_route`, `route_to_shell`, `shell_to_first_data`, `conversation_first_batch`, `channel_first_batch`, erro, timeout e quantidade de documentos lidos. Separar tempo de rede, tempo do backend e tempo de renderização Flutter.

## Critérios de aceite sugeridos

| Critério | Meta |
|---|---:|
| Clique até mudança visual de rota | ≤ 200 ms |
| AppBar e skeleton visíveis | ≤ 500 ms |
| Lista em cache visível | ≤ 1 s |
| Primeiro lote de mensagens em rede normal | ≤ 2 s |
| Lista de conversas completa em rede normal | ≤ 3 s |
| Lista de canais completa em rede normal | ≤ 3 s |
| Retorno para a lista | ≤ 300 ms percebidos |
| Spinner contínuo sem mensagem | Não permitido após 5 s |
| Erro de carregamento | Mensagem e botão “Tentar novamente” |

## Checklist para o programador

- [ ] Medir o tempo real dentro do app com `Stopwatch` ou timestamps de performance.
- [ ] Renderizar shell da conversa antes da consulta remota.
- [ ] Renderizar a última lista conhecida antes de sincronizar.
- [ ] Implementar cache em memória de conversas e canais.
- [ ] Adicionar paginação do histórico.
- [ ] Limitar o primeiro lote de mensagens.
- [ ] Paralelizar consultas independentes.
- [ ] Remover listeners duplicados.
- [ ] Evitar reconstrução completa da lista após cada mensagem.
- [ ] Configurar índices do Firestore conforme as consultas reais.
- [ ] Mostrar timeout após 5 segundos com opção de tentar novamente.
- [ ] Medir tamanho e quantidade das respostas do backend.
- [ ] Repetir o teste em 4G, Wi-Fi comum e rede lenta.
- [ ] Testar primeira abertura, retorno, cache quente e cache frio.
- [ ] Testar conversa com 10, 100 e 1.000 mensagens.
- [ ] Testar grupo com 5, 50 e 500 membros.
- [ ] Validar associação real de entrar/sair de grupo em ambiente de homologação.

## Conclusão

A aplicação está funcional, mas a abertura de conversas e grupos está significativamente lenta: entre **8 e 18 segundos** nos fluxos medidos. O retorno visual é rápido, porém o carregamento inicial é bloqueante e pouco transparente.

A melhor estratégia para se aproximar do WhatsApp é **não esperar todos os dados para mostrar a tela**. O sistema deve abrir a estrutura imediatamente, exibir cache ou skeleton, carregar somente o primeiro lote de dados e sincronizar o restante em segundo plano. Com cache, paginação, listeners corretos e consultas paralelas, o ganho mais importante será de percepção: o usuário verá resposta instantânea mesmo quando a rede ou o backend demorarem.

**Nota:** nenhuma mensagem, associação de grupo, denúncia ou ocorrência de emergência foi criada ou alterada durante esta medição.


## Teste adicional — envio de mensagem e relógio

**Data/hora do teste:** 8 de setembro de 2026, aproximadamente 10:27 (horário da sessão).  
**Destino observado:** conversa aberta com “Maqueiro”/grupo de 2 participantes, selecionada durante o teste.  
**Mensagem controlada:** `Teste de latência de envio 10:27`.

### Resultado observado

| Etapa | Observação | Tempo aproximado |
|---|---|---:|
| Campo focado e mensagem digitada | Texto apareceu corretamente no campo institucional | imediato após entrada |
| Clique no botão de envio | Mensagem apareceu no balão do remetente | imediato, dentro da atualização da tela |
| Relógio de pendência | Ícone de relógio apareceu ao lado do horário da mensagem | imediatamente após o clique |
| Confirmação de envio | Na checagem seguinte, o relógio havia sido substituído por indicador de confirmação | até aproximadamente 13 s |
| Entrega | Não foi possível confirmar entrega em outro dispositivo nesta sessão | não medido |
| Leitura | Não foi possível confirmar leitura com o segundo participante autenticado | não medido |

### Interpretação do indicador

O **relógio** representa que a mensagem foi criada na interface, mas ainda estava aguardando confirmação do backend ou da sincronização. O relógio não permaneceu indefinidamente: na inspeção seguinte, ele foi substituído por marcas de confirmação. Como a verificação foi feita em intervalos e não com um observador de eventos no backend, o valor seguro é **menos de aproximadamente 13 segundos**, e não um tempo exato de entrega.

O teste confirmou que o fluxo visual de envio funciona: digitação, clique, criação do balão e troca do estado pendente ocorreram sem mensagem de erro. Entretanto, a sessão tinha apenas uma janela autenticada; por isso, não foi possível separar com precisão:

- tempo até o servidor aceitar a mensagem;
- tempo até o destinatário receber a mensagem;
- tempo até o destinatário abrir a conversa;
- tempo até o indicador de leitura ser registrado.

### Medição recomendada para precisão de nível WhatsApp

O programador deve adicionar timestamps no cliente e no backend para cada mensagem:

1. `t_input_start`: usuário começa a digitar;
2. `t_send_click`: usuário toca em enviar;
3. `t_local_render`: balão aparece localmente;
4. `t_server_ack`: backend confirma a gravação;
5. `t_recipient_received`: segundo cliente recebe o evento;
6. `t_read`: destinatário abre ou marca como lida.

Com esses pontos, os indicadores serão:

| Indicador | Fórmula |
|---|---|
| Latência de envio | `t_server_ack - t_send_click` |
| Latência percebida | `t_local_render - t_send_click` |
| Latência de entrega | `t_recipient_received - t_server_ack` |
| Latência até leitura | `t_read - t_server_ack` |

### Critérios sugeridos para o envio

| Estado | Meta recomendada |
|---|---:|
| Balão local após tocar em enviar | ≤ 200 ms |
| Remoção do relógio / confirmação do servidor | ≤ 1 s em rede normal |
| Recebimento no segundo dispositivo | ≤ 2 s em rede normal |
| Atualização do status de leitura | ≤ 2 s após abrir a conversa |
| Falha ou timeout | informar em até 5 s, com opção de reenviar |

### Recomendação de implementação

A mensagem pode aparecer imediatamente no balão com um identificador local e estado `sending`, sem aguardar o backend. Depois, o listener deve trocar o estado para `sent`, `delivered` ou `read`. Em caso de falha, o relógio deve virar `failed` com botão de reenvio. Também é recomendável usar gravação otimista, fila local para mensagens offline, confirmação idempotente para evitar duplicatas e listener incremental somente para novos eventos.

**Conclusão do teste de envio:** o envio visual funcionou e o relógio foi substituído por confirmação em até aproximadamente 13 segundos na observação realizada. O tempo está acima da meta ideal para uma experiência semelhante ao WhatsApp e precisa de medição com timestamps no backend e dois dispositivos para identificar onde está o atraso. Nenhuma mensagem adicional foi criada além da mensagem controlada registrada acima.
