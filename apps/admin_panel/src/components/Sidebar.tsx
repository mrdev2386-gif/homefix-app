'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  LayoutDashboard, 
  Calendar, 
  FileText, 
  UserCheck, 
  Users, 
  Briefcase, 
  Star, 
  AlertTriangle,
  Wrench,
  Shield,
  Settings,
  Wallet
} from 'lucide-react';

const menuItems = [
  { name: 'Dashboard', href: '/admin', icon: LayoutDashboard },
  { name: 'Bookings', href: '/bookings', icon: Calendar },
  { name: 'Custom Requests', href: '/custom-requests', icon: FileText },
  { name: 'Withdrawals', href: '/withdrawals', icon: Wallet },
  { name: 'Technicians', href: '/technicians', icon: Users },
  { name: 'Technician Approvals', href: '/technician-approvals', icon: Shield },
  { name: 'Service Approvals', href: '/service-approvals', icon: Settings },
  { name: 'Applications', href: '/applications', icon: UserCheck },
  { name: 'Customers', href: '/customers', icon: Users },
  { name: 'Services', href: '/services', icon: Briefcase },
  { name: 'Reviews', href: '/reviews', icon: Star },
  { name: 'Disputes', href: '/disputes', icon: AlertTriangle },
];

export default function Sidebar({ collapsed }: { collapsed: boolean }) {
  const pathname = usePathname();

  return (
    <aside className={`fixed left-0 top-0 h-screen bg-[#0F172A] border-r border-[#1F2937] transition-all duration-300 z-20 ${collapsed ? 'w-20' : 'w-64'}`}>
      <div className="flex items-center justify-center h-16 px-4 border-b border-[#1F2937]">
        {collapsed ? (
          <Link href="/admin" className="w-10 h-10 bg-gradient-to-br from-[#6366F1] to-[#7C3AED] rounded-lg flex items-center justify-center hover:shadow-[0_0_15px_rgba(99,102,241,0.5)] transition-all duration-300 cursor-pointer">
            <Wrench size={20} className="text-white" />
          </Link>
        ) : (
          <Link href="/admin" className="hover:opacity-80 transition-opacity cursor-pointer flex items-center gap-2">
            <div className="w-8 h-8 bg-gradient-to-br from-[#6366F1] to-[#7C3AED] rounded-lg flex items-center justify-center">
              <Wrench size={16} className="text-white" />
            </div>
            <h1 className="font-bold text-xl text-gradient">HomeFix</h1>
          </Link>
        )}
      </div>
      
      <nav className="p-3 space-y-1 overflow-y-auto h-[calc(100vh-4rem)] scrollbar-thin scrollbar-thumb-[#1F2937] scrollbar-track-transparent">
        {menuItems.map((item) => {
          const Icon = item.icon;
          const isActive = pathname === item.href || (item.href !== '/admin' && pathname.startsWith(item.href));
          
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`sidebar-item ${
                isActive 
                  ? 'sidebar-item-active' 
                  : 'sidebar-item-inactive'
              }`}
              title={collapsed ? item.name : undefined}
            >
              <Icon size={20} className={isActive ? 'text-[#6366F1]' : 'text-[#9CA3AF]'} />
              {!collapsed && <span className="text-sm font-medium">{item.name}</span>}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
