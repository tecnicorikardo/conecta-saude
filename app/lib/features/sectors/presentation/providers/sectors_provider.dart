import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/http_service.dart';
import '../../domain/entities/sector_entity.dart';
import '../../domain/repositories/sectors_repository.dart';
import '../../data/repositories/sectors_repository_impl.dart';

final sectorsRepositoryProvider = Provider<SectorsRepository>((ref) {
  final httpService = ref.watch(httpServiceProvider);
  return SectorsRepositoryImpl(httpService);
});

final sectorsProvider =
    AsyncNotifierProvider<SectorsNotifier, List<SectorEntity>>(
  SectorsNotifier.new,
);

class SectorsNotifier extends AsyncNotifier<List<SectorEntity>> {
  @override
  Future<List<SectorEntity>> build() async {
    return _fetchSectors();
  }

  Future<List<SectorEntity>> _fetchSectors() async {
    final repository = ref.read(sectorsRepositoryProvider);
    final result = await repository.getSectors();
    return result.fold(
      (failure) => throw failure,
      (sectors) => sectors,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchSectors);
  }
}
