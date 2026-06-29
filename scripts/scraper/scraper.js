/**
 * scraper.js — CTR Aftermarket Zimbabwe Car Parts Scraper
 *
 * Targets: https://aftermarket.ctr.co.kr
 * Output:  scripts/scraper/output/
 *            parts.json          — all parts as structured JSON
 *            parts.csv           — flat CSV for spreadsheet import
 *            images/             — downloaded part images
 *            progress.json       — resume checkpoint
 *
 * Usage:
 *   npm install
 *   node scraper.js              # full run
 *   node scraper.js --resume     # resume from last checkpoint
 *   node scraper.js --brand TOYOTA   # only scrape one brand
 *   node scraper.js --dry-run    # print what would be scraped without fetching
 */

'use strict';

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const VEHICLES = require('./zimbabwe-vehicles');

// ─── Configuration ────────────────────────────────────────────────────────────
const CONFIG = {
  baseUrl: 'https://aftermarket.ctr.co.kr',
  outputDir: path.join(__dirname, 'output'),
  imagesDir: path.join(__dirname, 'output', 'images'),
  progressFile: path.join(__dirname, 'output', 'progress.json'),
  partsFile: path.join(__dirname, 'output', 'parts.json'),
  csvFile: path.join(__dirname, 'output', 'parts.csv'),

  // Rate-limiting: be polite to the server
  delayBetweenRequests: 1500,   // ms between page loads
  delayBetweenVehicles: 3000,   // ms between vehicles
  maxRetries: 3,
  pageTimeout: 45000,

  // Set true to skip image downloads (faster)
  downloadImages: true,
  maxImagesPerPart: 5,

  userAgent:
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
};

// ─── CLI flags ────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const FLAG_RESUME = args.includes('--resume');
const FLAG_DRY_RUN = args.includes('--dry-run');
const brandFilter = (() => {
  const idx = args.indexOf('--brand');
  return idx !== -1 ? args[idx + 1]?.toUpperCase() : null;
})();

// ─── Utilities ────────────────────────────────────────────────────────────────
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function log(msg, ...rest) {
  console.log(`[${new Date().toISOString()}] ${msg}`, ...rest);
}

function saveJson(filePath, data) {
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
}

function loadJson(filePath, fallback = null) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return fallback;
  }
}

