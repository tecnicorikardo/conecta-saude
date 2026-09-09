# Status do projeto Conecta Saúde

**Data e hora do registro:** 09/09/2026 20:39:24 (UTC−03:00, São Paulo)  
**Ambiente:** demonstração gratuita  
**Branch local:** `main`  
**Último commit remoto conhecido:** `b71a39d`

## Objetivo

Plataforma institucional de comunicação interna para substituir o uso de WhatsApp em hospitais, com conversas individuais, grupos, canais oficiais, comunicados, emergência, auditoria e controle hierárquico por hospital.

## Arquitetura atual

- **Aplicativo:** Flutter para Web, PWA e Android; Riverpod, Firebase Auth, FCM e cliente HTTP Dio.
- **API:** Node.js, TypeScript, Express e Prisma.
- **Banco:** Supabase PostgreSQL usando Session pooler.
- **Autenticação:** Firebase Auth. O backend confirma no banco o usuário, hospital/setor, cargo, nível hierárquico e situação de aprovação.
- **Hospedagem prevista:** Firebase Hosting para o Flutter Web e Render para a API.

## Migração do banco

A conexão do Supabase foi validada com consulta de leitura. O banco de destino estava vazio e recebeu a cópia do banco anterior.

Registros copiados:

| Tabela | Registros |
|---|---:|
| `sectors` | 4 |
| `users` | 12 |
| `conversations` | 3 |
| `conversation_members` | 6 |
| `messages` | 4 |
| `channels` | 5 |
| `channel_members` | 26 |
| `announcements` | 3 |
| Demais tabelas | 0 |

Foram copiadas 15 tabelas. A conferência por SHA-256 não encontrou diferenças, e nenhuma alteração concorrente foi detectada na origem durante a cópia. Os 12 vínculos Firebase foram conferidos. A origem não foi apagada.

As tabelas do Supabase estão com RLS ativado e acesso direto para `anon` e `authenticated` revogado. A autorização de negócio continua na API, que aplica participação na conversa e isolamento entre hospitais.

## Hierarquia e isolamento

- Direção Geral (nível 1): pode administrar a rede conforme as regras do sistema.
- Coordenação (nível 2): atua somente no hospital/setor ao qual está vinculada.
- Supervisão (nível 3): atua dentro das permissões do próprio hospital/setor.
- Funcionário (nível 4): comunicação permitida dentro do próprio hospital/setor e canais gerais autorizados.

Uma coordenação do CCO, por exemplo, não recebe acesso ao CCE ou CCDTI apenas por escolher o cargo “Coordenação”. O vínculo do hospital/setor é confirmado e usado pelo backend em cada consulta e ação.

## Mensagens

O cliente tinha consultas periódicas a cada três segundos. Foi adicionado um transporte WebSocket autenticado em `/api/realtime` para avisar os clientes imediatamente quando uma conversa muda. O aplicativo recupera os dados pela API após o aviso, reconecta automaticamente e mantém uma sincronização periódica de reserva.

O envio mantém a mensagem visível imediatamente, usa `clientMessageId` para repetir uma tentativa sem duplicar registros e mostra a ação “Tentar novamente” quando o envio falha.

O WebSocket atual pressupõe uma única instância da API, adequada para a demonstração. Antes de usar múltiplas instâncias do Render, será necessário um barramento compartilhado de eventos.

## Login

O fallback que criava um perfil local a partir do e-mail foi removido. Se a API não confirmar o cadastro, o aplicativo não concede acesso nem inventa cargo ou hospital; informa a falha e permite tentar novamente.

## Verificações executadas

- Backend TypeScript: compilação de produção passou.
- Backend Vitest: **26 testes passaram em 6 arquivos**.
- Teste de conexão Supabase: passou; nenhum dado foi alterado pelo teste.
- Endpoint local `/ready`: retornou `status: ready` e `database: supabase`.
- Flutter Analyze: passou.
- Teste de widget de reenvio de mensagem: passou.
- Flutter Web release: compilado com sucesso em `app/build/web`.
- `git diff --check`: sem erros de formatação.

## Render

O usuário atualizou `DATABASE_URL` no serviço `conecta-saude-backende` para a conexão Session pooler do Supabase e iniciou um redeploy.

O redeploy registrado no log falhou antes de publicar porque usou o commit antigo `b71a39d` e executou a compilação antes de gerar o Prisma Client. A configuração local já foi corrigida:

- `npm ci --include=dev` instala dependências de desenvolvimento no build.
- `npm run build` gera o Prisma Client antes do TypeScript.
- Os testes não entram na compilação de produção.
- O manifesto Render não contém valores de segredos.

Ainda é necessário enviar o código atualizado ao GitHub e executar um novo deploy. Depois, verificar `/ready` no domínio público e testar login e mensagens.

## Firebase Hosting

O build web local está pronto, mas ainda precisa ser publicado após a atualização do backend. O Firebase Hosting continua configurado para `app/build/web`.

## Segurança

- Não versionar `backend/.env`, senhas, chaves Firebase ou chaves Supabase.
- A senha do banco foi usada apenas na configuração local e não deve ser enviada na conversa.
- A chave secreta do Supabase compartilhada anteriormente deve ser rotacionada no painel do Supabase.
- O `render.yaml` foi ajustado para não carregar segredos diretamente no repositório.

## Pendências imediatas

1. Revisar as alterações locais.
2. Criar commit e enviar ao GitHub.
3. Fazer novo deploy do backend no Render.
4. Confirmar `/ready` com `database: supabase`.
5. Publicar `app/build/web` no Firebase Hosting.
6. Testar com dois usuários reais: envio, recebimento, reconexão e nova tentativa.
7. Testar bloqueio entre CCO, CCDTI e CCE.
8. Rotacionar a chave secreta Supabase compartilhada.

## Arquivos principais adicionados ou alterados

- `backend/src/realtime.ts`
- `app/lib/core/services/realtime_service.dart`
- `backend/scripts/migrate_supabase.cjs`
- `backend/scripts/check_supabase.cjs`
- `backend/SUPABASE-MIGRATION.md`
- `backend/src/__tests__/realtime.test.ts`
- `backend/src/__tests__/messages_delivery.test.ts`
- `app/test/message_retry_test.dart`
- `README.md`
- `render.yaml`
- `package.json`
- `backend/package.json`
- `backend/tsconfig.json`
- `status.md`

## Estado geral

**Migração local para Supabase:** concluída e conferida.  
**Login e hierarquia local:** corrigidos.  
**Mensagens em tempo real local:** implementadas e testadas.  
**Render público:** pendente de novo deploy com o código atualizado.  
**Flutter Web público:** pendente de publicação.  
**Pronto para apresentação:** após concluir as duas publicações e os testes entre dois dispositivos.
