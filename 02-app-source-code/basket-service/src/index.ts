import { createRedisClient } from "./redis";
import { setupApiRouter } from "./api";
import { setupOpsRouter } from "./ops";
import { logger } from "./logger";

const bootstrap = async () => {
  const redisUrl = process.env.REDIS_URL;

  if (!redisUrl) {
    logger.fatal("REDIS_URL environment variable is not set");
    process.exit(1);
  }

  try {
    const redisClient = await createRedisClient(redisUrl);
    logger.info("connected to redis");

    const apiApp = setupApiRouter(redisClient);
    const opsApp = setupOpsRouter(redisClient);

    const apiServer = apiApp.listen(8080, () => {
      logger.info({ port: 8080 }, "api server started");
    });

    const opsServer = opsApp.listen(9090, () => {
      logger.info({ port: 9090 }, "ops server started");
    });

    const shutdown = async (signal: string) => {
      logger.info({ signal }, "shutting down gracefully");

      apiServer.close(async () => {
        opsServer.close(async () => {
          await redisClient.quit();
          logger.info("server stopped cleanly");
          process.exit(0);
        });
      });

      setTimeout(() => {
        logger.fatal("forced shutdown due to timeout");
        process.exit(1);
      }, 10000).unref();
    };

    process.on("SIGTERM", () => shutdown("SIGTERM"));
    process.on("SIGINT", () => shutdown("SIGINT"));

  } catch (err) {
    logger.fatal({ err }, "failed to start application");
    process.exit(1);
  }
};

bootstrap();