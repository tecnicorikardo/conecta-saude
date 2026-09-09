export type HierarchyLevel = 1 | 2 | 3 | 4;

export const HIERARQUIA_NOMES: Record<HierarchyLevel, string> = {
  1: 'Direção Geral',
  2: 'Coordenação',
  3: 'Supervisão',
  4: 'Funcionário',
};

export interface Sector {
  id: string;
  nome: string;
  sigla: 'CCDTI' | 'CCO' | 'CCE' | 'DIRECAO';
  descricao: string;
  ativo: boolean;
}

export interface User {
  id: string;
  firebaseUid: string;
  nome: string;
  email: string;
  cargo: string;
  hierarquiaNivel: HierarchyLevel;
  setorId: string;
  setorNome?: string;
  fotoUrl?: string;
  ativo: boolean;
  matricula?: string;
  telefone?: string;
  criadoEm: string;
}

export interface Channel {
  id: string;
  nome: string;
  descricao: string;
  tipo: 'institucional' | 'emergencia' | 'setor';
  setorId?: string;
  setorSigla?: 'CCDTI' | 'CCO' | 'CCE' | 'DIRECAO';
  criadoPor: string;
  ativo: boolean;
  membrosCount: number;
  mensagensCount: number;
  criadoEm: string;
}

export interface Message {
  id: string;
  conversationId?: string;
  channelId?: string;
  remetenteId: string;
  remetenteNome: string;
  remetenteCargo?: string;
  texto: string;
  createdAt: string;
  lida: boolean;
  editada?: boolean;
  apagada?: boolean;
  tipo?: 'texto' | 'audio' | 'alerta';
  audioDuracaoSegundos?: number;
  createdAtTimestamp?: number;
}

export interface Conversation {
  id: string;
  tipo: 'individual' | 'grupo';
  membroIds: string[];
  nome?: string;
  descricao?: string;
  fotoUrl?: string;
  autoExcluir24h?: boolean;
  criadoPor?: string;
  ativo?: boolean;
  ultimaMensagem?: string;
  ultimaMensagemHora?: string;
  atualizadoEm: string;
}

export type AnnouncementPriority = 'normal' | 'alta' | 'urgente';

export interface Announcement {
  id: string;
  titulo: string;
  mensagem: string;
  prioridade: AnnouncementPriority;
  criadoPor: string;
  criadorNome: string;
  criadorCargo: string;
  publicadoEm: string;
  ativo: boolean;
  setorId?: string; // se undefined/null, é geral para todos os centros
  lidoPorUserIds: string[];
}

export interface EmergencyState {
  alertActive: boolean;
  alertMessage: string | null;
  alertTimestamp: string | null;
  alertByNome: string | null;
  alertByCargo: string | null;
}

export interface Report {
  id: string;
  autorId: string;
  autorNome: string; // pode ser "Anônimo" se o autor escolheu sigilo
  denunciadoId?: string;
  denunciadoNome?: string;
  motivo: string;
  descricao: string;
  mensagemTrecho?: string;
  status: 'pendente' | 'em_analise' | 'resolvido';
  createdAt: string;
  resolvidoEm?: string;
  observacoes?: string;
}

export interface AuditLog {
  id: string;
  usuarioId: string;
  usuarioNome: string;
  acao: string;
  modulo: string;
  detalhes: string;
  ip: string;
  createdAt: string;
}

export interface NotificationItem {
  id: string;
  userId: string; // se for 'all', visível a todos
  titulo: string;
  descricao: string;
  tipo: 'emergencia' | 'comunicado' | 'mensagem' | 'sistema';
  timestamp: string;
  lida: boolean;
  conversaId?: string;
  canalId?: string;
  comunicadoId?: string;
  remetenteId?: string;
}
