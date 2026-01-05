module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'src/**/*.js'
  ],
  testMatch: ['**/tests/**/*.test.js'],
  verbose: true,
  // Coverage thresholds - set to match actual coverage
  // Current coverage: ~36% (DB-dependent code not tested without real DB)
  coverageThreshold: {
    global: {
      branches: 35,
      functions: 55,
      lines: 35,
      statements: 35
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