function slugify(str) {
  return str.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

async function downloadImage(url, destPath) {
  return new Promise((resolve, reject) => {
    if (fs.existsSync(destPath)) return resolve(destPath);

    const proto = url.startsWith('https') ? https : http;
    const file = fs.createWriteStream(destPath);

    proto
      .get(url, { timeout: 15000 }, (res) => {
        if (res.statusCode === 301 || res.statusCode === 302) {
          file.close();
          fs.unlink(destPath, () => {});
          return downloadImage(res.headers.location, destPath).then(resolve).catch(reject);
        }
        if (res.statusCode !== 200) {
          file.close();
          fs.unlink(destPath, () => {});
          return reject(new Error(`HTTP ${res.statusCode} for ${url}`));
        }
        res.pipe(file);
        file.on('finish', () => file.close(() => resolve(destPath)));
      })
      .on('error', (err) => {
        fs.unlink(destPath, () => {});
        reject(err);
      });
  });
}

function writeCsv(parts) {
  const headers = [
    'part_number',
    'part_name',
    'category',
    'subcategory',
    'make',
    'model',
    'year',
    'engine',
    'description',
    'specifications',
    'oem_numbers',
    'price',
    'currency',
    'image_urls',
    'local_images',
    'product_url',
    'scraped_at',
  ];

  const escape = (v) => {
    const s = String(v ?? '').replace(/"/g, '""');
    return s.includes(',') || s.includes('"') || s.includes('\n') ? `"${s}"` : s;
  };

  const rows = [headers.join(',')];
  for (const p of parts) {
    rows.push(
      [
        p.partNumber,
        p.partName,
        p.category,
        p.subcategory,
        p.make,
        p.model,
        p.year,
        p.engine,
        p.description,
        Array.isArray(p.specifications)
          ? p.specifications.map((s) => `${s.key}:${s.value}`).join('; ')
          : '',
        Array.isArray(p.oemNumbers) ? p.oemNumbers.join('; ') : '',
        p.price,
        p.currency,
        Array.isArray(p.imageUrls) ? p.imageUrls.join('; ') : '',
        Array.isArray(p.localImages) ? p.localImages.join('; ') : '',
        p.productUrl,
        p.scrapedAt,
      ]
        .map(escape)
        .join(',')
    );
  }

  fs.writeFileSync(CONFIG.csvFile, rows.join('\n'), 'utf8');
}

// ─── CTR site interaction helpers ─────────────────────────────────────────────

/**
 * Navigate to the main page and detect which search mechanism the site uses.
 * CTR may use:
 *   A) A dropdown sequence: Make → Model → Year → Part category
 *   B) A text search box
 *   C) A URL-based catalog (e.g. /catalog?make=TOYOTA&model=COROLLA)
 *
 * Returns a descriptor of the search method found.
 */
async function detectSearchMethod(page) {
  await page.goto(CONFIG.baseUrl + '/Main', {
    waitUntil: 'networkidle',
    timeout: CONFIG.pageTimeout,
  });

  const method = await page.evaluate(() => {
    const selects = Array.from(document.querySelectorAll('select')).map((s) => ({
      id: s.id,
      name: s.name,
      className: s.className,
      options: Array.from(s.options).map((o) => o.text.trim()).filter(Boolean),
    }));

    const searchInputs = Array.from(
      document.querySelectorAll('input[type="text"], input[type="search"]')
    ).map((i) => ({ id: i.id, name: i.name, placeholder: i.placeholder }));

    const navLinks = Array.from(document.querySelectorAll('a[href]'))
      .map((a) => ({ href: a.href, text: a.textContent.trim() }))
      .filter((a) => a.text && (
        a.href.includes('catalog') ||
        a.href.includes('search') ||
        a.href.includes('product') ||
        a.href.includes('parts') ||
        a.href.includes('item')
      ));

    return { selects, searchInputs, navLinks };
  });

  return method;
}

/**
 * Search the CTR catalog for a specific vehicle.
 * This function handles the most common patterns seen on Korean aftermarket sites.
 *
 * Returns an array of part result URLs/objects found on the search results page.
 */
async function searchVehicleParts(page, vehicle, year) {
  const { make, model } = vehicle;
  log(`  Searching: ${make} ${model} ${year}`);

  // Strategy 1: Use select dropdowns if available
  const dropdownResult = await tryDropdownSearch(page, make, model, year);
  if (dropdownResult) return dropdownResult;

  // Strategy 2: Use text search
  const textResult = await tryTextSearch(page, make, model, year);
  if (textResult) return textResult;

  // Strategy 3: Try direct URL patterns common on Korean auto parts sites
  const urlPatterns = [
    `/search?make=${encodeURIComponent(make)}&model=${encodeURIComponent(model)}&year=${year}`,
    `/catalog/search?keyword=${encodeURIComponent(make + ' ' + model)}&year=${year}`,
    `/parts/search?brand=${encodeURIComponent(make)}&model=${encodeURIComponent(model)}`,
    `/product/list?maker=${encodeURIComponent(make)}&car=${encodeURIComponent(model)}`,
  ];

  for (const pattern of urlPatterns) {
    try {
      const response = await page.goto(CONFIG.baseUrl + pattern, {
        waitUntil: 'networkidle',
        timeout: 20000,
      });
      if (response && response.status() === 200) {
        const parts = await extractPartsFromResultsPage(page, make, model, year);
        if (parts.length > 0) {
          log(`    Found ${parts.length} parts via URL pattern: ${pattern}`);
          return parts;
        }
      }
    } catch {
      // Try next pattern
    }
    await sleep(500);
  }

  return [];
}

async function tryDropdownSearch(page, make, model, year) {
  await page.goto(CONFIG.baseUrl + '/Main', {
    waitUntil: 'networkidle',
    timeout: CONFIG.pageTimeout,
  });

  const selects = await page.$$('select');
  if (selects.length === 0) return null;

  // Try to find a make/brand dropdown
  for (const sel of selects) {
    const options = await sel.evaluate((el) =>
      Array.from(el.options).map((o) => o.text.trim().toUpperCase())
    );
    if (
      options.some(
        (o) => o.includes('TOYOTA') || o.includes('HONDA') || o.includes('MAKER') || o.includes('BRAND')
      )
    ) {
      // This looks like a make dropdown
      try {
        await sel.selectOption({ label: new RegExp(make, 'i') });
        await sleep(1000);

        // Wait for next dropdown to populate (model)
        const modelSels = await page.$$('select');
        for (const mSel of modelSels) {
          const mOptions = await mSel.evaluate((el) =>
            Array.from(el.options).map((o) => o.text.trim().toUpperCase())
          );
          if (mOptions.some((o) => o.includes(model.split(' ')[0]))) {
            await mSel.selectOption({ label: new RegExp(model.split(' ')[0], 'i') });
            await sleep(1000);
          }
        }

        // Try year dropdown
        const yearSels = await page.$$('select');
        for (const ySel of yearSels) {
          const yOptions = await ySel.evaluate((el) =>
            Array.from(el.options).map((o) => o.text.trim())
          );
          if (yOptions.some((o) => o.includes(String(year)))) {
            await ySel.selectOption({ label: String(year) });
            await sleep(1000);
          }
        }

        // Submit the search
        const submitBtn = await page.$('button[type="submit"], input[type="submit"], .btn-search, .search-btn');
        if (submitBtn) {
          await submitBtn.click();
          await page.waitForLoadState('networkidle', { timeout: 20000 });
          return await extractPartsFromResultsPage(page, make, model, year);
        }
      } catch {
        // Dropdown approach failed, fall through
      }
      break;
    }
  }

  return null;
}

async function tryTextSearch(page, make, model, year) {
  await page.goto(CONFIG.baseUrl + '/Main', {
    waitUntil: 'networkidle',
    timeout: CONFIG.pageTimeout,
  });

  const searchInput = await page.$(
    'input[type="text"][name*="search" i], input[type="text"][id*="search" i], ' +
    'input[type="search"], input[placeholder*="search" i], input[placeholder*="part" i]'
  );

  if (!searchInput) return null;

  const query = `${make} ${model} ${year}`;
  await searchInput.fill(query);

  const submitBtn = await page.$(
    'button[type="submit"], input[type="submit"], ' +
    '.btn-search, .search-btn, button.search'
  );
  if (submitBtn) {
    await submitBtn.click();
  } else {
    await searchInput.press('Enter');
  }

  await page.waitForLoadState('networkidle', { timeout: 20000 });
  return await extractPartsFromResultsPage(page, make, model, year);
}

/**
 * Parse a search results page and return part stubs for further detail fetching.
 */
async function extractPartsFromResultsPage(page, make, model, year) {
  return page.evaluate(
    ({ make, model, year }) => {
      const results = [];

      // Common patterns for product cards on Korean aftermarket sites
      const cardSelectors = [
        '.product-item', '.part-item', '.goods-item', '.item-box',
        '.product_item', '.product_list li', '.goods_list li',
        '.catalog-item', '.search-result-item', 'li.item',
        '[class*="product"][class*="card"]', '[class*="part"][class*="item"]',
        '.prd-item', '.prd_item', '.goods-card',
      ];

      let cards = [];
      for (const sel of cardSelectors) {
        cards = Array.from(document.querySelectorAll(sel));
        if (cards.length > 0) break;
      }

      // Fallback: look for links that appear to be product links
      if (cards.length === 0) {
        const productLinks = Array.from(document.querySelectorAll('a[href*="product"], a[href*="item"], a[href*="part"], a[href*="goods"]'));
        for (const link of productLinks.slice(0, 100)) {
          results.push({
            productUrl: link.href,
            partName: link.textContent.trim(),
            partNumber: null,
            make,
            model,
            year,
            thumbnailUrl: null,
          });
        }
        return results;
      }

      for (const card of cards) {
        const link = card.querySelector('a[href]');
        const nameEl = card.querySelector(
          '.product-name, .part-name, .goods-name, .item-name, ' +
          '.title, h3, h4, .name, [class*="name"], [class*="title"]'
        );
        const numberEl = card.querySelector(
          '.part-number, .item-no, .goods-no, .part-no, ' +
          '[class*="number"], [class*="partno"], [class*="code"]'
        );
        const imgEl = card.querySelector('img');
        const priceEl = card.querySelector(
          '.price, .amount, [class*="price"], [class*="amount"]'
        );

        results.push({
          productUrl: link ? link.href : null,
          partName: nameEl ? nameEl.textContent.trim() : (link ? link.textContent.trim() : null),
          partNumber: numberEl ? numberEl.textContent.trim().replace(/[^\w-]/g, '') : null,
          thumbnailUrl: imgEl ? imgEl.src : null,
          price: priceEl ? priceEl.textContent.trim() : null,
          make,
          model,
          year,
        });
      }

      return results.filter((r) => r.productUrl || r.partName);
    },
    { make, model, year }
  );
}

/**
 * Fetch the detail page for a single part and return the full data record.
 */
async function scrapePart(page, stub, retries = 0) {
  if (!stub.productUrl) return null;

  try {
    await page.goto(stub.productUrl, {
      waitUntil: 'networkidle',
      timeout: CONFIG.pageTimeout,
    });
  } catch (err) {
    if (retries < CONFIG.maxRetries) {
      await sleep(2000 * (retries + 1));
      return scrapePart(page, stub, retries + 1);
    }
    log(`    SKIP (load error): ${stub.productUrl} — ${err.message}`);
    return null;
  }

  const detail = await page.evaluate((stub) => {
    // ── Part number ──────────────────────────────────────────────────────────
    const partNumberSelectors = [
      '.part-number', '.item-no', '.goods-no', '.part-no',
      '[class*="partno"]', '[class*="part_no"]', '[class*="part-number"]',
      '[class*="item_code"]', '[class*="itemcode"]', 'td.code', '.code',
    ];
    let partNumber = stub.partNumber;
    for (const sel of partNumberSelectors) {
      const el = document.querySelector(sel);
      if (el) {
        partNumber = el.textContent.trim().replace(/[^A-Z0-9\-_]/gi, '');
        break;
      }
    }

    // ── Part name ────────────────────────────────────────────────────────────
    const nameSelectors = [
      'h1.product-name', 'h1.goods-name', 'h1.item-name', 'h1',
      '.product-title', '.goods-title', '.part-title', '.item-title',
      '[class*="product_name"]', '[class*="goods_name"]',
    ];
    let partName = stub.partName;
    for (const sel of nameSelectors) {
      const el = document.querySelector(sel);
      if (el && el.textContent.trim()) {
        partName = el.textContent.trim();
        break;
      }
    }

    // ── Images ───────────────────────────────────────────────────────────────
    const imageSelectors = [
      '.product-image img', '.goods-image img', '.item-image img',
      '.product-photo img', '.part-photo img',
      '.swiper-slide img', '.gallery img', '.thumbnail img',
      '[class*="product_img"] img', '[class*="goods_img"] img',
      '#productImage img', '#itemImage img',
    ];
    const imageUrls = new Set();
    for (const sel of imageSelectors) {
      document.querySelectorAll(sel).forEach((img) => {
        const src = img.src || img.dataset.src || img.dataset.lazy;
        if (src && src.startsWith('http') && !src.includes('noimage')) {
          imageUrls.add(src);
        }
      });
    }

    // ── Specifications table ─────────────────────────────────────────────────
    const specifications = [];
    const specSelectors = [
      '.spec-table tr', '.detail-table tr', '.product-info tr',
      '.goods-info tr', '.item-spec tr', 'table.spec tr',
      '[class*="spec"] tr', '[class*="detail"] tr', 'dl dt',
    ];

    for (const sel of specSelectors) {
      const rows = document.querySelectorAll(sel);
      if (rows.length > 0) {
        rows.forEach((row) => {
          const cells = row.querySelectorAll('td, th');
          if (cells.length >= 2) {
            const key = cells[0].textContent.trim();
            const value = cells[1].textContent.trim();
            if (key && value && key !== value) {
              specifications.push({ key, value });
            }
          }
        });
        if (specifications.length > 0) break;
      }
    }

    // Also check definition lists
    const dts = document.querySelectorAll('dl dt');
    dts.forEach((dt) => {
      const dd = dt.nextElementSibling;
      if (dd && dd.tagName === 'DD') {
        specifications.push({ key: dt.textContent.trim(), value: dd.textContent.trim() });
      }
    });

    // ── OEM / cross-reference numbers ────────────────────────────────────────
    const oemSelectors = [
      '.oem-number', '.cross-reference', '.ref-number',
      '[class*="oem"]', '[class*="cross"]', '[class*="ref"]',
    ];
    const oemNumbers = [];
    for (const sel of oemSelectors) {
      document.querySelectorAll(sel).forEach((el) => {
        const text = el.textContent.trim();
        if (text) oemNumbers.push(text);
      });
    }

    // ── Vehicle application / fitment ────────────────────────────────────────
    const fitmentSelectors = [
      '.application', '.fitment', '.vehicle-list', '.car-list',
      '[class*="application"]', '[class*="fitment"]', '[class*="vehicle"]',
      '.applicable-car', '.oe-application',
    ];
    const fitmentData = [];
    for (const sel of fitmentSelectors) {
      document.querySelectorAll(sel).forEach((el) => {
        const text = el.textContent.trim();
        if (text) fitmentData.push(text);
      });
    }

    // ── Category breadcrumb ──────────────────────────────────────────────────
    const breadcrumbs = Array.from(
      document.querySelectorAll(
        '.breadcrumb a, .breadcrumb li, nav.breadcrumb span, ' +
        '[class*="breadcrumb"] a, [class*="breadcrumb"] span'
      )
    )
      .map((el) => el.textContent.trim())
      .filter(Boolean);

    // ── Description ──────────────────────────────────────────────────────────
    const descSelectors = [
      '.product-description', '.goods-description', '.item-desc',
      '.description', '.detail-desc', '[class*="description"]',
    ];
    let description = '';
    for (const sel of descSelectors) {
      const el = document.querySelector(sel);
      if (el) {
        description = el.textContent.trim().substring(0, 1000);
        break;
      }
    }

    // ── Price ────────────────────────────────────────────────────────────────
    let price = stub.price;
    let currency = '';
    const priceEl = document.querySelector(
      '.price, .amount, [class*="price"], [class*="amount"], .cost'
    );
    if (priceEl) {
      const priceText = priceEl.textContent.trim();
      price = priceText.replace(/[^\d.,]/g, '').trim();
      currency = priceText.replace(/[\d.,\s]/g, '').trim() || 'KRW';
    }

    // ── Category from breadcrumb or headings ─────────────────────────────────
    const category = breadcrumbs[1] || '';
    const subcategory = breadcrumbs[2] || '';

    return {
      partNumber,
      partName,
      category,
      subcategory,
      description,
      imageUrls: Array.from(imageUrls).slice(0, 5),
      specifications,
      oemNumbers,
      fitmentData,
      price,
      currency,
      breadcrumbs,
      pageTitle: document.title,
    };
  }, stub);

  // ── Build the final part record ───────────────────────────────────────────
  const record = {
    partNumber: detail.partNumber || stub.partNumber || '',
    partName: detail.partName || stub.partName || '',
    category: detail.category,
    subcategory: detail.subcategory,
    make: stub.make,
    model: stub.model,
    year: stub.year,
    engine: '',
    description: detail.description,
    imageUrls: detail.imageUrls,
    localImages: [],
    specifications: detail.specifications,
    oemNumbers: detail.oemNumbers,
    fitmentData: detail.fitmentData,
    price: detail.price || '',
    currency: detail.currency || '',
    productUrl: stub.productUrl,
    pageTitle: detail.pageTitle,
    breadcrumbs: detail.breadcrumbs,
    scrapedAt: new Date().toISOString(),
  };

  // ── Download images ───────────────────────────────────────────────────────
  if (CONFIG.downloadImages && detail.imageUrls.length > 0) {
    const partSlug = slugify(
      `${stub.make}-${stub.model}-${stub.year}-${record.partNumber || record.partName}`
    ).substring(0, 80);
    const imgDir = path.join(CONFIG.imagesDir, partSlug);
    fs.mkdirSync(imgDir, { recursive: true });

    for (let i = 0; i < Math.min(detail.imageUrls.length, CONFIG.maxImagesPerPart); i++) {
      const imgUrl = detail.imageUrls[i];
      const ext = imgUrl.split('?')[0].split('.').pop() || 'jpg';
      const destFile = path.join(imgDir, `${i + 1}.${ext}`);
      try {
        await downloadImage(imgUrl, destFile);
        record.localImages.push(path.relative(__dirname, destFile));
      } catch (err) {
        log(`    Image download failed: ${imgUrl} — ${err.message}`);
      }
    }
  }

  return record;
}

// ─── Pagination helper ────────────────────────────────────────────────────────
async function getAllResultPages(page, make, model, year) {
  const allStubs = await extractPartsFromResultsPage(page, make, model, year);

  // Check for pagination
  let currentPage = 1;
  while (true) {
    const nextBtn = await page.$(
      'a.next, button.next, .pagination .next, [class*="paging"] .next, ' +
      'a[aria-label="Next"], .page-next, li.next a, .btn-next'
    );
    if (!nextBtn) break;

    const isDisabled = await nextBtn.evaluate((el) =>
      el.classList.contains('disabled') ||
      el.getAttribute('disabled') !== null ||
      el.getAttribute('aria-disabled') === 'true'
    );
    if (isDisabled) break;

    await nextBtn.click();
    await page.waitForLoadState('networkidle', { timeout: 20000 });
    currentPage++;
    log(`    → Page ${currentPage}`);

    const pageStubs = await extractPartsFromResultsPage(page, make, model, year);
    if (pageStubs.length === 0) break;

    allStubs.push(...pageStubs);
    await sleep(CONFIG.delayBetweenRequests);

    if (currentPage > 50) {
      log('    Pagination cap (50 pages) reached');
      break;
    }
  }

  return allStubs;
}

// ─── Main orchestration ───────────────────────────────────────────────────────
async function main() {
  if (FLAG_DRY_RUN) {
    console.log('DRY RUN — vehicles that would be scraped:');
    const vehicles = brandFilter
      ? VEHICLES.filter((v) => v.make === brandFilter)
      : VEHICLES;
    vehicles.forEach((v) =>
      v.years.forEach((y) => console.log(`  ${v.make} ${v.model} ${y}`))
    );
    return;
  }

  fs.mkdirSync(CONFIG.outputDir, { recursive: true });
  fs.mkdirSync(CONFIG.imagesDir, { recursive: true });

  // ── Load progress for resume ───────────────────────────────────────────────
  const progress = FLAG_RESUME ? (loadJson(CONFIG.progressFile, {}) || {}) : {};
  const allParts = FLAG_RESUME
    ? (loadJson(CONFIG.partsFile, []) || [])
    : [];

  const vehicles = brandFilter
    ? VEHICLES.filter((v) => v.make === brandFilter)
    : VEHICLES;

  log('=== CTR Zimbabwe Car Parts Scraper ===');
  log(`Target: ${CONFIG.baseUrl}`);
  log(`Vehicles: ${vehicles.length} makes/models`);
  log(`Images: ${CONFIG.downloadImages ? 'enabled' : 'disabled'}`);
  log(`Resume: ${FLAG_RESUME}`);

  // ── Launch browser ─────────────────────────────────────────────────────────
  const browser = await chromium.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
    ],
  });

  const context = await browser.newContext({
    userAgent: CONFIG.userAgent,
    viewport: { width: 1920, height: 1080 },
    acceptDownloads: true,
  });

  const page = await context.newPage();

  // ── Detect search method on first load ────────────────────────────────────
  log('\nDetecting site search method...');
  let searchMethod;
  try {
    searchMethod = await detectSearchMethod(page);
    log(`  Selects: ${searchMethod.selects.length}, Text inputs: ${searchMethod.searchInputs.length}, Nav links: ${searchMethod.navLinks.length}`);
    fs.writeFileSync(
      path.join(CONFIG.outputDir, 'search_method.json'),
      JSON.stringify(searchMethod, null, 2)
    );
  } catch (err) {
    log(`  Warning: could not load main page — ${err.message}`);
  }

  // ── Scrape each vehicle ────────────────────────────────────────────────────
  let totalParts = allParts.length;
  let vehiclesDone = 0;

  for (const vehicle of vehicles) {
    const { make, model, years } = vehicle;

    for (const year of years) {
      const vehicleKey = `${make}__${model}__${year}`;

      if (FLAG_RESUME && progress[vehicleKey] === 'done') {
        log(`SKIP (already done): ${make} ${model} ${year}`);
        continue;
      }

      log(`\n[${++vehiclesDone}/${vehicles.reduce((s, v) => s + v.years.length, 0)}] ${make} ${model} ${year}`);

      try {
        const stubs = await searchVehicleParts(page, vehicle, year);

        if (stubs.length === 0) {
          log(`  No results found`);
          progress[vehicleKey] = 'no_results';
          saveJson(CONFIG.progressFile, progress);
          await sleep(CONFIG.delayBetweenRequests);
          continue;
        }

        log(`  Found ${stubs.length} part stubs, fetching details...`);

        // Paginate if needed (already fetched first page stubs via searchVehicleParts)
        // For subsequent pages, we'd need to re-navigate — handled by getAllResultPages
        // if called directly on a results page.

        for (let i = 0; i < stubs.length; i++) {
          const stub = stubs[i];
          if (!stub.productUrl) continue;

          log(`  [${i + 1}/${stubs.length}] ${stub.partName || stub.productUrl}`);

          const part = await scrapePart(page, { ...stub, make, model, year });
          if (part) {
            allParts.push(part);
            totalParts++;
          }

          await sleep(CONFIG.delayBetweenRequests);

          // Save incremental progress every 10 parts
          if (totalParts % 10 === 0) {
            saveJson(CONFIG.partsFile, allParts);
            writeCsv(allParts);
            log(`  [saved] ${totalParts} parts so far`);
          }
        }

        progress[vehicleKey] = 'done';
        saveJson(CONFIG.progressFile, progress);
      } catch (err) {
        log(`  ERROR for ${make} ${model} ${year}: ${err.message}`);
        progress[vehicleKey] = `error:${err.message}`;
        saveJson(CONFIG.progressFile, progress);
      }

      await sleep(CONFIG.delayBetweenVehicles);
    }
  }

  // ── Final save ─────────────────────────────────────────────────────────────
  saveJson(CONFIG.partsFile, allParts);
  writeCsv(allParts);

  await browser.close();

  log(`\n=== Done ===`);
  log(`Total parts scraped: ${allParts.length}`);
  log(`Output: ${CONFIG.outputDir}`);
  log(`  parts.json  — structured data`);
  log(`  parts.csv   — flat spreadsheet`);
  log(`  images/     — downloaded part images`);
}

main().catch((err) => {
  console.error('Fatal:', err);
  process.exit(1);
});
