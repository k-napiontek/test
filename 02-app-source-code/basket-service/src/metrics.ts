import { Registry, collectDefaultMetrics, Counter } from "prom-client";
import { Request, Response, NextFunction } from "express";

export const register = new Registry();

collectDefaultMetrics({ register });

export const httpRequestsTotal = new Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "path", "status"],
  registers: [register],
});

export const metricsMiddleware = (req: Request, res: Response, next: NextFunction) => {
  res.on("finish", () => {
    httpRequestsTotal.inc({
      method: req.method,
      path: req.route ? req.route.path : req.path,
      status: res.statusCode,
    });
  });
  next();
};