import { Client } from 'pg';
import { MongoClient, Document } from 'mongodb';
import { createClient as createRedisClient, RedisClientType } from 'redis';
import { config } from '../config/environment';

// --- PostgreSQL Functions ---
async function queryPostgres(connectionString: string, query: string, params: any[] = []): Promise<any[]> {
  const client = new Client({ connectionString });
  try {
    await client.connect();
    const result = await client.query(query, params);
    return result.rows;
  } finally {
    await client.end();
  }
}

export function queryEventDB(query: string, params: any[] = []): Promise<any[]> {
  return queryPostgres(config.postgresEventDbUrl, query, params);
}

export function queryOrderDB(query: string, params: any[] = []): Promise<any[]> {
  return queryPostgres(config.postgresOrderDbUrl, query, params);
}

// --- MongoDB Function ---
export async function queryMongoDB(database: string, collection: string, query: object): Promise<Document[]> {
    const client = new MongoClient(config.mongodbAddress);
    try {
        await client.connect();
        const db = client.db(database);
        return await db.collection(collection).find(query).toArray();
    } finally {
        await client.close();
    }
}

// --- Redis Function ---
export async function checkRedisKey(key: string): Promise<number> {
    const client: RedisClientType = createRedisClient({ url: config.redisAddress });
    await client.connect();
    try {
        const exists = await client.exists(key);
        return exists;
    } finally {
        await client.disconnect();
    }
}