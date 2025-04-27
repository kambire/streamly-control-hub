
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Dashboard from "./pages/Dashboard";
import UsersPage from "./pages/UsersPage";
import PlansPage from "./pages/PlansPage";
import StatsPage from "./pages/StatsPage";
import NotFoundPage from "./pages/NotFoundPage";
import { AdminLayout } from "./components/layout/AdminLayout";

// Create a placeholder component for routes that don't have their own page yet
import React from "react";

const PlaceholderPage = ({ title }: { title: string }) => {
  return (
    <div className="flex flex-col items-center justify-center min-h-[calc(100vh-10rem)] bg-background rounded-lg border border-border p-8">
      <h1 className="text-3xl font-bold mb-4">{title}</h1>
      <p className="text-muted-foreground mb-6">This page is under development.</p>
    </div>
  );
};

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<AdminLayout><Dashboard /></AdminLayout>} />
          <Route path="/stats" element={<AdminLayout><StatsPage /></AdminLayout>} />
          
          {/* User Management Routes */}
          <Route path="/users" element={<AdminLayout><UsersPage /></AdminLayout>} />
          <Route path="/plans" element={<AdminLayout><PlansPage /></AdminLayout>} />
          <Route path="/store" element={<AdminLayout><PlaceholderPage title="Tienda" /></AdminLayout>} />
          
          {/* Streaming Routes */}
          <Route path="/streams" element={<AdminLayout><PlaceholderPage title="Control de Streams" /></AdminLayout>} />
          <Route path="/player" element={<AdminLayout><PlaceholderPage title="Reproductor" /></AdminLayout>} />
          <Route path="/vod" element={<AdminLayout><PlaceholderPage title="Video On Demand" /></AdminLayout>} />
          
          {/* System Routes */}
          <Route path="/control" element={<AdminLayout><PlaceholderPage title="Panel de Control" /></AdminLayout>} />
          <Route path="/mail" element={<AdminLayout><PlaceholderPage title="Servidor de Correo" /></AdminLayout>} />
          <Route path="/server-status" element={<AdminLayout><PlaceholderPage title="Estado del Servidor" /></AdminLayout>} />
          <Route path="/database" element={<AdminLayout><PlaceholderPage title="Base de Datos" /></AdminLayout>} />
          
          {/* Security Routes */}
          <Route path="/firewall" element={<AdminLayout><PlaceholderPage title="Firewall" /></AdminLayout>} />
          <Route path="/reports" element={<AdminLayout><PlaceholderPage title="Reportes" /></AdminLayout>} />
          
          {/* Settings */}
          <Route path="/settings" element={<AdminLayout><PlaceholderPage title="Configuración" /></AdminLayout>} />
          
          {/* 404 Page */}
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
