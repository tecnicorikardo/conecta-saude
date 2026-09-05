import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { Flag, X, CheckCircle2, ShieldCheck } from 'lucide-react';

interface ReportModalProps {
  isOpen: boolean;
  onClose: () => void;
  messageSnippet?: string;
  senderName?: string;
}

export const ReportModal: React.FC<ReportModalProps> = ({
  isOpen,
  onClose,
  messageSnippet,
  senderName,
}) => {
  const { addReport } = useApp();
  const [motivo, setMotivo] = useState('Comunicação imprópria');
  const [descricao, setDescricao] = useState('');
  const [submitted, setSubmitted] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    addReport(motivo, descricao, messageSnippet);
    setSubmitted(true);
    setTimeout(() => {
      setSubmitted(false);
      setDescricao('');
      onClose();
    }, 1800);
  };

  const motivos = [
    'Assédio moral ou desrespeito',
    'Ofensa ou discriminação',
    'Conteúdo institucional inadequado',
    'Comunicação imprópria em canal público',
    'Violação de sigilo médico ou de dados',
    'Outro',
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
      <div className="bg-white rounded-2xl max-w-md w-full overflow-hidden shadow-2xl border border-gray-200">
        <div className="bg-[#1565C0] text-white p-4 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <Flag className="w-5 h-5 text-amber-300" />
            <div>
              <h3 className="font-bold text-sm">Denunciar Mensagem / Conduta</h3>
              <p className="text-[11px] text-blue-100">Canal de Integridade e Ética Hospitalar</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-white/10 text-white">
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-5">
          {submitted ? (
            <div className="text-center py-6">
              <CheckCircle2 className="w-12 h-12 text-green-600 mx-auto mb-2 animate-bounce" />
              <h4 className="text-base font-bold text-gray-900">Ocorrência Registrada com Sucesso</h4>
              <p className="text-xs text-gray-600 mt-1">
                Sua comunicação foi encaminhada para a comissão de ética e direção de forma segura e
                rastreada.
              </p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="flex items-center gap-2 p-2.5 bg-blue-50/70 border border-blue-100 rounded-xl text-xs text-blue-900">
                <ShieldCheck className="w-4 h-4 text-blue-600 flex-shrink-0" />
                <span>
                  Garantia de sigilo e não retaliação conforme protocolo institucional do SUS.
                </span>
              </div>

              {messageSnippet && (
                <div className="p-2.5 bg-gray-50 border border-gray-200 rounded-lg text-xs">
                  <div className="text-[10px] font-bold text-gray-400 uppercase">
                    Trecho Selecionado {senderName ? `(${senderName})` : ''}
                  </div>
                  <p className="italic text-gray-700 mt-0.5">{messageSnippet}</p>
                </div>
              )}

              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">
                  Qual é a natureza do relato?
                </label>
                <div className="space-y-1.5">
                  {motivos.map((m) => (
                    <label
                      key={m}
                      className="flex items-center gap-2 text-xs text-gray-700 cursor-pointer p-1.5 rounded-lg hover:bg-gray-50"
                    >
                      <input
                        type="radio"
                        name="motivo"
                        value={m}
                        checked={motivo === m}
                        onChange={() => setMotivo(m)}
                        className="text-[#1565C0] focus:ring-[#1565C0]"
                      />
                      <span>{m}</span>
                    </label>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">
                  Descrição detalhada do ocorrido:
                </label>
                <textarea
                  value={descricao}
                  onChange={(e) => setDescricao(e.target.value)}
                  placeholder="Descreva o contexto, horário e envolvidos..."
                  rows={3}
                  required
                  className="w-full text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
                />
              </div>

              <div className="flex justify-end gap-2 pt-2 border-t border-gray-100">
                <button
                  type="button"
                  onClick={onClose}
                  className="px-3.5 py-1.5 text-xs font-semibold text-gray-600 hover:bg-gray-100 rounded-xl"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={!descricao.trim()}
                  className="px-4 py-1.5 text-xs font-bold text-white bg-[#1565C0] hover:bg-[#0D47A1] disabled:opacity-50 rounded-xl transition"
                >
                  Registrar Ocorrência
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};
