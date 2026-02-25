import { useState, useEffect, useCallback, useRef } from "react";
import { Server, Activity, Zap, Clock } from "lucide-react";
import ServiceCard from "@/components/ServiceCard";

type ServiceStatus = "healthy" | "degraded" | "down";

interface ServiceConfig {
  name: string;
  language: string;
  endpoint: string;
}

interface ServiceState extends ServiceConfig {
  status: ServiceStatus;
  latencyMs: number;
  lastChecked: Date | null;
}

const monitoredServices: ServiceConfig[] = [
  {
    name: "auth-service",
    language: "Go",
    endpoint: "/api/auth/healthz/live",
  },
  {
    name: "basket-service",
    language: "Node.js",
    endpoint: "/api/basket/healthz/live",
  },
];

const Index = () => {
  const [services, setServices] = useState<ServiceState[]>(
    monitoredServices.map((s) => ({
      ...s,
      status: "down",
      latencyMs: 0,
      lastChecked: null,
    }))
  );

  const [globalUptime, setGlobalUptime] = useState("0.00%");
  const abortControllerRef = useRef<AbortController | null>(null);

  const checkServiceHealth = async (service: ServiceConfig, signal: AbortSignal): Promise<ServiceState> => {
    const startTime = performance.now();
    try {
      const response = await fetch(service.endpoint, { 
        signal,
        cache: "no-store",
        headers: {
          "Cache-Control": "no-cache"
        }
      });
      const endTime = performance.now();
      
      return {
        ...service,
        status: response.ok ? "healthy" : "degraded",
        latencyMs: Math.round(endTime - startTime),
        lastChecked: new Date(),
      };
    } catch (error) {
      if ((error as Error).name === "AbortError") {
        throw error;
      }
      return {
        ...service,
        status: "down",
        latencyMs: 0,
        lastChecked: new Date(),
      };
    }
  };

  const fetchAllStatuses = useCallback(async () => {
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }
    
    abortControllerRef.current = new AbortController();
    const { signal } = abortControllerRef.current;

    try {
      const healthPromises = monitoredServices.map((service) =>
        checkServiceHealth(service, signal)
      );

      const results = await Promise.all(healthPromises);
      
      setServices(results);
      
      const healthyCount = results.filter(r => r.status === "healthy").length;
      const uptimePercentage = ((healthyCount / monitoredServices.length) * 100).toFixed(2);
      setGlobalUptime(`${uptimePercentage}%`);
      
    } catch (error) {
      if ((error as Error).name !== "AbortError") {
        console.error("Health check failed", error);
      }
    }
  }, []);

  useEffect(() => {
    fetchAllStatuses();
    const intervalId = setInterval(fetchAllStatuses, 5000);

    return () => {
      clearInterval(intervalId);
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
    };
  }, [fetchAllStatuses]);

  const activeServices = services.filter((s) => s.status === "healthy").length;
  const avgLatency = services.reduce((acc, curr) => acc + curr.latencyMs, 0) / (services.length || 1);

  const stats = [
    { icon: Server, label: "Network Nodes", value: `${activeServices}/${monitoredServices.length}` },
    { icon: Activity, label: "Gateway Status", value: activeServices > 0 ? "ONLINE" : "OFFLINE" },
    { icon: Zap, label: "Avg Latency", value: `${Math.round(avgLatency)}ms` },
    { icon: Clock, label: "Current Capacity", value: globalUptime },
  ];

  return (
    <div className="min-h-screen bg-background p-6 md:p-10">
      <div className="max-w-6xl mx-auto">
        <div className="mb-10">
          <div className="flex items-center gap-3 mb-2">
            <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
              <Server size={16} className="text-primary" />
            </div>
            <h1 className="text-2xl font-bold text-foreground">Infrastructure Connectivity</h1>
          </div>
          <p className="text-muted-foreground text-sm">
            Real-time ping via Nginx Reverse Proxy
          </p>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          {stats.map(({ icon: Icon, label, value }) => (
            <div key={label} className="rounded-lg border border-border bg-card px-4 py-3 shadow-sm">
              <div className="flex items-center gap-2 text-muted-foreground mb-1">
                <Icon size={13} />
                <span className="text-xs uppercase tracking-wider">{label}</span>
              </div>
              <p className="text-xl font-bold font-mono text-card-foreground">{value}</p>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {services.map((service) => (
            <ServiceCard 
              key={service.name} 
              name={service.name}
              language={service.language}
              requests={service.latencyMs} 
              status={service.status}
              trend={0} 
              uptime={service.lastChecked ? service.lastChecked.toLocaleTimeString() : "Pending..."}
            />
          ))}
        </div>
      </div>
    </div>
  );
};

export default Index;