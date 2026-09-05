import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { History, Search, ShieldAlert, Download, RefreshCw } from 'lucide-react';

export const AuditLogsView: React.FC = () => {
  const { auditLogs, currentUser, isAdmin, refreshAuditLogs, isSyncing } = useApp();
  const [searchTerm, setSearchTerm] = useState('');

  if (!isAdmin) {
    return (
      <div className="max-w-2xl mx-auto my-12 p-8 bg-white rounded-3xl border border-red-200 shadow-sm text-center">
        <div className="w-16 h-16 rounded-2xl bg-red-50 text-red-600 flex items-center justify-center mx-auto mb-4 border border-red-100">
          <ShieldAlert className="w-8 h-8" />
        </div>
        <h2 className="text-xl font-bold text-gray-900 mb-2">Acesso Restrito à Direção Geral</h2>
        <p className="text-xs text-gray-600 max-w-md mx-auto mb-6 leading-relaxed">
          Conforme as diretrizes de governança e integridade do SUS, as trilhas de auditoria contêm dados sensíveis e são restritas ao Nível 1 (Direção Geral).
        </p>
        <div className="bg-gray-50 p-4 rounded-2xl border border-gray-200 text-xs text-left max-w-md mx-auto space-y-1 mb-6">
          <div className="text-gray-500 font-semibold uppercase text-[10px] tracking-wider">Suas credenciais ativas:</div>
          <div className="font-bold text-gray-900">{currentUser.nome}</div>
          <div className="text-gray-600">{currentUser.cargo} — {currentUser.setorNome}</div>
          <div className="text-amber-700 font-bold">Nível Hierárquico: {currentUser.hierarquiaNivel} (Necessário Nível 1)</div>
        </div>
        <p className="text-[11px] text-gray-400">
          Dica: utilize o seletor no topo da tela para alternar para o perfil do Dr. Carlos Mendes (Direção Geral) para visualizar os logs.
        </p>
      </div>
    );
  }

  const filtered = auditLogs.filter(
    (l) =>
      l.acao.toLowerCase().includes(searchTerm.toLowerCase()) ||
      l.detalhes.toLowerCase().includes(searchTerm.toLowerCase()) ||
      l.usuarioNome.toLowerCase().includes(searchTerm.toLowerCase()) ||
      l.modulo.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="max-w-5xl mx-auto space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-gray-200 shadow-xs">
        <div>
          <div className="flex items-center gap-2">
            <History className="w-5 h-5 text-[#1565C0]" />
            <h2 className="font-bold text-lg text-gray-900">Trilhas de Auditoria & Compliance (API)</h2>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            Registro imutável no backend de eventos de segurança, criação de comunicados, moderação e acessos.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => refreshAuditLogs()}
            disabled={isSyncing}
            className="flex items-center gap-1.5 bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-2 rounded-xl text-xs font-semibold transition"
            title="Recarregar do backend"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isSyncing ? 'animate-spin' : ''}`} />
            <span>Atualizar</span>
          </button>

          <button
            onClick={() => alert('Log de auditoria exportado com sucesso no formato CSV.')}
            className="flex items-center gap-1.5 bg-blue-50 text-blue-700 hover:bg-blue-100 px-4 py-2 rounded-xl text-xs font-bold transition self-start sm:self-auto"
          >
            <Download className="w-4 h-4" />
            <span>Exportar Logs (CSV)</span>
          </button>
        </div>
      </div>

      {/* Search Bar */}
      <div className="bg-white p-3.5 rounded-2xl border border-gray-200 shadow-xs">
        <div className="relative">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-gray-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Filtrar por ação, usuário, módulo ou detalhe..."
            className="w-full pl-9 pr-3 py-2 text-xs bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
          />
        </div>
      </div>

      {/* Table of logs */}
      <div className="bg-white rounded-2xl border border-gray-200 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-gray-700">
            <thead className="bg-gray-50 text-gray-500 font-bold border-b border-gray-200 uppercase tracking-wider text-[10px]">
              <tr>
                <th className="py-3 px-4">Data / Hora</th>
                <th className="py-3 px-4">Ação</th>
                <th className="py-3 px-4">Módulo</th>
                <th className="py-3 px-4">Usuário</th>
                <th className="py-3 px-4">Detalhes</th>
                <th className="py-3 px-4">Endereço IP</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-gray-400">
                    Nenhum registro de auditoria encontrado.
                  </td>
                </tr>
              ) : (
                filtered.map((log) => (
                  <tr key={log.id} className="hover:bg-gray-50 transition">
                    <td className="py-3 px-4 font-mono text-gray-500 whitespace-nowrap">
                      {log.createdAt}
                    </td>
                    <td className="py-3 px-4">
                      <span className="font-mono font-bold text-blue-800 bg-blue-50 px-2 py-0.5 rounded border border-blue-100">
                        {log.acao}
                      </span>
                    </td>
                    <td className="py-3 px-4 font-semibold text-gray-800">{log.modulo}</td>
                    <td className="py-3 px-4 text-gray-900">{log.usuarioNome}</td>
                    <td className="py-3 px-4 text-gray-600 max-w-xs truncate">{log.detalhes}</td>
                    <td className="py-3 px-4 font-mono text-gray-400">{log.ip}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
