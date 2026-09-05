# Conecta Saúde — Progresso do Projeto
> **Última atualização:** 05/09/2026 às 11:02 (horário de Brasília)
> **Status geral:** 🟢 Em desenvolvimento ativo — 85% completo

---

## 📊 RESUMO EXECUTIVO

| Fase | Descrição | Status |
|------|-----------|--------|
| Core / Infraestrutura | Flutter base, tema, rotas, Firebase | ✅ 100% |
| Identidade Visual | Paleta SUS, tipografia, logo | ✅ 100% |
| Fase 1 — Auth | Login, logout, recuperação de senha | ✅ 100% |
| Fase 2 — Usuários | Funcionários (lista, criar, editar, ativar/desativar), Perfil | ✅ 100% |
| Fase 3 — Chat | Conversas, mensagens, áudio, swipe-to-reply | ✅ 100% |
| Fase 4 — Canais e Comunicados | Canais por centro (CCD/CCO/CCE), Comunicados | ✅ 100% |
| Fase 5 — Administração | Painel admin, Denúncias, Auditoria | ✅ 100% |
| Fase 5b — Emergência e Notificações | Tela de emergência, Central de Notificações | ✅ 100% |
| Banco de Dados (Neon) | PostgreSQL nuvem, Prisma schema, Seed CCDTI/CCO/CCE | ✅ 100% |
| Fase 6 — HTTP Real (Dio) | Integração com API backend real | 🔄 Próxima |
| Fase 7 — FCM | Notificações push Firebase | ⏳ Pendente |
| Fase 8 — Testes e Segurança | Vitest backend, testes Flutter | ⏳ Pendente |
| Fase 9 — Polimento | Dark mode, skeleton, acessibilidade | ⏳ Pendente |

---

## ✅ CONCLUÍDO

### 🎨 Identidade Visual
- [x] Paleta de cores `AppColors` — azul SUS `#1565C0` completo
- [x] Dark mode: fundo `#0A1628`, surface `#102040`
- [x] Cores de emergência, hierarquia (Direção/Coord/Supervisão/Funcionário), status
- [x] Tipografia Inter via Google Fonts (400/500/600/700)
- [x] Logo `logo_sus.png` com fundo transparente em `assets/images/`

---

### 📱 Flutter — Core
| Arquivo | Status |
|---------|--------|
| `pubspec.yaml` | ✅ Firebase, Riverpod, GoRouter, Dio, record, audioplayers, uuid, intl |
| `main.dart` | ✅ ProviderScope, tema light/dark, Firebase init, SharedPreferences |
| `AppColors` | ✅ Paleta SUS completa light + dark |
| `AppTheme` | ✅ ThemeData Material 3 — Flutter 3.47 compatível (CardThemeData, DialogThemeData) |
| `AppConstants` | ✅ Hierarquia, paginação, timeouts, janela de edição |
| `AppRoutes` | ✅ 15 rotas nomeadas (incluindo `/audit-logs`) |
| `AppRouter` | ✅ GoRouter — todas as rotas registradas + extra (ConversationEntity) |
| `firebase_options.dart` | ✅ Projeto `conecta-hospital` configurado |
| `SplashScreen` | ✅ Logo SUS, animação fade+slide, loading indicator |
| `HierarchyBadge` | ✅ Widget global de badge de hierarquia colorido |
| `StatusBadge` | ✅ Widget global de badge ativo/inativo |
| `flutter analyze` | ✅ **0 issues** |

---

### 🔐 Feature: Auth
| Arquivo | Status |
|---------|--------|
| `UserEntity` | ✅ isDirecao, isCoordenacao, hierarquiaNome, setorNome |
| `AuthRepositoryImpl` | ✅ Firebase Auth → ID Token → backend `/auth/verify` |
| `LoginPage` | ✅ Card compacto, sem scrollbar desktop, fundo branco, logo SUS |
| `LoginForm` | ✅ Campos estilizados, botão institucional |
| `ForgotPasswordPage` | ✅ Formulário + estado de sucesso |
| `currentUserProvider` | ✅ StreamProvider — usuário autenticado global |

---

