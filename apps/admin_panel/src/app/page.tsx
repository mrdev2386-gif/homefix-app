'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/components/AuthProvider';

export default function RootPage() {
    const router = useRouter();
    const { user, loading, isAdmin } = useAuth();

    useEffect(() => {
        if (!loading) {
            if (user && isAdmin) {
                router.push('/dashboard');
            } else {
                router.push('/login');
            }
        }
    }, [user, isAdmin, loading, router]);

    return (
        <div className="min-h-screen bg-slate-50 flex items-center justify-center">
            <div className="w-12 h-12 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
        </div>
    );
}
