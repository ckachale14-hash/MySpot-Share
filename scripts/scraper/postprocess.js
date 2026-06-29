/**
 * postprocess.js — Clean and enrich parts.json after scraping.
 *
 * - Deduplicates by part number
 * - Normalises part numbers (strips whitespace, uppercase)
 * - Infers category from part name keywords
 * - Rebuilds the CSV
 * - Outputs a summary report
 *
 * Usage:  node postprocess.js
 */

'use strict';

const fs = require('fs');
const path = require('path');

const OUT_DIR = path.join(__dirname, 'output');
const PARTS_FILE = path.join(OUT_DIR, 'parts.json');
const CSV_FILE = path.join(OUT_DIR, 'parts.csv');
const REPORT_FILE = path.join(OUT_DIR, 'report.json');

// Keyword → category mapping for inference
const CATEGORY_KEYWORDS = {
  'Suspension': ['suspension', 'shock', 'strut', 'spring', 'absorber', 'arm', 'ball joint', 'bushing', 'sway bar', 'stabilizer', 'link'],
  'Steering': ['steering', 'tie rod', 'rack', 'pinion', 'column', 'knuckle', 'king pin'],
  'Brakes': ['brake', 'disc', 'rotor', 'caliper', 'pad', 'shoe', 'drum', 'master cylinder'],
  'Engine': ['engine', 'timing', 'valve', 'piston', 'gasket', 'belt', 'chain', 'oil seal', 'bearing', 'camshaft', 'crankshaft'],
  'Transmission': ['transmission', 'gearbox', 'clutch', 'shaft', 'cv joint', 'axle', 'differential'],
  'Electrical': ['sensor', 'switch', 'relay', 'lamp', 'light', 'alternator', 'starter', 'battery'],
  'Cooling': ['radiator', 'coolant', 'thermostat', 'water pump', 'fan', 'hose'],
  'Fuel System': ['fuel', 'injector', 'pump', 'filter', 'carburetor'],
  'Exhaust': ['exhaust', 'muffler', 'catalytic', 'manifold', 'pipe'],
  'Body': ['door', 'hood', 'fender', 'bumper', 'mirror', 'glass', 'window', 'wiper'],
  'Drivetrain': ['drive', 'propeller', 'transfer case', '4wd', 'awd'],
};

function inferCategory(partName, existingCategory) {
  if (existingCategory && existingCategory !== 'Unknown') return existingCategory;
  const lower = (partName || '').toLowerCase();
  for (const [cat, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    if (keywords.some((kw) => lower.includes(kw))) return cat;
  }
  return 'Other';
}

function normalisePartNumber(raw) {
  if (!raw) return '';
  return String(raw).trim().toUpperCase().replace(/\s+/g, '');
}

function main() {
  if (!fs.existsSync(PARTS_FILE)) {
    console.error('parts.json not found. Run the scraper first.');
    process.exit(1);
  }

  const raw = JSON.parse(fs.readFileSync(PARTS_FILE, 'utf8'));
  console.log(`Loaded ${raw.length} raw records`);

  // ── Normalise ──────────────────────────────────────────────────────────────
  const normalised = raw.map((p) => ({
    ...p,
    partNumber: normalisePartNumber(p.partNumber),
    partName: (p.partName || '').trim(),
    category: inferCategory(p.partName, p.category),
    make: (p.make || '').toUpperCase(),
    model: (p.model || '').toUpperCase(),
  }));

  // ── Deduplicate: keep latest record per (partNumber + make + model + year) ─
  const seen = new Map();
  for (const p of normalised) {
    const key = `${p.partNumber}__${p.make}__${p.model}__${p.year}`;
    if (!p.partNumber || !seen.has(key)) {
      seen.set(key, p);
    }
  }
  const deduped = Array.from(seen.values());
  console.log(`After deduplication: ${deduped.length} records`);

  // ── Sort: by make, model, year, category, partName ────────────────────────
  deduped.sort((a, b) => {
    const fields = ['make', 'model', 'year', 'category', 'partName'];
    for (const f of fields) {
      const cmp = String(a[f] ?? '').localeCompare(String(b[f] ?? ''));
      if (cmp !== 0) return cmp;
    }
    return 0;
  });

  // ── Save cleaned JSON ──────────────────────────────────────────────────────
  fs.writeFileSync(PARTS_FILE, JSON.stringify(deduped, null, 2));
  console.log(`Saved: parts.json (${deduped.length} parts)`);

  // ── Rebuild CSV ────────────────────────────────────────────────────────────
  const headers = [
    'part_number', 'part_name', 'category', 'subcategory',
    'make', 'model', 'year', 'description',
    'specifications', 'oem_numbers', 'fitment',
    'price', 'currency', 'image_urls', 'local_images', 'product_url',
  ];
  const esc = (v) => {
    const s = String(v ?? '').replace(/"/g, '""');
    return /[,"\n]/.test(s) ? `"${s}"` : s;
  };
  const rows = [headers.join(',')];
  for (const p of deduped) {
    rows.push([
      p.partNumber,
      p.partName,
      p.category,
      p.subcategory,
      p.make,
      p.model,
      p.year,
      p.description,
      (p.specifications || []).map((s) => `${s.key}:${s.value}`).join('; '),
      (p.oemNumbers || []).join('; '),
      (p.fitmentData || []).join('; '),
      p.price,
      p.currency,
      (p.imageUrls || []).join('; '),
      (p.localImages || []).join('; '),
      p.productUrl,
    ].map(esc).join(','));
  }
  fs.writeFileSync(CSV_FILE, rows.join('\n'));
  console.log(`Saved: parts.csv`);

  // ── Summary report ─────────────────────────────────────────────────────────
  const byMake = {};
  const byCategory = {};
  const byModel = {};

  for (const p of deduped) {
    byMake[p.make] = (byMake[p.make] || 0) + 1;
    byCategory[p.category] = (byCategory[p.category] || 0) + 1;
    const mk = `${p.make} ${p.model}`;
    byModel[mk] = (byModel[mk] || 0) + 1;
  }

  const report = {
    totalParts: deduped.length,
    byMake: Object.entries(byMake).sort((a, b) => b[1] - a[1]),
    byCategory: Object.entries(byCategory).sort((a, b) => b[1] - a[1]),
    topModels: Object.entries(byModel).sort((a, b) => b[1] - a[1]).slice(0, 20),
    partsWithImages: deduped.filter((p) => p.imageUrls?.length > 0).length,
    partsWithPartNumber: deduped.filter((p) => p.partNumber).length,
    partsWithPrice: deduped.filter((p) => p.price).length,
    generatedAt: new Date().toISOString(),
  };

  fs.writeFileSync(REPORT_FILE, JSON.stringify(report, null, 2));

  console.log('\n=== Summary ===');
  console.log(`Total parts: ${report.totalParts}`);
  console.log(`With images: ${report.partsWithImages}`);
  console.log(`With part numbers: ${report.partsWithPartNumber}`);
  console.log(`With prices: ${report.partsWithPrice}`);
  console.log('\nBy make:');
  report.byMake.forEach(([k, v]) => console.log(`  ${k.padEnd(15)} ${v}`));
  console.log('\nBy category:');
  report.byCategory.forEach(([k, v]) => console.log(`  ${k.padEnd(20)} ${v}`));
  console.log(`\nReport saved: output/report.json`);
}

main();
