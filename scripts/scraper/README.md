# CTR Zimbabwe Car Parts Scraper

Scrapes **https://aftermarket.ctr.co.kr** for parts that fit the most common
vehicles in Zimbabwe. Uses CTR's own URL-based catalog API (discovered from
Google-indexed pages) — faster and more reliable than dropdown automation.

## How the CTR catalog API works

CTR exposes its catalog through clean, parameterised URLs:

```
# Parts list for a vehicle + category
/Catalogue/SearchList?location=JP&searchLocation=global&brand=TOYOTA&model=Corolla&year2=2010&groups=SUSPENSION

# Part detail page
/Catalogue/SearchDetail?loc=global&searchLoc=JP&oe_id=9083662
```

Key parameters:

| Parameter | Values | Meaning |
|-----------|--------|---------|
| `location` / `searchLoc` | `JP`, `ZA`, `KR`, `RU`, `DE`, `global` | Market / OEM number set |
| `brand` | `TOYOTA`, `HONDA`, `NISSAN`, … | Vehicle make |
| `model` | `Corolla`, `Hilux`, `Fit`, … | Vehicle model (CTR's own name) |
| `year2` | `2005`, `2010`, … | Model year |
| `groups` | `SUSPENSION`, `STEERING`, `BRAKE`, … | Part category |
| `oe_id` | numeric | Internal OEM part ID (used for detail pages) |

The scraper uses `JP` (Japanese market) as the primary location because most
Zimbabwe vehicles are Japanese grey imports. `ZA` (South Africa) is added as a
secondary pass for locally-sold models.

## Output

| File | Description |
|------|-------------|
| `output/parts.json` | All parts as structured JSON |
| `output/parts.csv` | Flat CSV for Excel / Google Sheets |
| `output/images/<slug>/` | Downloaded part images (up to 6 per part) |
| `output/report.json` | Summary: counts by make, model, category |
| `output/progress.json` | Checkpoint for `--resume` |

### Part record schema

```json
{
  "partNumber":    "CB0248R",
  "partName":      "Ball Joint Lower",
  "category":      "Wheel Suspension",
  "subcategory":   "Ball Joint",
  "make":          "TOYOTA",
  "model":         "Corolla",
  "year":          2010,
  "engine":        "1ZR-FE",
  "description":   "...",
  "specifications": [{ "key": "Thread Size", "value": "M12x1.5" }],
  "oemNumbers":    ["43340-02030", "43340-02040"],
  "fitmentData":   ["2007-2013 Toyota Corolla (E150)"],
  "imageUrls":     ["https://..."],
  "localImages":   ["output/images/toyota-corolla-2010-cb0248r/1.jpg"],
  "price":         "12500",
  "currency":      "KRW",
  "productUrl":    "https://aftermarket.ctr.co.kr/Catalogue/SearchDetail?...",
  "oeId":          "1178548",
  "searchLoc":     "JP",
  "scrapedAt":     "2026-06-29T10:00:00.000Z"
}
```

## Setup

```bash
cd scripts/scraper
npm install
npx playwright install chromium   # skip if Chromium is already installed
```

## Usage

### Step 1 — Explore (strongly recommended before the first full run)

Probes the site with known-good URLs, takes screenshots, dumps selectors.

```bash
node explore.js
```

Open `output/*.png` to visually confirm the page loaded and has results.
Open `output/*_structure.json` → `classNames` if you need to adjust selectors.
Open `output/detail_structure.json` to verify part data is being extracted.

### Step 2 — Full scrape

```bash
node scraper.js
```

### Resume after interruption

```bash
node scraper.js --resume
```

### Scrape a single brand or category

```bash
node scraper.js --brand TOYOTA
node scraper.js --group SUSPENSION
node scraper.js --brand HONDA --group STEERING
```

### Dry run — print all search URLs without fetching

```bash
node scraper.js --dry-run
```

### Step 3 — Post-process

Deduplicates, normalises part numbers, infers categories, rebuilds CSV + report.

```bash
node postprocess.js
```

## Vehicles targeted

Zimbabwe primarily imports Japanese used vehicles (grey imports). The most
commonly seen makes/models on Zimbabwean roads (sources: carbarn.co.zw,
classifieds.co.zw, autotrader.co.zw):

| Make | Most common models |
|------|--------------------|
| **Toyota** (~60%) | Corolla, Corolla Axio, Vitz, Allion, Premio, Hilux, Land Cruiser, Prado, RAV4, Camry, HiAce, Wish, Aqua, Prius |
| **Honda** (~15%) | Fit, Jazz, Civic, CR-V, Accord |
| **Nissan** (~10%) | March, Tiida, X-Trail, Navara, Note |
| **Mazda** (~5%) | Demio, Axela, Familia, BT-50 |
| **Mitsubishi** | Colt, Pajero, L200, Galant |
| **Isuzu** | D-Max, KB |
| **Suzuki** | Swift, Alto |
| **Subaru** | Forester, Impreza |

## Adapting selectors

If `explore.js` shows rows but `scraper.js` extracts 0 parts, the CTR site
likely changed its markup. Steps to fix:

1. Run `node explore.js` and open `output/*_structure.json`
2. Look at `usedSelector` — if empty, no row selector matched
3. Find the correct selector in `classNames` or `bodyHtmlSnippet`
4. Update `parseListPage()` → `rowSelectors` array in `scraper.js`
5. For detail fields: check `detail_structure.json` → `tables[].rows` to see
   the actual cell text, then update the selectors in `scrapeDetail()`

## Part categories (CTR `groups` parameter)

| Group | Contents |
|-------|----------|
| `SUSPENSION` | Ball joints, control arms, bushings, stabilizer links (7 512 parts) |
| `STEERING` | Tie rod ends, inner tie rods, rack & pinion (4 203 parts) |
| `BRAKE` | Brake discs, pads, calipers, drums |
| `DRIVESHAFT` | CV joints, drive shafts, axles |
| `WHEEL_HUB` | Wheel bearings, hub assemblies |
