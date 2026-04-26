// @ts-check
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',
  timeout: 30000,
  expect: { timeout: 10000 },
  fullyParallel: false, // run tests sequentially so Chrome is easy to follow
  retries: 0,
  workers: 1,
  outputDir: 'test-artifacts',
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'always' }],
  ],
  use: {
    headless: false,
    channel: 'chrome',
    viewport: { width: 1280, height: 800 },
    screenshot: 'only-on-failure',
    video: 'off',
    actionTimeout: 10000,
  },
  projects: [
    {
      name: 'FairTerms API — Chrome',
      use: { ...devices['Desktop Chrome'], channel: 'chrome', headless: false },
    },
  ],
});
