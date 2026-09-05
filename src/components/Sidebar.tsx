import React from 'react';
import { useApp } from '../context/AppContext';
import { AppView } from '../types';
import {
  Home,
  MessageSquare,
  Radio,
  FileText,
  AlertOctagon,
  Users,
  Shield,
  History,
  Flag,
  User,
  Bell,
} from 'lucide-react';

export const Sidebar: React.FC = () => {
  const {
    currentView,
    setCurrentView,
    isAdmin,
    isCoord,
    canManageEmployees,
    canViewReports,
    canViewAudit,
    announcements,
    conversations,
    notifications,
  } = useApp();

  const unreadAnnouncements = announcements.filter((a) => !a.lidoPorMim).length;
  const unreadMessages = conversations.reduce((acc, c) => acc + c.naoLidas, 0);
  const unreadNotifs = notifications.filter((n) => !n.lida).length;

  const navItems: {
    id: AppView;
    label: string;
    icon: React.ElementType;
    badge?: number;
    badgeColor?: string;
    section?: 'main' | 'admin';
  }[] = [
    { id: 'home', label: 'Início', icon: Home, section: 'main' },
    {
      id: 'conversations',
      label: 'Conversas',
      icon: MessageSquare,
      badge: unreadMessages,
      badgeColor: 'bg-blue-600',
      section: 'main',
    },
    { id: 'channels', label: 'Canais', icon: Radio, section: 'main' },
    {
      id: 'announcements',
      label: 'Comunicados',
      icon: FileText,
      badge: unreadAnnouncements,
      badgeColor: 'bg-emerald-600',
      section: 'main',
    },
    { id: 'emergency', label: 'Central de Emergência', icon: AlertOctagon, section: 'main' },
    {
      id: 'notifications',
      label: 'Notificações',
      icon: Bell,
      badge: unreadNotifs,
      badgeColor: 'bg-amber-600',
      section: 'main',
    },
  ];

  const adminItems: {
    id: AppView;
    label: string;
    icon: React.ElementType;
  }[] = [];

  // Quadro de Funcionários / Contatos do Setor
  adminItems.push({
    id: 'employees',
    label: isAdmin || isCoord ? 'Gestão Funcional' : 'Equipe do Setor',
    icon: Users,
  });

  if (canViewReports) {
    adminItems.push({ id: 'reports', label: 'Denúncias & Ética', icon: Flag });
  }

  if (canViewAudit) {
    adminItems.push({ id: 'audit-logs', label: 'Logs de Auditoria', icon: History });
  }

  if (isAdmin) {
    adminItems.push({ id: 'administration', label: 'Painel Admin', icon: Shield });
  }

  return (
    <>
      {/* Desktop Sidebar */}
      <aside className="hidden md:flex flex-col w-64 bg-white border-r border-gray-200 min-h-[calc(100vh-4rem)] p-4 flex-shrink-0">
        <div className="text-[11px] font-bold text-gray-400 uppercase tracking-wider px-3 mb-2">
          Comunicação
        </div>
        <nav className="space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = currentView === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setCurrentView(item.id)}
                className={`w-full flex items-center justify-between px-3 py-2.5 rounded-xl text-sm font-medium transition ${
                  isActive
                    ? 'bg-blue-50 text-[#1565C0] font-semibold shadow-xs'
                    : 'text-gray-700 hover:bg-gray-50 hover:text-gray-900'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon
                    className={`w-4 h-4 ${
                      isActive ? 'text-[#1565C0]' : 'text-gray-400'
                    }`}
                  />
                  <span>{item.label}</span>
                </div>
                {item.badge !== undefined && item.badge > 0 && (
                  <span
                    className={`text-[10px] text-white font-bold px-1.5 py-0.5 rounded-full ${
                      item.badgeColor || 'bg-blue-600'
                    }`}
                  >
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </nav>

        {adminItems.length > 0 && (
          <div className="mt-6 pt-4 border-t border-gray-100">
            <div className="text-[11px] font-bold text-gray-400 uppercase tracking-wider px-3 mb-2">
              Gestão & Controle
            </div>
            <nav className="space-y-1">
              {adminItems.map((item) => {
                const Icon = item.icon;
                const isActive = currentView === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => setCurrentView(item.id)}
                    className={`w-full flex items-center justify-between px-3 py-2.5 rounded-xl text-sm font-medium transition ${
                      isActive
                        ? 'bg-blue-50 text-[#1565C0] font-semibold'
                        : 'text-gray-700 hover:bg-gray-50 hover:text-gray-900'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <Icon
                        className={`w-4 h-4 ${
                          isActive ? 'text-[#1565C0]' : 'text-gray-400'
                        }`}
                      />
                      <span>{item.label}</span>
                    </div>
                  </button>
                );
              })}
            </nav>
          </div>
        )}

        <div className="mt-auto pt-4 border-t border-gray-100">
          <button
            onClick={() => setCurrentView('profile')}
            className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition ${
              currentView === 'profile'
                ? 'bg-blue-50 text-[#1565C0] font-semibold'
                : 'text-gray-700 hover:bg-gray-50'
            }`}
          >
            <User className="w-4 h-4 text-gray-400" />
            <span>Meu Perfil</span>
          </button>
        </div>
      </aside>

      {/* Mobile Bottom Navigation Bar */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-30 px-2 py-1 flex justify-around items-center shadow-lg">
        <button
          onClick={() => setCurrentView('home')}
          className={`flex flex-col items-center py-1 px-2 text-[10px] font-medium ${
            currentView === 'home' ? 'text-[#1565C0] font-bold' : 'text-gray-500'
          }`}
        >
          <Home className="w-5 h-5 mb-0.5" />
          <span>Início</span>
        </button>
        <button
          onClick={() => setCurrentView('conversations')}
          className={`flex flex-col items-center py-1 px-2 text-[10px] font-medium relative ${
            currentView === 'conversations' ? 'text-[#1565C0] font-bold' : 'text-gray-500'
          }`}
        >
          <MessageSquare className="w-5 h-5 mb-0.5" />
          <span>Chat</span>
          {unreadMessages > 0 && (
            <span className="absolute top-0 right-2 w-2 h-2 rounded-full bg-blue-600" />
          )}
        </button>
        <button
          onClick={() => setCurrentView('channels')}
          className={`flex flex-col items-center py-1 px-2 text-[10px] font-medium ${
            currentView === 'channels' ? 'text-[#1565C0] font-bold' : 'text-gray-500'
          }`}
        >
          <Radio className="w-5 h-5 mb-0.5" />
          <span>Canais</span>
        </button>
        <button
          onClick={() => setCurrentView('announcements')}
          className={`flex flex-col items-center py-1 px-2 text-[10px] font-medium relative ${
            currentView === 'announcements' ? 'text-[#1565C0] font-bold' : 'text-gray-500'
          }`}
        >
          <FileText className="w-5 h-5 mb-0.5" />
          <span>Avisos</span>
          {unreadAnnouncements > 0 && (
            <span className="absolute top-0 right-2 w-2 h-2 rounded-full bg-emerald-600" />
          )}
        </button>
        <button
          onClick={() => setCurrentView('profile')}
          className={`flex flex-col items-center py-1 px-2 text-[10px] font-medium ${
            currentView === 'profile' ? 'text-[#1565C0] font-bold' : 'text-gray-500'
          }`}
        >
          <User className="w-5 h-5 mb-0.5" />
          <span>Perfil</span>
        </button>
      </div>
    </>
  );
};