### 🏠 Feature: Home
| Arquivo | Status |
|---------|--------|
| `HomePage` | ✅ AppBar logo SUS, avatar, saudação gradiente, grid de atalhos, comunicados recentes, banner emergência, bottom nav |

---

### 💬 Feature: Chat
| Arquivo | Status |
|---------|--------|
| `ConversationsPage` | ✅ Lista estilo WhatsApp, busca, shimmer, empty state, badge, ticks de status |
| `ChatPage` | ✅ Separadores de data, scroll automático, swipe-to-reply, edição, reply |
| `MessageBubble` | ✅ Bolhas SUS, context menu long-press, áudio, mensagem apagada |
| `ChatInputBar` | ✅ Campo expansível, emoji, anexo, mic↔send, banners reply/edição |
| `AudioPlayerWidget` | ✅ Play/pause, waveform 24 barras, progresso |
| `AudioRecorderWidget` | ✅ Timer, amplitude animada, ponto vermelho piscante |

---

### 📢 Feature: Canais (Fase 4)
| Arquivo | Status |
|---------|--------|
| `channel_entity.dart` | ✅ `centroTag` (CCD/CCO/CCE/GERAL/EMERGENCIA), `isEmergencia` getter |
| `channels_provider.dart` | ✅ `ChannelTab` enum — CCD/CCO/CCE/Emergência/Todos |
| `channels_page.dart` | ✅ Abas: CCD (esq) / CCO (meio) / CCE (dir) / 🚨 Emergência / Todos |
| Mock channels | ✅ 9 canais distribuídos pelos 3 centros |

---

### 📣 Feature: Comunicados (Fase 4)
| Arquivo | Status |
|---------|--------|
| `announcement_entity.dart` | ✅ `AnnouncementPriority` enum, `percentualLeitura` getter |
| `announcements_provider.dart` | ✅ `AnnouncementFilter` (Todos/NãoLidos/Urgentes), StateNotifier |
| `announcements_page.dart` | ✅ Busca, filtros, cards com badges de prioridade, FAB coordenação+ |
| `announcement_detail_page.dart` | ✅ Conteúdo, barra de progresso de leitura, confirmar leitura |
| `announcement_form_dialog.dart` | ✅ Modal: título, prioridade, mensagem — validações |

---

### 👥 Feature: Funcionários (Fase 2)
| Arquivo | Status |
|---------|--------|
| `employees_page.dart` | ✅ Lista com busca, filtros hierarquia/setor/status, paginação, pull-to-refresh |
| `employee_detail_page.dart` | ✅ Perfil completo, ativar/desativar com dialog, editar |
| `employee_form_dialog.dart` | ✅ Criar/editar: nome, email, senha, cargo, hierarquia, setor |
| `employees_provider.dart` | ✅ StateNotifier com filtros, paginação, updateLocally |
| `employees_repository_impl.dart` | ✅ API real + fallback com 10 usuários mock (CCDTI/CCO/CCE) |

---

### 👤 Feature: Perfil
| Arquivo | Status |
|---------|--------|
| `profile_page.dart` | ✅ Avatar, nome, cargo, badge hierarquia, email, setor, seletor de tema, logout com confirmação |

---

### 🏥 Estrutura Institucional (3 Centros)
| Item | Status |
|------|--------|
| `seed.ts` | ✅ 4 centros: Direção Geral, CCDTI, CCO, CCE — 11 usuários |
| Isolamento de comunicação | ✅ Backend: cross-center bloqueado, Direção acessa tudo |
| `sectors_repository_impl.dart` | ✅ Fallback: CCDTI, CCO, CCE, Direção Geral hardcoded |
| `employees_repository_impl.dart` | ✅ Fallback: 10 usuários distribuídos pelos centros |

---

### 🛡️ Feature: Administração (Fase 5)
| Arquivo | Status |
|---------|--------|
| `administration_page.dart` | ✅ Métricas (usuários, comunicados, denúncias), barras por centro, ações rápidas, banners de alerta |
| `reports_page.dart` | ✅ Lista de denúncias, filtros por status, bottom sheet com ações (Em Análise/Resolvido/Arquivado) |
| `audit_logs_page.dart` | ✅ Timeline visual com ícones/cores por tipo, filtros, IP do ator, timestamp relativo |
| Controle de acesso | ✅ Administração e Auditoria restritos à Direção Geral |

