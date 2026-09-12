# Sistema de Status Manual "Em Serviço / Fora de Serviço"

## 📋 Resumo

Sistema que substitui o cálculo automático de jornada por um toggle manual controlado pelo usuário, resolvendo problemas de inconsistência de timezone e sincronização entre diferentes usuários visualizando o mesmo status.

---

## ✅ Implementações Concluídas

### 1. Backend - Banco de Dados
**Arquivo:** `backend/prisma/migrations/20260912183910_add_em_servico_field/migration.sql`
- ✅ Criada coluna `em_servico BOOLEAN DEFAULT true` na tabela `users`
- ✅ Adicionado índice para performance: `CREATE INDEX idx_users_em_servico ON users(em_servico)`
- ✅ Atualizado `backend/prisma/schema.prisma` com campo `emServico`

### 2. Backend - API REST
**Arquivo:** `backend/src/modules/users/users.controller.ts`
- ✅ Criado endpoint `PATCH /api/users/me/service-status`
- ✅ Validação: aceita apenas `{ "emServico": true | false }`
- ✅ Registra auditoria com ação `atualizar_status_servico`
- ✅ Log no console com nome do usuário e novo status

**Arquivo:** `backend/src/modules/users/users.routes.ts`
- ✅ Rota registrada: `router.patch('/me/service-status', asyncHandler(updateMyServiceStatus))`

**Arquivos atualizados para incluir `emServico` nos responses:**
- ✅ `backend/src/modules/auth/auth.controller.ts` - endpoints de login/registro
- ✅ `backend/src/modules/conversations/conversations.controller.ts` - participantes de conversas
- ✅ Substituído cálculo `isUserCurrentlyWorking(m.user)` por `m.user.emServico ?? true`

### 3. Backend - WebSocket (Realtime)
**Arquivo:** `backend/src/realtime.ts`
- ✅ Criada função `notifyUserStatusChanged(userId, emServico)` 
- ✅ Notifica todos os participantes das conversas do usuário
- ✅ Evento enviado: `{ type: 'user.status.changed', userId, emServico }`
- ✅ Atualizado tipo do método `notify()` para aceitar eventos genéricos

**Arquivo:** `backend/src/modules/users/users.controller.ts`
- ✅ Adicionado import: `import { notifyUserStatusChanged } from '../../realtime'`
- ✅ Chamada após atualização: `notifyUserStatusChanged(actor.id, emServico)`

### 4. Flutter - Entidades
**Arquivo:** `app/lib/features/auth/domain/entities/user_entity.dart`
- ✅ Adicionado campo `final bool emServico`
- ✅ Simplificado getter `isCurrentlyWorking` para retornar diretamente `emServico`
- ✅ Removida toda lógica de cálculo automático de jornada
- ✅ Atualizado `workStatusLabel` e `workStatusColor` para usar status manual
- ✅ Atualizado `copyWith()`, `toJson()` e `fromJson()`

**Arquivo:** `app/lib/features/chat/domain/entities/conversation_entity.dart`
- ✅ Atualizado `ConversationParticipant.isCurrentlyWorking` para usar `emServico` do backend
- ✅ Removida lógica de cálculo local

### 5. Flutter - Provider de Estado
**Arquivo:** `app/lib/features/auth/presentation/providers/service_status_provider.dart` ⭐ NOVO
- ✅ `StateNotifier<AsyncValue<bool>>` para gerenciar status
- ✅ Método `toggle()` - alterna o status com otimistic update
- ✅ Método `setStatus(bool)` - define explicitamente o status
- ✅ Rollback automático em caso de erro
- ✅ Chama `refreshUser()` após sucesso para sincronização

**Arquivo:** `app/lib/features/auth/presentation/providers/current_user_provider.dart`
- ✅ Adicionado método `refreshUser()` para recarregar dados do backend

### 6. Flutter - Interface (Home)
**Arquivo:** `app/lib/features/home/presentation/widgets/service_status_card.dart` ⭐ NOVO
- ✅ Card visual com gradient (verde para "Em Serviço", cinza para "Fora de Serviço")
- ✅ Ícone dinâmico: `Icons.work` / `Icons.work_off`
- ✅ Switch interativo com feedback visual
- ✅ SnackBar de confirmação após mudança
- ✅ Loading indicator durante requisição
- ✅ Tratamento de erros com mensagem

**Arquivo:** `app/lib/features/home/presentation/pages/home_page.dart`
- ✅ Adicionado `ServiceStatusCard()` logo após `WelcomeCard`
- ✅ Import do widget

### 7. Flutter - Interface (Perfil)
**Arquivo:** `app/lib/features/profile/presentation/pages/profile_page.dart`
- ✅ Criada seção "STATUS DE SERVIÇO" antes de "Minha Escala"
- ✅ Ícone circular com cor dinâmica (verde/cinza)
- ✅ Labels: "Em Serviço" / "Fora de Serviço"
- ✅ Descrição: "Disponível para atendimento" / "Não disponível no momento"
- ✅ Switch com loading state
- ✅ SnackBar de feedback

### 8. Flutter - Notificações
**Arquivos:** `app/lib/core/services/notification_service.dart` e `app/lib/core/widgets/main_shell.dart`
- ✅ Lógica já atualizada automaticamente
- ✅ Usa `isCurrentlyWorking` que agora retorna `emServico`
- ✅ Silencia notificações de rotina quando `silenciarForaJornada=true` e `emServico=false`
- ✅ Emergências sempre notificam independente do status

