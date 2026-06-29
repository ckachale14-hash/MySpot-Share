/**
 * explore.js — Probe the CTR aftermarket catalog structure before a full scrape.
 *
 * 1. Opens a real SearchList URL for a known vehicle (KIA Sportage 2010)
 *    — this URL is confirmed to exist from Google's index
 * 2. Dumps the page structure (HTML, selectors, pagination)
 * 3. Opens the first SearchDetail result and dumps part data
 * 4. Saves screenshots + JSON in output/
 *
 * Run this before the main scraper to verify selectors work in the current
 * version of the CTR site.
 *
 * Usage:  node explore.js
 *         node explore.js --url "https://aftermarket.ctr.co.kr/Catalogue/SearchList?..."
 */

'use strict';

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, 'output');
fs.mkdirSync(OUT, { recursive: true });

// Known-good URLs from Google's index — used as probe targets
const PROBE_URLS = [
  // KIA Sportage 2010 suspension (confirmed indexed)
  'https://aftermarket.ctr.co.kr/Catalogue/SearchList?location=KR&searchLocation=global&brand=KIA&model=Sportage&modelDtl=SL&year2=2010',
  // Honda CR-V suspension (confirmed indexed)
  'https://aftermarket.ctr.co.kr/Catalogue/searchList?searchLocation=global&location=JP&brand=HONDA&groups=SUSPENSION&model=CR-V',
  // Toyota Corolla (confirmed indexed)
  'https://aftermarket.ctr.co.kr/Catalogue/SearchList?location=RU&searchLocation=global&brand=TOYOTA&model=Corolla',
  // Zimbabwe-relevant: Toyota Hilux JP
  'https://aftermarket.ctr.co.kr/Catalogue/SearchList?location=JP&searchLocation=global&brand=TOYOTA&model=Hilux&groups=SUSPENSION',
  // Toyota Vitz
  'https://aftermarket.ctr.co.kr/Catalogue/SearchList?location=JP&searchLocation=global&brand=TOYOTA&model=Vitz&groups=SUSPENSION',
  // Honda Fit
  'https://aftermarket.ctr.co.kr/Catalogue/SearchList?location=JP&searchLocation=global&brand=HONDA&model=Fit&groups=SUSPENSION',
];

const customUrl = (() => {
  const i = process.argv.indexOf('--url');
  return i !== -1 ? process.argv[i + 1] : null;
})();

async function probePage(page, url, label) {
  console.log(`\n=== Probing: ${label} ===`);
  console.log(`URL: ${url}`);

  const networkXhr = [];
  page.on('response', async (res) => {
    if (['fetch', 'xhr'].includes(res.request().resourceType())) {
      try {
        const body = await res.text();
        networkXhr.push({ url: res.url(), status: res.status(), body: body.substring(0, 500) });
      } catch {}
    }
  });

  await page.goto(url, { waitUntil: 'networkidle', timeout: 45000 });
  const title = await page.title();
  console.log('Title:', title);
  console.log('Final URL:', page.url());

  const slug = label.replace(/[^a-z0-9]+/gi, '_').toLowerCase();
  await page.screenshot({ path: path.join(OUT, `${slug}.png`), fullPage: true });

  const structure = await page.evaluate(() => {
    // Find all result rows / cards
    const rowSelectors = [
      'table.list tbody tr', '.result-list tr', 'tr[onclick]', 'tr[data-oe-id]',
      '.item-row', '.product-row', 'li.item', '.list-item', '.product-item', '.part-item',
    ];
    let rows = [];
    let usedSelector = '';
    for (const sel of rowSelectors) {
      const found = document.querySelectorAll(sel);
      if (found.length > 0) { rows = Array.from(found); usedSelector = sel; break; }
    }

    // Find detail links
    const detailLinks = Array.from(
      document.querySelectorAll('a[href*="SearchDetail"], a[href*="searchDetail"]')
    ).map((a) => a.href).slice(0, 5);

    // Find pagination
    const paginationEl = document.querySelector('.pagination, .paging, [class*="paging"]');
    const pageLinks = paginationEl
      ? Array.from(paginationEl.querySelectorAll('a, button')).map((el) => el.textContent.trim())
      : [];

    // Find selects
    const selects = Array.from(document.querySelectorAll('select')).map((s) => ({
      id: s.id, name: s.name, optionCount: s.options.length,
      options: Array.from(s.options).slice(0, 20).map((o) => ({ value: o.value, text: o.text.trim() })),
    }));

    // Sample first row cells
    const sampleRow = rows[0];
    const sampleCells = sampleRow
      ? Array.from(sampleRow.querySelectorAll('td, th')).map((c) => ({
          text: c.textContent.trim(),
          className: c.className,
          innerHTML: c.innerHTML.substring(0, 200),
        }))
      : [];

    // All class names used (for selector discovery)
    const allClasses = new Set();
    document.querySelectorAll('[class]').forEach((el) => {
      el.className.split(/\s+/).forEach((c) => c && allClasses.add(c));
    });

    return {
      title: document.title,
      url: location.href,
      rowCount: rows.length,
      usedSelector,
      detailLinks,
      pageLinks,
      selects,
      sampleCells,
      bodyHtmlSnippet: document.body.innerHTML.substring(0, 5000),
      classNames: Array.from(allClasses).filter((c) => c.length > 2).sort().slice(0, 100),
    };
  });

  console.log(`Rows found: ${structure.rowCount} (selector: "${structure.usedSelector}")`);
  console.log(`Detail links: ${structure.detailLinks.length}`);
  structure.detailLinks.forEach((l) => console.log('  ', l));
  console.log(`Pagination buttons: ${structure.pageLinks.join(', ')}`);

  if (structure.selects.length > 0) {
    console.log('\nSelect dropdowns:');
    structure.selects.forEach((s) => {
      console.log(`  #${s.id} [${s.optionCount} options]: ${s.options.slice(0, 5).map((o) => o.text).join(', ')}`);
    });
  }

  if (structure.sampleCells.length > 0) {
    console.log('\nFirst row cells:');
    structure.sampleCells.forEach((c, i) => console.log(`  [${i}] class="${c.className}" text="${c.text.substring(0, 60)}"`));
  }

  const outFile = path.join(OUT, `${slug}_structure.json`);
  fs.writeFileSync(outFile, JSON.stringify({ structure, networkXhr }, null, 2));
  console.log(`Saved: ${outFile}`);

  return structure;
}

