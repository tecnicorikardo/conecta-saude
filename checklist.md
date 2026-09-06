# 📋 Checklist Geral de Testes & Funcionalidades — Conecta Saúde (SUS)

Este documento centraliza o histórico do que **já foi validado**, o que está **em teste no momento** e o que **falta testar/desenvolver**. Sempre será consultado e atualizado para mantermos o alinhamento total do projeto.

---

## 🏛️ Governança e Regras de Negócio (Base do Projeto)
- **Ecossistema SUS**: Gestão compartilhada entre diferentes organizações parceiras (ex: **CCO** gerido por SPDM/PAIS; **CCDTI** e **CCE** por outras gestoras).
- **Hierarquia Funcional**:
  - **Nível 1 (Direção Geral - Carlos Eduardo)**: Visão global de todas as unidades, canais, comunicados e auditoria.
  - **Nível 2 (Coordenação - Dr. Roberto)**: Gestão de equipe, publicação de canais/comunicados e aprovação de colaboradores.
  - **Nível 3 (Supervisão)**: Apoio operacional e acompanhamento de turno.
  - **Nível 4 (Funcionário - Paula Souza, Thiago Duarte)**: Leitura de comunicados, confirmação formal e chat interno.
- **Isolamento de Conversas**: Colaboradores do CCO interagem apenas dentro do CCO e com a Direção Geral.
- **Onboarding Futuro**: Auto-cadastro pelo funcionário com aprovação presencial do **RH da unidade** (ou Coordenador como reserva).

---

## ✅ 1. O que JÁ FOI TESTADO E APROVADO

| Módulo / Funcionalidade | Descrição do Teste | Status |
| :--- | :--- | :---: |
| **Autenticação & Perfis** | Login com diferentes perfis (Direção, Coordenador, Funcionária) e carregamento das permissões corretas. | 🟢 Aprovado |
| **Conversas Individuais (Chat 1x1)** | Troca de mensagens entre Coordenador (Dr. Roberto) e Funcionária (Paula Souza). | 🟢 Aprovado |
| **Grupos de Mensagens** | Criação de grupos no CCO, inclusão de membros e envio de mensagens coletivas. | 🟢 Aprovado |
| **Correção de Mensagens Duplicadas** | Eliminação do envio/exibição duplicada em chats e grupos. | 🟢 Aprovado |
| **Estabilidade da Lista de Conversas** | Ordenação consistente por última mensagem sem saltos/trocas involuntárias de posição. | 🟢 Aprovado |
| **Canais Institucionais (Publicação)** | Permissão restrita: apenas Coordenação e Direção podem criar canais e publicar avisos. | 🟢 Aprovado |
| **Canais (Visualização de Leitura)** | Registro no backend e exibição para a liderança de quem visualizou a postagem do canal (*"Paula visualizou"*). | 🟢 Aprovado |
| **Badges em Tempo Real (Conversas e Canais)** | Ponto vermelho e contadores dinâmicos atualizados via polling (a cada 3-4s) na barra inferior e no card da Home. | 🟢 Aprovado |
| **Correção de Auto-Contato** | O próprio usuário logado não aparece mais na lista de contatos ao clicar em "Nova Conversa", evitando erro de duplicação. | 🟢 Aprovado |
| **Comunicados Institucionais (Criação)** | Dr. Roberto ou Carlos criam comunicado oficial (Normal, Alta ou Urgente) com botão flutuante `+ Novo Comunicado`. | 🟢 Aprovado |
| **Notificação de Comunicados** | Ponto vermelho/badge aparece na hora para Paula/Thiago, **sem** aparecer para o próprio autor do comunicado. | 🟢 Aprovado |
| **Confirmação de Leitura Formal** | Paula abre o comunicado e clica em **"CONFIRMAR LEITURA DO COMUNICADO"** ➡️ Status muda para *"✓ Leitura Confirmada"* e o badge zera. | 🟢 Aprovado |
| **Painel de Auditoria da Liderança** | Coordenador/Diretor clica em **"Ver quem já leu e pendentes"** e visualiza a lista: Paula em *Confirmados* (com data/hora) e demais em *Pendentes*. | 🟢 Aprovado |
| **Central de Emergência & Protocolo Vermelho** | Disparo de emergência (PCR, pane, trauma), banner dinâmico pulsante na Home, tela limpa no dia a dia e encerramento pela liderança. | 🟢 Aprovado |

---

| **Canal de Denúncias Anônimas & Ouvidoria** | Envio confidencial/100% anônimo de relatos pelo colaborador (Assédio, Conduta, Risco Hospitalar, Fraude, Outro) com total blindagem. | 🟢 Aprovado |
| **Painel de Apuração da Direção Geral** | Acesso restrito à Direção Geral (Carlos Eduardo) para analisar, mudar status (Em Análise, Resolvido, Arquivado), emitir parecer e acompanhar resoluções. | 🟢 Aprovado |

---

## 🟡 2. O que ESTÁ SENDO TESTADO AGORA (Fase Atual)

| Módulo / Funcionalidade | Cenário a Validar | Status |
| :--- | :--- | :---: |
| 👥 **Esteira de Auto-Cadastro & Aprovação RH** | Cadastro pelo funcionário (matrícula SUS, unidade, cargo) e aprovação instantânea pelo RH da unidade (ou Coordenação se não houver RH). | 🟡 Em Preparação |

---

## ⏳ 3. O que FALTA TESTAR / PRÓXIMOS MÓDULOS

| Módulo / Funcionalidade | Descrição do Fluxo Previsto | Prioridade |
| :--- | :--- | :---: |
| 👥 **Esteira de Auto-Cadastro & Aprovação RH** | Tela de cadastro pelo funcionário com matrícula SUS e fila de aprovação em 1 clique para o RH da unidade / Coordenador. | 🟡 Alta |
| 📊 **Painel Executivo & Relatórios da Direção** | Relatórios consolidados de leitura, gráficos de adesão das unidades e logs de auditoria para prestação de contas. | 🟡 Média |
| 🏢 **Isolamento Multi-Unidades (CCDTI e CCE)** | Testes de isolamento estrito de conversas com contas de testes das outras gestoras parceiras. | 🟡 Média |
| 📱 **Gerar APK Android / Build de Produção** | Compilação do executável final do aplicativo móvel para instalação nos aparelhos dos funcionários. | 🟢 Final |

---

*Última atualização: 06/09/2026 — Antigravity Pair Programming*
