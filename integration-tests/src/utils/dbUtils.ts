import { Client } from 'pg';
import { MongoClient } from 'mongodb';
import { config } from '../config/environment';

export async function queryPostgres(query: string, params: any[] = []): Promise<any[]> {
  const client = new Client({
    connectionString: config.postgresqlAddress,
  });

  try {
    await client.connect();
    const result = await client.query(query, params);
    return result.rows;
  } catch (error) {
    console.error('Error querying PostgreSQL:', error);
    throw error;
  } finally {
    await client.end();
  }
}

export async function queryMongoDB(
  database: string,
  collection: string,
  query: object
): Promise<any[]> {
  const client = new MongoClient(config.mongodbAddress);
  
  try {
    await client.connect();
    const db = client.db(database);
    const result = await db.collection(collection).find(query).toArray();
    return result;
  } catch (error) {
    console.error('Error querying MongoDB:', error);
    throw error;
  } finally {
    await client.close();
  }
}