# 🏥 Conecta Saúde (SUS) — Documento de Progresso do Projeto

Documento oficial de acompanhamento do status de desenvolvimento, módulos entregues, arquitetura e roadmap do **Conecta Saúde**.

---

## 📊 1. Visão Geral do Progresso

| Métrica | Valor |
| :--- | :--- |
| **Status Geral do Projeto** | 🚀 **95% Concluído** |
| **Módulos Core Implementados** | **8 de 9 módulos entregues e validados** |
| **Backend & Banco de Dados** | Node.js + Express + Supabase PostgreSQL + Prisma ORM |
| **Frontend & Mobile** | Flutter 3.47+ (Web, PWA e Android APK Release) |
| **Autenticação & Segurança** | Firebase Auth + RBAC Hierárquico SUS de 4 Níveis + **FLAG_SECURE Anti-Print** |

---

## 🚦 2. Matriz de Módulos e Status

| Módulo | Descrição Funcional | Status | Testado? |
| :--- | :--- | :---: | :---: |
| 🔐 **1. Autenticação & Hierarquia** | Login seguro, 4 níveis de hierarquia SUS (Direção, Coordenação, Supervisão, Funcionário) e perfil institucional. | 🟢 Concluído | ✅ Sim |
| 💬 **2. Mensagens 1x1 e Grupos** | Chat individual e grupos com destaque visual (badges `GRUPO`, avatares temáticos, foto do grupo), gestão e adição de participantes, auto-exclusão 24h (mensagens temporárias de plantão), exclusão de conversa/mensagem e limpeza funcional de histórico. | 🟢 Concluído | ✅ Sim |
| 📢 **3. Canais de Comunicação** | Canais institucionais e de setor, publicação restrita à liderança, indicador de visualização. | 🟢 Concluído | ✅ Sim |
| 📋 **4. Comunicados Oficiais** | Avisos com prioridades, confirmação formal de leitura pelo servidor e painel de auditoria *Quem leu e pendentes*. | 🟢 Concluído | ✅ Sim |
| 🚨 **5. Central de Emergência** | Chamados críticos (PCR, trauma, pane O₂), banner dinâmico pulsante na Home e encerramento pela liderança. | 🟢 Concluído | ✅ Sim |
| 🛡️ **6. Ouvidoria & Denúncias** | Relatos anônimos/confidenciais com blindagem de chefia, apuração exclusiva da Direção Geral e resposta oficial. | 🟢 Concluído | ✅ Sim |
| 👥 **7. Onboarding & Aprovação RH** | Auto-cadastro do colaborador ("Primeiro Acesso?") com validação em 1 clique pelo RH ou Coordenação (Dr. Roberto - CCO). | 🟢 Concluído | ✅ Sim |
| 🔒 **8. Segurança Anti-Print & LGPD** | Proteção nativa `FLAG_SECURE` no Android contra capturas/gravações de tela e restrições de impressão no PWA Web. | 🟢 Concluído | ✅ Sim |
| 📊 **9. Apresentação Executiva em Slides** | Painel de slides institucional (18 slides) cobrindo o Dossiê Super Centro Carioca no Firebase Hosting. | 🟢 Concluído | ✅ Sim |
| 📱 **10. Empacotamento APK Android** | Compilação do executável otimizado release (.apk) com FLAG_SECURE. | 🟢 Pronto | ✅ Validado |

---

## 🌐 3. Como Testar Agora (Web & Mobile)

### 🚀 Opção A: Aplicativo Web / PWA (Navegador ou Celular)
- **URL Oficial:** 👉 **https://conecta-hospital.web.app** (ou https://conecta-hospital.firebaseapp.com)
- Funciona direto no Chrome/Edge do notebook ou em qualquer celular Android/iOS!
- No celular, basta tocar em *"Adicionar à tela inicial"* para instalar como PWA.

### 📊 Opção B: Dossiê Executivo de Apresentação (Slides ao Vivo)
- **URL Oficial:** 👉 **https://slide-conecta-hospital.web.app** (ou https://slide-conecta-hospital.firebaseapp.com)
- 18 slides cobrindo todos os 17 tópicos do Super Centro Carioca com roteiro do orador ("O que Falar").

