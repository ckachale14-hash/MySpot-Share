# CTR Zimbabwe Car Parts Scraper

Scrapes **https://aftermarket.ctr.co.kr** for parts that fit the most common vehicles in Zimbabwe — Toyota, Honda, Nissan, Mazda, Mitsubishi, Isuzu, and Suzuki.

## Output

| File | Description |
|------|-------------|
| `output/parts.json` | All parts as structured JSON |
| `output/parts.csv` | Flat CSV, importable into Excel / Google Sheets |
| `output/images/<part-slug>/` | Downloaded part images |
| `output/report.json` | Summary counts by make / category |
| `output/progress.json` | Checkpoint file for `--resume` |

Each part record contains:
- `partNumber` — CTR part number
- `partName` — part description
- `category` / `subcategory` — e.g. Suspension / Ball Joint
- `make` / `model` / `year` — vehicle fitment
- `specifications` — array of `{ key, value }` pairs
- `oemNumbers` — OEM / cross-reference numbers
- `fitmentData` — raw fitment text from the site
- `imageUrls` — original image URLs on the CTR server
- `localImages` — paths to downloaded images
- `price` / `currency`
- `productUrl` — link back to the CTR detail page

## Setup

```bash
cd scripts/scraper
npm install
npx playwright install chromium   # only needed if Chromium is not pre-installed
```

## Usage

### Step 1 — Explore (recommended first run)

Maps the site structure before committing to a full scrape.

```bash
node explore.js
```

Outputs:
- `output/main_page.png` — screenshot
- `output/page_structure.json` — nav, selects, forms
- `output/network_requests.json` — all XHR/fetch calls captured

Review these files and adjust the scraper selectors if the site's markup doesn't match the defaults.

### Step 2 — Full scrape

```bash
node scraper.js
```

### Resume an interrupted scrape

```bash
node scraper.js --resume
```

### Scrape a single brand only

```bash
node scraper.js --brand TOYOTA
node scraper.js --brand HONDA
```

### Dry run (print vehicles without fetching)

```bash
node scraper.js --dry-run
```

### Step 3 — Post-process

Deduplicates, normalises part numbers, infers categories, rebuilds CSV.

```bash
node postprocess.js
```

## Vehicles targeted

Zimbabwe's most common makes and models (based on import data):

| Make | Models |
|------|--------|
| Toyota (~60%) | Corolla, Hilux, Land Cruiser, Vitz, RAV4, Camry, Hiace, Prado, Wish, IST |
| Honda (~15%) | Fit/Jazz, Civic, CR-V, Accord |
| Nissan (~10%) | March, Tiida, X-Trail, Navara, Note, Hardbody |
| Mazda (~5%) | Demio, Familia, Axela, BT-50 |
| Mitsubishi | Colt, Pajero, L200 |
| Isuzu | D-Max, KB |
| Suzuki | Swift, Alto |

## Adapting the scraper

If the CTR site uses a different DOM structure than the defaults:

1. Run `node explore.js` and open `output/page_structure.json`
2. Find the correct CSS selectors for search inputs, result cards, and detail fields
3. Update the selector arrays in `scraper.js`:
   - `cardSelectors` in `extractPartsFromResultsPage()`
   - `partNumberSelectors`, `nameSelectors`, `imageSelectors` in `scrapePart()`
4. If the site uses an API (visible in `output/network_requests.json`), you can replace
   the page-based approach with direct API calls for speed

## Notes

- The scraper respects the site by sleeping 1.5 s between part pages and 3 s between vehicles
- Images are saved to `output/images/<make-model-year-partno>/`
- Progress is saved every 10 parts — use `--resume` after any interruption
- The site is in Korean; part names may appear in Korean — `postprocess.js` preserves them as-is
