
import React, { useState } from 'react';
import { AdminLayout } from '@/components/layout/AdminLayout';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Plus, Edit, Trash2, Check } from 'lucide-react';
import { useToast } from "@/hooks/use-toast";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

const initialPlans = [
  { 
    id: 1, 
    name: 'Plan Básico', 
    price: 19.99, 
    billingCycle: 'Mensual', 
    streamTypes: ['RTMP', 'HLS'],
    maxStreams: 1,
    maxViewers: 100,
    storage: '5GB',
    features: ['720p máximo', 'Reproductor personalizable', 'Soporte por correo']
  },
  { 
    id: 2, 
    name: 'Plan Pro', 
    price: 49.99, 
    billingCycle: 'Mensual', 
    streamTypes: ['RTMP', 'HLS', 'WebRTC'],
    maxStreams: 3,
    maxViewers: 500,
    storage: '25GB',
    features: ['1080p máximo', 'Reproductor personalizable', 'VOD', 'Soporte prioritario', 'API Access']
  },
  { 
    id: 3, 
    name: 'Plan Empresa', 
    price: 99.99, 
    billingCycle: 'Mensual', 
    streamTypes: ['RTMP', 'HLS', 'WebRTC', 'RTSP'],
    maxStreams: 10,
    maxViewers: 2000,
    storage: '100GB',
    features: ['4K máximo', 'Reproductor personalizable', 'VOD', 'Shoutcast/Icecast', 'Soporte 24/7', 'API Access', 'White label']
  },
];

