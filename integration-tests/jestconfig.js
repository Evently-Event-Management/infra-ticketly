module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testTimeout: 30000, // Increased timeout for slow integration tests
  testMatch: ['**/*.test.ts'],
  rootDir: './src',
  verbose: true,
  bail: true, // Stop after first test failure
  moduleNameMapper: {
    '^src/(.*)$': '<rootDir>/$1'
  },
  transform: {
    '^.+\\.tsx?$': ['ts-jest', {
      tsconfig: './tsconfig.json'
    }]
  },
  setupFilesAfterEnv: ['../jest.setup.js']
};