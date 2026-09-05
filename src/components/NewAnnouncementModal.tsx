import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { AnnouncementPriority } from '../types';
import { FileText, X } from 'lucide-react';

interface NewAnnouncementModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const NewAnnouncementModal: React.FC<NewAnnouncementModalProps> = ({ isOpen, onClose }) => {
  const { addAnnouncement, currentUser } = useApp();
  const [titulo, setTitulo] = useState('');
  const [mensagem, setMensagem] = useState('');
  const [prioridade, setPrioridade] = useState<AnnouncementPriority>('normal');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!titulo.trim() || !mensagem.trim()) return;

    addAnnouncement({
      titulo,
      mensagem,
      prioridade,
      criadoPor: currentUser.id,
      criadorNome: currentUser.nome,
      criadorCargo: currentUser.cargo,
      ativo: true,
      setorId: currentUser.setorId,
    });

    setTitulo('');
    setMensagem('');
    setPrioridade('normal');
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
      <div className="bg-white rounded-2xl max-w-lg w-full overflow-hidden shadow-2xl border border-gray-200">
        <div className="bg-[#1565C0] text-white p-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <FileText className="w-5 h-5 text-blue-200" />
            <div>
              <h3 className="font-bold text-sm">Publicar Comunicado Oficial</h3>
              <p className="text-[11px] text-blue-100">Expedido por: {currentUser.cargo}</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-white/10 text-white">
            <X className="w-4 h-4" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-5 space-y-4">
          <div>
            <label className="block text-xs font-bold text-gray-700 mb-1">
              Título do Comunicado
            </label>
            <input
              type="text"
              value={titulo}
              onChange={(e) => setTitulo(e.target.value)}
              placeholder="Ex: Reunião Integrada de Coordenação"
              required
              className="w-full text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-gray-700 mb-1">Nível de Prioridade</label>
            <div className="grid grid-cols-3 gap-2">
              {[
                { id: 'normal', label: 'Normal', color: 'border-blue-300 text-blue-700 bg-blue-50/50' },
                { id: 'alta', label: 'Alta', color: 'border-amber-300 text-amber-700 bg-amber-50/50' },
                { id: 'urgente', label: 'Urgente', color: 'border-red-300 text-red-700 bg-red-50/50' },
              ].map((p) => (
                <button
                  key={p.id}
                  type="button"
                  onClick={() => setPrioridade(p.id as AnnouncementPriority)}
                  className={`py-2 px-3 rounded-xl border text-xs font-bold transition flex items-center justify-center gap-1.5 ${
                    prioridade === p.id
                      ? `${p.color} ring-2 ring-blue-600 font-extrabold shadow-xs`
                      : 'border-gray-200 text-gray-600 hover:bg-gray-50'
                  }`}
                >
                  {p.id === 'urgente' && '🚨'}
                  {p.id === 'alta' && '⚠️'}
                  {p.label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-gray-700 mb-1">Conteúdo Oficial</label>
            <textarea
              value={mensagem}
              onChange={(e) => setMensagem(e.target.value)}
              placeholder="Digite o texto detalhado do comunicado, orientações e prazos..."
              rows={5}
              required
              className="w-full text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
            />
          </div>

          <div className="p-3 bg-gray-50 rounded-xl text-[11px] text-gray-500">
            Este comunicado exigirá confirmação de leitura individual por parte dos colaboradores
            e registrará métricas no painel administrativo da Direção Geral.
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
              className="px-4 py-1.5 text-xs font-bold text-white bg-[#1565C0] hover:bg-[#0D47A1] rounded-xl transition shadow-xs"
            >
              Publicar Comunicado
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
