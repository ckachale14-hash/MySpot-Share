/**
 * explore.js — Run this FIRST to map the CTR website structure.
 * Outputs the navigation, dropdown options, and any API endpoints so you
 * know how to configure the main scraper.
 *
 * Usage:  node explore.js
 */
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'https://aftermarket.ctr.co.kr';
const OUT_DIR = path.join(__dirname, 'output');

async function explore() {
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const context = await browser.newContext({
    userAgent:
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    viewport: { width: 1920, height: 1080 },
  });

  const page = await context.newPage();

  // Track all XHR/fetch calls so we can understand the API
  const networkRequests = [];
  page.on('request', (req) => {
    const url = req.url();
    if (
      !url.includes('.png') &&
      !url.includes('.jpg') &&
      !url.includes('.gif') &&
      !url.includes('.css') &&
      !url.includes('.woff') &&
      req.resourceType() !== 'image'
    ) {
      networkRequests.push({
        method: req.method(),
        url,
        resourceType: req.resourceType(),
        headers: req.headers(),
      });
    }
  });

  const networkResponses = [];
  page.on('response', async (res) => {
    const url = res.url();
    if (
      res.request().resourceType() === 'fetch' ||
      res.request().resourceType() === 'xhr'
    ) {
      try {
        const body = await res.text();
        networkResponses.push({ url, status: res.status(), body: body.substring(0, 2000) });
      } catch {
        networkResponses.push({ url, status: res.status(), body: '[could not read]' });
      }
    }
  });

  console.log('Opening:', BASE_URL + '/Main');
  await page.goto(BASE_URL + '/Main', { waitUntil: 'networkidle', timeout: 60000 });

  await page.screenshot({ path: path.join(OUT_DIR, 'main_page.png'), fullPage: true });
  console.log('Screenshot saved: output/main_page.png');

  const pageTitle = await page.title();
  console.log('Page title:', pageTitle);

  // ── Dump page structure ──────────────────────────────────────────────────
  const structure = await page.evaluate(() => {
    const navLinks = Array.from(
      document.querySelectorAll('nav a, .gnb a, .lnb a, .menu a, header a, #nav a')
    ).map((a) => ({ text: a.textContent.trim(), href: a.href })).filter((a) => a.text);

    const selects = Array.from(document.querySelectorAll('select')).map((s) => ({
      id: s.id,
      name: s.name,
      className: s.className,
      options: Array.from(s.options).map((o) => ({ value: o.value, text: o.text.trim() })),
    }));

    const inputs = Array.from(document.querySelectorAll('input')).map((i) => ({
      id: i.id,
      name: i.name,
      type: i.type,
      placeholder: i.placeholder,
      className: i.className,
    }));

    const forms = Array.from(document.querySelectorAll('form')).map((f) => ({
      id: f.id,
      action: f.action,
      method: f.method,
      className: f.className,
    }));

    const allLinks = Array.from(document.querySelectorAll('a[href]'))
      .map((a) => ({ text: a.textContent.trim().substring(0, 60), href: a.href }))
      .filter((a) => a.text)
      .slice(0, 100);

    const headings = Array.from(document.querySelectorAll('h1,h2,h3,h4'))
      .map((h) => h.textContent.trim())
      .filter(Boolean);

    const bodyHtml = document.body.innerHTML.substring(0, 8000);

    return { navLinks, selects, inputs, forms, allLinks, headings, bodyHtml };
  });

  fs.writeFileSync(
    path.join(OUT_DIR, 'page_structure.json'),
    JSON.stringify(structure, null, 2)
  );
  console.log('\nPage structure saved: output/page_structure.json');

  console.log('\n=== Navigation links ===');
  structure.navLinks.forEach((l) => console.log(` ${l.text.padEnd(30)} ${l.href}`));

  console.log('\n=== Select dropdowns ===');
  structure.selects.forEach((s) => {
    console.log(` id="${s.id}" name="${s.name}" — ${s.options.length} options`);
    s.options.slice(0, 12).forEach((o) => console.log(`   "${o.text}" = ${o.value}`));
  });

  console.log('\n=== Inputs ===');
  structure.inputs.forEach((i) =>
    console.log(` type=${i.type} id="${i.id}" name="${i.name}" placeholder="${i.placeholder}"`)
  );

  console.log('\n=== Forms ===');
  structure.forms.forEach((f) =>
    console.log(` id="${f.id}" action="${f.action}" method="${f.method}"`)
  );

  // ── Try clicking on a search/product link and record what happens ────────
  const productLinks = structure.allLinks.filter(
    (l) =>
      l.href.includes('search') ||
      l.href.includes('product') ||
      l.href.includes('part') ||
      l.href.includes('catalog') ||
      l.href.includes('item')
  );

  if (productLinks.length > 0) {
    console.log('\n=== Navigating to first product link:', productLinks[0].href);
    await page.goto(productLinks[0].href, { waitUntil: 'networkidle', timeout: 30000 });
    await page.screenshot({ path: path.join(OUT_DIR, 'product_page.png'), fullPage: true });

    const productStructure = await page.evaluate(() => {
      const images = Array.from(document.querySelectorAll('img')).map((i) => ({
        src: i.src,
        alt: i.alt,
      }));
      const tables = Array.from(document.querySelectorAll('table')).map((t) => ({
        rows: Array.from(t.rows)
          .slice(0, 5)
          .map((r) =>
            Array.from(r.cells)
              .map((c) => c.textContent.trim())
              .join(' | ')
          ),
      }));
      return { images: images.slice(0, 10), tables };
    });

    fs.writeFileSync(
      path.join(OUT_DIR, 'product_page_structure.json'),
      JSON.stringify(productStructure, null, 2)
    );
    console.log('Product page structure saved: output/product_page_structure.json');
  }

  // ── Save all network calls ───────────────────────────────────────────────
  fs.writeFileSync(
    path.join(OUT_DIR, 'network_requests.json'),
    JSON.stringify(networkRequests.slice(0, 200), null, 2)
  );
  fs.writeFileSync(
    path.join(OUT_DIR, 'network_responses.json'),
    JSON.stringify(networkResponses.slice(0, 50), null, 2)
  );
  console.log(
    `\nNetwork calls saved: ${networkRequests.length} requests, ${networkResponses.length} XHR responses`
  );

  await browser.close();
  console.log('\nExploration complete. Check the output/ folder.');
  console.log(
    'Review page_structure.json and network_requests.json, then run: node scraper.js'
  );
}

explore().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
