import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reports_repository.dart';

/// Provider para a lista de todas as denúncias (Exclusivo Direção Geral)
final allReportsProvider =
    FutureProvider.family<List<ReportEntity>, ReportStatus?>(
        (ref, statusFilter) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.listReports(status: statusFilter);
});

/// Provider para as denúncias enviadas pelo usuário logado
final myReportsProvider = FutureProvider<List<ReportEntity>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getMyReports();
});
