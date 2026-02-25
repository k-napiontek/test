import { Activity, ArrowUpRight, ArrowDownRight } from "lucide-react";

interface ServiceCardProps {
  name: string;
  language: string;
  requests: number;
  status: "healthy" | "degraded" | "down";
  trend: number; // percentage change
  uptime: string;
}

const statusConfig = {
  healthy: { label: "Healthy", dotClass: "bg-primary" },
  degraded: { label: "Degraded", dotClass: "bg-warning" },
  down: { label: "Down", dotClass: "bg-destructive" },
};

const langColors: Record<string, string> = {
  Go: "text-info",
  Python: "text-warning",
  "Node.js": "text-primary",
  Rust: "text-destructive",
};

const ServiceCard = ({ name, language, requests, status, trend, uptime }: ServiceCardProps) => {
  const { label, dotClass } = statusConfig[status];
  const isPositive = trend >= 0;

  return (
    <div className="group rounded-xl border border-border bg-card p-6 transition-all duration-300 hover:border-primary/30 hover:shadow-[0_0_30px_-10px_hsl(var(--primary)/0.15)]">
      {/* Header */}
      <div className="flex items-start justify-between mb-6">
        <div>
          <h3 className="text-lg font-semibold text-card-foreground font-mono">{name}</h3>
          <span className={`text-sm font-mono ${langColors[language] || "text-muted-foreground"}`}>
            {language}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <span className={`h-2 w-2 rounded-full ${dotClass} animate-pulse`} />
          <span className="text-xs text-muted-foreground">{label}</span>
        </div>
      </div>

      {/* Requests */}
      <div className="mb-4">
        <p className="text-xs uppercase tracking-wider text-muted-foreground mb-1">Requests / 24h</p>
        <div className="flex items-end gap-3">
          <span className="text-3xl font-bold font-mono text-card-foreground tabular-nums">
            {requests.toLocaleString()}
          </span>
          <div className={`flex items-center gap-0.5 text-sm font-mono ${isPositive ? "text-primary" : "text-destructive"}`}>
            {isPositive ? <ArrowUpRight size={14} /> : <ArrowDownRight size={14} />}
            {Math.abs(trend)}%
          </div>
        </div>
      </div>

      {/* Mini bar chart */}
      <div className="flex items-end gap-0.5 h-8 mb-4">
        {Array.from({ length: 24 }, (_, i) => {
          const h = 20 + Math.random() * 80;
          return (
            <div
              key={i}
              className="flex-1 rounded-sm bg-primary/20 group-hover:bg-primary/30 transition-colors"
              style={{ height: `${h}%` }}
            />
          );
        })}
      </div>

      {/* Footer */}
      <div className="flex items-center justify-between pt-4 border-t border-border">
        <div className="flex items-center gap-1.5 text-muted-foreground">
          <Activity size={12} />
          <span className="text-xs font-mono">Uptime {uptime}</span>
        </div>
      </div>
    </div>
  );
};

export default ServiceCard;