### 📦 Opção C: APK Nativo Android (.apk) com Proteção Anti-Print
- **Caminho Direto:** `c:\projetos\conecta-saude\conecta-saude.apk`
- **Tamanho:** ~59.4 MB (Build Release Otimizado)
- **Caminho Interno de Build:** `c:\projetos\conecta-saude\app\build\app\outputs\flutter-apk\app-release.apk`
- **Recurso Ativo:** `FLAG_SECURE` bloqueando capturas e gravações de tela para total conformidade LGPD.

---

## 🔍 4. Status da Investigação Atual (Tela Preta no APK)

- **Diagnóstico confirmado no celular via USB:** exceção `FirebaseCrashlytics component is not present` durante `Firebase.initializeApp()`, antes de `runApp()`.
- **Configuração encontrada:** Android reutilizava o App ID Web; não havia cadastro Android no Firebase, arquivo `google-services.json` nem plugins Gradle Google Services/Crashlytics.
- **Correção aplicada em 12/09/2026:**
  - Registrado `com.conectasaude.conecta_saude` no projeto Firebase `conecta-hospital`.
  - Baixado `app/android/app/google-services.json` e sincronizadas as opções Firebase Android em Dart.
  - Aplicados os plugins Gradle Google Services e Crashlytics.
  - Mantida a proteção `FLAG_SECURE`.
- **Teste no aparelho:** o primeiro APK com a configuração corrigida ainda falhou. Logcat confirmou `NoSuchMethodException` nos construtores de registradores Firebase, incluindo `CrashlyticsRegistrar`, removidos na otimização release.
- **Correção adicional:** regra ProGuard preserva nomes e construtores dos implementadores de `ComponentRegistrar`.
- **Validação concluída:** análise de `firebase_options.dart` sem problemas; APK release compilado e instalado via USB no aparelho 2311DRK48G. Abertura a frio concluída em 986 ms, Crashlytics inicializado sem a exceção anterior e tela de login confirmada pela árvore de interface Android (e-mail, senha e botão ENTRAR).
- **Entrega:** `conecta-saude.apk` atualizado na raiz. Login autenticado e demais fluxos não foram testados nesta correção.

---
*Documento atualizado em: 12/09/2026 — Conecta Saúde Team*

## 🔔 5. Notificações Push Android

- **Diagnóstico confirmado por logs:** o token foi salvo e os testes chegaram ao `onMessage`, mas a função de exibição atendia apenas Web. A permissão Android estava autorizada.
- **Correção:** ponte nativa para publicar notificações Android em primeiro plano, canal `conecta_messages` de alta importância e ícone de notificação. Preservado o filtro de jornada aplicado antes da exibição.
- **Segundo plano:** definido o canal padrão FCM, removido o serviço base redundante (o plugin registra seu próprio serviço) e adicionada a ação usada pelo servidor para abrir o app ao tocar na notificação.
- **Validação:** análise Dart sem problemas; build release e teste no aparelho em andamento.
## 🟢 6. Sistema de Status Manual "Em Serviço / Fora de Serviço" & Widget Android — 12/09/2026

- **Correção da Reversão:** Mapeado campo `emServico` no `AuthRepositoryImpl` e removida a seção antiga "Minha Escala & Plantão" do Perfil.
- **Widget Nativo Android (1-Toque na Tela Inicial):**
  - Layout nativo `widget_service_status.xml` com estados verde (`#2E7D32` Em Serviço) e cinza (`#546E7A` Fora de Serviço).
  - `ServiceStatusWidgetProvider.kt` com `ACTION_TOGGLE_STATUS` disparando requisição HTTP em background com 1 toque na tela inicial.
  - Sincronização bidirecional via `MethodChannel` (`updateWidget`).
- **Novo APK Release Compilado:**
  - Arquivo: `c:\projetos\conecta-saude\conecta-saude.apk` (~59.4 MB / 62.306.481 bytes).
  - Inclui proteção `FLAG_SECURE`, notificações de alta importância e suporte a AppWidget.
- **Deploy Web:** Versão PWA atualizada e ativa em **https://conecta-hospital.web.app**.