'use client';

import React from 'react';
import AdminLayout from '@/components/AdminLayout';
import { AuthProvider } from '@/components/AuthProvider';

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthProvider>
      <React.Suspense fallback={
        <div className="min-h-screen bg-[#0B1120] flex flex-col items-center justify-center gap-4">
          <div className="relative">
            <div className="w-12 h-12 border-4 border-indigo-500/20 rounded-full"></div>
            <div className="w-12 h-12 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin absolute top-0 left-0"></div>
          </div>
          <p className="text-indigo-400/80 text-[10px] font-black uppercase tracking-[0.3em] animate-pulse">Loading Panel</p>
        </div>
      }>
        <AdminLayout>{children}</AdminLayout>
      </React.Suspense>
    </AuthProvider>
  );
}
