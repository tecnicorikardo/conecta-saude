# Conecta Saúde

Comunicação institucional para hospitais: conversas, grupos, canais, comunicados e gestão de acesso.

## Estrutura ativa

- app/: Flutter (web e Android), Riverpod, Firebase Auth e FCM.
- backend/: Express e TypeScript, Prisma, Supabase PostgreSQL.
- e2e/: Playwright. Atenção: a configuração atual aponta para o site publicado.
- src/ e server/: interface React e servidor JSON anteriores; o package.json da raiz não inicia essa interface.

## Desenvolvimento

Backend (Node.js 20 ou superior), dentro de backend/:

```sh
npm ci
npm run db:generate
npm run dev
npm test
npm run build
```

Configurar DATABASE_URL no backend/.env com a conexão Supabase Session pooler e as variáveis Firebase existentes. Nunca versionar esse arquivo. Porta padrão da API: 3000.

Aplicativo, dentro de app/:

```sh
flutter pub get
flutter run -d chrome --web-port 8080
flutter analyze
flutter build web --release
```

O aplicativo web em localhost usa a API local na porta 3000. A versão publicada usa o serviço conecta-saude-backende no Render. O Firebase Hosting publica app/build/web.

## Mensagens e acesso

O chat usa envio otimista e avisos WebSocket autenticados em /api/realtime. O token é enviado em um quadro inicial, nunca na URL. Apenas participantes ativos recebem avisos; os dados são obtidos pela API autenticada. Reconexões recuperam alterações por HTTP. Há sincronização periódica de reserva. Canais oficiais ainda usam consultas periódicas.

Cargo e hospital são confirmados pelo backend, sem perfil improvisado a partir do e-mail. Permissões por hospital ainda exigem revisão completa antes de ampliar para outras instituições.

## Publicação e migração

Consulte backend/SUPABASE-MIGRATION.md. O banco local foi trocado para Supabase e os dados existentes foram copiados. O Render exige DATABASE_URL no painel. Os segredos Firebase também são configurados pelo painel, nunca pelo render.yaml.

A entrega em tempo real usa uma instância de API, adequada à demonstração gratuita. Antes de operar múltiplas instâncias, adicionar distribuição compartilhada de eventos. Desempenho de produção deve ser medido em dispositivos reais.
