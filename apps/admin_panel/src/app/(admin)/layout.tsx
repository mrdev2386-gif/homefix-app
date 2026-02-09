'use client';

import { useState, useEffect } from 'react';
import Sidebar from '@/components/Sidebar';
import Topbar from '@/components/Topbar';
import { useAuth } from '@/components/AuthProvider';
import { Loader2 } from 'lucide-react';
import { initializeBanners } from '@/lib/initialize-banners';

export default function AdminLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    const [isSidebarOpen, setIsSidebarOpen] = useState(false);
    const { isAdmin, loading } = useAuth();

    useEffect(() => {
        if (isAdmin) {
            initializeBanners();
        }
    }, [isAdmin]);

    const toggleSidebar = () => setIsSidebarOpen(!isSidebarOpen);

    if (loading) {
        return (
            <div className="min-h-screen bg-[#020617] flex flex-col items-center justify-center gap-4">
                <div className="w-12 h-12 border-4 border-indigo-600/20 border-t-indigo-500 rounded-full animate-spin shadow-xl"></div>
                <p className="text-slate-500 font-black uppercase tracking-[0.2em] text-[10px]">Synchronizing Identity</p>
            </div>
        );
    }


    if (!isAdmin) {
        return null; // AuthProvider handles redirect
    }

    return (
        <div className="min-h-screen bg-[#020617] flex overflow-hidden">
            {/* Shared Sidebar - Persistent across admin pages */}
            <Sidebar isOpen={isSidebarOpen} onClose={() => setIsSidebarOpen(false)} />

            <div className="flex-1 flex flex-col min-h-screen transition-all duration-300 w-full lg:ml-64">
                <Topbar onMenuClick={toggleSidebar} />
                <main className="flex-1 p-4 md:p-8 overflow-y-auto overflow-x-hidden w-full max-w-[1920px] mx-auto bg-slate-950/20">
                    <div className="animate-fade-in space-y-6 pb-20">
                        {children}
                    </div>
                </main>
            </div>
        </div>
    );
}

