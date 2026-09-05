import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/channel_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

enum ChannelTab {
  ccd,        // Esquerda: Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI)
  cco,        // Meio: Centro Carioca do Olho (CCO)
  cce,        // Direita: Centro Carioca de Especialidades (CCE)
  emergencia, // Alerta e Emergência
  todos,      // Visão Geral (Admin)
}

class ChannelsState {
  final bool isLoading;
  final List<ChannelEntity> channels;
  final ChannelTab selectedTab;
  final String searchQuery;
  final String? errorMessage;
  final UserEntity? currentUser;

  const ChannelsState({
    this.isLoading = false,
    this.channels = const [],
    this.selectedTab = ChannelTab.ccd,
    this.searchQuery = '',
    this.errorMessage,
    this.currentUser,
  });

  bool get isDirecao => currentUser?.isDirecao ?? false;

  String get userCentroTag {
    if (currentUser == null || isDirecao) return 'TODOS';
    final s = ('${currentUser!.setorNome} ${currentUser!.setorId}').toUpperCase();
    if (s.contains('CCD') || s.contains('IMAGEM')) return 'CCD';
    if (s.contains('CCO') || s.contains('OLHO')) return 'CCO';
    if (s.contains('CCE') || s.contains('ESPECIALIDADE')) return 'CCE';
    return 'TODOS';
  }

  ChannelEntity? get emergencyChannel =>
      channels.where((c) => c.isEmergencia).firstOrNull;

