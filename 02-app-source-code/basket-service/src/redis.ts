import { createClient } from "redis";
import { logger } from "./logger";

export type RedisClient = ReturnType<typeof createClient>;

export const createRedisClient = async (url: string): Promise<RedisClient> => {
  const client = createClient({ url });

  client.on("error", (err) => {
    logger.error({ err }, "redis client connection error");
  });

  await client.connect();
  
  await client.ping();

  return client;
};