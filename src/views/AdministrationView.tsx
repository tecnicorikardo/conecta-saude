import React from 'react';
import { useApp } from '../context/AppContext';
import {
  Shield,
  Users,
  Building2,
  FileCheck,
  Flag,
  Activity,
  Download,
  AlertOctagon,
  CheckCircle2,
} from 'lucide-react';

export const AdministrationView: React.FC = () => {
  const { users, announcements, channels, reports, auditLogs, setCurrentView, currentUser, isAdmin } = useApp();

  if (!isAdmin) {
    return (
      <div className="max-w-2xl mx-auto my-12 p-8 bg-white rounded-3xl border border-red-200 shadow-sm text-center">
        <div className="w-16 h-16 rounded-2xl bg-red-50 text-red-600 flex items-center justify-center mx-auto mb-4 border border-red-100">
          <Shield className="w-8 h-8" />
        </div>
        <h2 className="text-xl font-bold text-gray-900 mb-2">Painel Exclusivo da Direção Geral</h2>
        <p className="text-xs text-gray-600 max-w-md mx-auto mb-6 leading-relaxed">
          Os indicadores consolidados de governança, auditoria e taxas de leitura institucionais são reservados ao Nível 1 (Direção Geral).
        </p>
        <div className="bg-gray-50 p-4 rounded-2xl border border-gray-200 text-xs text-left max-w-md mx-auto space-y-1 mb-6">
          <div className="text-gray-500 font-semibold uppercase text-[10px] tracking-wider">Perfil ativo:</div>
          <div className="font-bold text-gray-900">{currentUser.nome}</div>
          <div className="text-gray-600">{currentUser.cargo} — {currentUser.setorNome}</div>
          <div className="text-amber-700 font-bold">Nível Hierárquico: {currentUser.hierarquiaNivel} (Necessário Nível 1)</div>
        </div>
        <p className="text-[11px] text-gray-400">
          Utilize o menu no cabeçalho para alternar para um membro da Direção Geral (ex: Dr. Carlos Mendes) caso deseje avaliar o painel.
        </p>
      </div>
    );
  }

  const totalUsers = users.length;
  const activeUsers = users.filter((u) => u.ativo).length;
  const pendingReports = reports.filter((r) => r.status === 'pendente').length;

  // Average read confirmation rate
  const avgReadRate = Math.round(
    announcements.reduce((acc, a) => acc + a.visualizacoesPorcentagem, 0) /
      (announcements.length || 1)
  );

  // Users per center
  const centerCounts = {
    CCDTI: users.filter((u) => u.setorId === 'sec-ccdti').length,
    CCO: users.filter((u) => u.setorId === 'sec-cco').length,
    CCE: users.filter((u) => u.setorId === 'sec-cce').length,
    DIRECAO: users.filter((u) => u.setorId === 'sec-direcao').length,
  };

  return (
    <div className="max-w-5xl mx-auto space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-gray-200 shadow-xs">
        <div>
          <div className="flex items-center gap-2">
            <Shield className="w-5 h-5 text-[#1565C0]" />
            <h2 className="font-bold text-lg text-gray-900">Painel Executivo da Direção Geral</h2>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            Consolidação de indicadores, governança hospitalar e integridade da rede SUS.
          </p>
        </div>

        <button
          onClick={() => alert('Relatório analítico em PDF gerado com sucesso.')}
          className="flex items-center gap-1.5 bg-blue-50 text-blue-700 hover:bg-blue-100 px-4 py-2 rounded-xl text-xs font-bold transition self-start sm:self-auto"
        >
          <Download className="w-4 h-4" />
          <span>Exportar Relatório</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-xs">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Quadro Funcional
            </span>
            <div className="w-8 h-8 rounded-xl bg-blue-50 text-[#1565C0] flex items-center justify-center">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-900">{activeUsers}</div>
          <p className="text-[11px] text-gray-500 mt-1">
            de {totalUsers} colaboradores ativos ({Math.round((activeUsers / totalUsers) * 100)}%)
          </p>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-xs">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Taxa de Leitura
            </span>
            <div className="w-8 h-8 rounded-xl bg-green-50 text-green-700 flex items-center justify-center">
              <FileCheck className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-900">{avgReadRate}%</div>
          <p className="text-[11px] text-green-700 mt-1 font-semibold flex items-center gap-1">
            <CheckCircle2 className="w-3 h-3" />
            Conformidade institucional alta
          </p>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-xs">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Canais & Setores
            </span>
            <div className="w-8 h-8 rounded-xl bg-sky-50 text-sky-700 flex items-center justify-center">
              <Building2 className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-900">{channels.length}</div>
          <p className="text-[11px] text-gray-500 mt-1">Centros CCDTI, CCO e CCE integrados</p>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-xs">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
              Ocorrências Ouvidoria
            </span>
            <div className="w-8 h-8 rounded-xl bg-red-50 text-red-700 flex items-center justify-center">
              <Flag className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-900">{pendingReports}</div>
          <p className="text-[11px] text-amber-700 mt-1 font-semibold">
            {pendingReports > 0 ? 'Exigem triagem da comissão' : 'Nenhuma pendente'}
          </p>
        </div>
      </div>

      {/* Breakdown by Sector & Hierarchical Level */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        {/* Sector distribution */}
        <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-xs space-y-4">
          <h3 className="font-bold text-sm text-gray-900 flex items-center gap-2">
            <Building2 className="w-4 h-4 text-[#1565C0]" />
            Distribuição por Unidade Hospitalar
          </h3>

          <div className="space-y-3 text-xs">
            <div>
              <div className="flex justify-between mb-1">
                <span className="font-semibold text-gray-800">CCDTI — Tomografia & Imagem</span>
                <span className="text-gray-500 font-mono">{centerCounts.CCDTI} colaboradores</span>
              </div>
              <div className="w-full h-2.5 bg-gray-100 rounded-full overflow-hidden">
                <div
                  className="h-full bg-blue-600 rounded-full"
                  style={{ width: `${(centerCounts.CCDTI / totalUsers) * 100}%` }}
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between mb-1">
                <span className="font-semibold text-gray-800">CCO — Centro Carioca do Olho</span>
                <span className="text-gray-500 font-mono">{centerCounts.CCO} colaboradores</span>
              </div>
              <div className="w-full h-2.5 bg-gray-100 rounded-full overflow-hidden">
                <div
                  className="h-full bg-sky-500 rounded-full"
                  style={{ width: `${(centerCounts.CCO / totalUsers) * 100}%` }}
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between mb-1">
                <span className="font-semibold text-gray-800">CCE — Especialidades & Regulação</span>
                <span className="text-gray-500 font-mono">{centerCounts.CCE} colaboradores</span>
              </div>
              <div className="w-full h-2.5 bg-gray-100 rounded-full overflow-hidden">
                <div
                  className="h-full bg-emerald-500 rounded-full"
                  style={{ width: `${(centerCounts.CCE / totalUsers) * 100}%` }}
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between mb-1">
                <span className="font-semibold text-gray-800">Direção Geral</span>
                <span className="text-gray-500 font-mono">{centerCounts.DIRECAO} colaboradores</span>
              </div>
              <div className="w-full h-2.5 bg-gray-100 rounded-full overflow-hidden">
                <div
                  className="h-full bg-purple-600 rounded-full"
                  style={{ width: `${(centerCounts.DIRECAO / totalUsers) * 100}%` }}
                />
              </div>
            </div>
          </div>
        </div>

        {/* Security & Audit Summary */}
        <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-xs space-y-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-bold text-sm text-gray-900 flex items-center gap-2">
                <Activity className="w-4 h-4 text-[#1565C0]" />
                Governança & Auditoria Recente
              </h3>
              <button
                onClick={() => setCurrentView('audit-logs')}
                className="text-xs text-[#1565C0] font-semibold hover:underline"
              >
                Ver todas
              </button>
            </div>
            <p className="text-xs text-gray-500 mb-3">
              Últimas ações registradas de forma auditável e imutável no sistema:
            </p>

            <div className="space-y-2 text-xs">
              {auditLogs.slice(0, 3).map((log) => (
                <div key={log.id} className="p-2.5 bg-gray-50 rounded-xl border border-gray-100">
                  <div className="flex justify-between text-[11px] text-gray-400 font-mono">
                    <span>{log.acao}</span>
                    <span>{log.createdAt.split(' ')[0]}</span>
                  </div>
                  <div className="font-semibold text-gray-900 mt-0.5">{log.detalhes}</div>
                </div>
              ))}
            </div>
          </div>

          <div className="pt-3 border-t border-gray-100 flex gap-2">
            <button
              onClick={() => setCurrentView('employees')}
              className="flex-1 py-2 text-xs font-bold text-blue-900 bg-blue-50 hover:bg-blue-100 rounded-xl transition text-center"
            >
              Gerenciar Equipes
            </button>
            <button
              onClick={() => setCurrentView('reports')}
              className="flex-1 py-2 text-xs font-bold text-red-900 bg-red-50 hover:bg-red-100 rounded-xl transition text-center"
            >
              Painel de Ouvidoria
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
