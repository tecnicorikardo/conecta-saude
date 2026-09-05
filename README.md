# Conecta Saúde — Plataforma Institucional SUS

Plataforma institucional de comunicação interna para ambiente hospitalar do SUS, integrando os centros **CCDTI** (Centro Carioca de Diagnóstico e Tratamento por Imagem), **CCO** (Centro Carioca do Olho), **CCE** (Centro Carioca de Especialidades) e a **Direção Geral**.

Comunicação profissional, organizada, segura e com rastreabilidade — mantendo estrita governança hierárquica e isolamento setorial entre os centros de atendimento.

---

## 🌟 Recursos Implementados

1. **Isolamento Institucional e Governança por Nível**:
   - **Nível 1 (Direção Geral)**: Acesso irrestrito a todos os centros, painel executivo de indicadores, gestão de funcionários, auditoria de logs e triagem de ouvidoria.
   - **Nível 2 (Coordenação Médica/Cirúrgica)**: Gestão de canais do seu setor, publicação de comunicados oficiais e acionamento de emergências.
   - **Nível 3 (Supervisão)**: Supervisão operacional de equipes e canais permitidos.
   - **Nível 4 (Funcionário)**: Comunicação estritamente restrita ao seu próprio centro (CCDTI, CCO ou CCE), comunicados gerais e canal de emergência.

2. **Canais Oficiais & Setoriais**:
   - Isolamento de canais por sigla (`CCDTI`, `CCO`, `CCE`). Colaboradores de um setor não acessam canais de outros setores, com exceção da Direção Geral.
   - Canal de Avisos da Direção Geral aberto a toda a rede.
   - Canal Prioritário de Emergência com disparo de alertas em tempo real.

3. **Comunicados Oficiais com Confirmação de Leitura**:
   - Publicação exclusiva por Lideranças e Coordenações.
   - Níveis de prioridade: Normal, Alta e 🚨 Urgente.
   - Confirmação formal de leitura por colaborador com métrica de taxa de leitura institucional.

4. **Central de Emergência e Ramais Hospitalares**:
   - Ramais diretos imediatos para Tomografia/CCDTI, Bloco Cirúrgico/CCO, Regulação/CCE e Plantão Geral.
   - Protocolos padronizados SUS: Código Amarelo, Código Vermelho e Código Roxo.
   - Disparo prioritário de Alerta Vermelho na rede hospitalar.

5. **Conversas e Mensagens Seguras**:
   - Mensagens diretas entre profissionais respeitando hierarquia.
   - Suporte a reprodução de mensagens de áudio institucionais gravadas.
   - Exclusão com soft-delete e ferramenta de denúncia para condutas impróprias.

6. **Gestão de Funcionários, Auditoria e Ouvidoria**:
   - Cadastro e ativação/desativação de funcionários pela Direção Geral.
   - Trilha imutável de logs de auditoria com IP, módulo, ação e data/hora.
   - Triagem e resolução de ocorrências anônimas de integridade e ética.

---

## 🚀 Execução no Ambiente

- **Ambiente**: Node.js 22
- **Porta**: 3000
- **Frontend**: React 19, TypeScript, Vite, Tailwind CSS v4, Lucide Icons
- **Scripts**:
  ```bash
  npm run dev     # Inicia o servidor Vite na porta 3000 (host 0.0.0.0)
  npm run build   # Compilação estática de produção em dist/
  npm run lint    # Verificação de tipos TypeScript
  ```

---

## 👥 Papéis Pré-Configurados para Testes

O seletor rápido no topo da aplicação permite alternar instantaneamente entre os perfis institucionais:
- **Dr. Carlos Eduardo Mendes** (Direção Geral — Nível 1)
- **Dra. Juliana Moreira** (Coord. Médica CCDTI — Nível 2)
- **Lucas Ribeiro** (Técnico Radiologia CCDTI — Nível 4)
- **Dr. Roberto Vasconcelos** (Coord. Cirúrgico CCO — Nível 2)
- **Paula Souza** (Técnica Oftalmológica CCO — Nível 4)
- **Dra. Beatriz Castro** (Coord. Ambulatorial CCE — Nível 2)
- **Gabriel Mendes** (Assistente Regulação CCE — Nível 4)
