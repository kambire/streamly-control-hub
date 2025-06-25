
import React from 'react';
import { StatsCard } from '@/components/dashboard/StatsCard';
import { Users, Play, FileVideo, CreditCard } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const data = [
  { name: 'Jan', streams: 400 },
  { name: 'Feb', streams: 600 },
  { name: 'Mar', streams: 800 },
  { name: 'Apr', streams: 1200 },
  { name: 'May', streams: 800 },
  { name: 'Jun', streams: 1600 },
  { name: 'Jul', streams: 1800 },
];

const Dashboard = () => {
  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatsCard title="Total Users" value="2,345" icon={Users} />
        <StatsCard title="Active Streams" value="126" icon={Play} />
        <StatsCard title="VOD Content" value="1,087" icon={FileVideo} />
        <StatsCard title="Monthly Revenue" value="$12,345" icon={CreditCard} />
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Streaming Activity</CardTitle>
            <CardDescription>Monthly active streams</CardDescription>
          </CardHeader>
          <CardContent className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={data}>
                <defs>
                  <linearGradient id="colorStreams" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#9b87f5" stopOpacity={0.8}/>
                    <stop offset="95%" stopColor="#9b87f5" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#333" vertical={false} />
                <XAxis dataKey="name" stroke="#888" />
                <YAxis stroke="#888" />
                <Tooltip 
                  contentStyle={{ backgroundColor: "#1A1F2C", borderColor: "#333" }} 
                  itemStyle={{ color: "#fff" }}
                  labelStyle={{ color: "#9b87f5" }}
                />
                <Area 
                  type="monotone" 
                  dataKey="streams" 
                  stroke="#9b87f5" 
                  fillOpacity={1} 
                  fill="url(#colorStreams)" 
                />
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader>
            <CardTitle>Popular Services</CardTitle>
            <CardDescription>Most used streaming protocols</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {[
                { name: "HLS", value: 42, color: "bg-streamly-primary" },
                { name: "RTMP", value: 28, color: "bg-streamly-secondary" },
                { name: "WebRTC", value: 18, color: "bg-streamly-accent" },
                { name: "RTSP", value: 12, color: "bg-muted-foreground" },
              ].map((item) => (
                <div key={item.name} className="space-y-2">
                  <div className="flex justify-between">
                    <span className="text-sm font-medium">{item.name}</span>
                    <span className="text-sm text-muted-foreground">{item.value}%</span>
                  </div>
                  <div className="h-2 w-full bg-muted rounded-full overflow-hidden">
                    <div className={`h-full ${item.color}`} style={{ width: `${item.value}%` }}></div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
      
      <div className="grid grid-cols-1 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
            <CardDescription>Latest user activities</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {[
                { user: "Carlos Rodriguez", action: "Started a new RTMP stream", time: "5 minutes ago" },
                { user: "Maria Garcia", action: "Purchased HLS Package", time: "1 hour ago" },
                { user: "John Smith", action: "Updated player settings", time: "2 hours ago" },
                { user: "Sara Johnson", action: "Added new VOD content", time: "5 hours ago" },
                { user: "Michael Brown", action: "Changed security settings", time: "1 day ago" },
              ].map((item, i) => (
                <div key={i} className="flex items-center justify-between py-2 border-b last:border-0">
                  <div>
                    <p className="font-medium">{item.user}</p>
                    <p className="text-sm text-muted-foreground">{item.action}</p>
                  </div>
                  <span className="text-xs text-muted-foreground">{item.time}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default Dashboard;
