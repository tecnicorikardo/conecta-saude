import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/core/auth/permissions_provider.dart';
import 'package:conecta_saude/core/errors/failures.dart';
import 'package:conecta_saude/core/theme/app_theme.dart';
import 'package:conecta_saude/features/auth/domain/entities/user_entity.dart';
import 'package:conecta_saude/features/employees/domain/entities/paginated_users.dart';
import 'package:conecta_saude/features/employees/domain/repositories/employees_repository.dart';
import 'package:conecta_saude/features/employees/presentation/pages/employee_detail_page.dart';
import 'package:conecta_saude/features/employees/presentation/providers/employees_provider.dart';
import 'package:conecta_saude/features/sectors/domain/entities/sector_entity.dart';
import 'package:conecta_saude/features/sectors/presentation/providers/sectors_provider.dart';

final employee = UserEntity(
    id: 'employee',
    firebaseUid: 'uid',
    nome: 'Pessoa Teste',
    email: 'test@example.invalid',
    cargo: 'Maqueiro',
    hierarquiaNivel: 4,
    setorId: 'sector',
    setorNome: 'Setor Teste',
    ativo: true,
    criadoEm: DateTime(2026));

class FakeEmployeesRepository implements EmployeesRepository {
  UserEntity user = employee;
  int calls = 0;
  @override
  Future<Either<Failure, PaginatedUsers>> listUsers(
          {int page = 1,
          int limit = 30,
          String? search,
          String? setorId,
          int? hierarquiaNivel,
          bool? ativo}) async =>
      Right(PaginatedUsers(
          items: [user], total: 1, page: 1, limit: 30, hasMore: false));
  @override
  Future<Either<Failure, UserEntity>> updateUser(
      {required String id,
      String? nome,
      String? cargo,
      int? hierarquiaNivel,
      String? setorId,
      String? fotoUrl}) async {
    calls++;
    user = user.copyWith(
        nome: nome,
        cargo: cargo,
        hierarquiaNivel: hierarquiaNivel,
        setorId: setorId);
    return Right(user);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<FakeEmployeesRepository> open(
      WidgetTester tester, int actorLevel) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeEmployeesRepository();
    final actor = employee.copyWith(id: 'actor', hierarquiaNivel: actorLevel);
    final notifier = EmployeesNotifier(repo, actor);
    // Pré-carrega a lista para testar o mesmo caminho usado ao clicar um colaborador.
    await notifier.fetchEmployees();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          employeesProvider.overrideWith((ref) => notifier),
          permissionsProvider.overrideWithValue(UserPermissions(actor)),
          sectorsProvider.overrideWith((ref) async =>
              [const SectorEntity(id: 'sector', nome: 'Setor Teste')]),
        ],
        child: MaterialApp(
            theme: AppTheme.dark,
            home: const EmployeeDetailPage(employeeId: 'employee'))));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('Direção altera NV4 para NV3 e vê perfil atualizado',
      (tester) async {
    final repo = await open(tester, 1);
    await tester.tap(find.text('Editar colaborador · Cargo e nível'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(1), 'Enfermeiro(a) Geral');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 — Supervisão / Enfermeiro').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(repo.calls, 1);
    expect(repo.user.hierarquiaNivel, 3);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Enfermeiro(a) Geral'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Coordenação não recebe ação de editar nível', (tester) async {
    await open(tester, 2);
    expect(find.text('Editar colaborador · Cargo e nível'), findsNothing);
    expect(find.byTooltip('Editar cargo e nível'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
