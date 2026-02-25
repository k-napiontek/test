import express, { Request, Response } from "express";
import { RedisClient } from "./redis";
import { metricsMiddleware } from "./metrics";
import { logger } from "./logger";

export const setupApiRouter = (redisClient: RedisClient): express.Express => {
  const app = express();
  app.use(express.json());
  app.use(metricsMiddleware);

  app.post("/basket/:userId", async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;
      const { items } = req.body;

      if (!items || !Array.isArray(items)) {
        res.status(400).json({ error: "invalid items format" });
        return;
      }

      const basketData = JSON.stringify(items);
      await redisClient.set(`basket:${userId}`, basketData, { EX: 3600 });

      res.status(200).json({ status: "basket_updated" });
    } catch (err) {
      logger.error({ err }, "failed to update basket");
      res.status(500).json({ error: "internal_server_error" });
    }
  });

  app.get("/basket/:userId", async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;
      const data = await redisClient.get(`basket:${userId}`);

      if (!data) {
        res.status(404).json({ error: "basket_not_found" });
        return;
      }

      res.status(200).json({ items: JSON.parse(data) });
    } catch (err) {
      logger.error({ err }, "failed to fetch basket");
      res.status(500).json({ error: "internal_server_error" });
    }
  });

  return app;
};