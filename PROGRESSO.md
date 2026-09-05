# Conecta Saúde — Progresso do Projeto
> **Última atualização:** 05/09/2026 às 15:05 (horário de Brasília)
> **Status geral:** 🟢 Em desenvolvimento ativo — 90% completo

---

## 📊 RESUMO EXECUTIVO

| Fase | Descrição | Status |
|------|-----------|--------|
| Core / Infraestrutura | Flutter base, tema SUS, rotas, Firebase | ✅ 100% |
| Identidade Visual | Paleta SUS, tipografia Inter, logo SUS | ✅ 100% |
| Fase 1 — Auth | Login, logout, recuperação de senha | ✅ 100% |
| Fase 2 — Usuários | Funcionários (lista, criar, editar, ativar/desativar), Perfil | ✅ 100% |
| Fase 3 — Chat | Conversas, mensagens, áudio, swipe-to-reply | ✅ 100% |
| Fase 4 — Canais e Comunicados | Canais por centro (CCD/CCO/CCE), Comunicados | ✅ 100% |
| Fase 5 — Administração | Painel admin, Denúncias, Auditoria | ✅ 100% |
| Fase 5b — Emergência e Notificações | Central de emergência, Central de Notificações | ✅ 100% |
| Banco de Dados (Neon) | PostgreSQL nuvem, Prisma schema, Seed CCDTI/CCO/CCE | ✅ 100% |
| Backend (Node + TS + Express) | Conectado ao Neon e Firebase Admin SDK | ✅ 100% |
| Controle de Acesso e Isolamento | Restrição rigorosa por Centro (CCD/CCO/CCE) e Hierarquia | ✅ 100% |
| Fase 6 — Integração HTTP Real | Substituição gradual de mocks por endpoints | 🔄 Em andamento |
| Fase 7 — FCM | Notificações push Firebase | ⏳ Pendente |
| Fase 8 — Testes e Segurança | Vitest backend, testes Flutter | ⏳ Pendente |
| Fase 9 — Polimento | PWA / APK, skeleton, acessibilidade | ⏳ Pendente |

---

## 🔒 CONTROLE DE ACESSO E ISOLAMENTO INSTITUCIONAL

A hierarquia e o isolamento entre centros agora são estritamente aplicados no sistema:

```
DIREÇÃO GERAL / ADMIN GERAL (Nível 1)
├── CCDTI (Centro Carioca de Diagnóstico e Tratamento por Imagem)
├── CCO (Centro Carioca do Olho)
└── CCE (Centro Carioca de Especialidades)
```

### Regras de Acesso Aplicadas:
1. **Direção Geral / Admin Geral (Nível 1)**:
   - Visualiza e gerencia os 3 centros (CCDTI, CCO, CCE)
   - Acesso exclusivo ao **Painel Administrativo** e **Log de Auditoria**
   - Criação de novos funcionários e canais
   - Moderação global de mensagens e denúncias

2. **Funcionário / Coordenação do CCDTI**:
   - Vê **apenas a aba CCD (CCDTI) e 🚨 Emergência** na tela de canais
   - Lista de funcionários restrita ao **CCDTI** e à **Direção Geral**
   - Vê comunicados do **CCDTI** e comunicados gerais da **Direção**

3. **Funcionário / Coordenação do CCO**:
   - Vê **apenas a aba CCO e 🚨 Emergência** na tela de canais
   - Lista de funcionários restrita ao **CCO** e à **Direção Geral**
   - Vê comunicados do **CCO** e comunicados gerais da **Direção**

4. **Funcionário / Coordenação do CCE**:
   - Vê **apenas a aba CCE e 🚨 Emergência** na tela de canais
   - Lista de funcionários restrita ao **CCE** e à **Direção Geral**
   - Vê comunicados do **CCE** e comunicados gerais da **Direção**

---

## ✅ CONCLUÍDO

### 🖥️ Backend e Banco de Dados (Neon + Firebase)
| Item | Status |
|------|--------|
| Credenciais Firebase Admin | ✅ Extraídas do JSON de service account e configuradas no `.env` |
| Conexão Neon PostgreSQL | ✅ Prisma conectado via pooling (`ep-noisy-bar-acsogt11-pooler`) |
| Seed Oficial | ✅ 4 centros/setores, 11 usuários oficiais, canais e comunicados |
| API Server | ✅ Rodando em `http://localhost:3000` (`tsc` e runtime 100% estáveis) |

