/**
 * scraper.js — CTR Aftermarket Zimbabwe Car Parts Scraper
 *
 * Uses CTR's own URL-based catalog API (discovered from Google-indexed URLs):
 *   List:   /Catalogue/SearchList?location=<LOC>&searchLocation=global&brand=<BRAND>&model=<MODEL>&year2=<YEAR>&groups=<GROUP>
 *   Detail: /Catalogue/SearchDetail?loc=global&searchLoc=<LOC>&oe_id=<ID>
 *
 * Output:  scripts/scraper/output/
 *   parts.json      — structured JSON for all parts
 *   parts.csv       — flat CSV for spreadsheet import
 *   images/         — downloaded part images
 *   progress.json   — resume checkpoint
 *
 * Usage:
 *   npm install && npx playwright install chromium
 *   node scraper.js              # full scrape, all vehicles + groups
 *   node scraper.js --resume     # pick up where it left off
 *   node scraper.js --brand TOYOTA
 *   node scraper.js --group SUSPENSION
 *   node scraper.js --dry-run    # print search URLs without fetching
 */

'use strict';

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const { ZIMBABWE_VEHICLES, CTR_GROUPS } = require('./zimbabwe-vehicles');

// ─── Configuration ────────────────────────────────────────────────────────────
const CONFIG = {
  baseUrl: 'https://aftermarket.ctr.co.kr',
  outputDir: path.join(__dirname, 'output'),
  imagesDir: path.join(__dirname, 'output', 'images'),
  progressFile: path.join(__dirname, 'output', 'progress.json'),
  partsFile: path.join(__dirname, 'output', 'parts.json'),
  csvFile: path.join(__dirname, 'output', 'parts.csv'),

  delayBetweenPages: 1200,    // ms between list/detail page loads
  delayBetweenVehicles: 2500, // ms between vehicle+group combos
  maxRetries: 3,
  pageTimeout: 45000,

  downloadImages: true,
  maxImagesPerPart: 6,

  // 'JP' captures Japanese-market OEM numbers (most Zimbabwe grey imports)
  // 'ZA' adds South-Africa-spec OEM numbers for locally-sold models
  searchLocations: ['JP', 'ZA'],

  userAgent:
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
};

// ─── CLI flags ────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const FLAG_RESUME = args.includes('--resume');
const FLAG_DRY_RUN = args.includes('--dry-run');
const brandFilter = (() => {
  const i = args.indexOf('--brand');
  return i !== -1 ? args[i + 1]?.toUpperCase() : null;
})();
const groupFilter = (() => {
  const i = args.indexOf('--group');
  return i !== -1 ? args[i + 1]?.toUpperCase() : null;
})();

// ─── Utilities ────────────────────────────────────────────────────────────────
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function log(msg, ...rest) {
  console.log(`[${new Date().toISOString().replace('T', ' ').slice(0, 19)}] ${msg}`, ...rest);
}

function saveJson(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
}

function loadJson(file, fallback) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); }
  catch { return fallback; }
}

function slugify(s) {
  return String(s).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

async function downloadImage(url, dest) {
  if (fs.existsSync(dest)) return dest;
  return new Promise((resolve, reject) => {
    const proto = url.startsWith('https') ? https : http;
    const file = fs.createWriteStream(dest);
    proto.get(url, { timeout: 15000 }, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        file.close(); fs.unlink(dest, () => {});
        return downloadImage(res.headers.location, dest).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        file.close(); fs.unlink(dest, () => {});
        return reject(new Error(`HTTP ${res.statusCode}`));
      }
      res.pipe(file);
      file.on('finish', () => file.close(() => resolve(dest)));
    }).on('error', (e) => { fs.unlink(dest, () => {}); reject(e); });
  });
}