### 9. Flutter - WebSocket Listener
**Arquivo:** `app/lib/core/services/realtime_service.dart`
- ✅ Adicionado `StreamController<Map<String, dynamic>> _statusEvents`
- ✅ Getter `Stream<Map<String, dynamic>> get statusChanges`
- ✅ Listener para evento `user.status.changed`
- ✅ Dispose do stream no método `dispose()`

---

### 10. Flutter - Atualização Realtime nas Conversas
**Arquivo:** `app/lib/features/chat/presentation/providers/chat_provider.dart`
- ✅ Adicionado `StreamSubscription<Map<String, dynamic>>? _statusSub` no `ConversationsNotifier`
- ✅ Escuta eventos de `realtime.statusChanges`
- ✅ Método `_updateParticipantStatus(userId, emServico)` atualiza o estado em memória imediatamente
- ✅ Dispose do listener configurado corretamente

---

## ⏳ Pendente / Próximos Passos (Deploy & Validação de Ambiente)

Todas as implementações de código no Backend e no Frontend foram **100% concluídas**. As próximas ações operacionais são a execução das migrações e validação em ambiente ativo:

## 🔧 Deploy e Testes

### Comandos de Deploy

#### Backend (Produção)
```bash
# 1. Aplicar migração no banco de dados
cd backend
npx prisma migrate deploy

# 2. Reiniciar servidor para carregar novo código
pm2 restart conecta-saude-backend
# ou
systemctl restart conecta-saude
```

#### Frontend (Web)
```bash
cd app
flutter build web --release
firebase deploy --only hosting
```

#### Frontend (Android)
```bash
cd app
flutter build apk --release
# Upload manual no Play Console
```

### Checklist de Testes

- [ ] **Backend:**
  - [ ] Migração aplicada sem erros
  - [ ] Endpoint `PATCH /api/users/me/service-status` responde 200
  - [ ] Campo `emServico` aparece nos responses de `/api/auth/me`
  - [ ] WebSocket envia evento `user.status.changed` corretamente

- [ ] **Frontend:**
  - [ ] Card de status aparece na home
  - [ ] Toggle funciona e persiste após refresh
  - [ ] Seção de status aparece no perfil
  - [ ] Status visual atualiza em conversas
  - [ ] Notificações respeitam o status (testando com `silenciarForaJornada=true`)

- [ ] **Integração:**
  - [ ] Usuário A muda status → Usuário B vê atualização em tempo real
  - [ ] Status correto em lista de conversas
  - [ ] Status correto em chat aberto
  - [ ] Auditoria registrada no backend

---

## 📊 Diferenças do Sistema Antigo vs Novo

| Aspecto | Sistema Antigo (Automático) | Sistema Novo (Manual) |
|---------|---------------------------|----------------------|
| **Controle** | Calculado pelo sistema | Controlado pelo usuário |
| **Timezone** | Problema de inconsistência | ❌ Não usa timezone |
| **Fonte de verdade** | Cliente ou servidor? | ✅ Sempre o backend |
| **"Estender expediente"** | Apenas local | ❌ Não existe mais |
| **Sincronização** | Diferentes entre usuários | ✅ Sempre sincronizado |
| **Complexidade** | Alta (jornada, plantão, dias) | ✅ Baixa (apenas boolean) |
| **Notificação realtime** | Não existia | ✅ WebSocket |

---

## 🎨 Paleta de Cores

### Em Serviço
- **Gradiente:** `#2E7D32` → `#43A047` (verde)
- **Ícone:** `Icons.work`

### Fora de Serviço
- **Gradiente:** `#757575` → `#9E9E9E` (cinza)
- **Ícone:** `Icons.work_off`

---

## 📝 Notas Técnicas

### Retrocompatibilidade
- Campo `emServico` tem `DEFAULT true` - todos os usuários existentes iniciam "Em Serviço"
- Frontend trata ausência do campo como `emServico = true` via `?? true`

### Auditoria
Cada mudança gera registro:
```json
{
  "userId": "uuid",
  "acao": "atualizar_status_servico",
  "entidade": "user",
  "entidadeId": "uuid",
  "detalhes": "{\"emServico\":true,\"timestamp\":\"2026-09-12T18:39:10.000Z\"}",
  "ip": "192.168.1.1"
}
```

### Performance
- Índice criado: `idx_users_em_servico` para queries rápidas
- WebSocket usa `Set` para verificação O(1) de permissões
- Frontend usa otimistic updates para UX instantânea

---

## 🐛 Problemas Conhecidos Resolvidos

1. ✅ **Roberto via Ricardo fora de serviço, mas Ricardo estava em serviço**
   - **Causa:** Timezone + cálculo client-side vs server-side
   - **Solução:** Status manual, single source of truth

2. ✅ **"Estender expediente" só atualizava localmente**
   - **Causa:** Estado não persistido no backend
   - **Solução:** Toggle persiste sempre no PostgreSQL

3. ✅ **Conversas em cache mostravam status desatualizado**
   - **Causa:** Backend enviava cálculo, não dado real
   - **Solução:** Backend envia `emServico` direto do banco

---

## 📞 Suporte

Em caso de dúvidas sobre a implementação:
- Documentação do endpoint: `GET /api/docs` (se habilitado)
- Logs do backend: `/var/log/conecta-saude/` ou via `pm2 logs`
- Logs do Flutter: DevTools ou `flutter logs`

---

**Última atualização:** 2026-09-12  
**Versão:** 1.0  
**Status:** ✅ 11/11 tarefas de código concluídas (100%) | ⏳ Pendente apenas execução de migração e testes operacionais em produção
