'use client';

import { Menu, Bell, Search, User } from 'lucide-react';
import { useAuth } from './AuthProvider';

interface TopbarProps {
    onMenuClick: () => void;
}

export default function Topbar({ onMenuClick }: TopbarProps) {
    const { user } = useAuth();

    return (
        <header className="h-16 px-4 md:px-8 bg-[#0f172a]/80 backdrop-blur-md border-b border-slate-800/50 flex items-center justify-between sticky top-0 z-40">
            <div className="flex items-center gap-4">
                <button
                    onClick={onMenuClick}
                    className="p-2 -ml-2 hover:bg-slate-800/50 rounded-lg lg:hidden text-slate-400"
                    aria-label="Toggle Menu"
                >
                    <Menu size={20} />
                </button>

                <div className="hidden md:flex items-center gap-2 text-slate-500 bg-slate-900/50 px-4 py-2 rounded-xl border border-slate-800/50 w-80 group focus-within:border-indigo-500/50 transition-all">
                    <Search size={16} className="group-focus-within:text-indigo-400" />
                    <input
                        type="text"
                        placeholder="Search for anything..."
                        className="bg-transparent border-none outline-none text-sm text-slate-300 w-full placeholder:text-slate-600 font-medium"
                    />
                </div>
            </div>

            <div className="flex items-center gap-4">
                <button className="p-2.5 hover:bg-slate-800/50 rounded-xl text-slate-400 relative transition-colors group">
                    <Bell size={20} className="group-hover:text-white transition-colors" />
                    <span className="absolute top-2.5 right-2.5 w-2 h-2 bg-indigo-500 rounded-full border-2 border-[#0f172a] shadow-[0_0_8px_rgba(99,102,241,0.6)]" />
                </button>

                <div className="flex items-center gap-3 pl-2 border-l border-slate-800/50">
                    <div className="flex flex-col items-end hidden sm:flex">
                        <span className="text-xs font-bold text-white leading-tight">Admin User</span>
                        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider leading-tight">Super Admin</span>
                    </div>
                    <div className="w-9 h-9 rounded-xl bg-indigo-600 flex items-center justify-center text-white font-black text-sm shadow-lg shadow-indigo-500/20 hover:scale-105 active:scale-95 transition-all cursor-pointer">
                        {user?.email?.charAt(0).toUpperCase() || <User size={16} />}
                    </div>
                </div>
            </div>
        </header>
    );
}
