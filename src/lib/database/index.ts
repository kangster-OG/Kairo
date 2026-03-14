import { createExpoSQLiteDatabaseClient } from '@/src/lib/database/clients/expo-sqlite-client';
import type { DatabaseClient } from '@/src/lib/database/client';
import { runMigrations } from '@/src/lib/database/migrations';
import {
  createAtlasRepositories,
  type AtlasRepositories,
} from '@/src/lib/database/repositories';
import { seedAtlasDevData } from '@/src/lib/database/seed';

let atlasDatabaseClientPromise: Promise<DatabaseClient> | null = null;
let atlasRepositoriesPromise: Promise<AtlasRepositories> | null = null;

export async function getAtlasDatabaseClient(): Promise<DatabaseClient> {
  if (!atlasDatabaseClientPromise) {
    atlasDatabaseClientPromise = (async () => {
      try {
        const client = await createExpoSQLiteDatabaseClient();
        await runMigrations(client);
        return client;
      } catch (error) {
        atlasDatabaseClientPromise = null;
        throw error;
      }
    })();
  }

  return atlasDatabaseClientPromise;
}

export async function getAtlasRepositories(): Promise<AtlasRepositories> {
  if (!atlasRepositoriesPromise) {
    atlasRepositoriesPromise = (async () => {
      try {
        const client = await getAtlasDatabaseClient();
        return createAtlasRepositories(client);
      } catch (error) {
        atlasRepositoriesPromise = null;
        throw error;
      }
    })();
  }

  return atlasRepositoriesPromise;
}

export async function seedAtlasDatabaseForDev(): Promise<void> {
  const repositories = await getAtlasRepositories();
  await seedAtlasDevData(repositories);
}

export * from '@/src/lib/database/client';
export * from '@/src/lib/database/mappers';
export * from '@/src/lib/database/migrations';
export * from '@/src/lib/database/repositories';
export * from '@/src/lib/database/schemas';
