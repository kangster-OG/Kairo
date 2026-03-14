module.exports = {
  preset: 'jest-expo',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.ts'],
  testMatch: ['**/__tests__/**/*.test.(ts|tsx)'],
  modulePathIgnorePatterns: ['<rootDir>/atlas-ios/'],
  testPathIgnorePatterns: ['/node_modules/', '<rootDir>/atlas-ios/'],
  watchPathIgnorePatterns: ['<rootDir>/atlas-ios/'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
  },
  transformIgnorePatterns: [
    'node_modules/(?!(react-native|@react-native|expo(nent)?|@expo(nent)?/.*|expo-router|expo-modules-core|@expo/.*|@unimodules/.*|unimodules|sentry-expo|native-base|react-native-svg)/)'
  ],
};
