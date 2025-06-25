
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
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
  ChartBar,
  RefreshCw,
  Mail,
  Database
} from 'lucide-react';
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from '@/components/ui/sidebar';

interface NavSection {
  title: string;
  items: NavItem[];
}

interface NavItem {
  title: string;
  href: string;
  icon: React.ElementType;
}

const navSections: NavSection[] = [
  {
    title: "Panel Principal",
    items: [
      { title: 'Dashboard', href: '/', icon: LayoutDashboard },
      { title: 'Estadísticas', href: '/stats', icon: ChartBar },
    ]
  },
  {
    title: "Gestión de Usuarios",
    items: [
      { title: 'Usuarios', href: '/users', icon: Users },
      { title: 'Planes & Servicios', href: '/plans', icon: CreditCard },
      { title: 'Tienda', href: '/store', icon: Store },
    ]
  },
  {
    title: "Streaming",
    items: [
      { title: 'Control de Streams', href: '/streams', icon: RefreshCw },
      { title: 'Reproductor', href: '/player', icon: Play },
      { title: 'Video On Demand', href: '/vod', icon: FileVideo },
    ]
  },
  {
    title: "Sistema",
    items: [
      { title: 'Panel de Control', href: '/control', icon: Settings },
      { title: 'Servidor de Correo', href: '/mail', icon: Mail },
      { title: 'Estado del Servidor', href: '/server-status', icon: Server },
      { title: 'Base de Datos', href: '/database', icon: Database },
    ]
  },
  {
    title: "Seguridad",
    items: [
      { title: 'Firewall', href: '/firewall', icon: Shield },
      { title: 'Reportes', href: '/reports', icon: FileText },
    ]
  }
];

export function AppSidebar() {
  const location = useLocation();
  const currentPath = location.pathname;

  return (
    <Sidebar>
      <SidebarHeader className="px-4 py-4 border-b">
        <h1 className="text-xl font-bold text-primary">Streamly Admin</h1>
      </SidebarHeader>
      
      <SidebarContent className="px-2 py-4">
        {navSections.map((section, idx) => (
          <SidebarGroup key={idx} className="mb-6">
            <SidebarGroupLabel className="px-3 py-2 text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              {section.title}
            </SidebarGroupLabel>
            <SidebarGroupContent className="mt-2">
              <SidebarMenu className="space-y-1">
                {section.items.map((item) => {
                  const isActive = currentPath === item.href;
                  return (
                    <SidebarMenuItem key={item.title}>
                      <SidebarMenuButton asChild isActive={isActive} className="px-3 py-2.5 rounded-lg transition-colors">
                        <Link to={item.href} className="flex items-center gap-3">
                          <item.icon className="h-4 w-4" />
                          <span className="text-sm font-medium">{item.title}</span>
                        </Link>
                      </SidebarMenuButton>
                    </SidebarMenuItem>
                  );
                })}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        ))}
      </SidebarContent>
      
      <SidebarFooter className="border-t p-4">
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton asChild className="px-3 py-2.5 rounded-lg">
              <Link to="/settings" className="flex items-center gap-3">
                <Settings className="h-4 w-4" />
                <span className="text-sm font-medium">Configuración</span>
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  );
}
