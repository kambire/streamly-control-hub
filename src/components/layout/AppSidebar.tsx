
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
      <SidebarHeader className="p-4">
        <h1 className="text-xl font-bold text-primary">Streamly Admin</h1>
      </SidebarHeader>
      
      <SidebarContent>
        {navSections.map((section, idx) => (
          <SidebarGroup key={idx}>
            <SidebarGroupLabel>{section.title}</SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu>
                {section.items.map((item) => {
                  const isActive = currentPath === item.href;
                  return (
                    <SidebarMenuItem key={item.title}>
                      <SidebarMenuButton asChild isActive={isActive}>
                        <Link to={item.href}>
                          <item.icon />
                          <span>{item.title}</span>
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
      
      <SidebarFooter>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton asChild>
              <Link to="/settings">
                <Settings />
                <span>Configuración</span>
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  );
}
