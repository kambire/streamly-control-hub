
import React from 'react';
import { AdminLayout } from '@/components/layout/AdminLayout';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ChartContainer, ChartTooltip, ChartTooltipContent } from '@/components/ui/chart';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { ChartLine, ChartBar, Calendar, Mail, Download } from 'lucide-react';

// Datos de ejemplo para los gráficos
const viewersData = [
  { name: 'Lun', viewers: 4000, sessions: 2400 },
  { name: 'Mar', viewers: 3000, sessions: 1398 },
  { name: 'Mié', viewers: 2000, sessions: 9800 },
  { name: 'Jue', viewers: 2780, sessions: 3908 },
  { name: 'Vie', viewers: 1890, sessions: 4800 },
  { name: 'Sáb', viewers: 2390, sessions: 3800 },
  { name: 'Dom', viewers: 3490, sessions: 4300 },
];

const servicesData = [
  { name: 'RTMP', value: 45 },
  { name: 'HLS', value: 30 },
  { name: 'WebRTC', value: 15 },
  { name: 'RTSP', value: 5 },
  { name: 'VOD', value: 5 },
];

const bandwidthData = [
  { name: 'Semana 1', bandwidth: 350 },
  { name: 'Semana 2', bandwidth: 420 },
  { name: 'Semana 3', bandwidth: 380 },
  { name: 'Semana 4', bandwidth: 510 },
];

const locationData = [
  { country: 'Estados Unidos', users: 1456 },
  { country: 'México', users: 824 },
  { country: 'España', users: 756 },
  { country: 'Argentina', users: 498 },
  { country: 'Colombia', users: 387 },
];

const COLORS = ['#8B5CF6', '#D946EF', '#0EA5E9', '#F97316', '#22C55E'];

const StatsPage = () => {
  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Estadísticas del Sistema</h1>
          <div className="flex items-center space-x-3">
            <div className="flex items-center space-x-2">
              <Label>Período:</Label>
              <Select defaultValue="7days">
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="Seleccionar período" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="today">Hoy</SelectItem>
                  <SelectItem value="yesterday">Ayer</SelectItem>
                  <SelectItem value="7days">Últimos 7 días</SelectItem>
                  <SelectItem value="30days">Últimos 30 días</SelectItem>
                  <SelectItem value="90days">Últimos 90 días</SelectItem>
                  <SelectItem value="custom">Personalizado</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <Button variant="outline">
              <Mail className="mr-2 h-4 w-4" />
              Enviar Reporte
            </Button>
            <Button variant="outline">
              <Download className="mr-2 h-4 w-4" />
              Exportar
            </Button>
          </div>
        </div>

        {/* Tarjetas de Resumen */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Usuarios Activos</CardTitle>
              <Badge variant="success">+5%</Badge>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">1,248</div>
              <p className="text-xs text-muted-foreground">+125 desde la última semana</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Streams Activos</CardTitle>
              <Badge variant="success">+12%</Badge>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">348</div>
              <p className="text-xs text-muted-foreground">+38 desde la última semana</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Ancho de Banda</CardTitle>
              <Badge variant="destructive">-3%</Badge>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">625 GB</div>
              <p className="text-xs text-muted-foreground">-18 GB desde la última semana</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Nuevos Registros</CardTitle>
              <Badge variant="success">+8%</Badge>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">57</div>
              <p className="text-xs text-muted-foreground">+4 desde la última semana</p>
            </CardContent>
          </Card>
        </div>

        {/* Gráficos */}
        <div className="grid gap-6 md:grid-cols-2">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Tendencia de Visualización</CardTitle>
                <div className="flex items-center space-x-2">
                  <ChartLine className="h-4 w-4 text-primary" />
                  <span className="text-sm font-medium">Visualizaciones en tiempo real</span>
                </div>
              </div>
              <CardDescription>Viewers y sesiones en los últimos 7 días</CardDescription>
            </CardHeader>
            <CardContent className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={viewersData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="viewers" stroke="#8B5CF6" activeDot={{ r: 8 }} />
                  <Line type="monotone" dataKey="sessions" stroke="#22C55E" />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Distribución de Servicios</CardTitle>
                <div className="flex items-center space-x-2">
                  <ChartBar className="h-4 w-4 text-primary" />
                  <span className="text-sm font-medium">Distribución por tipo</span>
                </div>
              </div>
              <CardDescription>Uso de los diferentes servicios de streaming</CardDescription>
            </CardHeader>
            <CardContent className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={servicesData}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                    outerRadius={90}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {servicesData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </div>

        {/* Mapa de usuarios (simulado) */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Mapa Global de Usuarios</CardTitle>
              <div className="flex items-center space-x-2">
                <Calendar className="h-4 w-4 text-primary" />
                <span className="text-sm font-medium">Actualizado: Hoy, 14:32</span>
              </div>
            </div>
            <CardDescription>Distribución geográfica de los usuarios</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="rounded-md border border-dashed h-[400px] w-full bg-muted/20 flex items-center justify-center">
              <div className="text-center">
                <p className="text-sm text-muted-foreground mb-4">
                  Mapa interactivo (requiere conexión a un servicio de mapas)
                </p>
                <Button variant="outline">Conectar servicio de mapas</Button>
              </div>
            </div>
            <div className="mt-6 space-y-4">
              <h3 className="text-lg font-medium">Principales ubicaciones</h3>
              <div className="grid gap-4 md:grid-cols-2">
                <Card>
                  <CardContent className="p-4">
                    <div className="space-y-2">
                      {locationData.map((location, i) => (
                        <div key={i} className="flex items-center justify-between pb-2">
                          <div className="font-medium">{location.country}</div>
                          <div className="flex items-center">
                            <span className="text-muted-foreground mr-2">{location.users}</span>
                            <Badge variant="outline">{Math.round(location.users / 40)}%</Badge>
                          </div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
                <Card>
                  <CardHeader className="p-4 pb-0">
                    <CardTitle className="text-sm">Consumo de Ancho de Banda</CardTitle>
                  </CardHeader>
                  <CardContent className="p-4">
                    <ResponsiveContainer width="100%" height={150}>
                      <BarChart data={bandwidthData}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="name" />
                        <YAxis />
                        <Tooltip />
                        <Bar dataKey="bandwidth" fill="#8B5CF6" />
                      </BarChart>
                    </ResponsiveContainer>
                  </CardContent>
                </Card>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </AdminLayout>
  );
};

export default StatsPage;
