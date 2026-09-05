import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/chat/presentation/pages/conversations_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/channels/presentation/pages/channels_page.dart';
import '../../features/announcements/presentation/pages/announcements_page.dart';
import '../../features/announcements/presentation/pages/announcement_detail_page.dart';
import '../../features/emergency/presentation/pages/emergency_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/employees/presentation/pages/employees_page.dart';
import '../../features/employees/presentation/pages/employee_detail_page.dart';
import '../../features/administration/presentation/pages/administration_page.dart';
import '../../features/administration/presentation/pages/audit_logs_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/chat/domain/entities/conversation_entity.dart';
import '../widgets/splash_screen.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // ─── Splash ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),

      // ─── Auth ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),

      // ─── Shell principal com bottom nav ──────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomePage(),
        routes: [
          // Conversas (lista) — acessível via bottom nav
          GoRoute(
            path: 'conversations',
            builder: (_, __) => const ConversationsPage(),
          ),
        ],
      ),

      // ─── Chat (tela cheia, sem bottom nav) ───────────────────────────
      GoRoute(
        path: AppRoutes.conversations,
        builder: (_, __) => const ConversationsPage(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          // Passa ConversationEntity via `extra` para evitar re-fetch
          final conversation = state.extra as ConversationEntity?;
          return ChatPage(
            conversationId: id,
            conversation: conversation,
          );
        },
      ),

      // ─── Canais ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.channels,
        builder: (_, __) => const ChannelsPage(),
      ),

      // ─── Comunicados ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.announcements,
        builder: (_, __) => const AnnouncementsPage(),
      ),
      GoRoute(
        path: AppRoutes.announcementDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AnnouncementDetailPage(announcementId: id);
        },
      ),

      // ─── Emergência ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.emergency,
        builder: (_, __) => const EmergencyPage(),
      ),

      // ─── Notificações ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsPage(),
      ),

      // ─── Perfil ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfilePage(),
      ),

      // ─── Funcionários ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.employees,
        builder: (_, __) => const EmployeesPage(),
      ),
      GoRoute(
        path: AppRoutes.employeeDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EmployeeDetailPage(employeeId: id);
        },
      ),

      // ─── Administração ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.administration,
        builder: (_, __) => const AdministrationPage(),
      ),

      // ─── Denúncias ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.reports,
        builder: (_, __) => const ReportsPage(),
      ),

      // ─── Log de Auditoria ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.auditLogs,
        builder: (_, __) => const AuditLogsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Página não encontrada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              state.uri.toString(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
  );
}
