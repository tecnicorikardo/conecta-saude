import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { EMERGENCY_RAMAIS } from '../data/initialData';
import { AlertTriangle, PhoneCall, X, ShieldAlert, CheckCircle2 } from 'lucide-react';

interface EmergencyModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const EmergencyModal: React.FC<EmergencyModalProps> = ({ isOpen, onClose }) => {
  const { triggerEmergencyAlert, isCoord } = useApp();
  const [alertText, setAlertText] = useState('');
  const [confirmed, setConfirmed] = useState(false);
  const [successNotice, setSuccessNotice] = useState(false);

  if (!isOpen) return null;

  const handleBroadcast = (e: React.FormEvent) => {
    e.preventDefault();
    if (!alertText.trim()) return;
    triggerEmergencyAlert(alertText);
    setSuccessNotice(true);
    setTimeout(() => {
      setSuccessNotice(false);
      setAlertText('');
      setConfirmed(false);
      onClose();
    }, 2000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
      <div className="bg-white rounded-2xl max-w-lg w-full overflow-hidden shadow-2xl border border-red-200">
        {/* Header */}
        <div className="bg-red-700 text-white p-5 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center">
              <ShieldAlert className="w-6 h-6 text-white" />
            </div>
            <div>
              <h3 className="font-bold text-lg leading-tight">Protocolo de Emergência Hospitalar</h3>
              <p className="text-xs text-red-100">Rede Integrada CCDTI · CCO · CCE · Direção</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-white/80 hover:text-white p-1 rounded-lg hover:bg-white/10 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6 space-y-5 max-h-[75vh] overflow-y-auto">
          {successNotice ? (
            <div className="text-center py-8">
              <CheckCircle2 className="w-16 h-16 text-green-600 mx-auto mb-3 animate-bounce" />
              <h4 className="text-lg font-bold text-gray-900">Alerta Geral Disparado!</h4>
              <p className="text-sm text-gray-600 mt-1">
                Todas as equipes e coordenadorias foram notificadas imediatamente no canal prioritário.
              </p>
            </div>
          ) : (
            <>
              {/* Ramais diretos */}
              <div>
                <h4 className="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                  <PhoneCall className="w-4 h-4 text-red-600" />
                  Ramais de Acionamento Imediato
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
                  {EMERGENCY_RAMAIS.map((item, idx) => (
                    <div
                      key={idx}
                      className="p-3 bg-red-50/70 rounded-xl border border-red-100 flex flex-col justify-between"
                    >
                      <div>
                        <span className="font-semibold text-gray-900 block line-clamp-1">
                          {item.centro}
                        </span>
                        <span className="text-[11px] text-gray-500">{item.responsavel}</span>
                      </div>
                      <div className="mt-2 font-mono font-bold text-red-700 text-sm">
                        {item.ramal} · {item.direto}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Disparo de Alerta Geral (Liderança e Coordenação) */}
              <div className="pt-3 border-t border-gray-100">
                <div className="flex items-center gap-2 mb-2">
                  <AlertTriangle className="w-4 h-4 text-red-600" />
                  <h4 className="text-xs font-bold text-gray-700 uppercase tracking-wider">
                    Disparar Alerta na Rede Hospitalar
                  </h4>
                </div>
                {isCoord ? (
                  <form onSubmit={handleBroadcast} className="space-y-3">
                    <p className="text-xs text-gray-600">
                      Este aviso exibirá um banner prioritário vermelho instantâneo para todos os
                      funcionários conectados e publicará no canal oficial de emergência.
                    </p>
                    <textarea
                      value={alertText}
                      onChange={(e) => setAlertText(e.target.value)}
                      placeholder="Ex: Acionamento de Código Amarelo na UTI. Equipes de apoio de plantão comparecer ao posto central..."
                      rows={3}
                      className="w-full text-xs p-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-red-500 focus:outline-none"
                      required
                    />

                    <label className="flex items-center gap-2 text-xs text-gray-700 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={confirmed}
                        onChange={(e) => setConfirmed(e.target.checked)}
                        className="rounded text-red-600 focus:ring-red-500"
                        required
                      />
                      <span>Confirmo a gravidade e veracidade institucional deste acionamento.</span>
                    </label>

                    <div className="flex justify-end gap-2 pt-2">
                      <button
                        type="button"
                        onClick={onClose}
                        className="px-4 py-2 text-xs font-semibold text-gray-600 hover:bg-gray-100 rounded-xl"
                      >
                        Cancelar
                      </button>
                      <button
                        type="submit"
                        disabled={!confirmed || !alertText.trim()}
                        className="px-4 py-2 text-xs font-bold text-white bg-red-600 hover:bg-red-700 disabled:opacity-50 rounded-xl transition shadow-sm"
                      >
                        Disparar Alerta Imediato
                      </button>
                    </div>
                  </form>
                ) : (
                  <div className="p-3 bg-amber-50 rounded-xl border border-amber-200 text-xs text-amber-800">
                    O disparo de alertas gerais é restrito à <strong>Direção Geral</strong> e{' '}
                    <strong>Coordenação Médica</strong>. Para urgências, utilize os ramais diretos
                    acima.
                  </div>
                )}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};
