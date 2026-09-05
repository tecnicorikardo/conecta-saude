import React from 'react';
import { useApp } from '../context/AppContext';
import { HierarchyBadge } from '../components/HierarchyBadge';
import {
  User,
  Building2,
  Mail,
  Phone,
  ShieldCheck,
  KeyRound,
  CheckCircle2,
  Lock,
} from 'lucide-react';

export const ProfileView: React.FC = () => {
  const { currentUser, userCenterSigla } = useApp();

  const getPermissionsList = () => {
    switch (currentUser.hierarquiaNivel) {
      case 1:
        return [
          'Acesso irrestrito a todos os centros hospitalares (CCDTI, CCO, CCE)',
          'Publicação de comunicados institucionais com obrigatoriedade de leitura',
          'Gestão cadastral completa de funcionários (admissão, suspensão e hierarquia)',
          'Auditoria integral de logs e trilhas de segurança',
          'Acesso a todas as ocorrências da ouvidoria e compliance',
          'Disparo prioritário de Alerta Vermelho de emergência na rede',
        ];
      case 2:
        return [
          `Acesso irrestrito às equipes e canais do centro ${userCenterSigla}`,
          'Publicação de comunicados setoriais e avisos aos colaboradores',
          'Acompanhamento de relatórios da ouvidoria do seu setor',
          'Disparo de alertas prioritários no canal de emergência',
          'Visualização de taxas de leitura da sua equipe',
        ];
      case 3:
        return [
          `Supervisão de fluxos técnicos e escalas no centro ${userCenterSigla}`,
          'Envio de comunicados operacionais internos',
          'Acesso a canais institucionais e setoriais permitidos',
        ];
      default:
        return [
          `Acesso seguro aos canais e comunicados exclusivos do setor ${userCenterSigla}`,
          'Comunicação direta via chat institucional entre colaboradores',
          'Confirmação formal de leitura dos comunicados oficiais',
          'Acesso direto aos ramais e canal de emergência hospitalar 24h',
          'Envio confidencial de relatos e denúncias para a ouvidoria',
        ];
    }
  };

  return (
    <div className="max-w-3xl mx-auto space-y-6 pb-12">
      {/* Header Profile Card */}
      <div className="bg-white rounded-2xl border border-gray-200 p-6 shadow-xs flex flex-col sm:flex-row items-center sm:items-start gap-5">
        <div className="w-20 h-20 rounded-full bg-[#1565C0] text-white font-bold text-3xl flex items-center justify-center border-4 border-blue-50 flex-shrink-0 shadow-sm">
          {currentUser.nome.charAt(0)}
        </div>

        <div className="flex-1 text-center sm:text-left">
          <div className="flex flex-col sm:flex-row sm:items-center gap-2">
            <h2 className="text-xl font-bold text-gray-900">{currentUser.nome}</h2>
            <HierarchyBadge level={currentUser.hierarquiaNivel} size="sm" />
          </div>

          <p className="text-sm font-semibold text-[#1565C0] mt-0.5">{currentUser.cargo}</p>
          <p className="text-xs text-gray-500 mt-0.5">{currentUser.setorNome}</p>

          <div className="mt-4 flex flex-wrap gap-2 justify-center sm:justify-start text-xs">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-gray-50 border border-gray-200 rounded-xl text-gray-700">
              <Mail className="w-3.5 h-3.5 text-gray-400" />
              {currentUser.email}
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-gray-50 border border-gray-200 rounded-xl text-gray-700">
              <Phone className="w-3.5 h-3.5 text-gray-400" />
              {currentUser.telefone || '(21) 3111-0000'}
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-gray-50 border border-gray-200 rounded-xl font-mono text-gray-700">
              Matrícula: {currentUser.matricula || 'SUS-00000'}
            </span>
          </div>
        </div>
      </div>

      {/* Permissions Breakdown Card */}
      <div className="bg-white rounded-2xl border border-gray-200 p-6 shadow-xs space-y-4">
        <div className="flex items-center gap-2">
          <ShieldCheck className="w-5 h-5 text-emerald-600" />
          <h3 className="font-bold text-sm text-gray-900">
            Escopo de Permissões & Isolamento Setorial
          </h3>
        </div>

        <p className="text-xs text-gray-600 leading-relaxed">
          Seu perfil está autenticado sob as diretrizes de governança da rede hospitalar. Suas
          atribuições no sistema:
        </p>

        <div className="space-y-2">
          {getPermissionsList().map((perm, idx) => (
            <div key={idx} className="flex items-start gap-2.5 text-xs text-gray-700">
              <CheckCircle2 className="w-4 h-4 text-emerald-600 flex-shrink-0 mt-0.5" />
              <span>{perm}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Security & Authentication Info */}
      <div className="bg-white rounded-2xl border border-gray-200 p-6 shadow-xs space-y-3">
        <div className="flex items-center gap-2">
          <KeyRound className="w-5 h-5 text-blue-600" />
          <h3 className="font-bold text-sm text-gray-900">Segurança & Autenticação Institucional</h3>
        </div>

        <div className="p-3 bg-blue-50/60 rounded-xl border border-blue-100 text-xs text-blue-900 space-y-1">
          <div className="font-semibold">Sessão Criptografada Ativa</div>
          <p className="text-[11px] text-blue-800">
            Sessão validada com duplo fator e vínculo institucional ao cadastro nacional de
            estabelecimentos de saúde (CNES).
          </p>
        </div>
      </div>
    </div>
  );
};