---

### 🚨 Feature: Emergência e Notificações (Fase 5b)
| Arquivo | Status |
|---------|--------|
| `emergency_page.dart` | ✅ Protocolo de emergência com visual pulsante, canal de emergência direto, ramais oficiais CCDTI/CCO/CCE e emissão de alerta para Coordenação/Direção |
| `notifications_page.dart` | ✅ Central de notificações organizada por categorias (emergência, comunicado, mensagem, sistema), marcar como lida, limpar histórico e redirecionamento |

---

### 🖥️ Backend — Node.js + TypeScript
| Módulo | Status |
|--------|--------|
| `authenticate.ts` | ✅ Firebase ID Token → banco → valida ativo |
| `requireHierarquia()` | ✅ Autorização por nível |
| `auth` module | ✅ POST /auth/verify, GET /me, PATCH /fcm-token |
| `users` module | ✅ GET/POST/PUT/PATCH (com Firebase Auth sync) |
| `sectors` module | ✅ GET/POST/PUT |
| `conversations` module | ✅ GET/POST + mensagens |
| `messages` module | ✅ PUT edição 5min, DELETE soft, moderação Direção |
| `announcements` module | ✅ GET/POST, confirmação leitura, stats % |
| `reports` module | ✅ POST denúncia, GET/PATCH admin |
| `audit` module | ✅ GET logs (Direção apenas) |
| `schema.prisma` | ✅ 12 entidades completas |
| `seed.ts` | ✅ CCDTI/CCO/CCE/Direção — 11 usuários, canais, comunicados |
| `tsc --noEmit` | ✅ **0 erros** |

---

## ❌ O QUE FALTA IMPLEMENTAR

### Fase 6 — Integração HTTP Real (Dio)
- [ ] `HttpService` — Dio com interceptor Bearer token automático
- [ ] Refresh de token ao expirar
- [ ] Substituir mocks: Auth, Chat, Canais, Comunicados, Funcionários
- [ ] Tratamento de erros de rede (sem internet, timeout, 401, 403, 500)
- [ ] Indicador de conectividade global

---

### Fase 7 — FCM — Notificações Push
- [ ] Solicitar permissão no Android 13+ e iOS
- [ ] Capturar FCM token e enviar ao backend (`PATCH /auth/fcm-token`)
- [ ] Foreground: exibir SnackBar / banner in-app
- [ ] Background/fechado: deep link para tela certa
- [ ] Canal de emergência com prioridade máxima (heads-up notification)

---

### Fase 8 — Testes e Segurança
- [ ] Testes de autorização backend (Vitest):
  - [ ] Funcionário → setor de outro → 403
  - [ ] Funcionário → endpoint admin → 403
  - [ ] Usuário inativo → qualquer rota → 403
  - [ ] Editar/excluir mensagem de outro → 403
- [ ] Firebase App Check (proteção anti-abuse)
- [ ] Testes unitários providers Flutter (Riverpod)
- [ ] Revisão de escalação de privilégios

---

### Fase 9 — Polimento e Acessibilidade
- [ ] Dark mode verificado em todas as telas
- [ ] Skeleton loading (shimmer) nas listas
- [ ] Empty states padronizados em todas as telas
- [ ] Microinterações (confirmação de leitura, envio de mensagem)
- [ ] Responsividade tablet e desktop (LayoutBuilder)
- [ ] Acessibilidade: contraste WCAG AA, `Semantics`, toque mínimo 48px
- [ ] Modal de denúncia acessível pelo usuário no chat
- [ ] Melhorias visuais na tela de login (solicitadas, diferidas)

---

## 📋 CONFIGURAÇÕES PENDENTES (ambiente de produção)
| Item | Status |
|------|--------|
| `google-services.json` do Firebase Console | ⬜ Pendente |
| `app/android/app/google-services.json` | ⬜ Pendente |
| `firebase_options.dart` com `appId` Android real | ⬜ Pendente |
| `backend/.env` — `DATABASE_URL` real (Supabase/Neon) | ⬜ Pendente |
| `backend/.env` — Firebase Admin SDK (service account JSON) | ⬜ Pendente |
| `npm run db:migrate && npm run db:seed` | ⬜ Pendente |

