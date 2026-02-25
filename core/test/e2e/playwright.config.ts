import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: '.',
  testIgnore: ['**/load/**'],  // Exclude load tests by default
  timeout: 30000,  // 30s max per test - fail fast
  globalSetup: './global-setup.ts',
  use: {
    baseURL: process.env.E2E_BASE_URL || 'https://eyra-next-test1.fly.dev',
    viewport: { width: 1280, height: 720 },
    video: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
});
