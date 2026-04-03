'use client';

import AdminLayout from '@/components/AdminLayout';
import { AuthProvider } from '@/components/AuthProvider';

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthProvider>
      <AdminLayout>{children}</AdminLayout>
    </AuthProvider>
  );
}
