// @ts-nocheck
/**
 * FairTerms Backend API — Playwright Test Suite
 *
 * Runs in headed Chrome. The Express server starts ONCE in full-mock mode:
 *   NODE_ENV=development
 *   USE_MOCK_FIRESTORE=true
 *   USE_MOCK_FAIRNESS_DATA=true
 *   USE_MOCK_GEMINI=true
 *
 * Auth: the server accepts the literal string "mock-token" as a valid
 *       Bearer token when NODE_ENV=development.
 */

const { test, expect } = require('@playwright/test');
const { spawn } = require('child_process');
const http = require('http');
const path = require('path');

const PORT = 8099;
const BASE = `http://localhost:${PORT}`;
const MOCK_TOKEN = 'mock-token';
const AUTH = { Authorization: `Bearer ${MOCK_TOKEN}` };

// ─── Server polling helper ───────────────────────────────────────────────────

async function waitForServer(url, timeoutMs = 15000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const ok = await new Promise((resolve) => {
      const req = http.get(url, (res) => { resolve(res.statusCode === 200); });
      req.on('error', () => resolve(false));
      req.setTimeout(1000, () => { req.destroy(); resolve(false); });
    });
    if (ok) return;
    await new Promise((r) => setTimeout(r, 400));
  }
  throw new Error(`Server at ${url} did not become ready within ${timeoutMs}ms`);
}

// ─── Visual card helpers ─────────────────────────────────────────────────────

async function showSection(page, title) {
  await page.evaluate((title) => {
    const container = document.getElementById('ft-results');
    if (!container) return;
    const h = document.createElement('h2');
    h.textContent = title;
    h.style.cssText =
      'color:#ccc;font-size:13px;font-weight:700;text-transform:uppercase;' +
      'letter-spacing:.08em;margin:22px 0 8px;border-top:1px solid #2a2a2a;padding-top:18px';
    container.appendChild(h);
  }, title);
}

async function showResult(page, label, passed, detail = '') {
  const colour = passed ? '#34A853' : '#EA4335';
  const icon = passed ? '✅' : '❌';
  await page.evaluate(
    ({ label, icon, colour, detail }) => {
      let container = document.getElementById('ft-results');
      if (!container) {
        document.body.style.cssText =
          'margin:0;font-family:system-ui,sans-serif;background:#0f0f0f;color:#eee;padding:24px 32px';
        const h1 = document.createElement('h1');
        h1.textContent = '🧪 FairTerms — API Test Suite';
        h1.style.cssText = 'color:#fff;margin:0 0 4px;font-size:24px';
        const sub = document.createElement('p');
        sub.textContent = 'Headed Chrome · Node.js mock mode · No cloud credentials needed';
        sub.style.cssText = 'color:#666;margin:0 0 24px;font-size:13px';
        document.body.prepend(sub);
        document.body.prepend(h1);
        container = document.createElement('div');
        container.id = 'ft-results';
        container.style.cssText = 'max-width:900px';
        document.body.appendChild(container);
      }
      const card = document.createElement('div');
      card.style.cssText = [
        'display:flex;align-items:flex-start;gap:12px',
        `background:#1a1a1a;border-left:4px solid ${colour}`,
        'border-radius:6px;padding:12px 16px;margin-bottom:8px',
      ].join(';');
      card.innerHTML =
        `<span style="font-size:17px;line-height:1.3">${icon}</span>` +
        `<div><div style="font-weight:600;font-size:14px">${label}</div>` +
        (detail
          ? `<div style="color:#888;font-size:12px;margin-top:3px;word-break:break-all">${detail}</div>`
          : '') +
        '</div>';
      container.appendChild(card);
      card.scrollIntoView({ behavior: 'smooth', block: 'end' });
    },
    { label, icon, colour, detail },
  );
  await page.waitForTimeout(300);
}

// ─── Test suite (serial — server starts once for all tests) ──────────────────

/** @type {import('child_process').ChildProcess} */
let server;
/** @type {string} */ let profileId = '';
/** @type {string} */ let analysisId = '';

