'use client';

import React, { useState } from 'react';
import Sidebar from '@/components/Sidebar';
import Topbar from '@/components/Topbar';
import { useAuth } from '@/components/AuthProvider';
import { Loader2 } from 'lucide-react';

class ErrorBoundary extends React.Component<
    { children: React.ReactNode },
    { hasError: boolean }
> {
    constructor(props: { children: React.ReactNode }) {
        super(props);
        this.state = { hasError: false };
    }

    static getDerivedStateFromError() {
        return { hasError: true };
    }

    componentDidCatch(error: Error) {
        if (process.env.NODE_ENV === 'development') {
            console.error('ErrorBoundary caught:', error);
        }
    }

    render() {
        if (this.state.hasError) {
            return (
                <div className="flex min-h-screen bg-[#0f172a] items-center justify-center">
                    <div className="text-center">
                        <h2 className="text-white text-xl mb-4">Something went wrong</h2>
                        <button 
                            onClick={() => window.location.reload()}
                            className="px-4 py-2 bg-indigo-500 text-white rounded-lg hover:bg-indigo-600"
                        >
                            Reload
                        </button>
                    </div>
                </div>
            );
        }
        return this.props.children;
    }
}

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
    const { loading, isAdmin } = useAuth();
    const [isSidebarOpen, setIsSidebarOpen] = useState(false);

    const toggleSidebar = () => setIsSidebarOpen(!isSidebarOpen);

    // Initial Loading State
    if (loading) {
        return (
            <div className="flex min-h-screen bg-[#0f172a] items-center justify-center">
                <div className="flex flex-col items-center gap-6">
                    <div className="relative">
                        <div className="w-16 h-16 border-4 border-indigo-500/20 rounded-full animate-pulse"></div>
                        <Loader2 className="w-16 h-16 text-indigo-500 animate-spin absolute top-0 left-0" />
                    </div>
                    <div className="flex flex-col items-center gap-2">
                        <span className="text-white font-black text-xl tracking-tight">HomeFix</span>
                        <span className="text-slate-500 font-bold uppercase tracking-[0.3em] text-[10px] animate-pulse">Initialising Admin Console</span>
                    </div>
                </div>
            </div>
        );
    }

    // Access Control
    if (!isAdmin) {
        return null; // AuthProvider handles redirect
    }

    return (
        <ErrorBoundary>
            <div className="min-h-screen bg-[#0f172a] flex overflow-hidden selection:bg-indigo-500/30">
                {/* Sidebar handles its own responsive visibility */}
                <Sidebar collapsed={!isSidebarOpen} />

                {/* Main Content Area */}
                <div className="flex-1 flex flex-col min-h-screen transition-all duration-300 w-full lg:ml-64">
                    <Topbar onToggleSidebar={toggleSidebar} pageTitle="Dashboard" />

                    <main className="flex-1 p-4 md:p-8 overflow-y-auto no-scrollbar overflow-x-hidden w-full max-w-[1600px] mx-auto">
                        <div className="animate-in space-y-8 pb-20">
                            {children}
                        </div>
                    </main>
                </div>
            </div>
        </ErrorBoundary>
    );
}
