'use client';

import React from 'react';
import AdminLayout from '@/components/AdminLayout';
import { AuthProvider } from '@/components/AuthProvider';

// Error Boundary Component
class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { hasError: boolean; error?: Error }
> {
  constructor(props: { children: React.ReactNode }) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Admin Panel Error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-[#0B1120] flex flex-col items-center justify-center gap-4 p-4">
          <div className="text-red-400 text-6xl">⚠️</div>
          <h1 className="text-2xl font-bold text-[#E5E7EB]">Something went wrong</h1>
          <p className="text-[#9CA3AF] text-center max-w-md">
            An error occurred in the admin panel. Please refresh the page or contact support if the issue persists.
          </p>
          <button
            onClick={() => window.location.reload()}
            className="px-6 py-3 bg-[#6366F1] text-white rounded-lg hover:bg-[#4F46E5] transition-colors"
          >
            Reload Page
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ErrorBoundary>
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
    </ErrorBoundary>
  );
}
