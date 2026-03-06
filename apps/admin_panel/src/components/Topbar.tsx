'use client';

import { useState } from 'react';
import { Bell, Menu, User, LogOut, Settings as SettingsIcon } from 'lucide-react';
import { useRouter } from 'next/navigation';

export default function Topbar({ 
  onToggleSidebar, 
  pageTitle 
}: { 
  onToggleSidebar: () => void;
  pageTitle: string;
}) {
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const router = useRouter();

  return (
    <header className="h-16 bg-[#0F172A] border-b border-[#1F2937] flex items-center justify-between px-6 sticky top-0 z-10">
      <div className="flex items-center gap-4">
        <button 
          onClick={onToggleSidebar}
          className="p-2 hover:bg-[#1F2937] rounded-lg transition-colors"
          aria-label="Toggle sidebar"
        >
          <Menu size={20} className="text-[#E5E7EB]" />
        </button>
        <h2 className="text-xl font-semibold text-[#E5E7EB]">{pageTitle}</h2>
      </div>
      
      <div className="flex items-center gap-4">
        <button className="relative p-2 hover:bg-[#1F2937] rounded-lg transition-colors" aria-label="Notifications">
          <Bell size={20} className="text-[#9CA3AF]" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full"></span>
        </button>
        
        <div className="relative pl-4 border-l border-[#1F2937]">
          <button
            onClick={() => setShowProfileMenu(!showProfileMenu)}
            className="flex items-center gap-3 hover:bg-[#1F2937] rounded-lg p-2 transition-colors"
          >
            <div className="w-8 h-8 bg-gradient-to-br from-[#6366F1] to-[#7C3AED] rounded-full flex items-center justify-center">
              <User size={16} className="text-white" />
            </div>
            <div className="hidden md:block text-left">
              <p className="text-sm font-medium text-[#E5E7EB]">Admin</p>
              <p className="text-xs text-[#9CA3AF]">admin@homefix.com</p>
            </div>
          </button>

          {showProfileMenu && (
            <>
              <div 
                className="fixed inset-0 z-10" 
                onClick={() => setShowProfileMenu(false)}
              />
              <div className="absolute right-0 mt-2 w-48 bg-[#111827] border border-[#1F2937] rounded-lg shadow-xl py-1 z-20">
                <button
                  onClick={() => {
                    setShowProfileMenu(false);
                    router.push('/settings');
                  }}
                  className="w-full flex items-center gap-3 px-4 py-2 text-sm text-[#9CA3AF] hover:bg-[#1F2937] hover:text-[#E5E7EB] transition-colors"
                >
                  <SettingsIcon size={16} />
                  Settings
                </button>
                <button
                  onClick={() => {
                    setShowProfileMenu(false);
                    router.push('/login');
                  }}
                  className="w-full flex items-center gap-3 px-4 py-2 text-sm text-red-400 hover:bg-[#1F2937] transition-colors"
                >
                  <LogOut size={16} />
                  Logout
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </header>
  );
}
