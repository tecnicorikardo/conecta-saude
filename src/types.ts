export type HierarchyLevel = 1 | 2 | 3 | 4;

export interface Sector {
  id: string;
  nome: string;
  sigla: string;
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
  avatarUrl?: string;
  ativo: boolean;
  matricula?: string;
  telefone?: string;
}

export type MessageStatus = 'sending' | 'sent' | 'delivered' | 'read' | 'failed';

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
  status?: MessageStatus;
}

export interface Conversation {
  id: string;
  tipo: 'individual' | 'grupo';
  membros: User[];
  nome?: string;
  descricao?: string;
  fotoUrl?: string;
  autoExcluir24h?: boolean;
  criadoPor?: string;
  ultimaMensagem?: string;
  ultimaMensagemHora?: string;
  naoLidas: number;
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
  setorId?: string;
  visualizacoesPorcentagem: number;
  lidoPorMim: boolean;
}

export interface NotificationItem {
  id: string;
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

export interface Report {
  id: string;
  motivo: string;
  descricao: string;
  mensagemId?: string;
  mensagemTrecho?: string;
  autorId: string;
  autorNome: string;
  denunciadoNome?: string;
  status: 'pendente' | 'em_analise' | 'resolvido';
  createdAt: string;
}

export interface EmergencyState {
  alertActive: boolean;
  alertMessage: string | null;
  alertTimestamp: string | null;
  alertByNome: string | null;
  alertByCargo: string | null;
}

export type AppView =
  | 'home'
  | 'conversations'
  | 'channels'
  | 'announcements'
  | 'emergency'
  | 'employees'
  | 'administration'
  | 'audit-logs'
  | 'reports'
  | 'notifications'
  | 'profile';
