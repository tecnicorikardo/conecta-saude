import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import {
  Bell,
  AlertTriangle,
  ChevronDown,
  UserCheck,
  Building2,
  ShieldAlert,
  Server,
  RefreshCw,
} from 'lucide-react';
import { HierarchyBadge } from './HierarchyBadge';

interface HeaderProps {
  onOpenEmergencyModal: () => void;
}

export const Header: React.FC<HeaderProps> = ({ onOpenEmergencyModal }) => {
  const {
    currentUser,
    switchProfile,
    availableProfiles,
    notifications,
    setCurrentView,
    emergencyAlertActive,
    emergencyAlertMessage,
    dismissEmergencyAlert,
    backendOnline,
    isSyncing,
  } = useApp();

  const [showUserDropdown, setShowUserDropdown] = useState(false);

  const unreadNotifsCount = notifications.filter((n) => !n.lida).length;

  // Agrupamento de perfis por centro hospitalar
  const profilesBySector = {
    DIRECAO: availableProfiles.filter((u) => u.setorId === 'sec-direcao'),
    CCDTI: availableProfiles.filter((u) => u.setorId === 'sec-ccdti'),
    CCO: availableProfiles.filter((u) => u.setorId === 'sec-cco'),
    CCE: availableProfiles.filter((u) => u.setorId === 'sec-cce'),
  };

  return (
    <header className="sticky top-0 z-40 bg-[#1565C0] text-white shadow-md">
      {/* Urgent Emergency Alert Ticker */}
      {emergencyAlertActive && (
        <div className="bg-red-600 text-white px-4 py-2 flex items-center justify-between animate-pulse">
          <div className="flex items-center gap-2">
            <AlertTriangle className="w-5 h-5 flex-shrink-0" />
            <span className="font-bold text-sm tracking-wide">
              ALERTA PRIORITÁRIO: {emergencyAlertMessage || 'Acionamento de Emergência Hospitalar'}
            </span>
          </div>
          {currentUser.hierarquiaNivel === 1 && (
            <button
              onClick={dismissEmergencyAlert}
              className="text-xs bg-black/30 hover:bg-black/40 px-2.5 py-1 rounded text-white font-semibold transition"
            >
              Dispensar Alerta (Direção)
            </button>
          )}
        </div>
      )}

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        {/* Left: SUS Logo & Brand */}
        <div className="flex items-center gap-3.5">
          <div className="h-10 w-16 bg-white rounded-md p-1 flex items-center justify-center shadow-sm">
            <img
              src="/logo_sus.png"
              alt="Logo SUS"
              className="max-h-full max-w-full object-contain"
            />
          </div>
          <div className="cursor-pointer" onClick={() => setCurrentView('home')}>
            <h1 className="font-bold text-lg leading-tight tracking-tight flex items-center gap-2">
              Conecta Saúde
              <span className="hidden sm:inline-block text-[10px] bg-white/20 text-white px-1.5 py-0.5 rounded font-medium">
                Rede Hospitalar
              </span>
            </h1>
            <p className="text-xs text-blue-100 hidden sm:block">
              SUS — Comunicação Institucional Oficial
            </p>
          </div>
        </div>

        {/* Center: Center Badge & Real Backend Status */}
        <div className="hidden md:flex items-center gap-3">
          <div className="flex items-center gap-2 bg-blue-800/60 px-3 py-1.5 rounded-lg border border-blue-400/20 text-xs">
            <Building2 className="w-4 h-4 text-blue-200" />
            <span className="text-blue-100">Unidade:</span>
            <span className="font-semibold text-white">
              {currentUser.setorNome || 'Direção Geral'}
            </span>
          </div>

          <div
            className={`flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium border ${
              backendOnline
                ? 'bg-emerald-950/40 text-emerald-300 border-emerald-500/30'
                : 'bg-amber-950/40 text-amber-300 border-amber-500/30'
            }`}
            title="Conexão com servidor Node.js/Express na porta 3000"
          >
            <Server className="w-3.5 h-3.5" />
            <span>{backendOnline ? 'Backend Conectado' : 'Backend Offline'}</span>
            {isSyncing && <RefreshCw className="w-3 h-3 animate-spin ml-1 text-emerald-200" />}
          </div>
        </div>

        {/* Right: Actions, Notifications & Role Switcher */}
        <div className="flex items-center gap-2 sm:gap-3">
          {/* Quick Emergency Button */}
          <button
            onClick={onOpenEmergencyModal}
            className="flex items-center gap-1.5 bg-red-600 hover:bg-red-700 text-white px-3 py-1.5 rounded-lg text-xs font-bold transition shadow-sm"
            title="Disparar Alerta ou Ver Protocolo"
          >
            <ShieldAlert className="w-4 h-4" />
            <span className="hidden sm:inline">Emergência</span>
          </button>

          {/* Notifications Button */}
          <button
            onClick={() => setCurrentView('notifications')}
            className="relative p-2 rounded-lg hover:bg-blue-600/70 transition text-white"
            title="Notificações"
          >
            <Bell className="w-5 h-5" />
            {unreadNotifsCount > 0 && (
              <span className="absolute top-1 right-1 bg-red-500 text-white text-[10px] font-bold w-4 h-4 rounded-full flex items-center justify-center border-2 border-[#1565C0]">
                {unreadNotifsCount}
              </span>
            )}
          </button>

          {/* User Switcher Dropdown (Simulates Logging in as Different Institutional Roles) */}
          <div className="relative">
            <button
              onClick={() => setShowUserDropdown(!showUserDropdown)}
              className="flex items-center gap-2 bg-blue-700/70 hover:bg-blue-600 px-2.5 py-1.5 rounded-lg border border-blue-400/30 text-left transition"
              title="Trocar papel de usuário para testar permissões"
            >
              <div className="w-7 h-7 rounded-full bg-white/20 text-white font-bold flex items-center justify-center text-xs border border-white/40">
                {currentUser.nome.charAt(0)}
              </div>
              <div className="hidden lg:block">
                <div className="text-xs font-semibold leading-tight line-clamp-1">
                  {currentUser.nome.split(' ').slice(0, 2).join(' ')}
                </div>
                <div className="text-[10px] text-blue-200 line-clamp-1">
                  {currentUser.cargo.split('—')[0]}
                </div>
              </div>
              <ChevronDown className="w-3.5 h-3.5 text-blue-200" />
            </button>

            {/* Dropdown Menu */}
            {showUserDropdown && (
              <>
                <div
                  className="fixed inset-0 z-40"
                  onClick={() => setShowUserDropdown(false)}
                />
                <div className="absolute right-0 mt-2 w-84 bg-white rounded-xl shadow-2xl border border-gray-200 text-gray-800 z-50 py-2 overflow-hidden animate-in fade-in zoom-in-95">
                  <div className="px-4 py-2.5 border-b border-gray-100 bg-gray-50">
                    <div className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">
                      Usuário Atual Conectado (API)
                    </div>
                    <div className="font-bold text-sm text-gray-900 mt-0.5">
                      {currentUser.nome}
                    </div>
                    <div className="text-xs text-gray-600 mb-1.5">
                      {currentUser.cargo}
                    </div>
                    <div className="flex items-center gap-2">
                      <HierarchyBadge level={currentUser.hierarquiaNivel} size="sm" />
                      <span className="text-[11px] font-medium text-gray-500 bg-gray-200 px-1.5 py-0.5 rounded">
                        Mat: {currentUser.matricula || 'SUS-001'}
                      </span>
                    </div>
                  </div>

                  <div className="px-3 py-2 text-[11px] font-semibold text-gray-400 uppercase tracking-wider bg-gray-50/50">
                    Alternar Usuário (Testar Regras e Permissões):
                  </div>

                  <div className="max-h-80 overflow-y-auto px-2 space-y-3 py-1">
                    {/* Seção Direção */}
                    <div>
                      <div className="text-[10px] font-bold text-blue-900 uppercase tracking-wider px-2 py-0.5 mb-1 bg-blue-50 rounded">
                        Direção Geral (Nível 1 — Acesso Global)
                      </div>
                      {profilesBySector.DIRECAO.map((u) => (
                        <button
                          key={u.id}
                          onClick={() => {
                            switchProfile(u.id);
                            setShowUserDropdown(false);
                          }}
                          className={`w-full text-left px-2.5 py-1.5 rounded-lg text-xs flex items-center justify-between transition ${
                            u.id === currentUser.id
                              ? 'bg-blue-100/70 text-blue-900 font-semibold'
                              : 'hover:bg-gray-100 text-gray-700'
                          }`}
                        >
                          <div>
                            <div className="font-medium text-gray-900">{u.nome}</div>
                            <div className="text-[10px] text-gray-500">{u.cargo}</div>
                          </div>
                          {u.id === currentUser.id && (
                            <UserCheck className="w-4 h-4 text-blue-600 flex-shrink-0 ml-2" />
                          )}
                        </button>
                      ))}
                    </div>

                    {/* Seção CCDTI */}
                    <div>
                      <div className="text-[10px] font-bold text-indigo-900 uppercase tracking-wider px-2 py-0.5 mb-1 bg-indigo-50 rounded">
                        CCDTI — Centro de Imagem (Isolado)
                      </div>
                      {profilesBySector.CCDTI.map((u) => (
                        <button
                          key={u.id}
                          onClick={() => {
                            switchProfile(u.id);
                            setShowUserDropdown(false);
                          }}
                          className={`w-full text-left px-2.5 py-1.5 rounded-lg text-xs flex items-center justify-between transition ${
                            u.id === currentUser.id
                              ? 'bg-blue-100/70 text-blue-900 font-semibold'
                              : 'hover:bg-gray-100 text-gray-700'
                          }`}
                        >
                          <div>
                            <div className="font-medium text-gray-900 flex items-center gap-1.5">
                              {u.nome}
                              <span className="text-[9px] px-1 py-0.2 rounded bg-gray-200 text-gray-700 font-normal">
                                Nível {u.hierarquiaNivel}
                              </span>
                            </div>
                            <div className="text-[10px] text-gray-500">{u.cargo}</div>
                          </div>
                          {u.id === currentUser.id && (
                            <UserCheck className="w-4 h-4 text-blue-600 flex-shrink-0 ml-2" />
                          )}
                        </button>
                      ))}
                    </div>

                    {/* Seção CCO */}
                    <div>
                      <div className="text-[10px] font-bold text-teal-900 uppercase tracking-wider px-2 py-0.5 mb-1 bg-teal-50 rounded">
                        CCO — Centro do Olho (Isolado)
                      </div>
                      {profilesBySector.CCO.map((u) => (
                        <button
                          key={u.id}
                          onClick={() => {
                            switchProfile(u.id);
                            setShowUserDropdown(false);
                          }}
                          className={`w-full text-left px-2.5 py-1.5 rounded-lg text-xs flex items-center justify-between transition ${
                            u.id === currentUser.id
                              ? 'bg-blue-100/70 text-blue-900 font-semibold'
                              : 'hover:bg-gray-100 text-gray-700'
                          }`}
                        >
                          <div>
                            <div className="font-medium text-gray-900 flex items-center gap-1.5">
                              {u.nome}
                              <span className="text-[9px] px-1 py-0.2 rounded bg-gray-200 text-gray-700 font-normal">
                                Nível {u.hierarquiaNivel}
                              </span>
                            </div>
                            <div className="text-[10px] text-gray-500">{u.cargo}</div>
                          </div>
                          {u.id === currentUser.id && (
                            <UserCheck className="w-4 h-4 text-blue-600 flex-shrink-0 ml-2" />
                          )}
                        </button>
                      ))}
                    </div>

                    {/* Seção CCE */}
                    <div>
                      <div className="text-[10px] font-bold text-amber-900 uppercase tracking-wider px-2 py-0.5 mb-1 bg-amber-50 rounded">
                        CCE — Especialidades (Isolado)
                      </div>
                      {profilesBySector.CCE.map((u) => (
                        <button
                          key={u.id}
                          onClick={() => {
                            switchProfile(u.id);
                            setShowUserDropdown(false);
                          }}
                          className={`w-full text-left px-2.5 py-1.5 rounded-lg text-xs flex items-center justify-between transition ${
                            u.id === currentUser.id
                              ? 'bg-blue-100/70 text-blue-900 font-semibold'
                              : 'hover:bg-gray-100 text-gray-700'
                          }`}
                        >
                          <div>
                            <div className="font-medium text-gray-900 flex items-center gap-1.5">
                              {u.nome}
                              <span className="text-[9px] px-1 py-0.2 rounded bg-gray-200 text-gray-700 font-normal">
                                Nível {u.hierarquiaNivel}
                              </span>
                            </div>
                            <div className="text-[10px] text-gray-500">{u.cargo}</div>
                          </div>
                          {u.id === currentUser.id && (
                            <UserCheck className="w-4 h-4 text-blue-600 flex-shrink-0 ml-2" />
                          )}
                        </button>
                      ))}
                    </div>
                  </div>

                  <div className="border-t border-gray-100 mt-2 pt-1 px-2">
                    <button
                      onClick={() => {
                        setShowUserDropdown(false);
                        setCurrentView('profile');
                      }}
                      className="w-full text-left px-3 py-2 rounded-lg text-xs text-blue-700 hover:bg-blue-50 font-medium flex items-center justify-between"
                    >
                      <span>Ver Meus Dados & Permissões</span>
                      <span className="text-[10px] text-gray-400">ID: {currentUser.id}</span>
                    </button>
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};
