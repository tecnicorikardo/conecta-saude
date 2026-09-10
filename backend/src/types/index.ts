// ─── Hierarquia ──────────────────────────────────────────────────────────────
export enum HierarquiaNivel {
  DIRECAO = 1,
  COORDENACAO = 2,
  SUPERVISAO = 3,
  FUNCIONARIO = 4,
}

// ─── Usuário autenticado (extraído do token + banco) ─────────────────────────
export interface AuthenticatedUser {
  id: string;
  firebaseUid: string;
  nome: string;
  email: string;
  cargo: string;
  hierarquiaNivel: HierarquiaNivel;
  setorId: string;
  unitId?: string | null;
  ativo: boolean;
}

// ─── Tipos de conversa ────────────────────────────────────────────────────────
export enum ConversationTipo {
  INDIVIDUAL = 'individual',
  GRUPO = 'grupo',
  SETOR = 'setor',
}

// ─── Tipos de canal ───────────────────────────────────────────────────────────
export enum ChannelTipo {
  INSTITUCIONAL = 'institucional',
  SETOR = 'setor',
  EMERGENCIA = 'emergencia',
  GERAL = 'geral',
}

// ─── Prioridade de comunicado ─────────────────────────────────────────────────
export enum AnnouncementPrioridade {
  NORMAL = 'normal',
  ALTA = 'alta',
  URGENTE = 'urgente',
}

// ─── Status de denúncia ───────────────────────────────────────────────────────
export enum ReportStatus {
  PENDENTE = 'pendente',
  EM_ANALISE = 'em_analise',
  RESOLVIDO = 'resolvido',
  ARQUIVADO = 'arquivado',
}

// ─── Resposta padrão da API ───────────────────────────────────────────────────
export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
}

// ─── Paginação ────────────────────────────────────────────────────────────────
export interface PaginationQuery {
  page?: number;
  limit?: number;
  cursor?: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}