async function probeDetailPage(page, detailUrl) {
  if (!detailUrl) return;
  console.log(`\n=== Probing Detail Page ===`);
  console.log('URL:', detailUrl);

  await page.goto(detailUrl, { waitUntil: 'networkidle', timeout: 45000 });
  await page.screenshot({ path: path.join(OUT, 'detail_page.png'), fullPage: true });

  const detail = await page.evaluate(() => {
    const images = Array.from(document.querySelectorAll('img'))
      .map((i) => ({ src: i.src, alt: i.alt, className: i.className }))
      .filter((i) => i.src && !i.src.includes('blank') && !i.src.includes('noimage'))
      .slice(0, 10);

    const tables = Array.from(document.querySelectorAll('table')).slice(0, 5).map((t) => ({
      className: t.className,
      rows: Array.from(t.rows).slice(0, 6).map((r) =>
        Array.from(r.cells).map((c) => c.textContent.trim()).join(' | ')
      ),
    }));

    const heading = document.querySelector('h1, h2')?.textContent?.trim();
    const breadcrumbs = Array.from(document.querySelectorAll('.breadcrumb a, .breadcrumb li, nav a'))
      .map((el) => el.textContent.trim()).filter(Boolean);

    const allText = document.body.innerText.substring(0, 3000);

    return { images, tables, heading, breadcrumbs, allText, title: document.title };
  });

  console.log('Title:', detail.title);
  console.log('Heading:', detail.heading);
  console.log('Breadcrumbs:', detail.breadcrumbs.join(' > '));
  console.log(`Images: ${detail.images.length}`);
  detail.images.forEach((i) => console.log('  ', i.src));
  console.log(`Tables: ${detail.tables.length}`);
  detail.tables.forEach((t) => {
    console.log(`  Table .${t.className}:`);
    t.rows.forEach((r) => console.log('   ', r));
  });

  fs.writeFileSync(path.join(OUT, 'detail_structure.json'), JSON.stringify(detail, null, 2));
  console.log('Saved: output/detail_structure.json');
}

async function main() {
  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu'],
  });

  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    viewport: { width: 1920, height: 1080 },
  });

  const page = await context.newPage();
  const urls = customUrl ? [customUrl] : PROBE_URLS;

  let firstDetailLink = null;

  for (const url of urls) {
    const label = url.match(/brand=(\w+).*model=([^&]+)/)?.[0] || url.split('/').pop();
    try {
      const structure = await probePage(page, url, label);
      if (!firstDetailLink && structure.detailLinks.length > 0) {
        firstDetailLink = structure.detailLinks[0];
      }
      // Stop at first URL that actually returns results
      if (structure.rowCount > 0 || structure.detailLinks.length > 0) break;
    } catch (err) {
      console.error(`  Error probing ${url}: ${err.message}`);
    }
  }

  if (firstDetailLink) {
    await probeDetailPage(page, firstDetailLink);
  } else {
    console.log('\nNo detail link found — check output/*.png screenshots');
    // Try a known working SearchDetail URL from Google index
    await probeDetailPage(
      page,
      'https://aftermarket.ctr.co.kr/Catalogue/SearchDetail?loc=global&searchLoc=JP&oe_id=9083662'
    );
  }

  await browser.close();

  console.log('\n=== Exploration complete ===');
  console.log('Review the files in output/:');
  console.log('  *.png            — screenshots of each page');
  console.log('  *_structure.json — DOM structure + selectors found');
  console.log('  detail_structure.json — part detail page structure');
  console.log('\nIf the selectors in scraper.js need adjusting, update the');
  console.log('parseListPage() and scrapeDetail() functions using the class');
  console.log('names visible in *_structure.json → classNames array.');
}

main().catch((err) => {
  console.error('Fatal:', err);
  process.exit(1);
});
