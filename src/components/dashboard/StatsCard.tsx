
import React from 'react';
import { cn } from '@/lib/utils';

interface StatsCardProps {
  title: string;
  value: string | number;
  icon: React.ElementType;
  className?: string;
}

export const StatsCard: React.FC<StatsCardProps> = ({ title, value, icon: Icon, className }) => {
  return (
    <div className={cn("stats-card", className)}>
      <div className="stats-card-icon">
        <Icon className="h-8 w-8" />
      </div>
      <div className="space-y-1">
        <p className="stats-card-value">{value}</p>
        <p className="stats-card-title">{title}</p>
      </div>
    </div>
  );
};
