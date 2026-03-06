'use client';

import { useState, useEffect } from 'react';
import { usePathname } from 'next/navigation';
import Sidebar from './Sidebar';
import Topbar from './Topbar';

const pageTitles: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/bookings': 'Bookings',
  '/custom-requests': 'Custom Requests',
  '/applications': 'Technician Applications',
  '/technicians': 'Technicians',
  '/customers': 'Customers',
  '/services': 'Services',
  '/reviews': 'Reviews',
  '/disputes': 'Disputes',
};

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const pathname = usePathname();
  const pageTitle = pageTitles[pathname] || 'Admin Panel';

  return (
    <div className="min-h-screen bg-[#0B1120]">
      <Sidebar collapsed={sidebarCollapsed} />
      
      <div className={`transition-all duration-300 ${sidebarCollapsed ? 'ml-20' : 'ml-64'}`}>
        <Topbar 
          onToggleSidebar={() => setSidebarCollapsed(!sidebarCollapsed)} 
          pageTitle={pageTitle}
        />
        
        <main className="p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
