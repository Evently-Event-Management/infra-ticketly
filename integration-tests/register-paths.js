/* eslint-disable @typescript-eslint/no-var-requires */
const tsConfig = require('./tsconfig.json');
const tsConfigPaths = require('tsconfig-paths');

// This script ensures that the paths defined in tsconfig.json work at runtime
const baseUrl = './dist'; // This is the output directory
const cleanup = tsConfigPaths.register({
  baseUrl,
  paths: tsConfig.compilerOptions.paths || {},
});

// When the module is being unloaded, clean up the hooks
process.on('exit', cleanup);