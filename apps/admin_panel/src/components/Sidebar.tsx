'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
    LayoutDashboard,
    Users,
    Wrench,
    Calendar,
    AlertTriangle,
    Settings,
    LogOut,
    CreditCard,
    ClipboardList,
    Briefcase,
    Shield,
    X,
    FlaskConical,
    IndianRupee,
    Star,
    Video,
    Sparkles,
    ShieldAlert,
} from 'lucide-react';
import { useAuth } from '@/components/AuthProvider';

const menuItems = [
    { icon: LayoutDashboard, label: 'Dashboard', href: '/dashboard' },
    { icon: Calendar, label: 'Bookings', href: '/bookings' },
    { icon: ClipboardList, label: 'Technician Applications', href: '/applications' },
    { icon: Wrench, label: 'Technicians', href: '/technicians' },
    { icon: Users, label: 'Customers', href: '/customers' },
    { icon: Briefcase, label: 'Services', href: '/services' },
    { icon: Star, label: 'Reviews', href: '/reviews' },
    { icon: AlertTriangle, label: 'Disputes', href: '/disputes' },
    { icon: ShieldAlert, label: 'Risk', href: '/risk' },
    { icon: CreditCard, label: 'Finance', href: '/finance' },
    { icon: IndianRupee, label: 'Payouts', href: '/finance/payouts' },
    { icon: ClipboardList, label: 'Audit Logs', href: '/audit-logs' },
    { icon: FlaskConical, label: 'System Tests', href: '/system-tests' },
    { icon: Settings, label: 'Settings', href: '/settings' },
];



interface SidebarProps {
    isOpen: boolean;
    onClose: () => void;
}

export default function Sidebar({ isOpen, onClose }: SidebarProps) {
    const pathname = usePathname();
    const { signOut, user } = useAuth();

    // Helper to determine if link is active
    const isLinkActive = (href: string) => {
        if (href === '/dashboard') return pathname === '/dashboard' || pathname === '/';
        return pathname.startsWith(href);
    };

    const handleLinkClick = () => {
        if (window.innerWidth < 1024) {
            onClose();
        }
    };

    return (
        <>
            {/* Mobile Overlay */}
            <div
                className={`fixed inset-0 bg-black/60 backdrop-blur-sm z-40 transition-opacity lg:hidden ${isOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'
                    }`}
                onClick={onClose}
                aria-hidden="true"
            />

            {/* Sidebar Content */}
            <aside
                className={`w-64 h-screen fixed left-0 top-0 bg-[#0f172a] border-r border-slate-800/50 flex flex-col z-50 transition-transform duration-300 ease-in-out lg:translate-x-0 ${isOpen ? 'translate-x-0' : '-translate-x-full'
                    }`}
            >
                <div className="p-6 flex items-center justify-between">
                    <Link href="/dashboard" className="flex items-center gap-3 active:scale-95 transition-transform duration-200" onClick={handleLinkClick}>
                        <div className="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center text-white shadow-lg shadow-indigo-500/20">
                            <Shield size={22} strokeWidth={2.5} />
                        </div>
                        <div className="flex flex-col">
                            <span className="text-white font-black text-xl leading-none">HomeFix</span>
                            <span className="text-indigo-400 text-[10px] font-black uppercase tracking-widest mt-0.5">Admin Panel</span>
                        </div>
                    </Link>
                    <button
                        onClick={onClose}
                        className="p-1 rounded-lg hover:bg-slate-800 lg:hidden text-slate-400"
                        aria-label="Close Sidebar"
                    >
                        <X size={20} />
                    </button>
                </div>

                <nav className="flex-1 px-4 space-y-1 overflow-y-auto no-scrollbar py-2">
                    <h3 className="px-4 text-[10px] font-bold text-slate-500 uppercase tracking-[0.2em] mb-4 mt-4">Main Menu</h3>
                    {menuItems.map((item) => {
                        const isActive = isLinkActive(item.href);
                        return (
                            <Link
                                key={item.href}
                                href={item.href}
                                prefetch={true}
                                onClick={handleLinkClick}
                                className={`flex items-center justify-between gap-3 px-4 py-3 rounded-xl transition-all duration-200 group ${isActive
                                    ? 'bg-indigo-600/10 text-indigo-400 border border-indigo-500/20'
                                    : 'text-slate-400 hover:bg-slate-800/50 hover:text-white border border-transparent'
                                    }`}
                            >
                                <div className="flex items-center gap-3">
                                    <item.icon size={18} className={`transition-all duration-200 ${isActive ? 'text-indigo-400' : 'text-slate-500 group-hover:text-white'}`} />
                                    <span className={`text-sm tracking-tight ${isActive ? 'font-bold' : 'font-medium'}`}>{item.label}</span>
                                </div>
                                {isActive && <div className="w-1 h-4 bg-indigo-500 rounded-full shadow-[0_0_8px_rgba(99,102,241,0.6)]" />}
                            </Link>
                        )
                    })}
                </nav>

                <div className="p-4 border-t border-slate-800/50">
                    <div className="mb-4 px-4 py-3 bg-slate-900/50 border border-slate-800/50 rounded-xl flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center text-xs font-black text-white shadow-sm">
                            {user?.email?.charAt(0).toUpperCase() || 'A'}
                        </div>
                        <div className="flex flex-col overflow-hidden">
                            <span className="text-xs font-bold text-slate-200 truncate max-w-[120px]">{user?.email}</span>
                            <span className="text-[10px] font-bold text-indigo-400 uppercase tracking-wide">Administrator</span>
                        </div>
                    </div>

                    <button
                        onClick={signOut}
                        className="flex items-center gap-3 px-4 py-3 w-full text-slate-400 hover:text-red-400 hover:bg-red-400/10 rounded-xl transition-all duration-200 group border border-transparent hover:border-red-400/20"
                    >
                        <LogOut size={18} className="transition-transform group-hover:translate-x-1" />
                        <span className="font-bold text-sm tracking-tight">Sign Out</span>
                    </button>
                </div>
            </aside>
        </>
    );
}
