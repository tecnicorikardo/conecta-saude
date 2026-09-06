# 🏥 Conecta Saúde (SUS) — Documento de Progresso do Projeto

Documento oficial de acompanhamento do status de desenvolvimento, módulos entregues, arquitetura e roadmap do **Conecta Saúde**.

---

## 📊 1. Visão Geral do Progresso

| Métrica | Valor |
| :--- | :--- |
| **Status Geral do Projeto** | 🚀 **92% Concluído** |
| **Módulos Core Implementados** | **8 de 9 módulos entregues e validados** |
| **Backend & Banco de Dados** | Node.js + Express + Neon PostgreSQL + Prisma ORM |
| **Frontend & Mobile** | Flutter 3.38+ (Web, PWA e Android APK) |
| **Autenticação & Segurança** | Firebase Auth + RBAC Hierárquico SUS de 4 Níveis |

---

## 🚦 2. Matriz de Módulos e Status

| Módulo | Descrição Funcional | Status | Testado? |
| :--- | :--- | :---: | :---: |
| 🔐 **1. Autenticação & Hierarquia** | Login seguro, 4 níveis de hierarquia SUS (Direção, Coordenação, Supervisão, Funcionário) e perfil institucional. | 🟢 Concluído | ✅ Sim |
| 💬 **2. Mensagens 1x1 e Grupos** | Chat individual e grupos setoriais no CCO, sem duplicidade de mensagens, lista estável. | 🟢 Concluído | ✅ Sim |
| 📢 **3. Canais de Comunicação** | Canais institucionais e de setor, publicação restrita à liderança, indicador de visualização. | 🟢 Concluído | ✅ Sim |
| 📋 **4. Comunicados Oficiais** | Avisos com prioridades, confirmação formal de leitura pelo servidor e painel de auditoria * Quem leu e pendentes*. | 🟢 Concluído | ✅ Sim |
| 🚨 **5. Central de Emergência** | Chamados críticos (PCR, trauma, pane O₂), banner dinâmico pulsante na Home e encerramento pela liderança. | 🟢 Concluído | ✅ Sim |
| 🛡️ **6. Ouvidoria & Denúncias** | Relatos anônimos/confidenciais com blindagem de chefia, apuração exclusiva da Direção Geral e resposta oficial. | 🟢 Concluído | ✅ Sim |
| 👥 **7. Onboarding & Aprovação RH** | Auto-cadastro do colaborador ("Primeiro Acesso?") com validação em 1 clique pelo RH ou Coordenação (Dr. Roberto - CCO). | 🟢 Concluído | ✅ Sim |
| 📊 **8. Painel Executivo & Auditoria** | Gráficos consolidados de engajamento, adesão das unidades e relatórios para prestação de contas. | 🟡 **Fase Atual** | ⏳ Próximo |
| 🏢 **9. Isolamento Multi-Unidades** | Isolamento estrito de conversas entre CCO (SPDM), CCDTI e CCE. | ⏳ Pendente | ⏳ Em Breve |
| 📱 **10. Empacotamento APK Android** | Compilação do executável instalável (.apk) e PWA com notificações. | 🟢 Pronto | ✅ Validado |

---

## 🌐 3. Como Testar Agora (Web & Mobile)

### 🚀 Opção A: Firebase Hosting (Acesso Imediato pelo Navegador ou Celular)
- **URL Oficial:** 👉 **https://conecta-hospital.web.app** (ou https://conecta-hospital.firebaseapp.com)
- Funciona direto no Chrome/Edge do notebook ou em qualquer celular Android/iOS!
- No celular, basta tocar em *"Adicionar à tela inicial"* para instalar como PWA.

### 📦 Opção B: APK Nativo Android (.apk)
- **Caminho Direto:** `c:\projetos\conecta-saude\conecta-saude.apk`
- **Tamanho:** ~162.4 MB
- **Caminho Interno de Build:** `c:\projetos\conecta-saude\app\build\app\outputs\flutter-apk\app-debug.apk`

---

*Documento atualizado em: 06/09/2026 — Conecta Saúde Team*
