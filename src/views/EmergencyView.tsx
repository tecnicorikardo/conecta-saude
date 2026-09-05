import React from 'react';
import { useApp } from '../context/AppContext';
import { EMERGENCY_RAMAIS } from '../data/initialData';
import {
  AlertOctagon,
  PhoneCall,
  ShieldAlert,
  AlertTriangle,
  Clock,
  CheckCircle2,
  BellRing,
} from 'lucide-react';

interface EmergencyViewProps {
  onOpenEmergencyModal: () => void;
}

export const EmergencyView: React.FC<EmergencyViewProps> = ({ onOpenEmergencyModal }) => {
  const { emergencyAlertActive, emergencyAlertMessage, isCoord, messages } = useApp();

  const emergencyMessages = messages.filter((m) => m.channelId === 'chn-emergencia');

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-12">
      {/* Hero Banner */}
      <div className="bg-gradient-to-r from-red-700 via-red-600 to-rose-700 rounded-2xl p-6 text-white shadow-md">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-2xl bg-white/20 flex items-center justify-center flex-shrink-0 shadow-inner">
              <ShieldAlert className="w-8 h-8 text-white" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-xl font-bold tracking-tight">Central de Emergência e Crises</h2>
                <span className="bg-white/20 text-white text-[10px] font-extrabold px-2 py-0.5 rounded-full uppercase">
                  Plantão Permanente
                </span>
              </div>
              <p className="text-xs text-red-100 mt-1 leading-relaxed">
                Linha de acionamento imediato e protocolos de contingência da Rede Hospitalar SUS.
              </p>
            </div>
          </div>

          <button
            onClick={onOpenEmergencyModal}
            className="px-5 py-2.5 bg-white text-red-700 hover:bg-red-50 text-xs font-bold rounded-xl shadow-md transition flex items-center gap-2 self-start sm:self-auto"
          >
            <BellRing className="w-4 h-4 animate-bounce" />
            <span>Disparar Alerta Hospitalar</span>
          </button>
        </div>
      </div>

      {/* Active Alert Notice if triggered */}
      {emergencyAlertActive && (
        <div className="p-4 bg-red-100 border-2 border-red-500 rounded-2xl text-red-900 flex items-start gap-3">
          <AlertTriangle className="w-6 h-6 text-red-600 flex-shrink-0 mt-0.5 animate-pulse" />
          <div>
            <h4 className="font-bold text-sm">ALERTA VERMELHO ATIVO NA REDE</h4>
            <p className="text-xs text-red-800 mt-0.5">{emergencyAlertMessage}</p>
          </div>
        </div>
      )}

      {/* Direct Ramais Grid */}
      <div>
        <h3 className="text-xs font-bold text-gray-500 uppercase tracking-wider mb-3 flex items-center gap-2">
          <PhoneCall className="w-4 h-4 text-red-600" />
          Ramais Diretos dos Centros Hospitalares
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {EMERGENCY_RAMAIS.map((item, idx) => (
            <div
              key={idx}
              className="p-4 bg-white rounded-2xl border border-gray-200 hover:border-red-300 shadow-xs transition flex flex-col justify-between"
            >
              <div>
                <span className="text-[10px] font-extrabold text-red-700 uppercase tracking-wider block">
                  Linha de Urgência
                </span>
                <h4 className="font-bold text-sm text-gray-900 mt-0.5">{item.centro}</h4>
                <p className="text-xs text-gray-500 mt-0.5">{item.responsavel}</p>
              </div>

              <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between">
                <div>
                  <span className="text-base font-bold font-mono text-red-700">{item.ramal}</span>
                  <span className="text-xs text-gray-400 block font-mono">{item.direto}</span>
                </div>
                <button
                  onClick={() => alert(`Chamada direta para ${item.ramal} (${item.centro})`)}
                  className="px-3 py-1.5 bg-red-50 hover:bg-red-100 text-red-700 rounded-xl text-xs font-bold transition flex items-center gap-1.5"
                >
                  <PhoneCall className="w-3.5 h-3.5" />
                  Chamar
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Protocol Codes */}
      <div className="bg-white rounded-2xl border border-gray-200 p-5 shadow-xs">
        <h3 className="text-xs font-bold text-gray-500 uppercase tracking-wider mb-3">
          Protocolos de Contingência Padronizados SUS
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
          <div className="p-3 bg-amber-50/70 border border-amber-200 rounded-xl">
            <span className="font-extrabold text-amber-900 block mb-1">CÓDIGO AMARELO</span>
            <p className="text-amber-800 text-[11px] leading-relaxed">
              Sobrecarregamento de leitos ou atraso imprevisto em laudos críticos. Acionar reforço de
              plantão ambulatorial.
            </p>
          </div>
          <div className="p-3 bg-red-50/70 border border-red-200 rounded-xl">
            <span className="font-extrabold text-red-900 block mb-1">CÓDIGO VERMELHO</span>
            <p className="text-red-800 text-[11px] leading-relaxed">
              Parada cardiorrespiratória ou trauma grave no centro de imagem/cirurgia. Prioridade
              absoluta no canal.
            </p>
          </div>
          <div className="p-3 bg-purple-50/70 border border-purple-200 rounded-xl">
            <span className="font-extrabold text-purple-900 block mb-1">CÓDIGO ROXO</span>
            <p className="text-purple-800 text-[11px] leading-relaxed">
              Evacuação estrutural, sinistro ou falha em gases medicinais. Seguir rotas de fuga dos
              anexos hospitalares.
            </p>
          </div>
        </div>
      </div>

      {/* Recent Emergency Channel Broadcasts */}
      <div className="bg-white rounded-2xl border border-gray-200 p-5 shadow-xs">
        <h3 className="text-xs font-bold text-gray-500 uppercase tracking-wider mb-3">
          Histórico de Transmissões de Alerta
        </h3>
        <div className="space-y-2">
          {emergencyMessages.length === 0 ? (
            <p className="text-xs text-gray-400">Nenhum alerta recente registrado no canal.</p>
          ) : (
            emergencyMessages.map((msg) => (
              <div
                key={msg.id}
                className="p-3 bg-red-50/40 rounded-xl border border-red-100 flex items-start gap-3"
              >
                <AlertOctagon className="w-4 h-4 text-red-600 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-bold text-gray-900">{msg.remetenteNome}</span>
                    <span className="text-[10px] text-gray-400">{msg.createdAt}</span>
                  </div>
                  <p className="text-xs text-gray-700 mt-1">{msg.texto}</p>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};
