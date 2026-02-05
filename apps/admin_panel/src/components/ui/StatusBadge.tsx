import React from 'react';

const colors: Record<string, string> = {
    // General
    active: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
    inactive: 'bg-slate-500/10 text-slate-400 border-slate-500/20',
    pending: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
    blocked: 'bg-red-500/10 text-red-400 border-red-500/20',
    suspicious: 'bg-orange-500/10 text-orange-400 border-orange-500/20',
    // Bookings
    requested: 'bg-sky-500/10 text-sky-400 border-sky-500/20',
    assigned: 'bg-indigo-500/10 text-indigo-400 border-indigo-500/20',
    accepted: 'bg-violet-500/10 text-violet-400 border-violet-500/20',
    in_progress: 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20',
    completed: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
    cancelled: 'bg-red-500/10 text-red-400 border-red-500/20',
    payment_pending: 'bg-orange-500/10 text-orange-400 border-orange-500/20',
    refunded: 'bg-pink-500/10 text-pink-400 border-pink-500/20',
    paid: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
    // Tech
    approved: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
    rejected: 'bg-red-500/10 text-red-400 border-red-500/20',
    online: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
    offline: 'bg-slate-500/10 text-slate-400 border-slate-500/20'
};

export default function StatusBadge({ status }: { status: string }) {
    const key = status?.toLowerCase() || 'inactive';
    const colorStyles = colors[key] || 'bg-slate-100 text-slate-600';

    return (
        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-lg text-[10px] font-black uppercase tracking-widest border shadow-sm ${colorStyles}`}>
            <span className={`w-1.5 h-1.5 rounded-full mr-1.5 animate-pulse ${colorStyles.split(' ')[1].replace('text-', 'bg-')}`}></span>
            {status?.replace('_', ' ')}
        </span>
    );
}
