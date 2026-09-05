import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { Flag, CheckCircle2, Clock, ShieldCheck, AlertTriangle } from 'lucide-react';
import { Report } from '../types';

export const ReportsView: React.FC = () => {
  const { reports, updateReportStatus } = useApp();
  const [filterStatus, setFilterStatus] = useState<'all' | 'pendente' | 'em_analise' | 'resolvido'>(
    'all'
  );

  const filtered = reports.filter((r) => {
    if (filterStatus === 'all') return true;
    return r.status === filterStatus;
  });

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-12">
      {/* Header */}
      <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-xs">
        <div className="flex items-center gap-2">
          <Flag className="w-5 h-5 text-red-600" />
          <h2 className="font-bold text-lg text-gray-900">Ouvidoria, Denúncias & Ética</h2>
        </div>
        <p className="text-xs text-gray-500 mt-1">
          Triagem de ocorrências de assédio, descumprimento de conduta e relatos anônimos da rede
          hospitalar.
        </p>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2">
        {[
          { id: 'all', label: 'Todas as Ocorrências' },
          { id: 'pendente', label: 'Pendentes' },
          { id: 'em_analise', label: 'Em Análise' },
          { id: 'resolvido', label: 'Resolvidas' },
        ].map((f) => (
          <button
            key={f.id}
            onClick={() => setFilterStatus(f.id as any)}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition ${
              filterStatus === f.id
                ? 'bg-red-700 text-white shadow-xs'
                : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Reports List */}
      <div className="space-y-4">
        {filtered.length === 0 ? (
          <div className="p-8 text-center bg-white rounded-2xl border border-gray-200 text-gray-400 text-xs">
            Nenhuma ocorrência encontrada com o filtro selecionado.
          </div>
        ) : (
          filtered.map((rep) => {
            const isPendente = rep.status === 'pendente';
            const isAnalise = rep.status === 'em_analise';
            const isResolvido = rep.status === 'resolvido';

            return (
              <div
                key={rep.id}
                className="bg-white rounded-2xl border border-gray-200 p-5 shadow-xs space-y-3"
              >
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div>
                    <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">
                      Protocolo #{rep.id.slice(-6)}
                    </span>
                    <h3 className="font-bold text-sm text-gray-900 mt-0.5">{rep.motivo}</h3>
                  </div>

                  <div>
                    {isPendente && (
                      <span className="text-[10px] font-bold bg-amber-100 text-amber-900 border border-amber-300 px-2.5 py-1 rounded-full uppercase">
                        Pendente
                      </span>
                    )}
                    {isAnalise && (
                      <span className="text-[10px] font-bold bg-blue-100 text-blue-900 border border-blue-300 px-2.5 py-1 rounded-full uppercase">
                        Em Análise
                      </span>
                    )}
                    {isResolvido && (
                      <span className="text-[10px] font-bold bg-green-100 text-green-900 border border-green-300 px-2.5 py-1 rounded-full uppercase">
                        Resolvido
                      </span>
                    )}
                  </div>
                </div>

                {rep.mensagemTrecho && (
                  <div className="p-3 bg-gray-50 border-l-4 border-red-500 rounded-r-xl text-xs text-gray-700 italic">
                    {rep.mensagemTrecho}
                  </div>
                )}

                <p className="text-xs text-gray-700 leading-relaxed">{rep.descricao}</p>

                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-3 border-t border-gray-100 text-xs">
                  <div className="text-gray-500 text-[11px]">
                    Registrado em <span className="font-medium">{rep.createdAt}</span> · {rep.autorNome}
                  </div>

                  <div className="flex items-center gap-2">
                    {rep.status !== 'em_analise' && (
                      <button
                        onClick={() => updateReportStatus(rep.id, 'em_analise')}
                        className="px-3 py-1 bg-blue-50 text-blue-700 hover:bg-blue-100 rounded-xl text-xs font-semibold transition"
                      >
                        Iniciar Análise
                      </button>
                    )}
                    {rep.status !== 'resolvido' && (
                      <button
                        onClick={() => updateReportStatus(rep.id, 'resolvido')}
                        className="px-3 py-1 bg-green-50 text-green-700 hover:bg-green-100 rounded-xl text-xs font-semibold transition"
                      >
                        Marcar como Resolvido
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};
