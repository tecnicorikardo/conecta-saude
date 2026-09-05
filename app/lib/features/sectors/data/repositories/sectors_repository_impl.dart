import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/http_service.dart';
import '../../domain/entities/sector_entity.dart';
import '../../domain/repositories/sectors_repository.dart';
import '../models/sector_model.dart';

class SectorsRepositoryImpl implements SectorsRepository {
  final HttpService _httpService;

  SectorsRepositoryImpl(this._httpService);

  @override
  Future<Either<Failure, List<SectorEntity>>> getSectors() async {
    try {
      final response = await _httpService.get('/sectors');
      final data = response.data;

      if (data is Map<String, dynamic> && data['data'] is List) {
        final list = (data['data'] as List)
            .map((item) => SectorModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return Right(list);
      }

      return Right(_fallbackSectors);
    } catch (_) {
      return Right(_fallbackSectors);
    }
  }

  static final List<SectorEntity> _fallbackSectors = [
    const SectorEntity(
      id: 'sec-ccdti',
      nome: 'Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI)',
      descricao: 'Exames de imagem, tomografia, ressonância e diagnóstico',
      ativo: true,
    ),
    const SectorEntity(
      id: 'sec-cco',
      nome: 'Centro Carioca do Olho (CCO)',
      descricao: 'Oftalmologia, bloco cirúrgico e consultas especializadas',
      ativo: true,
    ),
    const SectorEntity(
      id: 'sec-cce',
      nome: 'Centro Carioca de Especialidades (CCE)',
      descricao: 'Consultas ambulatoriais especializadas e regulação',
      ativo: true,
    ),
    const SectorEntity(
      id: 'sec-direcao',
      nome: 'Direção Geral',
      descricao: 'Administração Central e Gestão Integrada',
      ativo: true,
    ),
  ];

  @override
  Future<Either<Failure, SectorEntity>> createSector({
    required String nome,
    String? descricao,
  }) async {
    try {
      final response = await _httpService.post(
        '/sectors',
        data: {
          'nome': nome,
          if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
        },
      );
      final data = response.data;

      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final sector = SectorModel.fromJson(data['data'] as Map<String, dynamic>);
        return Right(sector);
      }

      return const Left(ServerFailure('Formato de resposta inválido.'));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SectorEntity>> updateSector({
    required String id,
    String? nome,
    String? descricao,
    bool? ativo,
  }) async {
    try {
      final response = await _httpService.put(
        '/sectors/$id',
        data: {
          if (nome != null) 'nome': nome,
          if (descricao != null) 'descricao': descricao,
          if (ativo != null) 'ativo': ativo,
        },
      );
      final data = response.data;

      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final sector = SectorModel.fromJson(data['data'] as Map<String, dynamic>);
        return Right(sector);
      }

      return const Left(ServerFailure('Formato de resposta inválido.'));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
