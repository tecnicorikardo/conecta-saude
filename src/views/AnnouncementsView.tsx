import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import {
  FileText,
  Plus,
  Clock,
  CheckCircle2,
  AlertTriangle,
  CheckCheck,
  Eye,
  Building,
} from 'lucide-react';
import { AnnouncementPriority } from '../types';

interface AnnouncementsViewProps {
  onOpenNewModal: () => void;
}

export const AnnouncementsView: React.FC<AnnouncementsViewProps> = ({ onOpenNewModal }) => {
  const { announcements, markAnnouncementAsRead, isCoord, canPublishAnnouncement } = useApp();
  const [filterPriority, setFilterPriority] = useState<'all' | AnnouncementPriority>('all');

  const filtered = announcements.filter((a) => {
    if (filterPriority === 'all') return true;
    return a.prioridade === filterPriority;
  });

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-12">
      {/* Top Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-gray-200 shadow-xs">
        <div>
          <div className="flex items-center gap-2">
            <FileText className="w-5 h-5 text-[#1565C0]" />
            <h2 className="font-bold text-lg text-gray-900">Comunicados Oficiais</h2>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            Diretrizes, protocolos e avisos oficiais homologados pela Direção Geral e Coordenações.
          </p>
        </div>

        {canPublishAnnouncement && (
          <button
            onClick={onOpenNewModal}
            className="flex items-center gap-1.5 bg-[#1565C0] hover:bg-[#0D47A1] text-white px-4 py-2 rounded-xl text-xs font-bold transition shadow-xs self-start sm:self-auto"
          >
            <Plus className="w-4 h-4" />
            <span>Novo Comunicado</span>
          </button>
        )}
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        {[
          { id: 'all', label: 'Todos os Comunicados' },
          { id: 'urgente', label: '🚨 Urgentes' },
          { id: 'alta', label: '⚠️ Alta Prioridade' },
          { id: 'normal', label: 'Normal' },
        ].map((f) => (
          <button
            key={f.id}
            onClick={() => setFilterPriority(f.id as any)}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap transition ${
              filterPriority === f.id
                ? 'bg-[#1565C0] text-white shadow-xs'
                : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Announcements List */}
      <div className="space-y-4">
        {filtered.length === 0 ? (
          <div className="p-8 text-center bg-white rounded-2xl border border-gray-200 text-gray-400 text-xs">
            Nenhum comunicado encontrado com o filtro selecionado.
          </div>
        ) : (
          filtered.map((ann) => {
            const isUrgente = ann.prioridade === 'urgente';
            const isAlta = ann.prioridade === 'alta';

            return (
              <article
                key={ann.id}
                className={`bg-white rounded-2xl border p-5 shadow-xs transition space-y-3.5 ${
                  isUrgente
                    ? 'border-red-300 ring-1 ring-red-200 bg-red-50/15'
                    : isAlta
                    ? 'border-amber-300'
                    : 'border-gray-200'
                }`}
              >
                {/* Header */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div className="flex items-center gap-2.5">
                    <span
                      className={`text-[10px] font-extrabold uppercase px-2.5 py-1 rounded-md tracking-wider ${
                        isUrgente
                          ? 'bg-red-600 text-white'
                          : isAlta
                          ? 'bg-amber-100 text-amber-900 border border-amber-300'
                          : 'bg-blue-100 text-blue-800'
                      }`}
                    >
                      {ann.prioridade}
                    </span>
                    <h3 className="font-bold text-base text-gray-900">{ann.titulo}</h3>
                  </div>

                  <div className="flex items-center gap-1.5 text-xs text-gray-400">
                    <Clock className="w-3.5 h-3.5" />
                    <span>{ann.publicadoEm}</span>
                  </div>
                </div>

                {/* Body */}
                <p className="text-xs text-gray-700 leading-relaxed whitespace-pre-line">
                  {ann.mensagem}
                </p>

                {/* Footer and Read Engagement Bar */}
                <div className="pt-3 border-t border-gray-100 space-y-3">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
                    <div className="text-gray-500">
                      Emitido por:{' '}
                      <span className="font-semibold text-gray-800">{ann.criadorNome}</span> (
                      {ann.criadorCargo})
                    </div>

                    <div>
                      {ann.lidoPorMim ? (
                        <div className="inline-flex items-center gap-1.5 text-xs font-semibold text-green-700 bg-green-50 px-3 py-1 rounded-full border border-green-200">
                          <CheckCircle2 className="w-4 h-4 text-green-600" />
                          <span>Leitura Confirmada</span>
                        </div>
                      ) : (
                        <button
                          onClick={() => markAnnouncementAsRead(ann.id)}
                          className="px-4 py-1.5 text-xs font-bold text-white bg-[#1565C0] hover:bg-[#0D47A1] rounded-xl transition shadow-xs"
                        >
                          Confirmar Leitura Oficial
                        </button>
                      )}
                    </div>
                  </div>

                  {/* Read Rate Metric */}
                  <div>
                    <div className="flex items-center justify-between text-[11px] text-gray-500 mb-1">
                      <span className="flex items-center gap-1">
                        <Eye className="w-3.5 h-3.5 text-gray-400" />
                        Engajamento da Rede Hospitalar
                      </span>
                      <span className="font-bold text-blue-900">
                        {ann.visualizacoesPorcentagem}% dos colaboradores leram
                      </span>
                    </div>
                    <div className="w-full h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-blue-600 rounded-full transition-all duration-500"
                        style={{ width: `${ann.visualizacoesPorcentagem}%` }}
                      />
                    </div>
                  </div>
                </div>
              </article>
            );
          })
        )}
      </div>
    </div>
  );
};
