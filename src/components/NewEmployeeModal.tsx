import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { HierarchyLevel } from '../types';
import { INITIAL_SECTORS } from '../data/initialData';
import { UserPlus, X } from 'lucide-react';

interface NewEmployeeModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const NewEmployeeModal: React.FC<NewEmployeeModalProps> = ({ isOpen, onClose }) => {
  const { addUser } = useApp();
  const [nome, setNome] = useState('');
  const [email, setEmail] = useState('');
  const [cargo, setCargo] = useState('');
  const [setorId, setSetorId] = useState('sec-ccdti');
  const [hierarquiaNivel, setHierarquiaNivel] = useState<HierarchyLevel>(4);
  const [matricula, setMatricula] = useState('');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nome.trim() || !email.trim() || !cargo.trim()) return;

    const setor = INITIAL_SECTORS.find((s) => s.id === setorId);

    addUser({
      nome,
      email,
      cargo,
      hierarquiaNivel,
      setorId,
      setorNome: setor ? setor.nome : 'Setor Hospitalar',
      matricula: matricula || `SUS-${Math.floor(10000 + Math.random() * 90000)}`,
      ativo: true,
    });

    setNome('');
    setEmail('');
    setCargo('');
    setMatricula('');
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
      <div className="bg-white rounded-2xl max-w-md w-full overflow-hidden shadow-2xl border border-gray-200">
        <div className="bg-[#1565C0] text-white p-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <UserPlus className="w-5 h-5 text-blue-200" />
            <div>
              <h3 className="font-bold text-sm">Cadastrar Novo Funcionário</h3>
              <p className="text-[11px] text-blue-100">Controle de Acesso Institucional SUS</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-white/10 text-white">
            <X className="w-4 h-4" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-5 space-y-3.5">
          <div>
            <label className="block text-xs font-bold text-gray-700 mb-1">Nome Completo</label>
            <input
              type="text"
              value={nome}
              onChange={(e) => setNome(e.target.value)}
              placeholder="Ex: João da Silva Santos"
              required
              className="w-full text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">E-mail Institucional</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="joao@conectasaude.dev"
                required
                className="w-full text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">Matrícula SUS</label>
              <input
                type="text"
                value={matricula}
                onChange={(e) => setMatricula(e.target.value)}
                placeholder="SUS-01994"
                className="w-full text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-gray-700 mb-1">Cargo / Função</label>
            <input
              type="text"
              value={cargo}
              onChange={(e) => setCargo(e.target.value)}
              placeholder="Ex: Técnico em Enfermagem — CCO"
              required
              className="w-full text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">Centro / Setor</label>
              <select
                value={setorId}
                onChange={(e) => setSetorId(e.target.value)}
                className="w-full text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white"
              >
                {INITIAL_SECTORS.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.sigla} — {s.nome.split('(')[0]}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">Nível Hierárquico</label>
              <select
                value={hierarquiaNivel}
                onChange={(e) => setHierarquiaNivel(Number(e.target.value) as HierarchyLevel)}
                className="w-full text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none bg-white"
              >
                <option value={1}>1 — Direção Geral</option>
                <option value={2}>2 — Coordenação</option>
                <option value={3}>3 — Supervisão</option>
                <option value={4}>4 — Funcionário</option>
              </select>
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-3 border-t border-gray-100">
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
              Salvar Funcionário
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