---

### 📱 Flutter — Telas e Funcionalidades
| Feature | Arquivo | Status |
|---------|---------|--------|
| Auth | `login_page.dart` | ✅ Redesign SUS compacto, sem scrollbar no desktop |
| Home | `home_page.dart` | ✅ Atalhos com controle por nível, banner emergência, comunicados |
| Canais | `channels_page.dart` | ✅ Abas e canais isolados estritamente pelo centro do funcionário |
| Comunicados | `announcements_page.dart` | ✅ Filtragem por centro + comunicados gerais da Direção |
| Funcionários | `employees_page.dart` | ✅ Listagem filtrada por centro; FAB criar exclusivo da Direção |
| Administração | `administration_page.dart` | ✅ Dashboard e métricas exclusivo da Direção Geral |
| Auditoria | `audit_logs_page.dart` | ✅ Timeline de eventos com IP e filtros; exclusivo Direção |
| Denúncias | `reports_page.dart` | ✅ Gestão de ocorrências por status e observações |
| Emergência | `emergency_page.dart` | ✅ Protocolo pulsante, ramais dos 3 centros e disparo restrito |
| Notificações | `notifications_page.dart` | ✅ Central com categorias, marcar lida e limpeza |

---

## ❌ O QUE FALTA IMPLEMENTAR

### Fase 6 — Integração HTTP Real (Dio)
- [x] Backend ativo e configurado com Neon + Firebase
- [x] AuthRepository integrado a `/auth/verify` e `/me`
- [ ] Conectar ChatRepository real para envio de mensagens via API
- [ ] Conectar ChannelsRepository real para criação e membros via API

### Fase 7 — FCM (Notificações Push)
- [ ] Solicitar permissão no Android 13+ e iOS
- [ ] Capturar FCM token e enviar ao backend (`PATCH /auth/fcm-token`)
- [ ] Foreground banner e notificação prioritária de emergência

### Fase 8 — Testes e Segurança
- [ ] Testes de autorização backend (Vitest) para garantir bloqueio cross-center
- [ ] Testes unitários dos providers Riverpod

### Fase 9 — Polimento e Distribuição
- [x] Build Web testado e validado (`build/web` gerado)
- [ ] Build APK Android (`flutter build apk`)
- [ ] Teste em dispositivos físicos PWA / Safari iOS

---

## 🗂️ HISTÓRICO DE SESSÕES

| Data/Hora | O que foi feito |
|-----------|----------------|
| Set/2026 — Sessão 1 | Estrutura base, Firebase, tema SUS, splash, login |
| Set/2026 — Sessão 2 | Chat completo (WhatsApp style), áudio, backend completo |
| Set/2026 — Sessão 3 | Funcionários, Perfil, Comunicados, Canais |
| 05/09/2026 09:00 | Reestruturação dos 3 centros (CCDTI/CCO/CCE), seed, regras de comunicação |
| 05/09/2026 09:53 | **Fase 5**: Painel Admin, Denúncias, Auditoria — implementação completa |
| 05/09/2026 10:13 | **Fase 5b**: Central de Emergência & Central de Notificações concluídas |
| 05/09/2026 11:02 | **Neon PostgreSQL**: CLI instalada, link project, `prisma db push` e `db:seed` executados no Neon |
| 05/09/2026 15:05 | **Firebase Admin & Isolamento Institucional**: Extração das credenciais do JSON do Firebase, inicialização com sucesso do Backend Node.js, isolamento completo por centro (CCDTI/CCO/CCE) nas abas de canais, comunicados e lista de funcionários. `flutter analyze` 0 issues. |

---

## 🚀 PRÓXIMOS PASSOS

1. **Testar o fluxo completo de login e isolamento** de cada centro no navegador / app.
2. **Conectar repositórios de Chat e Canais** à API Node.js/Prisma em tempo real.
3. **Gerar APK de produção** para testes em celulares Android.
