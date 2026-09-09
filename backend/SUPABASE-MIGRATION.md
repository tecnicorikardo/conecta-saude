# Migração para Supabase

## Estado em 09/09/2026

Conexão validada via Session pooler. Foram copiadas 15 tabelas com verificação
SHA-256 de cada conjunto de registros: 12 usuários, 3 conversas, 4 mensagens,
4 setores, 5 canais, 26 vínculos de canais, 6 vínculos de conversas e 3 comunicados.
As demais tabelas estavam vazias. Nenhuma alteração concorrente foi detectada
na origem durante a cópia. Backup e relatório estão em `.local-migration/`, ignorado pelo Git.

DATABASE_URL local já aponta para Supabase. As 15 tabelas têm RLS ativado e
acesso anon/authenticated revogado; a autorização continua na API. Os 12 vínculos
Firebase foram conferidos. A origem não foi apagada.

Pendente: o usuário atualizar DATABASE_URL no Render e publicar o código e o Flutter web.
Se a origem recebeu novas gravações após a cópia, reconciliar antes da troca final.

O chat agora recebe avisos autenticados por WebSocket da API, com recuperação
HTTP após reconexão e sincronização periódica de reserva. Isso usa uma única
instância Render, sem Supabase Realtime. Para várias instâncias, adicionar um
barramento compartilhado. Canais oficiais ainda usam a sincronização periódica.

O fallback de perfil por e-mail foi removido. O envio do chat usa IDs de mensagem
para repetição sem duplicação e mostra tentativa novamente quando falha.

---

As etapas abaixo documentam o procedimento de migração; não repetir a cópia em um destino preenchido.

Projeto de destino: `sxviipihvpkggukyfcfj`.

O backend usa Prisma com conexão PostgreSQL. Chaves publishable, anon e secret
da API Supabase não são senhas PostgreSQL.

## Preparação local

No painel Supabase, abrir Connect e copiar a conexão Session pooler (porta 5432).
Adicionar `SUPABASE_DATABASE_URL` ao arquivo ignorado `backend/.env`, com a senha
do banco devidamente codificada para URL. Manter a conexão atual até concluir a
cópia e a validação dos dados. Não colocar credenciais no Git ou na conversa.

Executar em backend: `node scripts/check_supabase.cjs`.
O comando apenas testa o destino com SELECT 1 e não mostra credenciais ou dados.

## Etapas pendentes para a troca

1. Validar acesso ao destino e inventariar esquema e dados existentes na origem.
2. Fazer backup e copiar dados preservando IDs, vínculos Firebase e relacionamentos.
3. Restringir acesso às tabelas via Data API antes de disponibilizar o destino.
4. Validar autenticação, aprovação de cadastro e isolamento de cada instituição.
5. Configurar DATABASE_URL do backend local e Render para o Supabase e publicar.
6. Conferir dados após a troca e somente então desativar a dependência Neon.

## Mensagens

O cliente anterior consultava mensagens a cada três segundos. Migrar o banco não remove
esse atraso. A entrega em tempo real deve usar canais privados e autorização por
participação e hospital; não usar canais públicos com dados institucionais.
Preservar envio otimista, acrescentar confirmação e tentativa novamente sem
duplicação, além de recuperar mensagens perdidas após reconexão.

A validação deve medir envio até recebimento em dois clientes distintos e testar
reconexão, usuário removido do grupo e tentativa de acesso por outro hospital.
Não afirmar equivalência de desempenho com WhatsApp antes dessa medição.

## Login

O cliente anterior usava timeout de quatro segundos e construía perfis locais a partir
do e-mail quando a API falha. Remover esse fallback: somente o servidor pode
confirmar hospital, cargo, aprovação e atividade do usuário. Mostrar falha ou
tentativa novamente quando a API estiver indisponível, sem conceder privilégios.

## Credenciais

Substituir a chave secreta compartilhada na conversa. As credenciais previamente
versionadas também precisam de rotação; retirar valores do arquivo atual não os
remove do histórico. Nenhuma chave secreta deve ser embutida no Flutter.
