module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'src/**/*.js'
  ],
  testMatch: ['**/tests/**/*.test.js'],
  verbose: true,
  // Coverage thresholds - CI will fail if coverage drops below these values
  coverageThreshold: {
    global: {
      branches: 50,
      functions: 50,
      lines: 50,
      statements: 50
    }
  },
  // Test timeout
  testTimeout: 10000,
  // Clear mocks between tests
  clearMocks: true,
  // Force exit after tests complete (handles unclosed connections)
  forceExit: true,
  // Detect open handles
  detectOpenHandles: true
};
