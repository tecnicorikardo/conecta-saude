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
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/chat/domain/entities/conversation_entity.dart';
import '../widgets/splash_screen.dart';
import '../widgets/main_shell.dart';
import '../auth/permissions_provider.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  // Observar permissões para redirecionar quando mudar
  final perms = ref.watch(permissionsProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    // ─── Guard de rotas ─────────────────────────────────────────────────
    redirect: (context, state) {
      final path = state.matchedLocation;
      final loggedIn = perms.isLoggedIn;

      // Rotas públicas
      final isPublic = path == AppRoutes.splash ||
          path == AppRoutes.login ||
          path == AppRoutes.forgotPassword;

      // Não logado tentando acessar rota protegida → login
      if (!loggedIn && !isPublic) return AppRoutes.login;

      // Logado tentando acessar login → home
      if (loggedIn && path == AppRoutes.login) return AppRoutes.home;

      // Rotas exclusivas da Direção
      if (path.startsWith('/admin') || path == AppRoutes.administration) {
        if (!perms.canAccessAdmin) return AppRoutes.home;
      }
      if (path == AppRoutes.employees ||
          path.startsWith('/employees')) {
        if (!perms.canManageEmployees) return AppRoutes.home;
      }
      if (path == AppRoutes.auditLogs) {
        if (!perms.canViewAudit) return AppRoutes.home;
      }

      return null; // sem redirect
    },

    routes: [
      // ─── Splash ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),

      // ─── Auth ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),

      // ─── Shell com bottom nav fixo ────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0 — Início (todos)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomePage(),
              ),
            ],
          ),

          // Branch 1 — Conversas (todos)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.conversations,
                builder: (_, __) => const ConversationsPage(),
              ),
            ],
          ),

          // Branch 2 — Canais (todos)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.channels,
                builder: (_, __) => const ChannelsPage(),
              ),
            ],
          ),

          // Branch 3 — Comunicados (todos)
          StatefulShellBranch(
            routes: [
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
            ],
          ),

          // Branch 4 — Administração (Coordenação + Direção)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.administration,
                builder: (_, __) => const AdministrationPage(),
              ),
            ],
          ),
        ],
      ),

      // ─── Telas sem bottom nav ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final conv = state.extra as ConversationEntity?;
          return ChatPage(conversationId: id, conversation: conv);
        },
      ),
      GoRoute(
        path: AppRoutes.emergency,
        builder: (_, __) => const EmergencyPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfilePage(),
      ),
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
      GoRoute(
        path: AppRoutes.reports,
        builder: (_, __) => const ReportsPage(),
      ),
      GoRoute(
        path: AppRoutes.auditLogs,
        builder: (_, __) => const AdministrationPage(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Página não encontrada',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(state.uri.toString(),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    ),
  );
}