  List<ChannelEntity> get filteredChannels {
    final allowedCentro = userCentroTag;

    return channels.where((c) {
      // 1. Isolamento institucional estrito:
      // Se não for Direção Geral, só pode ver canais do seu centro, de emergência ou institucionais gerais
      if (!isDirecao && allowedCentro != 'TODOS') {
        final isMyCenter = c.centroTag == allowedCentro;
        final isGeneralOrEmergency = c.isEmergencia || c.centroTag == 'GERAL';
        if (!isMyCenter && !isGeneralOrEmergency) {
          return false;
        }
      }

      // 2. Busca textual
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchNome = c.nome.toLowerCase().contains(query);
        final matchDesc = (c.descricao ?? '').toLowerCase().contains(query);
        final matchSetor = (c.setorNome ?? '').toLowerCase().contains(query);
        if (!matchNome && !matchDesc && !matchSetor) return false;
      }

      // 3. Filtro por Aba Selecionada
      switch (selectedTab) {
        case ChannelTab.ccd:
          return c.centroTag == 'CCD' || (!isDirecao && c.centroTag == 'GERAL' && allowedCentro == 'CCD');
        case ChannelTab.cco:
          return c.centroTag == 'CCO' || (!isDirecao && c.centroTag == 'GERAL' && allowedCentro == 'CCO');
        case ChannelTab.cce:
          return c.centroTag == 'CCE' || (!isDirecao && c.centroTag == 'GERAL' && allowedCentro == 'CCE');
        case ChannelTab.emergencia:
          return c.isEmergencia;
        case ChannelTab.todos:
          return true;
      }
    }).toList();
  }

  ChannelsState copyWith({
    bool? isLoading,
    List<ChannelEntity>? channels,
    ChannelTab? selectedTab,
    String? searchQuery,
    String? errorMessage,
    UserEntity? currentUser,
  }) {
    return ChannelsState(
      isLoading: isLoading ?? this.isLoading,
      channels: channels ?? this.channels,
      selectedTab: selectedTab ?? this.selectedTab,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class ChannelsNotifier extends StateNotifier<ChannelsState> {
  ChannelsNotifier(UserEntity? user) : super(ChannelsState(currentUser: user)) {
    _initDefaultTab(user);
    loadChannels();
  }

  void _initDefaultTab(UserEntity? user) {
    if (user != null && !user.isDirecao) {
      final s = ('${user.setorNome} ${user.setorId}').toUpperCase();
      if (s.contains('CCO') || s.contains('OLHO')) {
        state = state.copyWith(selectedTab: ChannelTab.cco);
      } else if (s.contains('CCE') || s.contains('ESPECIALIDADE')) {
        state = state.copyWith(selectedTab: ChannelTab.cce);
      } else {
        state = state.copyWith(selectedTab: ChannelTab.ccd);
      }
    }
  }

  void updateUser(UserEntity? user) {
    if (state.currentUser != user) {
      state = state.copyWith(currentUser: user);
      _initDefaultTab(user);
    }
  }

  Future<void> loadChannels() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 250));

    final mockChannels = [
      // ─── Emergência Geral ────────────────────────────────────────────────
      ChannelEntity(
        id: 'chan-emergencia',
        nome: 'Alerta e Emergência Geral',
        descricao:
            'Canal prioritário para acionamento de código azul, traumas graves e transferências entre centros.',
        tipo: ChannelType.emergencia,
        centroTag: 'EMERGENCIA',
        totalMembros: 95,
        ultimaMensagem: 'Leito de observação liberado para transferência urgente.',
        ultimaMensagemHora: DateTime.now().subtract(const Duration(minutes: 15)),
        naoLidas: 1,
      ),

      // ─── CCD — Centro Carioca de Diagnóstico e Tratamento por Imagem ───────
      ChannelEntity(
        id: 'chan-ccd-1',
        nome: 'CCDTI — Tomografia e Ressonância',
        descricao:
            'Passagem de plantão dos técnicos e enfermeiros do setor de imagem avançada.',
        tipo: ChannelType.setor,
        centroTag: 'CCD',
        setorId: 'sec-ccdti',
        setorNome: 'CCDTI — Imagem',
        totalMembros: 28,
        ultimaMensagem: 'Protocolo de contraste revisado com a nefrologia.',
        ultimaMensagemHora: DateTime.now().subtract(const Duration(minutes: 32)),
        naoLidas: 2,
      ),
      ChannelEntity(
        id: 'chan-ccd-2',
        nome: 'CCDTI — Laudos e Telemedicina',
        descricao:
            'Discussão de laudos de urgência e comunicação com médicos radiologistas.',
        tipo: ChannelType.setor,
        centroTag: 'CCD',
        setorId: 'sec-ccdti',
        setorNome: 'CCDTI — Laudos',
        totalMembros: 22,
        ultimaMensagem: 'Laudo da tomografia do leito 04 liberado no prontuário.',
        ultimaMensagemHora: DateTime.now().subtract(const Duration(hours: 1)),
        naoLidas: 0,
      ),
      ChannelEntity(
        id: 'chan-ccd-3',
        nome: 'CCDTI — Recepção e Atendimento',
        descricao:
            'Acolhimento de pacientes agendados e regulação do fluxo de exames.',
        tipo: ChannelType.setor,
        centroTag: 'CCD',
        setorId: 'sec-ccdti',
        setorNome: 'CCDTI — Recepção',
        totalMembros: 18,
        ultimaMensagem: 'Grade de agendamento de ressonância do turno da tarde confirmada.',
        ultimaMensagemHora: DateTime.now().subtract(const Duration(hours: 4)),
        naoLidas: 0,
      ),

      // ─── CCO — Centro Carioca do Olho ────────────────────────────────────
      ChannelEntity(
        id: 'chan-cco-1',
        nome: 'CCO — Bloco Cirúrgico de Catarata',
        descricao:
            'Organização da escala do centro cirúrgico e conferência de lentes intraoculares.',
        tipo: ChannelType.setor,
        centroTag: 'CCO',
        setorId: 'sec-cco',
        setorNome: 'CCO — Cirurgia',
        totalMembros: 34,
        ultimaMensagem: 'Mutirão de sábado: 40 procedimentos confirmados.',
        ultimaMensagemHora: DateTime.now().subtract(const Duration(minutes: 50)),
        naoLidas: 3,
      ),
      ChannelEntity(
        id: 'chan-cco-2',
        nome: 'CCO — Cirurgia Refrativa e Córnea',
        descricao:
            'Avaliação pré-operatória, exames de topografia e triagem de transplantes.',
        tipo: ChannelType.setor,
        centroTag: 'CCO',
        setorId: 'sec-cco',
        setorNome: 'CCO — Especialidades',
        totalMembros: 24,
        ultimaMensagem: 'Equipamento a laser calibrado para os exames matutinos.',
        ultimaMensagemHora: DateTime.now().subtract(const Duration(hours: 2)),
        naoLidas: 0,
      ),
      ChannelEntity(
        id: 'chan-cco-3',
        nome: 'CCO — Ambulatório Geral de Oftalmologia',
        descricao:
            'Atendimento ambulatorial, consultas de retorno e acolhimento.',
        tipo: ChannelType.setor,
        centroTag: 'CCO',
        setorId: 'sec-cco',
        setorNome: 'CCO — Ambulatório',
        totalMembros: 26,
        ultimaMensagem: 'Todos os consultórios do térreo abastecidos com colírios diagnósticos.',
        ultimaMensagemHora: DateTime.now().subtract(const Duration(hours: 5)),
        naoLidas: 0,
      ),

      // ─── CCE — Centro Carioca de Especialidades ──────────────────────────
      ChannelEntity(
        id: 'chan-cce-1',
        nome: 'CCE — Consultas Especializadas',
        descricao:
            'Corpo clínico das especialidades médicas: cardiologia, endocrino e ortopedia.',
        tipo: ChannelType.setor,
        centroTag: 'CCE',
        setorId: 'sec-cce',
        setorNome: 'CCE — Consultórios',
        totalMembros: 38,
        ultimaMensagem: 'Encaixes de cardiologia regulados pelo SISREG.',
        ultimaMensagemHora: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        naoLidas: 0,
      ),
      ChannelEntity(
        id: 'chan-cce-2',
        nome: 'CCE — Regulação Ambulatorial e Vagas',
        descricao:
            'Equipe de regulação de vagas de primeira consulta e retornos prioritários.',
        tipo: ChannelType.setor,
        centroTag: 'CCE',
        setorId: 'sec-cce',
        setorNome: 'CCE — Regulação',
        totalMembros: 20,
        ultimaMensagem: 'Abertura das vagas extras para endocrinologia autorizada.',
        ultimaMensagemHora: DateTime.now().subtract(const Duration(hours: 3)),
        naoLidas: 0,
      ),

      // ─── Canal Institucional Direção Geral ───────────────────────────────
      ChannelEntity(
        id: 'chan-dir-1',
        nome: 'Direção Geral — Avisos Institucionais',
        descricao:
            'Comunicados e portarias da Direção Geral integrando CCDTI, CCO e CCE.',
        tipo: ChannelType.institucional,
        centroTag: 'GERAL',
        totalMembros: 120,
        ultimaMensagem: 'Publicada a resolução unificada de plantões integrados.',
        ultimaMensagemHora: DateTime.now().subtract(const Duration(days: 1)),
        naoLidas: 0,
      ),
    ];

    state = state.copyWith(
      isLoading: false,
      channels: mockChannels,
    );
  }

  void setTab(ChannelTab tab) {
    state = state.copyWith(selectedTab: tab);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }
}

final channelsProvider =
    StateNotifierProvider<ChannelsNotifier, ChannelsState>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  final notifier = ChannelsNotifier(user);
  return notifier;
});
