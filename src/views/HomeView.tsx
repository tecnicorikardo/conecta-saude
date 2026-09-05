import React from 'react';
import { useApp } from '../context/AppContext';
import { HierarchyBadge } from '../components/HierarchyBadge';
import {
  MessageSquare,
  Radio,
  FileText,
  AlertOctagon,
  Bell,
  Users,
  Flag,
  Shield,
  History,
  ChevronRight,
  Clock,
  CheckCircle2,
  AlertTriangle,
} from 'lucide-react';

interface HomeViewProps {
  onOpenEmergencyModal: () => void;
  onOpenAnnouncementModal: () => void;
}

export const HomeView: React.FC<HomeViewProps> = ({
  onOpenEmergencyModal,
  onOpenAnnouncementModal,
}) => {
  const {
    currentUser,
    setCurrentView,
    isAdmin,
    isCoord,
    canManageEmployees,
    canViewReports,
    canViewAudit,
    announcements,
    conversations,
    notifications,
    markAnnouncementAsRead,
  } = useApp();

  const unreadMessages = conversations.reduce((acc, c) => acc + c.naoLidas, 0);
  const unreadNotifs = notifications.filter((n) => !n.lida).length;

  const firstName = currentUser.nome.split(' ')[0];

  return (
    <div className="space-y-6 max-w-5xl mx-auto pb-12">
      {/* ─── 1. Institutional Welcome Card ─────────────────────────────── */}
      <div className="rounded-2xl p-6 bg-gradient-to-br from-[#1565C0] to-[#1976D2] text-white shadow-md relative overflow-hidden">
        <div className="absolute right-0 top-0 translate-x-8 -translate-y-8 w-48 h-48 bg-white/10 rounded-full blur-2xl pointer-events-none" />

        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 relative z-10">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-full bg-white/20 text-white font-bold text-xl flex items-center justify-center border-2 border-white/40 shadow-inner">
              {currentUser.nome.charAt(0)}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-xl font-bold tracking-tight">Olá, {firstName}</h2>
                <HierarchyBadge level={currentUser.hierarquiaNivel} size="sm" />
              </div>
              <p className="text-xs text-blue-100 mt-0.5">
                {currentUser.cargo} · {currentUser.setorNome}
              </p>
              <p className="text-[11px] text-blue-200 mt-1 font-mono">
                Matrícula: {currentUser.matricula || 'SUS-PADRÃO'}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 w-full sm:w-auto">
            <button
              onClick={() => setCurrentView('profile')}
              className="px-3.5 py-1.5 rounded-xl bg-white/15 hover:bg-white/25 text-xs font-semibold text-white border border-white/20 transition backdrop-blur-xs w-full sm:w-auto text-center"
            >
              Ver Cadastro
            </button>
            {isCoord && (
              <button
                onClick={onOpenAnnouncementModal}
                className="px-3.5 py-1.5 rounded-xl bg-white text-[#1565C0] hover:bg-blue-50 text-xs font-bold transition shadow-xs w-full sm:w-auto text-center"
              >
                + Comunicado
              </button>
            )}
          </div>
        </div>
      </div>

      {/* ─── 2. Emergency Quick Banner ─────────────────────────────────── */}
      <div
        onClick={onOpenEmergencyModal}
        className="rounded-2xl p-4 bg-red-50 border border-red-200 flex items-center justify-between cursor-pointer hover:bg-red-100/70 transition shadow-xs group"
      >
        <div className="flex items-center gap-3.5">
          <div className="w-11 h-11 rounded-xl bg-red-600 text-white flex items-center justify-center flex-shrink-0 group-hover:scale-105 transition shadow-xs">
            <AlertOctagon className="w-6 h-6" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-bold text-sm text-red-900">
                Central de Emergência e Protocolos Rápidos
              </span>
              <span className="bg-red-600 text-white text-[10px] font-extrabold px-2 py-0.5 rounded-full uppercase tracking-wider">
                Plantão 24h
              </span>
            </div>
            <p className="text-xs text-red-700 mt-0.5">
              Acionamento de ramais diretos (CCDTI, CCO, CCE) e disparo de alerta hospitalar
              prioritário.
            </p>
          </div>
        </div>
        <ChevronRight className="w-5 h-5 text-red-500 group-hover:translate-x-1 transition" />
      </div>

      {/* ─── 3. Quick Access Grid ─────────────────────────────────────── */}
      <div>
        <h3 className="text-xs font-bold text-gray-500 uppercase tracking-wider mb-3">
          Acesso Rápido
        </h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
          {/* Conversas */}
          <div
            onClick={() => setCurrentView('conversations')}
            className="p-4 bg-white rounded-2xl border border-gray-200 hover:border-blue-400 hover:shadow-md transition cursor-pointer flex flex-col justify-between"
          >
            <div className="flex items-center justify-between mb-2">
              <div className="w-9 h-9 rounded-xl bg-blue-50 text-[#1565C0] flex items-center justify-center">
                <MessageSquare className="w-5 h-5" />
              </div>
              {unreadMessages > 0 && (
                <span className="text-[10px] font-bold bg-blue-600 text-white px-2 py-0.5 rounded-full">
                  {unreadMessages}
                </span>
              )}
            </div>
            <div>
              <h4 className="font-bold text-sm text-gray-900">Conversas</h4>
              <p className="text-[11px] text-gray-500 mt-0.5">Mensagens diretas e equipes</p>
            </div>
          </div>

          {/* Canais */}
          <div
            onClick={() => setCurrentView('channels')}
            className="p-4 bg-white rounded-2xl border border-gray-200 hover:border-blue-400 hover:shadow-md transition cursor-pointer flex flex-col justify-between"
          >
            <div className="flex items-center justify-between mb-2">
              <div className="w-9 h-9 rounded-xl bg-sky-50 text-sky-700 flex items-center justify-center">
                <Radio className="w-5 h-5" />
              </div>
              <span className="text-[10px] font-semibold text-gray-400">Setores</span>
            </div>
            <div>
              <h4 className="font-bold text-sm text-gray-900">Canais Oficiais</h4>
              <p className="text-[11px] text-gray-500 mt-0.5">Isolados por centro e avisos</p>
            </div>
          </div>

          {/* Comunicados */}
          <div
            onClick={() => setCurrentView('announcements')}
            className="p-4 bg-white rounded-2xl border border-gray-200 hover:border-blue-400 hover:shadow-md transition cursor-pointer flex flex-col justify-between"
          >
            <div className="flex items-center justify-between mb-2">
              <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center">
                <FileText className="w-5 h-5" />
              </div>
              <span className="text-[10px] font-bold bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded-full">
                {announcements.length}
              </span>
            </div>
            <div>
              <h4 className="font-bold text-sm text-gray-900">Comunicados</h4>
              <p className="text-[11px] text-gray-500 mt-0.5">Diretrizes da Direção Geral</p>
            </div>
          </div>

          {/* Notificações */}
          <div
            onClick={() => setCurrentView('notifications')}
            className="p-4 bg-white rounded-2xl border border-gray-200 hover:border-blue-400 hover:shadow-md transition cursor-pointer flex flex-col justify-between"
          >
            <div className="flex items-center justify-between mb-2">
              <div className="w-9 h-9 rounded-xl bg-amber-50 text-amber-700 flex items-center justify-center">
                <Bell className="w-5 h-5" />
              </div>
              {unreadNotifs > 0 && (
                <span className="text-[10px] font-bold bg-amber-500 text-white px-2 py-0.5 rounded-full">
                  {unreadNotifs}
                </span>
              )}
            </div>
            <div>
              <h4 className="font-bold text-sm text-gray-900">Notificações</h4>
              <p className="text-[11px] text-gray-500 mt-0.5">Alertas e confirmações</p>
            </div>
          </div>

          {/* Funcionários (Direção) */}
          {canManageEmployees && (
            <div
              onClick={() => setCurrentView('employees')}
              className="p-4 bg-white rounded-2xl border border-gray-200 hover:border-purple-400 hover:shadow-md transition cursor-pointer flex flex-col justify-between"
            >
              <div className="flex items-center justify-between mb-2">
                <div className="w-9 h-9 rounded-xl bg-purple-50 text-purple-700 flex items-center justify-center">
                  <Users className="w-5 h-5" />
                </div>
                <span className="text-[10px] font-bold bg-purple-100 text-purple-800 px-2 py-0.5 rounded-full">
                  Direção
                </span>
              </div>
              <div>
                <h4 className="font-bold text-sm text-gray-900">Funcionários</h4>
                <p className="text-[11px] text-gray-500 mt-0.5">Controle de acessos e equipes</p>
              </div>
            </div>
          )}

          {/* Denúncias (Coord+) */}
          {canViewReports && (
            <div
              onClick={() => setCurrentView('reports')}
              className="p-4 bg-white rounded-2xl border border-gray-200 hover:border-red-400 hover:shadow-md transition cursor-pointer flex flex-col justify-between"
            >
              <div className="flex items-center justify-between mb-2">
                <div className="w-9 h-9 rounded-xl bg-red-50 text-red-700 flex items-center justify-center">
                  <Flag className="w-5 h-5" />
                </div>
                <span className="text-[10px] font-bold bg-red-100 text-red-800 px-2 py-0.5 rounded-full">
                  Ouvidoria
                </span>
              </div>
              <div>
                <h4 className="font-bold text-sm text-gray-900">Denúncias & Ética</h4>
                <p className="text-[11px] text-gray-500 mt-0.5">Gestão de conformidade</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ─── 4. Painel Administrativo (Coordenação e Direção) ───────────── */}
      {isCoord && (
        <div className="p-4 rounded-2xl bg-blue-50/70 border border-blue-200/80">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Shield className="w-4 h-4 text-[#1565C0]" />
              <h3 className="font-bold text-xs text-[#1565C0] uppercase tracking-wider">
                Painel Administrativo & Gestão
              </h3>
            </div>
            <span className="text-[11px] text-blue-700 font-medium">
              Visão Institucional Restrita
            </span>
          </div>

          <div className="flex flex-wrap gap-2">
            {canManageEmployees && (
              <button
                onClick={() => setCurrentView('employees')}
                className="px-3 py-1.5 bg-white rounded-xl border border-blue-200 text-xs font-semibold text-blue-900 hover:bg-blue-50 flex items-center gap-1.5 transition"
              >
                <Users className="w-3.5 h-3.5 text-[#1565C0]" />
                Gerenciar Funcionários
              </button>
            )}
            {canViewReports && (
              <button
                onClick={() => setCurrentView('reports')}
                className="px-3 py-1.5 bg-white rounded-xl border border-blue-200 text-xs font-semibold text-blue-900 hover:bg-blue-50 flex items-center gap-1.5 transition"
              >
                <Flag className="w-3.5 h-3.5 text-red-600" />
                Ouvidoria & Denúncias
              </button>
            )}
            {canViewAudit && (
              <button
                onClick={() => setCurrentView('audit-logs')}
                className="px-3 py-1.5 bg-white rounded-xl border border-blue-200 text-xs font-semibold text-blue-900 hover:bg-blue-50 flex items-center gap-1.5 transition"
              >
                <History className="w-3.5 h-3.5 text-[#1565C0]" />
                Trilhas de Auditoria
              </button>
            )}
            {isAdmin && (
              <button
                onClick={() => setCurrentView('administration')}
                className="px-3 py-1.5 bg-white rounded-xl border border-blue-200 text-xs font-semibold text-blue-900 hover:bg-blue-50 flex items-center gap-1.5 transition"
              >
                <Shield className="w-3.5 h-3.5 text-[#1565C0]" />
                Indicadores Globais
              </button>
            )}
          </div>
        </div>
      )}

      {/* ─── 5. Comunicados Recentes ────────────────────────────────────── */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-xs font-bold text-gray-500 uppercase tracking-wider">
            Comunicados Recentes da Rede
          </h3>
          <button
            onClick={() => setCurrentView('announcements')}
            className="text-xs font-semibold text-[#1565C0] hover:underline flex items-center gap-1"
          >
            Ver todos ({announcements.length})
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="space-y-3">
          {announcements.slice(0, 3).map((ann) => {
            const isUrgente = ann.prioridade === 'urgente';
            const isAlta = ann.prioridade === 'alta';

            return (
              <div
                key={ann.id}
                className={`p-4 rounded-2xl border transition bg-white shadow-xs ${
                  isUrgente
                    ? 'border-red-300 bg-red-50/20'
                    : isAlta
                    ? 'border-amber-200'
                    : 'border-gray-200'
                }`}
              >
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-2">
                  <div className="flex items-center gap-2">
                    <span
                      className={`text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-md ${
                        isUrgente
                          ? 'bg-red-600 text-white'
                          : isAlta
                          ? 'bg-amber-100 text-amber-900 border border-amber-300'
                          : 'bg-blue-100 text-blue-800'
                      }`}
                    >
                      {ann.prioridade}
                    </span>
                    <h4 className="font-bold text-sm text-gray-900 line-clamp-1">{ann.titulo}</h4>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-gray-500">
                    <Clock className="w-3.5 h-3.5" />
                    <span>{ann.publicadoEm}</span>
                  </div>
                </div>

                <p className="text-xs text-gray-700 line-clamp-2 mb-3 leading-relaxed">
                  {ann.mensagem}
                </p>

                <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-gray-100 text-xs">
                  <div className="text-[11px] text-gray-500">
                    Publicado por: <span className="font-medium text-gray-700">{ann.criadorNome}</span>
                  </div>

                  <div className="flex items-center gap-3">
                    <span className="text-[11px] text-gray-500">
                      {ann.visualizacoesPorcentagem}% visualizaram
                    </span>
                    {ann.lidoPorMim ? (
                      <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-green-700 bg-green-50 px-2 py-0.5 rounded-full border border-green-200">
                        <CheckCircle2 className="w-3 h-3" />
                        Leitura Confirmada
                      </span>
                    ) : (
                      <button
                        onClick={() => markAnnouncementAsRead(ann.id)}
                        className="px-2.5 py-1 text-xs font-bold text-white bg-[#1565C0] hover:bg-[#0D47A1] rounded-lg transition"
                      >
                        Confirmar Leitura
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
