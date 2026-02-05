'use client';

import { Loader2 } from 'lucide-react';

export default function Loading() {
    return (
        <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center gap-4">
            <div className="relative">
                <div className="w-16 h-16 border-4 border-indigo-100 rounded-full animate-spin"></div>
                <div className="w-16 h-16 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin absolute top-0 left-0"></div>
            </div>
            <p className="text-slate-400 font-black uppercase tracking-[0.2em] text-xs animate-pulse">
                Accessing Node
            </p>
        </div>
    );
}
