import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/sector_entity.dart';

abstract class SectorsRepository {
  Future<Either<Failure, List<SectorEntity>>> getSectors();
  Future<Either<Failure, SectorEntity>> createSector({
    required String nome,
    String? descricao,
  });
  Future<Either<Failure, SectorEntity>> updateSector({
    required String id,
    String? nome,
    String? descricao,
    bool? ativo,
  });
}
