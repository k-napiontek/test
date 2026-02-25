import express, { Request, Response } from "express";
import { RedisClient } from "./redis";
import { register } from "./metrics";

export const setupOpsRouter = (redisClient: RedisClient): express.Express => {
  const app = express();

  app.get("/healthz/live", (req: Request, res: Response) => {
    res.status(200).json({ status: "alive" });
  });

  app.get("/healthz/ready", async (req: Request, res: Response) => {
    try {
      await redisClient.ping();
      res.status(200).json({ status: "ready" });
    } catch (err) {
      res.status(503).json({ status: "database_down" });
    }
  });

  app.get("/metrics", async (req: Request, res: Response) => {
    res.setHeader("Content-Type", register.contentType);
    const metrics = await register.metrics();
    res.send(metrics);
  });

  return app;
};