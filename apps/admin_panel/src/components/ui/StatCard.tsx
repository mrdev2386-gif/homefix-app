import { LucideIcon } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  trend?: {
    value: string;
    isPositive: boolean;
  };
  color?: 'blue' | 'green' | 'orange' | 'red' | 'purple';
}

const colorClasses = {
  blue: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  green: 'bg-green-500/20 text-green-400 border-green-500/30',
  orange: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  red: 'bg-red-500/20 text-red-400 border-red-500/30',
  purple: 'bg-[#6366F1]/20 text-[#6366F1] border-[#6366F1]/30',
};

export default function StatCard({ title, value, icon: Icon, trend, color = 'purple' }: StatCardProps) {
  return (
    <div className="admin-card p-6 hover:shadow-[0_0_20px_rgba(99,102,241,0.15)] hover:border-[#6366F1]/30 transition-all duration-300">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-[#9CA3AF] mb-1">{title}</p>
          <h3 className="text-2xl font-bold text-[#E5E7EB]">{value}</h3>
          {trend && (
            <p className={`text-sm mt-2 ${trend.isPositive ? 'text-green-400' : 'text-red-400'}`}>
              {trend.isPositive ? '↑' : '↓'} {trend.value}
            </p>
          )}
        </div>
        <div className={`w-12 h-12 rounded-lg flex items-center justify-center border ${colorClasses[color]}`}>
          <Icon size={24} />
        </div>
      </div>
    </div>
  );
}
