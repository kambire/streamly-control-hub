
import React from 'react';
import { useIsMobile } from '@/hooks/use-mobile';
import { Menu, Bell, User } from 'lucide-react';
import { 
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

interface HeaderProps {
  sidebarOpen: boolean;
  setSidebarOpen: (open: boolean) => void;
}

export const Header: React.FC<HeaderProps> = ({ sidebarOpen, setSidebarOpen }) => {
  const isMobile = useIsMobile();
  
  return (
    <header className="h-16 bg-card border-b border-border flex items-center justify-between px-4 md:px-6">
      <div className="flex items-center">
        {isMobile && (
          <button
            className="mr-4 rounded-md p-1.5 hover:bg-accent focus:outline-none focus:ring-2 focus:ring-inset focus:ring-primary"
            onClick={() => setSidebarOpen(!sidebarOpen)}
          >
            <Menu className="h-5 w-5" />
          </button>
        )}
        <h2 className="text-xl font-semibold">Admin Dashboard</h2>
      </div>
      
      <div className="flex items-center space-x-4">
        <button className="rounded-full p-1.5 hover:bg-accent focus:outline-none focus:ring-2 focus:ring-primary">
          <Bell className="h-5 w-5" />
        </button>
        
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button className="flex items-center text-sm rounded-full focus:outline-none focus:ring-2 focus:ring-primary">
              <div className="h-8 w-8 rounded-full bg-streamly-primary/20 flex items-center justify-center text-streamly-primary">
                <User className="h-5 w-5" />
              </div>
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            <DropdownMenuLabel>My Account</DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem>Profile</DropdownMenuItem>
            <DropdownMenuItem>Settings</DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem>Log out</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
};
