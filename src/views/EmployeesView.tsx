import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { HierarchyBadge } from '../components/HierarchyBadge';
import {
  Users,
  UserPlus,
  Search,
  Filter,
  CheckCircle2,
  XCircle,
  Building2,
  Mail,
  Phone,
  BadgeAlert,
} from 'lucide-react';

interface EmployeesViewProps {
  onOpenNewEmployeeModal: () => void;
}

export const EmployeesView: React.FC<EmployeesViewProps> = ({ onOpenNewEmployeeModal }) => {
  const { users, toggleUserStatus, currentUser, isAdmin, isCoord } = useApp();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [sectorFilter, setSectorFilter] = useState<string>('all');

  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      u.nome.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.cargo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (u.matricula && u.matricula.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesStatus =
      statusFilter === 'all'
        ? true
        : statusFilter === 'active'
        ? u.ativo
        : !u.ativo;

    const matchesSector =
      sectorFilter === 'all' ? true : u.setorId === sectorFilter;

    return matchesSearch && matchesStatus && matchesSector;
  });

  return (
    <div className="max-w-5xl mx-auto space-y-6 pb-12">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-gray-200 shadow-xs">
        <div>
          <div className="flex items-center gap-2">
            <Users className="w-5 h-5 text-[#1565C0]" />
            <h2 className="font-bold text-lg text-gray-900">Quadro Funcional & Permissões</h2>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            {isAdmin
              ? 'Direção Geral: Visão irrestrita dos 4 centros hospitalares da rede SUS.'
              : `Acesso Setorial Restrito: Visualizando colaboradores do seu centro (${currentUser.setorNome}) e Direção Geral.`}
          </p>
        </div>

        {isCoord && (
          <button
            onClick={onOpenNewEmployeeModal}
            className="flex items-center gap-1.5 bg-[#1565C0] hover:bg-[#0D47A1] text-white px-4 py-2 rounded-xl text-xs font-bold transition shadow-xs self-start sm:self-auto"
          >
            <UserPlus className="w-4 h-4" />
            <span>Cadastrar Funcionário</span>
          </button>
        )}
      </div>

      {/* Sector Isolation Notification Badge */}
      {!isAdmin && (
        <div className="p-3.5 bg-blue-50/80 rounded-2xl border border-blue-200 flex items-center justify-between text-xs text-blue-900">
          <div className="flex items-center gap-2">
            <Building2 className="w-4 h-4 text-blue-600 flex-shrink-0" />
            <span>
              <strong>Regra Institucional:</strong> Seus contatos no catálogo estão restritos à sua unidade funcional ({currentUser.setorNome}) e à Direção Geral.
            </span>
          </div>
          <span className="text-[10px] font-bold uppercase tracking-wider bg-white px-2 py-0.5 rounded border border-blue-300">
            Nível {currentUser.hierarquiaNivel}
          </span>
        </div>
      )}

      {/* Filters Bar */}
      <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xs flex flex-col md:flex-row gap-3 items-center justify-between">
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-gray-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Buscar por nome, cargo ou matrícula..."
            className="w-full pl-9 pr-3 py-2 text-xs bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
          />
        </div>

        <div className="flex items-center gap-2 w-full md:w-auto overflow-x-auto">
          {/* Status Tabs */}
          <div className="flex bg-gray-100 p-1 rounded-xl text-xs">
            <button
              onClick={() => setStatusFilter('all')}
              className={`px-3 py-1 rounded-lg font-medium transition ${
                statusFilter === 'all' ? 'bg-white text-gray-900 shadow-xs font-semibold' : 'text-gray-600'
              }`}
            >
              Todos ({users.length})
            </button>
            <button
              onClick={() => setStatusFilter('active')}
              className={`px-3 py-1 rounded-lg font-medium transition ${
                statusFilter === 'active' ? 'bg-white text-green-700 shadow-xs font-semibold' : 'text-gray-600'
              }`}
            >
              Ativos ({users.filter((u) => u.ativo).length})
            </button>
            <button
              onClick={() => setStatusFilter('inactive')}
              className={`px-3 py-1 rounded-lg font-medium transition ${
                statusFilter === 'inactive' ? 'bg-white text-red-700 shadow-xs font-semibold' : 'text-gray-600'
              }`}
            >
              Inativos ({users.filter((u) => !u.ativo).length})
            </button>
          </div>

          {/* Sector Dropdown */}
          <select
            value={sectorFilter}
            onChange={(e) => setSectorFilter(e.target.value)}
            className="text-xs p-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none text-gray-700"
          >
            <option value="all">Todos os Centros</option>
            <option value="sec-direcao">Direção Geral</option>
            <option value="sec-ccdti">CCDTI (Imagem)</option>
            <option value="sec-cco">CCO (Olho)</option>
            <option value="sec-cce">CCE (Especialidades)</option>
          </select>
        </div>
      </div>

      {/* Directory Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filteredUsers.length === 0 ? (
          <div className="col-span-2 p-10 text-center bg-white rounded-2xl border border-gray-200 text-gray-400 text-xs">
            Nenhum colaborador encontrado com os filtros especificados.
          </div>
        ) : (
          filteredUsers.map((user) => (
            <div
              key={user.id}
              className={`bg-white rounded-2xl border p-4 shadow-xs transition flex flex-col justify-between ${
                user.ativo ? 'border-gray-200 hover:border-blue-300' : 'border-gray-200 bg-gray-50/70 opacity-75'
              }`}
            >
              <div>
                <div className="flex items-start justify-between gap-3 mb-2">
                  <div className="flex items-center gap-3">
                    <div className="w-11 h-11 rounded-full bg-blue-600 text-white font-bold text-base flex items-center justify-center flex-shrink-0">
                      {user.nome.charAt(0)}
                    </div>
                    <div>
                      <h4 className="font-bold text-sm text-gray-900">{user.nome}</h4>
                      <p className="text-xs text-gray-500">{user.cargo}</p>
                    </div>
                  </div>

                  <HierarchyBadge level={user.hierarquiaNivel} size="sm" />
                </div>

                <div className="space-y-1 mt-3 text-xs text-gray-600">
                  <div className="flex items-center gap-2">
                    <Building2 className="w-3.5 h-3.5 text-gray-400" />
                    <span>{user.setorNome || 'Unidade Hospitalar'}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Mail className="w-3.5 h-3.5 text-gray-400" />
                    <span className="font-mono text-[11px]">{user.email}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Phone className="w-3.5 h-3.5 text-gray-400" />
                    <span>{user.telefone || '(21) 3111-0000'}</span>
                    <span className="text-[10px] text-gray-400 font-mono ml-auto">
                      {user.matricula}
                    </span>
                  </div>
                </div>
              </div>

              <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between text-xs">
                <div className="flex items-center gap-1.5">
                  {user.ativo ? (
                    <span className="inline-flex items-center gap-1 text-green-700 font-semibold text-[11px]">
                      <CheckCircle2 className="w-3.5 h-3.5 text-green-600" />
                      Ativo no Sistema
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 text-red-600 font-semibold text-[11px]">
                      <XCircle className="w-3.5 h-3.5 text-red-500" />
                      Acesso Inativo
                    </span>
                  )}
                </div>

                {isAdmin && user.id !== currentUser.id && (
                  <button
                    onClick={() => toggleUserStatus(user.id)}
                    className={`px-3 py-1 rounded-xl text-xs font-semibold transition ${
                      user.ativo
                        ? 'text-red-700 bg-red-50 hover:bg-red-100'
                        : 'text-green-700 bg-green-50 hover:bg-green-100'
                    }`}
                  >
                    {user.ativo ? 'Desativar' : 'Reativar'}
                  </button>
                )}
                {!isAdmin && (
                  <span className="text-[10px] text-gray-400 italic">
                    Gestão exclusiva Direção
                  </span>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