test.describe.serial('FairTerms API', () => {
  test.beforeAll(async () => {
    server = spawn('node', ['src/index.js'], {
      cwd: path.join(__dirname, '..'),
      env: {
        ...process.env,
        PORT: String(PORT),
        NODE_ENV: 'development',
        ALLOW_MOCK_AUTH: 'true',
        USE_MOCK_FIRESTORE: 'true',
        USE_MOCK_FAIRNESS_DATA: 'true',
        USE_MOCK_GEMINI: 'true',
      },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    server.stdout?.on('data', (d) => process.stdout.write(`[server] ${d}`));
    server.stderr?.on('data', (d) => process.stderr.write(`[server] ${d}`));
    server.on('error', (err) => { throw err; });
    await waitForServer(`${BASE}/api/v1/health`);
  });

  test.afterAll(async () => {
    if (server) server.kill('SIGTERM');
  });

  // ── A. HEALTH ──────────────────────────────────────────────────────────────

  test('A1 — Health endpoint returns OK', async ({ page, request }) => {
    await page.goto('about:blank');
    const res = await request.get(`${BASE}/api/v1/health`);
    const body = await res.json();
    const passed = res.status() === 200 && body?.data?.status === 'OK';
    await showSection(page, 'A — Health');
    await showResult(page, 'A1 · GET /health → 200 OK', passed, JSON.stringify(body));
    expect(res.status()).toBe(200);
    expect(body.data.status).toBe('OK');
  });

  // ── B. AUTH ────────────────────────────────────────────────────────────────

  test('B1 — No token → 401', async ({ page, request }) => {
    const res = await request.get(`${BASE}/api/v1/analysis/history`);
    const passed = res.status() === 401;
    await showSection(page, 'B — Auth');
    await showResult(page, 'B1 · No Bearer token → 401', passed, `HTTP ${res.status()}`);
    expect(res.status()).toBe(401);
  });

  test('B2 — Bad token → 401', async ({ page, request }) => {
    const res = await request.get(`${BASE}/api/v1/analysis/history`, {
      headers: { Authorization: 'Bearer invalid-token-xyz' },
    });
    const passed = res.status() === 401;
    await showResult(page, 'B2 · Invalid token → 401', passed, `HTTP ${res.status()}`);
    expect(res.status()).toBe(401);
  });

  test('B3 — Mock token (dev mode) → 200', async ({ page, request }) => {
    const res = await request.get(`${BASE}/api/v1/analysis/history`, { headers: AUTH });
    const passed = res.status() === 200;
    await showResult(page, 'B3 · mock-token → 200', passed, `HTTP ${res.status()}`);
    expect(res.status()).toBe(200);
  });

  // ── C. SME PROFILE ─────────────────────────────────────────────────────────

  test('C1 — Create SME profile → 201 + profile_id', async ({ page, request }) => {
    const res = await request.post(`${BASE}/api/v1/sme/profile`, {
      headers: AUTH,
      data: {
        business_name: 'Barasat Textiles',
        owner_name: 'Ramesh Kumar',
        city: 'Barasat',
        pincode: '743201',
        state: 'West Bengal',
        industry: 'Textiles',
        annual_revenue_inr: 5000000,
        employee_count: 12,
        years_in_operation: 8,
      },
    });
    const body = await res.json();
    const passed = res.status() === 201 && !!body?.data?.profile_id;
    profileId = body?.data?.profile_id || '';
    await showSection(page, 'C — SME Profile');
    await showResult(page, 'C1 · POST /sme/profile → 201 + profile_id', passed,
      `profile_id: ${profileId}`);
    expect(res.status()).toBe(201);
    expect(body.data.profile_id).toBeTruthy();
  });

  test('C2 — Get profile by ID → 200', async ({ page, request }) => {
    const res = await request.get(`${BASE}/api/v1/sme/profile/${profileId}`, { headers: AUTH });
    const body = await res.json();
    const passed = res.status() === 200 && body?.data?.profile_id === profileId;
    await showResult(page, 'C2 · GET /sme/profile/:id → 200', passed,
      `business_name: ${body?.data?.business_name}`);
    expect(res.status()).toBe(200);
    expect(body.data.profile_id).toBe(profileId);
  });

  test('C3 — Missing business_name → 400 INVALID_INPUT', async ({ page, request }) => {
    const res = await request.post(`${BASE}/api/v1/sme/profile`, {
      headers: AUTH,
      data: {
        owner_name: 'No Name',
        pincode: '743201',
        state: 'West Bengal',
        industry: 'Textiles',
        annual_revenue_inr: 100000,
        employee_count: 5,
        years_in_operation: 2,
      },
    });
    const body = await res.json();
    const passed = res.status() === 400 && body?.error === 'INVALID_INPUT';
    await showResult(page, 'C3 · Missing business_name → 400', passed, body?.message);
    expect(res.status()).toBe(400);
    expect(body.error).toBe('INVALID_INPUT');
  });

  test('C4 — Invalid GST format → 400', async ({ page, request }) => {
    const res = await request.post(`${BASE}/api/v1/sme/profile`, {
      headers: AUTH,
      data: {
        business_name: 'GST Test Co',
        owner_name: 'Test Owner',
        pincode: '743201',
        state: 'West Bengal',
        industry: 'Textiles',
        annual_revenue_inr: 1000000,
        employee_count: 5,
        years_in_operation: 3,
        gst_number: 'INVALID123',
      },
    });
    const body = await res.json();
    const passed = res.status() === 400;
    await showResult(page, 'C4 · Bad GST format → 400', passed, body?.message);
    expect(res.status()).toBe(400);
  });

  // ── D. ANALYSIS PIPELINE ───────────────────────────────────────────────────

  test('D1 — Run analysis → 202 + analysis_id', async ({ page, request }) => {
    const res = await request.post(`${BASE}/api/v1/analysis/run`, {
      headers: AUTH,
      data: {
        profile_id: profileId,
        buyer_name: 'Reliance Retail Ltd',
        buyer_type: 'Retail',
        buyer_address: '222 Nariman Point, Mumbai',
        payment_terms_days: 90,
        order_value_inr: 250000,
      },
    });
    const body = await res.json();
    const passed = res.status() === 202 && !!body?.data?.analysis_id;
    analysisId = body?.data?.analysis_id || '';
    await showSection(page, 'D — Analysis Pipeline');
    await showResult(page, 'D1 · POST /analysis/run → 202 processing', passed,
      `analysis_id: ${analysisId}`);
    expect(res.status()).toBe(202);
    expect(body.data.status).toBe('processing');
  });

  test('D2 — Poll analysis status', async ({ page, request }) => {
    // Give the background pipeline time to complete (all mock = instant)
    await page.waitForTimeout(2000);
    const res = await request.get(`${BASE}/api/v1/analysis/${analysisId}/status`, { headers: AUTH });
    const body = await res.json();
    const status = body?.data?.status;
    const passed = res.status() === 200 && !!status;
    await showResult(page, `D2 · GET /analysis/:id/status → ${status}`, passed,
      `analysis_id: ${analysisId}`);
    expect(res.status()).toBe(200);
    expect(['completed', 'processing', 'failed']).toContain(status);
  });

  test('D3 — Report has interest_calculation + tax_alert', async ({ page, request }) => {
    // Poll until completed (mock pipeline is near-instant)
    let body;
    for (let i = 0; i < 10; i++) {
      await page.waitForTimeout(1000);
      const res = await request.get(`${BASE}/api/v1/analysis/${analysisId}/report`, { headers: AUTH });
      body = await res.json();
      if (body?.data?.overall_fairness_score !== undefined) break;
    }
    const data = body?.data || {};
    const allGood = data.interest_calculation !== null && data.interest_calculation !== undefined
      && data.tax_alert !== null && data.tax_alert !== undefined
      && typeof data.overall_fairness_score === 'number';

    await showResult(page,
      'D3 · Report has interest_calculation + tax_alert',
      allGood,
      `score: ${data.overall_fairness_score} | interest: ₹${data.interest_calculation?.compound_interest_inr} | tax_lost: ₹${data.tax_alert?.tax_deduction_lost_inr}`,
    );
    expect(typeof data.overall_fairness_score).toBe('number');
    expect(data.interest_calculation).not.toBeNull();
    expect(data.tax_alert).not.toBeNull();
    expect(data.interest_calculation.daily_accrual_inr).toBeGreaterThan(0);
    expect(data.tax_alert.tax_deduction_lost_inr).toBeGreaterThan(0);
  });

  test('D4 — Analysis missing buyer_name → 400', async ({ page, request }) => {
    const res = await request.post(`${BASE}/api/v1/analysis/run`, {
      headers: AUTH,
      data: { profile_id: profileId, payment_terms_days: 60, order_value_inr: 100000 },
    });
    const body = await res.json();
    await showResult(page, 'D4 · Missing buyer_name → 400', res.status() === 400, body?.message);
    expect(res.status()).toBe(400);
  });

  test('D5 — Analysis history returns array', async ({ page, request }) => {
    const res = await request.get(`${BASE}/api/v1/analysis/history`, { headers: AUTH });
    const body = await res.json();
    const passed = res.status() === 200 && Array.isArray(body?.data);
    await showResult(page, 'D5 · GET /analysis/history → array', passed,
      `${body?.data?.length ?? 0} records`);
    expect(res.status()).toBe(200);
    expect(Array.isArray(body.data)).toBe(true);
  });

  // ── E. INTEREST & TAX LOGIC (unit) ─────────────────────────────────────────

  test('E1 — Interest: Net 90 ₹2.5L → delay 45 days, rate 19.5%', async ({ page }) => {
    const { buildInterestCalculation } = require('../src/services/report-enrichment.service');
    const r = buildInterestCalculation({ payment_terms_days: 90, order_value_inr: 250000 });
    const passed = r?.delay_days === 45 && r?.applicable_rate === 19.5 && r?.compound_interest_inr > 0;
    await showSection(page, 'E — Stage-2 Math (unit)');
    await showResult(page, 'E1 · Interest Net 90, ₹2.5L: delay=45d, rate=19.5%', passed,
      `₹${r?.compound_interest_inr} interest | ₹${r?.daily_accrual_inr}/day | total ₹${r?.total_owed_inr}`);
    expect(r.delay_days).toBe(45);
    expect(r.applicable_rate).toBe(19.5);
    expect(r.compound_interest_inr).toBeGreaterThan(0);
    expect(r.total_owed_inr).toBe(r.principal_inr + r.compound_interest_inr);
  });

  test('E2 — Interest: Net 45 → 0 delay, 0 interest', async ({ page }) => {
    const { buildInterestCalculation } = require('../src/services/report-enrichment.service');
    const r = buildInterestCalculation({ payment_terms_days: 45, order_value_inr: 250000 });
    await showResult(page, 'E2 · Interest Net 45 → 0 delay, 0 interest',
      r?.delay_days === 0 && r?.compound_interest_inr === 0,
      `delay_days: ${r?.delay_days}`);
    expect(r.delay_days).toBe(0);
    expect(r.compound_interest_inr).toBe(0);
  });

  test('E3 — Interest: zero order_value → null', async ({ page }) => {
    const { buildInterestCalculation } = require('../src/services/report-enrichment.service');
    const r = buildInterestCalculation({ payment_terms_days: 90, order_value_inr: 0 });
    await showResult(page, 'E3 · Interest zero order_value → null', r === null, 'returns null');
    expect(r).toBeNull();
  });

  test('E4 — Tax alert: Net 90 ₹2.5L → ₹62,500 lost', async ({ page }) => {
    const { buildTaxAlert } = require('../src/services/report-enrichment.service');
    const r = buildTaxAlert({ payment_terms_days: 90, order_value_inr: 250000 });
    const expected = Math.round(250000 * 0.25);
    const passed = r?.tax_deduction_lost_inr === expected && r?.non_deductible_amount_inr === 250000;
    await showResult(page, `E4 · Tax alert: ₹${expected.toLocaleString('en-IN')} lost`, passed,
      `section: ${r?.section}`);
    expect(r.tax_deduction_lost_inr).toBe(expected);
    expect(r.section).toBe('43B(h) Income Tax Act');
  });

  test('E5 — Tax alert: Net 45 → ₹0 lost deduction', async ({ page }) => {
    const { buildTaxAlert } = require('../src/services/report-enrichment.service');
    const r = buildTaxAlert({ payment_terms_days: 45, order_value_inr: 250000 });
    await showResult(page, 'E5 · Tax alert Net 45 → ₹0 lost (within window)',
      r?.tax_deduction_lost_inr === 0, `tax_lost: ₹${r?.tax_deduction_lost_inr}`);
    expect(r.tax_deduction_lost_inr).toBe(0);
  });

  // ── F. HEATMAP ─────────────────────────────────────────────────────────────

  test('F1 — GET /heatmap/national → states with bias_level', async ({ page, request }) => {
    const res = await request.get(`${BASE}/api/v1/heatmap/national`, { headers: AUTH });
    const body = await res.json();
    const data = body?.data;
    const passed = res.status() === 200 && Array.isArray(data?.states) && data.states.length > 0;
    await showSection(page, 'F — Heatmap');
    await showResult(page, 'F1 · GET /heatmap/national → states[]', passed,
      `${data?.states?.length} states | last_updated: ${data?.last_updated}`);
    expect(res.status()).toBe(200);
    expect(data.states[0]).toHaveProperty('bias_level');
    expect(data.states[0]).toHaveProperty('state_code');
  });

  test('F2 — Heatmap industry filter echoed back', async ({ page, request }) => {
    const res = await request.get(`${BASE}/api/v1/heatmap/national?industry=Textiles`, { headers: AUTH });
    const body = await res.json();
    const passed = res.status() === 200 && body?.data?.industry_filter === 'Textiles';
    await showResult(page, 'F2 · ?industry=Textiles → filter echoed', passed,
      `industry_filter: ${body?.data?.industry_filter}`);
    expect(body.data.industry_filter).toBe('Textiles');
  });

  test('F3 — Heatmap no auth → 401', async ({ page, request }) => {
    const res = await request.get(`${BASE}/api/v1/heatmap/national`);
    await showResult(page, 'F3 · /heatmap without auth → 401', res.status() === 401,
      `HTTP ${res.status()}`);
    expect(res.status()).toBe(401);
  });

  // ── G. LEADERBOARD ─────────────────────────────────────────────────────────

  test('G1 — GET /leaderboard → buyers with badge', async ({ page, request }) => {
    const res = await request.get(`${BASE}/api/v1/leaderboard`, { headers: AUTH });
    const body = await res.json();
    const data = body?.data;
    const passed = res.status() === 200 && Array.isArray(data?.buyers) && data.buyers.length > 0;
    await showSection(page, 'G — Leaderboard');
    await showResult(page, 'G1 · GET /leaderboard → buyers[]', passed,
      `top: ${data?.buyers?.[0]?.buyer_name} (${data?.buyers?.[0]?.badge})`);
    expect(res.status()).toBe(200);
    expect(['gold', 'silver', 'bronze', 'red_flag']).toContain(data.buyers[0].badge);
  });

  test('G2 — Leaderboard with sort/order/limit params', async ({ page, request }) => {
    const res = await request.get(
      `${BASE}/api/v1/leaderboard?sort=fairness_score&order=asc&limit=10`, { headers: AUTH });
    const body = await res.json();
    const passed = res.status() === 200 && Array.isArray(body?.data?.buyers);
    await showResult(page, 'G2 · ?sort=fairness_score&order=asc&limit=10 → 200', passed,
      `buyers: ${body?.data?.buyers?.length}`);
    expect(res.status()).toBe(200);
  });

  test('G3 — Leaderboard invalid sort field → 400', async ({ page, request }) => {
    const res = await request.get(`${BASE}/api/v1/leaderboard?sort=invalid_field`, { headers: AUTH });
    await showResult(page, 'G3 · ?sort=invalid_field → 400', res.status() === 400,
      `HTTP ${res.status()}`);
    expect(res.status()).toBe(400);
  });

  test('G4 — Leaderboard limit > 100 → 400', async ({ page, request }) => {
    const res = await request.get(`${BASE}/api/v1/leaderboard?limit=999`, { headers: AUTH });
    await showResult(page, 'G4 · ?limit=999 → 400', res.status() === 400,
      `HTTP ${res.status()}`);
    expect(res.status()).toBe(400);
  });

  // ── H. BENCHMARK ───────────────────────────────────────────────────────────

  test('H1 — POST /benchmark/compare → 200', async ({ page, request }) => {
    const res = await request.post(`${BASE}/api/v1/benchmark/compare`, {
      headers: AUTH,
      data: {
        industry: 'Textiles',
        state: 'West Bengal',
        payment_terms_days: 90,
        annual_revenue_min: 1000000,
        annual_revenue_max: 10000000,
      },
    });
    const body = await res.json();
    const passed = res.status() === 200 && body?.success === true;
    await showSection(page, 'H — Benchmark');
    await showResult(page, 'H1 · POST /benchmark/compare → 200', passed,
      JSON.stringify(body?.data).slice(0, 120));
    expect(res.status()).toBe(200);
    expect(body.success).toBe(true);
  });

  test('H2 — Benchmark missing industry → 400', async ({ page, request }) => {
    const res = await request.post(`${BASE}/api/v1/benchmark/compare`, {
      headers: AUTH,
      data: { payment_terms_days: 60 },
    });
    const passed = res.status() === 400;
    await showResult(page, 'H2 · Missing industry → 400', passed, `HTTP ${res.status()}`);
    expect(res.status()).toBe(400);
  });

  // ── SUMMARY ────────────────────────────────────────────────────────────────

  test('Summary — final score banner', async ({ page }) => {
    await page.evaluate(() => {
      const container = document.getElementById('ft-results');
      if (!container) return;
      const allCards = container.querySelectorAll('div[style*="border-left"]');
      const passCount = container.querySelectorAll('span').length;
      const banner = document.createElement('div');
      banner.style.cssText =
        'margin-top:28px;background:#1e2a1e;border:1px solid #34A853;' +
        'border-radius:8px;padding:20px 24px;';
      banner.innerHTML =
        '<div style="font-size:20px;font-weight:700;color:#34A853;margin-bottom:6px">' +
        '🎯 Test run complete — FairTerms API</div>' +
        '<div style="color:#aaa;font-size:13px;line-height:1.7">' +
        '✔ All endpoints tested with real Express server (mock cloud, real routing)<br>' +
        '✔ Auth, validation, analysis pipeline, Stage-2 math, heatmap, leaderboard, benchmark' +
        '</div>';
      container.appendChild(banner);
    });
    await page.waitForTimeout(4000);
  });
});