function writeCsv(parts) {
  const headers = [
    'part_number', 'part_name', 'category', 'subcategory',
    'make', 'model', 'year', 'engine',
    'description', 'specifications', 'oem_numbers', 'fitment',
    'price', 'currency', 'image_urls', 'local_images', 'product_url', 'scraped_at',
  ];
  const esc = (v) => {
    const s = String(v ?? '').replace(/"/g, '""');
    return /[,"\n]/.test(s) ? `"${s}"` : s;
  };
  const rows = [headers.join(',')];
  for (const p of parts) {
    rows.push([
      p.partNumber, p.partName, p.category, p.subcategory,
      p.make, p.model, p.year, p.engine,
      p.description,
      (p.specifications || []).map((s) => `${s.key}:${s.value}`).join('; '),
      (p.oemNumbers || []).join('; '),
      (p.fitmentData || []).join('; '),
      p.price, p.currency,
      (p.imageUrls || []).join('; '),
      (p.localImages || []).join('; '),
      p.productUrl, p.scrapedAt,
    ].map(esc).join(','));
  }
  fs.writeFileSync(CONFIG.csvFile, rows.join('\n'), 'utf8');
}

// ─── CTR URL builders ─────────────────────────────────────────────────────────

function buildListUrl(vehicle, year, group, searchLoc) {
  const params = new URLSearchParams({
    location: searchLoc,
    searchLocation: 'global',
    brand: vehicle.make,
    model: vehicle.ctrModel || vehicle.model,
    year2: String(year),
    groups: group,
  });
  return `${CONFIG.baseUrl}/Catalogue/SearchList?${params}`;
}

function buildDetailUrl(oeId, searchLoc) {
  const params = new URLSearchParams({
    loc: 'global',
    searchLoc,
    oe_id: String(oeId),
  });
  return `${CONFIG.baseUrl}/Catalogue/SearchDetail?${params}`;
}

// ─── Page parsers ─────────────────────────────────────────────────────────────

/**
 * Parse a SearchList results page and return all part stubs visible on it.
 * Returns [] if no results or page is empty.
 */
async function parseListPage(page, vehicle, year, group, searchLoc) {
  return page.evaluate(
    ({ make, model, year, group, searchLoc }) => {
      const stubs = [];

      // Each result row/card on CTR's SearchList page
      // Selectors observed on Korean aftermarket list pages
      const rowSelectors = [
        'table.list tbody tr',
        '.result-list tr',
        '.catalogue-list tr',
        '.parts-list tr',
        'tr[data-oe-id]',
        'tr[onclick]',
        '.item-row',
        '.product-row',
        'li.item',
        '.list-item',
      ];

      let rows = [];
      for (const sel of rowSelectors) {
        rows = Array.from(document.querySelectorAll(sel));
        if (rows.length > 0) break;
      }

      // Also look for any anchor tags that link to SearchDetail
      const detailLinks = Array.from(
        document.querySelectorAll('a[href*="SearchDetail"], a[href*="searchDetail"]')
      );

      for (const link of detailLinks) {
        const url = new URL(link.href, location.origin);
        const oeId = url.searchParams.get('oe_id');
        const sLoc = url.searchParams.get('searchLoc') || searchLoc;
        if (!oeId) continue;

        const row = link.closest('tr, li, .item, .product, .row') || link.parentElement;
        const cells = row ? Array.from(row.querySelectorAll('td, th, .cell, .col')) : [];

        const partNumberEl = row?.querySelector(
          '[class*="part-no"], [class*="partno"], [class*="code"], td:nth-child(1)'
        );
        const partNameEl = row?.querySelector(
          '[class*="name"], [class*="title"], [class*="desc"], td:nth-child(2)'
        );
        const imgEl = row?.querySelector('img');

        stubs.push({
          oeId,
          searchLoc: sLoc,
          detailUrl: link.href,
          partNumber: partNumberEl?.textContent?.trim() || link.textContent?.trim() || '',
          partName: partNameEl?.textContent?.trim() || cells[1]?.textContent?.trim() || '',
          thumbnailUrl: imgEl?.src || null,
          make, model, year, group,
        });
      }

      // If no links found, try parsing table rows directly
      if (stubs.length === 0 && rows.length > 0) {
        rows.forEach((row) => {
          const cells = Array.from(row.querySelectorAll('td'));
          if (cells.length < 2) return;
          const onclick = row.getAttribute('onclick') || '';
          const oeMatch = onclick.match(/oe_id[=\s'"]+(\d+)/);
          const oeId = oeMatch ? oeMatch[1] : null;
          stubs.push({
            oeId,
            searchLoc,
            detailUrl: oeId
              ? `${location.origin}/Catalogue/SearchDetail?loc=global&searchLoc=${searchLoc}&oe_id=${oeId}`
              : null,
            partNumber: cells[0]?.textContent?.trim() || '',
            partName: cells[1]?.textContent?.trim() || '',
            thumbnailUrl: row.querySelector('img')?.src || null,
            make, model, year, group,
          });
        });
      }

      return stubs;
    },
    { make: vehicle.make, model: vehicle.ctrModel || vehicle.model, year, group, searchLoc }
  );
}

/**
 * Check how many pages of results exist and return total count.
 */
async function getTotalPages(page) {
  return page.evaluate(() => {
    // Look for a pagination indicator
    const pageInfo = document.querySelector(
      '.pagination, .paging, [class*="page-info"], [class*="total-count"]'
    );
    if (!pageInfo) return 1;

    // Try to find "Page X of Y" or a count of page links
    const text = pageInfo.textContent;
    const match = text.match(/(\d+)\s*\/\s*(\d+)|of\s+(\d+)|총\s*(\d+)/);
    if (match) return parseInt(match[2] || match[3] || match[4], 10) || 1;

    const pageLinks = pageInfo.querySelectorAll('a, button, span[class*="page"]');
    return pageLinks.length > 0 ? pageLinks.length : 1;
  });
}

/**
 * Click to the next page, return false if no next page.
 */
async function goToNextPage(page) {
  const nextBtn = await page.$(
    'a.next, button.next, .pagination .next, li.next a, ' +
    'a[aria-label*="next" i], .page-next a, .btn-next, ' +
    'a[title*="next" i], span.next a, .paging-next'
  );
  if (!nextBtn) return false;

  const disabled = await nextBtn.evaluate((el) =>
    el.classList.contains('disabled') ||
    el.getAttribute('disabled') != null ||
    el.getAttribute('aria-disabled') === 'true'
  );
  if (disabled) return false;

  await nextBtn.click();
  await page.waitForLoadState('networkidle', { timeout: 20000 });
  return true;
}

/**
 * Scrape the detail page for a single part.
 */
async function scrapeDetail(page, stub, retries = 0) {
  if (!stub.detailUrl && !stub.oeId) return null;

  const url = stub.detailUrl || buildDetailUrl(stub.oeId, stub.searchLoc);

  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: CONFIG.pageTimeout });
  } catch (err) {
    if (retries < CONFIG.maxRetries) {
      await sleep(2000 * (retries + 1));
      return scrapeDetail(page, stub, retries + 1);
    }
    log(`    SKIP (load error): ${url} — ${err.message}`);
    return null;
  }

  const detail = await page.evaluate((stub) => {
    // ── Part number ────────────────────────────────────────────────────────
    let partNumber = stub.partNumber || '';
    const pnSelectors = [
      '.part-number', '.item-no', '.goods-no', '.part-no', '.code',
      'td.partnumber', '[class*="partno"]', '[class*="part_no"]',
      '[class*="part-number"]', '[class*="item_code"]',
      'h1 span', '.product-code',
    ];
    for (const sel of pnSelectors) {
      const el = document.querySelector(sel);
      if (el?.textContent?.trim()) { partNumber = el.textContent.trim(); break; }
    }
    // Also check page title — CTR titles look like "Search > CB0171 | CTR Aftermarket"
    if (!partNumber) {
      const titleMatch = document.title.match(/>\s*([A-Z]{1,3}\d{3,5}[A-Z]?)\s*\|/);
      if (titleMatch) partNumber = titleMatch[1];
    }

    // ── Part name ──────────────────────────────────────────────────────────
    let partName = stub.partName || '';
    const nameSelectors = [
      'h1', 'h2.product-name', 'h1.goods-name', '.item-title',
      '.product-title', '[class*="part-name"]', '[class*="item-name"]',
      '.part_name', '.goods_name',
    ];
    for (const sel of nameSelectors) {
      const el = document.querySelector(sel);
      if (el?.textContent?.trim() && el.textContent.trim() !== partNumber) {
        partName = el.textContent.trim().substring(0, 200);
        break;
      }
    }

    // ── Images ────────────────────────────────────────────────────────────
    const imageUrls = [];
    const imgSelectors = [
      '.product-image img', '.goods-image img', '.part-image img',
      '.swiper-slide img', '.gallery img', '.product-photo img',
      '#mainImage img', '#productImage', '.main-img img',
      '[class*="product_img"] img', '[class*="part_img"] img',
      'img[src*="upload"]', 'img[src*="product"]', 'img[src*="image"]',
    ];
    const seen = new Set();
    for (const sel of imgSelectors) {
      document.querySelectorAll(sel).forEach((img) => {
        const src = img.src || img.dataset?.src || img.dataset?.lazy || '';
        if (src && src.startsWith('http') && !src.includes('noimage') && !src.includes('blank') && !seen.has(src)) {
          seen.add(src);
          imageUrls.push(src);
        }
      });
    }

    // ── Specifications ─────────────────────────────────────────────────────
    const specifications = [];
    // Try spec tables
    const specTableSelectors = [
      '.spec-table tr', 'table.spec tr', '.spec tr',
      '.detail-table tr', '.product-info tr', '.part-info tr',
      'table.detail tr', '[class*="spec"] tr', '[class*="detail"] tr',
    ];
    for (const sel of specTableSelectors) {
      const rows = document.querySelectorAll(sel);
      if (rows.length > 0) {
        rows.forEach((row) => {
          const [th, td] = [row.querySelector('th, td:first-child'), row.querySelector('td:not(:first-child), td:last-child')];
          if (th && td && th !== td) {
            const key = th.textContent.trim();
            const value = td.textContent.trim();
            if (key && value) specifications.push({ key, value });
          }
        });
        if (specifications.length > 0) break;
      }
    }
    // Try definition lists
    document.querySelectorAll('dl dt').forEach((dt) => {
      const dd = dt.nextElementSibling;
      if (dd?.tagName === 'DD') {
        specifications.push({ key: dt.textContent.trim(), value: dd.textContent.trim() });
      }
    });

    // ── OEM / cross-reference numbers ──────────────────────────────────────
    const oemNumbers = [];
    const oemSelectors = [
      '.oem-number', '.oe-number', '.oem-ref', '.cross-ref',
      '[class*="oem"]', '[class*="cross"]', '[class*="oe-num"]',
      'td.oe', 'td.oem', '.ref-no',
    ];
    for (const sel of oemSelectors) {
      document.querySelectorAll(sel).forEach((el) => {
        const t = el.textContent.trim();
        if (t && !oemNumbers.includes(t)) oemNumbers.push(t);
      });
    }

    // ── Vehicle application / fitment ──────────────────────────────────────
    const fitmentData = [];
    const fitmentSelectors = [
      '.application', '.fitment', '.vehicle-list li', '.car-list li',
      '[class*="application"] li', '[class*="fitment"] li',
      '.applicable-car', 'table.application tr', '.oe-application li',
    ];
    for (const sel of fitmentSelectors) {
      document.querySelectorAll(sel).forEach((el) => {
        const t = el.textContent.trim();
        if (t && t.length > 2) fitmentData.push(t);
      });
    }

    // ── Category from breadcrumb ───────────────────────────────────────────
    const breadcrumbs = Array.from(
      document.querySelectorAll('.breadcrumb a, .breadcrumb li, [class*="breadcrumb"] span, nav[aria-label*="breadcrumb"] a')
    ).map((el) => el.textContent.trim()).filter(Boolean);

    // ── Description ───────────────────────────────────────────────────────
    let description = '';
    const descSelectors = [
      '.product-description', '.goods-description', '.item-desc',
      '.description', '.detail-desc', '[class*="description"]',
    ];
    for (const sel of descSelectors) {
      const el = document.querySelector(sel);
      if (el?.textContent?.trim()) { description = el.textContent.trim().substring(0, 1000); break; }
    }

    // ── Price ─────────────────────────────────────────────────────────────
    let price = '', currency = '';
    const priceEl = document.querySelector('.price, .amount, [class*="price"], .cost');
    if (priceEl) {
      const t = priceEl.textContent.trim();
      price = t.replace(/[^\d.,]/g, '').trim();
      currency = t.replace(/[\d.,\s]/g, '').trim() || 'KRW';
    }

    // ── Engine / variant info ─────────────────────────────────────────────
    let engine = '';
    const engineEl = document.querySelector('[class*="engine"], [class*="variant"], td.engine');
    if (engineEl) engine = engineEl.textContent.trim();

    return {
      partNumber: partNumber.replace(/\s+/g, '').toUpperCase(),
      partName,
      imageUrls: imageUrls.slice(0, 6),
      specifications,
      oemNumbers,
      fitmentData,
      breadcrumbs,
      description,
      price,
      currency,
      engine,
      pageTitle: document.title,
    };
  }, stub);

  // ── Build record ──────────────────────────────────────────────────────────
  const category = detail.breadcrumbs[1] || stub.group || '';
  const subcategory = detail.breadcrumbs[2] || '';

  const record = {
    partNumber: detail.partNumber || stub.partNumber || '',
    partName: detail.partName || stub.partName || '',
    category,
    subcategory,
    make: stub.make,
    model: stub.model,
    year: stub.year,
    engine: detail.engine,
    description: detail.description,
    imageUrls: detail.imageUrls,
    localImages: [],
    specifications: detail.specifications,
    oemNumbers: detail.oemNumbers,
    fitmentData: detail.fitmentData,
    price: detail.price,
    currency: detail.currency,
    productUrl: url,
    oeId: stub.oeId,
    searchLoc: stub.searchLoc,
    scrapedAt: new Date().toISOString(),
  };

  // ── Download images ────────────────────────────────────────────────────────
  if (CONFIG.downloadImages && detail.imageUrls.length > 0) {
    const slug = slugify(
      `${stub.make}-${stub.model}-${stub.year}-${record.partNumber || record.partName}`
    ).substring(0, 80);
    const imgDir = path.join(CONFIG.imagesDir, slug);
    fs.mkdirSync(imgDir, { recursive: true });

    for (let i = 0; i < Math.min(detail.imageUrls.length, CONFIG.maxImagesPerPart); i++) {
      const imgUrl = detail.imageUrls[i];
      const ext = imgUrl.split('?')[0].split('.').pop().substring(0, 4) || 'jpg';
      const dest = path.join(imgDir, `${i + 1}.${ext}`);
      try {
        await downloadImage(imgUrl, dest);
        record.localImages.push(path.relative(__dirname, dest));
      } catch (err) {
        log(`      Image failed: ${err.message}`);
      }
    }
  }

  return record;
}

// ─── Main orchestration ───────────────────────────────────────────────────────
async function main() {
  const vehicles = brandFilter
    ? ZIMBABWE_VEHICLES.filter((v) => v.make.toUpperCase() === brandFilter)
    : ZIMBABWE_VEHICLES;

  const groups = groupFilter
    ? CTR_GROUPS.filter((g) => g.toUpperCase() === groupFilter)
    : CTR_GROUPS;

  if (FLAG_DRY_RUN) {
    console.log('DRY RUN — search URLs that would be fetched:');
    for (const v of vehicles) {
      for (const year of v.years) {
        for (const group of groups) {
          for (const loc of CONFIG.searchLocations) {
            console.log(buildListUrl(v, year, group, loc));
          }
        }
      }
    }
    return;
  }

  fs.mkdirSync(CONFIG.outputDir, { recursive: true });
  fs.mkdirSync(CONFIG.imagesDir, { recursive: true });

  const progress = FLAG_RESUME ? loadJson(CONFIG.progressFile, {}) : {};
  const allParts = FLAG_RESUME ? loadJson(CONFIG.partsFile, []) : [];
  // Quick lookup to avoid re-scraping the same oe_id across vehicles
  const scrapedOeIds = new Set(allParts.map((p) => p.oeId).filter(Boolean));

  const totalCombinations = vehicles.reduce(
    (sum, v) => sum + v.years.length * groups.length * CONFIG.searchLocations.length, 0
  );

  log('=== CTR Zimbabwe Car Parts Scraper ===');
  log(`Target: ${CONFIG.baseUrl}`);
  log(`Vehicles: ${vehicles.length}  Groups: ${groups.length}  Locations: ${CONFIG.searchLocations.join(', ')}`);
  log(`Search combinations: ${totalCombinations}`);
  log(`Images: ${CONFIG.downloadImages ? 'enabled' : 'disabled'}`);
  log(`Resume: ${FLAG_RESUME} (${allParts.length} parts already saved)`);

  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu'],
  });

  const context = await browser.newContext({
    userAgent: CONFIG.userAgent,
    viewport: { width: 1920, height: 1080 },
  });

  const page = await context.newPage();

  let done = 0;
  let totalParts = allParts.length;

  for (const vehicle of vehicles) {
    for (const year of vehicle.years) {
      for (const group of groups) {
        for (const searchLoc of CONFIG.searchLocations) {
          const key = `${vehicle.make}__${vehicle.model}__${year}__${group}__${searchLoc}`;
          done++;

          if (FLAG_RESUME && progress[key] === 'done') {
            log(`SKIP [${done}/${totalCombinations}] ${vehicle.make} ${vehicle.model} ${year} ${group} ${searchLoc}`);
            continue;
          }

          log(`[${done}/${totalCombinations}] ${vehicle.make} ${vehicle.model} ${year} — ${group} (${searchLoc})`);

          let pageNum = 0;
          let vehiclePartCount = 0;

          try {
            const listUrl = buildListUrl(vehicle, year, group, searchLoc);
            await page.goto(listUrl, { waitUntil: 'networkidle', timeout: CONFIG.pageTimeout });

            while (true) {
              pageNum++;
              const stubs = await parseListPage(page, vehicle, year, group, searchLoc);

              if (stubs.length === 0) {
                if (pageNum === 1) log('  No results');
                break;
              }

              log(`  Page ${pageNum}: ${stubs.length} parts`);

              for (let i = 0; i < stubs.length; i++) {
                const stub = stubs[i];

                // Skip if we already scraped this OE ID (avoids duplicates across model years)
                if (stub.oeId && scrapedOeIds.has(stub.oeId)) {
                  log(`  [${i + 1}/${stubs.length}] SKIP (duplicate oe_id ${stub.oeId})`);
                  continue;
                }

                log(`  [${i + 1}/${stubs.length}] ${stub.partNumber || stub.oeId} ${stub.partName?.substring(0, 50)}`);

                const part = await scrapeDetail(page, stub);
                if (part) {
                  allParts.push(part);
                  if (stub.oeId) scrapedOeIds.add(stub.oeId);
                  totalParts++;
                  vehiclePartCount++;
                }

                await sleep(CONFIG.delayBetweenPages);

                // Return to list if detail navigation changed the page
                if (pageNum > 1 || i < stubs.length - 1) {
                  const currentUrl = page.url();
                  if (!currentUrl.includes('SearchList') && !currentUrl.includes('searchList')) {
                    await page.goto(listUrl, { waitUntil: 'networkidle', timeout: CONFIG.pageTimeout });
                    // Jump back to current page number
                    for (let p = 1; p < pageNum; p++) {
                      await goToNextPage(page);
                      await sleep(500);
                    }
                  }
                }

                if (totalParts % 20 === 0) {
                  saveJson(CONFIG.partsFile, allParts);
                  writeCsv(allParts);
                  log(`  [checkpoint] ${totalParts} total parts saved`);
                }
              }

              const hasNext = await goToNextPage(page);
              if (!hasNext) break;
              await sleep(CONFIG.delayBetweenPages);
            }

            progress[key] = 'done';
          } catch (err) {
            log(`  ERROR: ${err.message}`);
            progress[key] = `error:${err.message.substring(0, 80)}`;
          }

          saveJson(CONFIG.progressFile, progress);
          log(`  ${vehicle.make} ${vehicle.model} ${year} ${group} ${searchLoc}: ${vehiclePartCount} new parts`);
          await sleep(CONFIG.delayBetweenVehicles);
        }
      }
    }
  }

  // ── Final save ─────────────────────────────────────────────────────────────
  saveJson(CONFIG.partsFile, allParts);
  writeCsv(allParts);

  await browser.close();

  log('\n=== Done ===');
  log(`Total parts: ${allParts.length}`);
  log(`Output directory: ${CONFIG.outputDir}`);
  log('  parts.json — structured JSON');
  log('  parts.csv  — spreadsheet CSV');
  log('  images/    — part images');
  log('\nNext step: node postprocess.js');
}

main().catch((err) => {
  console.error('Fatal:', err);
  process.exit(1);
});
