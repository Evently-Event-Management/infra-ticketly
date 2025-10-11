import fs from 'fs';
import path from 'path';

export function readRequestFile(filePath: string): any {
  try {
    const fullPath = path.resolve(__dirname, '../../requests', filePath);
    const fileContent = fs.readFileSync(fullPath, 'utf8');
    return JSON.parse(fileContent);
  } catch (error) {
    console.error(`Error reading request file ${filePath}:`, error);
    throw error;
  }
}

export function updateRequestData(data: any, updates: Record<string, any>): any {
  const updatedData = { ...data };
  
  Object.entries(updates).forEach(([key, value]) => {
    const keys = key.split('.');
    let current = updatedData;
    
    for (let i = 0; i < keys.length - 1; i++) {
      if (!current[keys[i]]) {
        current[keys[i]] = {};
      }
      current = current[keys[i]];
    }
    
    current[keys[keys.length - 1]] = value;
  });
  
  return updatedData;
}