---

## 📁 ESTRUTURA ATUAL DO PROJETO

```
conecta-saude/
├── app/                              ← Flutter (Clean Architecture + Riverpod)
│   ├── android/                      ← ✅ Gerado
│   ├── web/                          ← ✅ Habilitado para preview
│   ├── assets/images/logo_sus.png    ← ✅ Logo SUS com transparência
│   └── lib/
│       ├── core/
│       │   ├── constants/            ← AppConstants ✅
│       │   ├── errors/               ← Failures ✅
│       │   ├── routes/               ← AppRouter (15 rotas) ✅
│       │   ├── services/             ← HttpService (Dio) ✅
│       │   ├── theme/                ← AppColors (SUS), AppTheme ✅
│       │   └── widgets/              ← SplashScreen, HierarchyBadge, StatusBadge ✅
│       └── features/
│           ├── auth/                 ← ✅ Login completo com visual SUS
│           ├── home/                 ← ✅ Dashboard com logo SUS no AppBar
│           ├── chat/                 ← ✅ Chat completo estilo WhatsApp + áudio
│           ├── channels/             ← ✅ Canais por centro (CCD/CCO/CCE)
│           ├── announcements/        ← ✅ Comunicados completo (criar, detalhe, filtros)
│           ├── emergency/            ← 🔄 Em implementação
│           ├── notifications/        ← 🔄 Em implementação
│           ├── profile/              ← ✅ Perfil funcional com troca de tema
│           ├── employees/            ← ✅ Lista, criar, editar, ativar/desativar
│           ├── administration/       ← ✅ Painel admin + Auditoria
│           ├── sectors/              ← ✅ Repository com fallback CCDTI/CCO/CCE
│           └── reports/              ← ✅ Denúncias com filtros e ações admin
│
├── backend/                          ← ✅ Node.js + TypeScript (tsc 0 erros)
│   ├── src/modules/                  ← auth, users, sectors, conversations,
│   │                                    messages, announcements, reports, audit
│   ├── src/middleware/               ← authenticate.ts, requireHierarquia ✅
│   ├── prisma/schema.prisma          ← ✅ 12 entidades
│   ├── prisma/seed.ts                ← ✅ Dados CCDTI/CCO/CCE
│   └── .env.example                  ← ✅
│
├── README.md                         ← ✅
└── PROGRESSO.md                      ← este arquivo
```

---

## 🗂️ HISTÓRICO DE SESSÕES

| Data/Hora | O que foi feito |
|-----------|----------------|
| Set/2026 — Sessão 1 | Estrutura base, Firebase, tema SUS, splash, login |
| Set/2026 — Sessão 2 | Chat completo (WhatsApp style), áudio, backend completo |
| Set/2026 — Sessão 3 | Funcionários, Perfil, Comunicados, Canais |
| 05/09/2026 09:00 | Reestruturação dos 3 centros (CCDTI/CCO/CCE), seed, regras de comunicação |
| 05/09/2026 09:21 | Fix flutter analyze (imports duplicados + parâmetro inválido) → 0 issues |
| 05/09/2026 09:53 | **Fase 5**: Painel Admin, Denúncias, Auditoria — implementação completa |
| 05/09/2026 10:08 | PROGRESSO.md reestruturado completo |
| 05/09/2026 10:13 | **Fase 5b**: Central de Emergência & Central de Notificações concluídas com 0 issues |
| 05/09/2026 11:02 | **Neon PostgreSQL**: CLI instalada, MCP/skills configurados, link project `spring-fire-94048078`, `neon deploy`, `prisma db push` e `db:seed` executados com sucesso no Neon |

---

## 🚀 PRÓXIMOS PASSOS (ordem de prioridade)

1. **[AGORA]** Integração Dio / HTTP real (Fase 6) — conectar chamadas do app Flutter à API Node.js/Prisma
2. **[PRÓXIMO]** Credenciais do Firebase Admin SDK no `backend/.env`
3. **[FUTURO]** FCM — notificações push em foreground e background
4. **[FUTURO]** Testes de segurança backend (Vitest)
5. **[FUTURO]** Polimento: dark mode, skeleton, acessibilidade
