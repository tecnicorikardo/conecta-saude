# Conecta Saúde

Plataforma institucional de comunicação interna para ambiente hospitalar.

Comunicação profissional, organizada, segura e com rastreabilidade — separada da comunicação pessoal dos funcionários.

---

## Arquitetura

```
Flutter App (Android)
    ↓
Firebase Authentication → ID Token
    ↓
Node.js API (TypeScript)
    ├── Firebase Admin SDK (validação de tokens + FCM)
    └── PostgreSQL via Prisma (dados, usuários, mensagens, auditoria)
```

---

## Tecnologias

| Camada       | Tecnologia                              |
|--------------|-----------------------------------------|
| Frontend     | Flutter, Dart, Riverpod, GoRouter       |
| UI           | Material 3, Google Fonts (Inter)        |
| Auth         | Firebase Authentication                 |
| Notificações | Firebase Cloud Messaging (FCM)          |
| Backend      | Node.js, TypeScript, Express            |
| Banco        | PostgreSQL (Supabase ou Neon)           |
| ORM          | Prisma                                  |
| Validação    | Zod                                     |

---

## Estrutura do Projeto

```
conecta-saude/
├── app/                    # Flutter
│   ├── lib/
│   │   ├── core/           # Tema, rotas, config, utils
│   │   └── features/       # auth, home, chat, channels...
│   └── pubspec.yaml
│
└── backend/                # Node.js
    ├── src/
    │   ├── config/         # Firebase, banco
    │   ├── middleware/      # Auth, errors
    │   ├── modules/         # auth, users, sectors, conversations...
    │   └── utils/
    ├── prisma/
    │   ├── schema.prisma
    │   └── seed.ts
    └── package.json
```

---

## Configuração do Backend

### 1. Instalar dependências

```bash
cd backend
npm install
```

### 2. Configurar variáveis de ambiente

```bash
cp .env.example .env
# Editar .env com suas credenciais reais
```

### 3. Banco de dados

Recomendado: **Neon** (neon.tech) ou **Supabase** — ambos possuem plano gratuito.

Após configurar o `DATABASE_URL` no `.env`:

```bash
npm run db:generate   # Gerar cliente Prisma
npm run db:migrate    # Executar migrations
npm run db:seed       # Popular com dados de desenvolvimento
```

### 4. Firebase Admin SDK

1. Acesse o Firebase Console
2. Configurações do Projeto → Contas de Serviço
3. Gerar nova chave privada
4. Copiar `project_id`, `client_email` e `private_key` para o `.env`
5. **Nunca versionar o arquivo JSON da service account**

### 5. Executar em desenvolvimento

```bash
npm run dev
```

API disponível em: `http://localhost:3000`
Health check: `http://localhost:3000/health`

---

## Endpoints Principais

| Método | Endpoint                        | Descrição                        | Auth |
|--------|---------------------------------|----------------------------------|------|
| POST   | /api/auth/verify                | Validar ID Token Firebase        | Não  |
| GET    | /api/me                         | Dados do usuário autenticado     | Sim  |
| GET    | /api/users                      | Listar funcionários              | Sim  |
| POST   | /api/users                      | Criar funcionário (Direção)      | Sim  |
| PUT    | /api/users/:id                  | Editar funcionário (Direção)     | Sim  |
| PATCH  | /api/users/:id/status           | Ativar/desativar (Direção)       | Sim  |
| GET    | /api/sectors                    | Listar setores                   | Sim  |
| GET    | /api/conversations              | Listar conversas                 | Sim  |
| POST   | /api/conversations              | Criar conversa                   | Sim  |
| GET    | /api/conversations/:id/messages | Listar mensagens                 | Sim  |
| POST   | /api/conversations/:id/messages | Enviar mensagem                  | Sim  |
| PUT    | /api/messages/:id               | Editar mensagem                  | Sim  |
| DELETE | /api/messages/:id               | Excluir mensagem (soft delete)   | Sim  |
| GET    | /api/announcements              | Listar comunicados               | Sim  |
| POST   | /api/announcements              | Criar comunicado (Coord+)        | Sim  |
| POST   | /api/announcements/:id/read     | Confirmar leitura                | Sim  |
| POST   | /api/reports                    | Registrar denúncia               | Sim  |
| GET    | /api/admin/audit-logs           | Logs de auditoria (Direção)      | Sim  |

---

## Hierarquia

| Nível | Nome          | Permissões principais                              |
|-------|---------------|----------------------------------------------------|
| 1     | Direção       | Acesso total, gerencia todos                       |
| 2     | Coordenação   | Gerencia seu setor, cria canais do setor           |
| 3     | Supervisão    | Conversa com superiores e colegas do setor         |
| 4     | Funcionário   | Conversa com superiores e colegas do setor         |

> Toda validação de hierarquia acontece no backend. O app Flutter é apenas cliente.

---

## Configuração do Flutter

### 1. Instalar Flutter

Baixar em: https://docs.flutter.dev/get-started/install/windows

### 2. Dependências

```bash
cd app
flutter pub get
```

### 3. Firebase

1. Adicionar o app Android no Firebase Console (package: `com.conectasaude.app`)
2. Baixar `google-services.json` e colocar em `android/app/`
3. Atualizar `lib/core/config/firebase_options.dart` com o `appId` Android correto

### 4. Executar

```bash
flutter run
```

---

## Segurança

- Tokens Firebase são verificados pelo backend em **toda** requisição
- Hierarquia, setor e status do usuário são sempre lidos do PostgreSQL
- O app Flutter **nunca** define permissões — apenas exibe
- Soft delete em mensagens e usuários — histórico preservado
- Auditoria de todas as ações administrativas
- Rate limiting global (200 req/15min) e por autenticação (20 req/15min)
- Variáveis sensíveis exclusivamente no backend via `.env`

---

## Fases de Desenvolvimento

- [x] **Fase 1** — Base (Flutter + Backend + Firebase Auth)
- [ ] **Fase 2** — Usuários, setores e hierarquia (UI completa)
- [ ] **Fase 3** — Chat e mensagens
- [ ] **Fase 4** — Comunicados, canais, FCM
- [ ] **Fase 5** — Administração, denúncias, auditoria
- [ ] **Fase 6** — Segurança e testes
- [ ] **Fase 7** — Polimento, Dark Mode, acessibilidade
