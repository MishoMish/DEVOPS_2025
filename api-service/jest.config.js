module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/index.js'
  ],
  testMatch: ['**/tests/**/*.test.js'],
  verbose: true,
  // Coverage thresholds - CI will fail if coverage drops below these values
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  // Test timeout
  testTimeout: 10000,
  // Clear mocks between tests
  clearMocks: true
};
