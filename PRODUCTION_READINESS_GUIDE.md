# 🚀 Roteiro de Prontidão para Produção (Conecta Saúde)

> **Gatilho de Execução:** Quando o usuário disser **"vamos deixar pronto pra produção"**, este roteiro será ativado e executado ponta a ponta no backend e frontend.

---

## 1. Esgotamento de Conexões: Prisma + Supabase (Supavisor)

O Prisma precisa de duas conexões configuradas no `schema.prisma`: uma para rodar as consultas do dia a dia (com pooling/Supavisor porta 6543) e outra direta para rodar comandos de migração (`prisma migrate` porta 5432).

### Configuração no Painel Supabase
1. Ir em **Project Settings** > **Database**.
2. Em **Connection pooling**, selecionar o modo **Transaction** (porta `6543`).
3. Em **Direct connection**, copiar a URL direta (porta `5432`).

### No `backend/prisma/schema.prisma`
```prisma
datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")      // URL com pool (porta 6543) + ?pgbouncer=true
  directUrl = env("DIRECT_URL")        // URL direta (porta 5432)
}
```

### No arquivo `.env` (Backend / Render)
```env
# Conexão de rotina com pool de conexões (Supavisor)
DATABASE_URL="postgresql://postgres.[REF]:[SENHA]@aws-0-[REGIAO].pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"

# Conexão exclusiva para migrações
DIRECT_URL="postgresql://postgres.[REF]:[SENHA]@aws-0-[REGIAO].pooler.supabase.com:5432/postgres"
```

---

## 2. Renovação Automática de Token Firebase Auth (Flutter + Dio)

Garante que o token JWT nunca expire durante o uso do colaborador em plantão. O `DioInterceptor` recupera o token atual e renova forçadamente caso receba `401 Unauthorized`.

### Implementação de `ApiService` / `DioClient`
```dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://conecta-saude-backende.onrender.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  ApiService() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final refreshedToken = await user.getIdToken(true);
              e.requestOptions.headers['Authorization'] = 'Bearer $refreshedToken';
              
              final response = await dio.fetch(e.requestOptions);
              return handler.resolve(response);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}
```

---

## 3. Tratamento de Conectividade e Quedas de Rede (Flutter)

Prevenção contra telas vermelhas e encerramentos abruptos quando o profissional estiver em áreas com sinal oscilante no hospital:
- Captura seletiva de `DioExceptionType.connectionTimeout`, `receiveTimeout` e `connectionError`.
- Feedback com SnackBar não bloqueante ("Sem conexão. Verifique sua rede") e opção de "Tentar novamente".

```dart
Future<void> fetchMensagensSeguro() async {
  try {
    final response = await apiService.dio.get('/api/messages');
    // Tratar dados
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.connectionError) {
      mostrarAviso("Sem conexão com a rede hospitalar. Tentando reconectar...");
    } else {
      mostrarAviso("Erro ao carregar dados. Tente novamente mais tarde.");
    }
  }
}
```

---

## 4. Monitoramento e Telemetria: Crashlytics & Sentry

- **Firebase Crashlytics:** Adicionar ao Flutter para capturar exceções não tratadas e crash reports no console Firebase.
- **Sentry (Node.js & Flutter):** Configurar DSN do Sentry no backend (Render) e app Flutter para alertas em tempo real de erros 500 com rastreio da linha exata.
