
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { cn } from '@/lib/utils';
import { 
  Users, 
  Settings, 
  Play, 
  FileVideo, 
  Store, 
  CreditCard,
  Shield, 
  FileText, 
  LayoutDashboard,
  Server,
  Link2,
  Key
} from 'lucide-react';

interface SidebarProps {
  open: boolean;
  setOpen: (open: boolean) => void;
}

interface NavItem {
  title: string;
  href: string;
  icon: React.ElementType;
}

const navItems: NavItem[] = [
  { title: 'Dashboard', href: '/', icon: LayoutDashboard },
  { title: 'Users Management', href: '/users', icon: Users },
  { title: 'Control Panel', href: '/control', icon: Settings },
  { title: 'Player Options', href: '/player', icon: Play },
  { title: 'Video on Demand', href: '/vod', icon: FileVideo },
  { title: 'Store', href: '/store', icon: Store },
  { title: 'Payment Gateways', href: '/payments', icon: CreditCard },
  { title: 'WHMCS Integration', href: '/whmcs', icon: Link2 },
  { title: 'API', href: '/api', icon: Server },
  { title: 'Firewall', href: '/firewall', icon: Shield },
  { title: 'Domain Security', href: '/security', icon: Key },
  { title: 'Reports', href: '/reports', icon: FileText },
];

export const Sidebar: React.FC<SidebarProps> = ({ open, setOpen }) => {
  const location = useLocation();
  const currentPath = location.pathname;

  return (
    <aside
      className={cn(
        "fixed inset-y-0 left-0 z-50 flex h-screen w-64 flex-col bg-sidebar transition-transform duration-300 ease-in-out md:static",
        open ? "translate-x-0" : "-translate-x-full md:translate-x-0 md:w-16"
      )}
    >
      <div className="flex h-16 items-center justify-between px-4 border-b border-sidebar-border">
        <div className={cn("flex items-center", open ? "justify-between w-full" : "justify-center")}>
          {open ? (
            <>
              <h1 className="text-xl font-bold text-primary whitespace-nowrap">Streamly Admin</h1>
              <button 
                className="md:flex hidden items-center justify-center text-sidebar-foreground hover:text-primary"
                onClick={() => setOpen(false)}
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m15 18-6-6 6-6"/></svg>
              </button>
            </>
          ) : (
            <button 
              className="hidden md:flex items-center justify-center text-sidebar-foreground hover:text-primary"
              onClick={() => setOpen(true)}
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m9 18 6-6-6-6"/></svg>
            </button>
          )}
        </div>
      </div>
      
      <div className="flex-1 overflow-y-auto py-4 px-3">
        <nav className="space-y-1">
          {navItems.map((item) => {
            const isActive = currentPath === item.href;
            return (
              <Link
                key={item.title}
                to={item.href}
                className={cn(
                  "flex items-center rounded-md px-3 py-2 text-sm font-medium transition-colors",
                  isActive 
                    ? "bg-sidebar-accent text-primary" 
                    : "text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-foreground",
                  !open && "justify-center px-3"
                )}
              >
                <item.icon className={cn("h-5 w-5", isActive && "text-primary")} />
                {open && <span className="ml-3">{item.title}</span>}
              </Link>
            );
          })}
        </nav>
      </div>
      
      <div className="border-t border-sidebar-border p-4">
        <Link
          to="/settings"
          className={cn(
            "flex items-center rounded-md px-3 py-2 text-sm font-medium text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-foreground transition-colors",
            !open && "justify-center px-3"
          )}
        >
          <Settings className="h-5 w-5" />
          {open && <span className="ml-3">Settings</span>}
        </Link>
      </div>
    </aside>
  );
};
