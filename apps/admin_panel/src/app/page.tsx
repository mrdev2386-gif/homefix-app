'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/components/AuthProvider';

export default function HomePage() {
  const router = useRouter();
  const { user, isAdmin, loading } = useAuth();

  useEffect(() => {
    if (!loading) {
      if (user && isAdmin) {
        router.replace('/admin');
      } else {
        router.replace('/login');
      }
    }
  }, [user, isAdmin, loading, router]);

  // Show loading state while redirecting
  return (
    <div className="h-screen w-full flex flex-col items-center justify-center bg-[#020617] gap-4">
      <div className="relative">
        <div className="w-12 h-12 border-4 border-indigo-500/20 rounded-full"></div>
        <div className="w-12 h-12 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin absolute top-0 left-0"></div>
      </div>
      <p className="text-indigo-400/80 text-[10px] font-black uppercase tracking-[0.3em] animate-pulse">
        {loading ? 'Loading...' : 'Redirecting...'}
      </p>
    </div>
  );
}
