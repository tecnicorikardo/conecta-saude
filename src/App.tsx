import React, { useState } from 'react';
import { AppProvider, useApp } from './context/AppContext';
import { Header } from './components/Header';
import { Sidebar } from './components/Sidebar';
import { HomeView } from './views/HomeView';
import { ConversationsView } from './views/ConversationsView';
import { ChannelsView } from './views/ChannelsView';
import { AnnouncementsView } from './views/AnnouncementsView';
import { EmergencyView } from './views/EmergencyView';
import { EmployeesView } from './views/EmployeesView';
import { AdministrationView } from './views/AdministrationView';
import { AuditLogsView } from './views/AuditLogsView';
import { ReportsView } from './views/ReportsView';
import { NotificationsView } from './views/NotificationsView';
import { ProfileView } from './views/ProfileView';

import { EmergencyModal } from './components/EmergencyModal';
import { NewAnnouncementModal } from './components/NewAnnouncementModal';
import { NewEmployeeModal } from './components/NewEmployeeModal';
import { ReportModal } from './components/ReportModal';

const AppContent: React.FC = () => {
  const { currentView } = useApp();

  const [isEmergencyModalOpen, setIsEmergencyModalOpen] = useState(false);
  const [isAnnouncementModalOpen, setIsAnnouncementModalOpen] = useState(false);
  const [isEmployeeModalOpen, setIsEmployeeModalOpen] = useState(false);
  const [reportModalData, setReportModalData] = useState<{
    isOpen: boolean;
    snippet?: string;
    senderName?: string;
  }>({
    isOpen: false,
  });

  const handleOpenReportModal = (snippet?: string, senderName?: string) => {
    setReportModalData({
      isOpen: true,
      snippet,
      senderName,
    });
  };

  const handleCloseReportModal = () => {
    setReportModalData({ isOpen: false });
  };

  return (
    <div className="min-h-screen bg-[#F5F7FA] text-[#0D1B2A] flex flex-col antialiased">
      {/* Institutional SUS Header */}
      <Header onOpenEmergencyModal={() => setIsEmergencyModalOpen(true)} />

      {/* Main Layout Area */}
      <div className="flex-1 flex max-w-7xl w-full mx-auto">
        {/* Sidebar Navigation */}
        <Sidebar />

        {/* Dynamic View Content */}
        <main className="flex-1 p-4 sm:p-6 lg:p-8 min-w-0 overflow-y-auto">
          {currentView === 'home' && (
            <HomeView
              onOpenEmergencyModal={() => setIsEmergencyModalOpen(true)}
              onOpenAnnouncementModal={() => setIsAnnouncementModalOpen(true)}
            />
          )}

          {currentView === 'conversations' && (
            <ConversationsView onOpenReportModal={handleOpenReportModal} />
          )}

          {currentView === 'channels' && <ChannelsView />}

          {currentView === 'announcements' && (
            <AnnouncementsView onOpenNewModal={() => setIsAnnouncementModalOpen(true)} />
          )}

          {currentView === 'emergency' && (
            <EmergencyView onOpenEmergencyModal={() => setIsEmergencyModalOpen(true)} />
          )}

          {currentView === 'employees' && (
            <EmployeesView onOpenNewEmployeeModal={() => setIsEmployeeModalOpen(true)} />
          )}

          {currentView === 'administration' && <AdministrationView />}

          {currentView === 'audit-logs' && <AuditLogsView />}

          {currentView === 'reports' && <ReportsView />}

          {currentView === 'notifications' && <NotificationsView />}

          {currentView === 'profile' && <ProfileView />}
        </main>
      </div>

      {/* Institutional Modals */}
      <EmergencyModal
        isOpen={isEmergencyModalOpen}
        onClose={() => setIsEmergencyModalOpen(false)}
      />

      <NewAnnouncementModal
        isOpen={isAnnouncementModalOpen}
        onClose={() => setIsAnnouncementModalOpen(false)}
      />

      <NewEmployeeModal
        isOpen={isEmployeeModalOpen}
        onClose={() => setIsEmployeeModalOpen(false)}
      />

      <ReportModal
        isOpen={reportModalData.isOpen}
        onClose={handleCloseReportModal}
        messageSnippet={reportModalData.snippet}
        senderName={reportModalData.senderName}
      />
    </div>
  );
};

export default function App() {
  return (
    <AppProvider>
      <AppContent />
    </AppProvider>
  );
}
