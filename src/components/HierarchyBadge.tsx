import React from 'react';
import { HierarchyLevel } from '../types';

interface HierarchyBadgeProps {
  level: HierarchyLevel;
  size?: 'sm' | 'md';
}

export const HierarchyBadge: React.FC<HierarchyBadgeProps> = ({ level, size = 'md' }) => {
  const config = {
    1: {
      label: 'DIREÇÃO GERAL',
      bg: 'bg-blue-900/10 text-blue-800 border-blue-800/30',
      dot: 'bg-blue-800',
    },
    2: {
      label: 'COORDENAÇÃO',
      bg: 'bg-blue-700/10 text-blue-700 border-blue-700/30',
      dot: 'bg-blue-600',
    },
    3: {
      label: 'SUPERVISÃO',
      bg: 'bg-sky-600/10 text-sky-700 border-sky-600/30',
      dot: 'bg-sky-500',
    },
    4: {
      label: 'FUNCIONÁRIO',
      bg: 'bg-slate-500/10 text-slate-700 border-slate-400/30',
      dot: 'bg-slate-500',
    },
  }[level];

  return (
    <span
      className={`inline-flex items-center gap-1.5 font-bold uppercase tracking-wider rounded-md border ${
        config.bg
      } ${size === 'sm' ? 'px-2 py-0.5 text-[10px]' : 'px-2.5 py-1 text-xs'}`}
    >
      <span className={`w-1.5 h-1.5 rounded-full ${config.dot}`} />
      {config.label}
    </span>
  );
};