const PlansPage = () => {
  const { toast } = useToast();
  const [plans, setPlans] = useState(initialPlans);
  const [showAddPlanDialog, setShowAddPlanDialog] = useState(false);
  const [newPlan, setNewPlan] = useState({
    name: '',
    price: '',
    billingCycle: 'Mensual',
    streamType: 'RTMP',
    maxStreams: '',
    maxViewers: '',
    storage: '',
    features: ''
  });

  const handleAddPlan = () => {
    const featuresArray = newPlan.features.split(',').map(item => item.trim()).filter(Boolean);
    
    const planToAdd = {
      id: plans.length + 1,
      name: newPlan.name,
      price: parseFloat(newPlan.price),
      billingCycle: newPlan.billingCycle,
      streamTypes: [newPlan.streamType],
      maxStreams: parseInt(newPlan.maxStreams),
      maxViewers: parseInt(newPlan.maxViewers),
      storage: newPlan.storage,
      features: featuresArray
    };
    
    setPlans([...plans, planToAdd]);
    setShowAddPlanDialog(false);
    toast({
      title: "Plan creado",
      description: `El plan ${newPlan.name} ha sido creado exitosamente`,
    });
    
    // Reset form
    setNewPlan({
      name: '',
      price: '',
      billingCycle: 'Mensual',
      streamType: 'RTMP',
      maxStreams: '',
      maxViewers: '',
      storage: '',
      features: ''
    });
  };

  const handleDeletePlan = (id: number, name: string) => {
    setPlans(plans.filter(plan => plan.id !== id));
    toast({
      title: "Plan eliminado",
      description: `El plan ${name} ha sido eliminado`,
      variant: "destructive",
    });
  };

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Administración de Planes</h1>
          <Dialog open={showAddPlanDialog} onOpenChange={setShowAddPlanDialog}>
            <DialogTrigger asChild>
              <Button>
                <Plus className="h-4 w-4 mr-2" />
                Nuevo Plan
              </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[550px]">
              <DialogHeader>
                <DialogTitle>Crear nuevo plan</DialogTitle>
                <DialogDescription>
                  Complete la información para crear un nuevo plan de servicio.
                </DialogDescription>
              </DialogHeader>
              <div className="grid gap-4 py-4">
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="name" className="text-right">Nombre</Label>
                  <Input
                    id="name"
                    value={newPlan.name}
                    onChange={(e) => setNewPlan({...newPlan, name: e.target.value})}
                    className="col-span-3"
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="price" className="text-right">Precio</Label>
                  <Input
                    id="price"
                    type="number"
                    value={newPlan.price}
                    onChange={(e) => setNewPlan({...newPlan, price: e.target.value})}
                    className="col-span-3"
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="billing" className="text-right">Facturación</Label>
                  <Select
                    value={newPlan.billingCycle}
                    onValueChange={(value) => setNewPlan({...newPlan, billingCycle: value})}
                  >
                    <SelectTrigger className="col-span-3">
                      <SelectValue placeholder="Seleccionar ciclo de facturación" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Mensual">Mensual</SelectItem>
                      <SelectItem value="Trimestral">Trimestral</SelectItem>
                      <SelectItem value="Anual">Anual</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="streamType" className="text-right">Tipo Stream</Label>
                  <Select
                    value={newPlan.streamType}
                    onValueChange={(value) => setNewPlan({...newPlan, streamType: value})}
                  >
                    <SelectTrigger className="col-span-3">
                      <SelectValue placeholder="Seleccionar tipo de stream" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="RTMP">RTMP</SelectItem>
                      <SelectItem value="HLS">HLS</SelectItem>
                      <SelectItem value="WebRTC">WebRTC</SelectItem>
                      <SelectItem value="RTSP">RTSP</SelectItem>
                      <SelectItem value="VOD">Video On Demand</SelectItem>
                      <SelectItem value="Shoutcast">Shoutcast/Icecast</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="maxStreams" className="text-right">Máx. Streams</Label>
                  <Input
                    id="maxStreams"
                    type="number"
                    value={newPlan.maxStreams}
                    onChange={(e) => setNewPlan({...newPlan, maxStreams: e.target.value})}
                    className="col-span-3"
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="maxViewers" className="text-right">Máx. Viewers</Label>
                  <Input
                    id="maxViewers"
                    type="number"
                    value={newPlan.maxViewers}
                    onChange={(e) => setNewPlan({...newPlan, maxViewers: e.target.value})}
                    className="col-span-3"
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="storage" className="text-right">Almacenamiento</Label>
                  <Input
                    id="storage"
                    value={newPlan.storage}
                    onChange={(e) => setNewPlan({...newPlan, storage: e.target.value})}
                    className="col-span-3"
                    placeholder="Ej: 5GB"
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="features" className="text-right">
                    Características
                  </Label>
                  <Textarea
                    id="features"
                    value={newPlan.features}
                    onChange={(e) => setNewPlan({...newPlan, features: e.target.value})}
                    className="col-span-3"
                    placeholder="Una característica por línea o separadas por comas"
                  />
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setShowAddPlanDialog(false)}>
                  Cancelar
                </Button>
                <Button onClick={handleAddPlan}>
                  Crear Plan
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {plans.map((plan) => (
            <Card key={plan.id} className="relative overflow-hidden">
              {plan.id === 2 && (
                <div className="absolute -right-12 top-8 bg-primary text-primary-foreground transform rotate-45 px-12 py-1 text-sm font-medium">
                  Popular
                </div>
              )}
              <CardHeader>
                <CardTitle>{plan.name}</CardTitle>
                <CardDescription className="flex items-baseline">
                  <span className="text-3xl font-extrabold">${plan.price}</span>
                  <span className="ml-2 text-sm text-muted-foreground">/{plan.billingCycle.toLowerCase()}</span>
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div>
                    <h4 className="text-sm font-medium mb-2">Tipos de Stream</h4>
                    <div className="flex flex-wrap gap-1">
                      {plan.streamTypes.map((type, idx) => (
                        <Badge key={idx} variant="outline">{type}</Badge>
                      ))}
                    </div>
                  </div>
                  <div>
                    <h4 className="text-sm font-medium">Límites</h4>
                    <ul className="text-sm mt-2">
                      <li className="flex items-center"><Check className="h-4 w-4 mr-2 text-primary" /> {plan.maxStreams} streams simultáneos</li>
                      <li className="flex items-center"><Check className="h-4 w-4 mr-2 text-primary" /> {plan.maxViewers} viewers máximo</li>
                      <li className="flex items-center"><Check className="h-4 w-4 mr-2 text-primary" /> {plan.storage} almacenamiento</li>
                    </ul>
                  </div>
                  <div>
                    <h4 className="text-sm font-medium">Características</h4>
                    <ul className="text-sm mt-2 space-y-1">
                      {plan.features.map((feature, idx) => (
                        <li key={idx} className="flex items-center">
                          <Check className="h-4 w-4 mr-2 text-primary" /> {feature}
                        </li>
                      ))}
                    </ul>
                  </div>
                  <div className="flex space-x-2 pt-4">
                    <Button variant="outline" size="sm" className="w-full">
                      <Edit className="h-4 w-4 mr-2" />
                      Editar
                    </Button>
                    <Button 
                      variant="outline" 
                      size="sm" 
                      className="w-full text-destructive hover:bg-destructive/10"
                      onClick={() => handleDeletePlan(plan.id, plan.name)}
                    >
                      <Trash2 className="h-4 w-4 mr-2" />
                      Eliminar
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </AdminLayout>
  );
};

export default PlansPage;
