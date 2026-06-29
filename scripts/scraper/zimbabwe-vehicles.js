/**
 * Most common vehicles in Zimbabwe based on market data.
 *
 * Zimbabwe primarily imports Japanese used cars (grey imports) — the searchLoc
 * for CTR's catalog is therefore 'JP' for most models. Right-hand-drive African
 * spec vehicles from South Africa use 'ZA'.
 *
 * CTR model names must match the site's own naming (visible in Google-indexed
 * URLs like /Catalogue/SearchList?brand=TOYOTA&model=Corolla).
 * The `ctrModel` field overrides `model` when the two differ.
 *
 * Sources:
 *   carbarn.co.zw, classifieds.co.zw, autotrader.co.zw (2024-2026 listings data)
 */
const ZIMBABWE_VEHICLES = [
  // ─── TOYOTA (dominant ~60% of market) ────────────────────────────────────
  // Corolla / Axio — the most-seen car on Zimbabwean roads
  { make: 'TOYOTA', model: 'Corolla',        ctrModel: 'Corolla',      searchLoc: 'JP', years: [2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014] },
  // Corolla Axio (11th-gen saloon sold in Japan, very common grey import)
  { make: 'TOYOTA', model: 'Corolla Axio',   ctrModel: 'Corolla Axio', searchLoc: 'JP', years: [2006, 2008, 2010, 2012, 2014, 2016] },
  // Vitz (Yaris in export markets) — top budget segment
  { make: 'TOYOTA', model: 'Vitz',           ctrModel: 'Vitz',         searchLoc: 'JP', years: [2002, 2005, 2008, 2010, 2012, 2014] },
  // Allion — popular mid-size saloon grey import
  { make: 'TOYOTA', model: 'Allion',         ctrModel: 'Allion',       searchLoc: 'JP', years: [2001, 2004, 2007, 2010, 2014] },
  // Hilux — the dominant pickup / workhorse
  { make: 'TOYOTA', model: 'Hilux',          ctrModel: 'Hilux',        searchLoc: 'JP', years: [2005, 2008, 2010, 2012, 2015, 2016, 2018] },
  // Land Cruiser — common 4x4 and mine/safari vehicle
  { make: 'TOYOTA', model: 'Land Cruiser',   ctrModel: 'Land Cruiser', searchLoc: 'JP', years: [2000, 2005, 2008, 2010, 2015] },
  // Prado — smaller Land Cruiser, very popular
  { make: 'TOYOTA', model: 'Land Cruiser Prado', ctrModel: 'Land Cruiser Prado', searchLoc: 'JP', years: [2003, 2005, 2008, 2010, 2014] },
  // RAV4
  { make: 'TOYOTA', model: 'RAV4',           ctrModel: 'RAV4',         searchLoc: 'JP', years: [2005, 2008, 2010, 2013, 2016] },
  // Camry
  { make: 'TOYOTA', model: 'Camry',          ctrModel: 'Camry',        searchLoc: 'JP', years: [2002, 2006, 2009, 2012, 2015] },
  // HiAce — minibus / commuter staple
  { make: 'TOYOTA', model: 'HiAce',          ctrModel: 'HiAce',        searchLoc: 'JP', years: [2005, 2008, 2010, 2014] },
  // Wish — family MPV grey import
  { make: 'TOYOTA', model: 'Wish',           ctrModel: 'Wish',         searchLoc: 'JP', years: [2003, 2005, 2007, 2009] },
  // Aqua (Prius C) — growing hybrid segment
  { make: 'TOYOTA', model: 'Aqua',           ctrModel: 'Aqua',         searchLoc: 'JP', years: [2012, 2014, 2016, 2018] },
  // Prius — popular hybrid
  { make: 'TOYOTA', model: 'Prius',          ctrModel: 'Prius',        searchLoc: 'JP', years: [2004, 2006, 2009, 2012, 2016] },
  // IST — compact hatchback
  { make: 'TOYOTA', model: 'Ist',            ctrModel: 'Ist',          searchLoc: 'JP', years: [2002, 2004, 2007] },
  // Premio — saloon, common grey import
  { make: 'TOYOTA', model: 'Premio',         ctrModel: 'Premio',       searchLoc: 'JP', years: [2001, 2004, 2007, 2010] },

  // ─── HONDA (~15% market share) ────────────────────────────────────────────
  // Fit/Jazz — top budget hatchback alongside Vitz
  { make: 'HONDA', model: 'Fit',             ctrModel: 'Fit',          searchLoc: 'JP', years: [2002, 2004, 2007, 2009, 2011, 2014] },
  // Civic
  { make: 'HONDA', model: 'Civic',           ctrModel: 'Civic',        searchLoc: 'JP', years: [2001, 2004, 2006, 2009, 2012, 2015] },
  // CR-V
  { make: 'HONDA', model: 'CR-V',            ctrModel: 'CR-V',         searchLoc: 'JP', years: [2002, 2005, 2007, 2010, 2013] },
  // Accord
  { make: 'HONDA', model: 'Accord',          ctrModel: 'Accord',       searchLoc: 'JP', years: [2003, 2006, 2009, 2012] },
  // Jazz (same as Fit but sold under Jazz name in some ZIM imports)
  { make: 'HONDA', model: 'Jazz',            ctrModel: 'Jazz',         searchLoc: 'JP', years: [2002, 2004, 2007, 2009] },

  // ─── NISSAN (~10% market share) ───────────────────────────────────────────
  // March / Micra
  { make: 'NISSAN', model: 'March',          ctrModel: 'March',        searchLoc: 'JP', years: [2003, 2005, 2007, 2010, 2013] },
  // Tiida
  { make: 'NISSAN', model: 'Tiida',          ctrModel: 'Tiida',        searchLoc: 'JP', years: [2004, 2006, 2009, 2012] },
  // X-Trail
  { make: 'NISSAN', model: 'X-Trail',        ctrModel: 'X-Trail',      searchLoc: 'JP', years: [2001, 2004, 2007, 2010, 2014] },
  // Navara pickup
  { make: 'NISSAN', model: 'Navara',         ctrModel: 'Navara',       searchLoc: 'JP', years: [2005, 2008, 2011, 2015] },
  // Note — small MPV
  { make: 'NISSAN', model: 'Note',           ctrModel: 'Note',         searchLoc: 'JP', years: [2005, 2007, 2009, 2012] },

  // ─── MAZDA (~5% market share) ─────────────────────────────────────────────
  // Demio (Mazda2)
  { make: 'MAZDA', model: 'Demio',           ctrModel: 'Demio',        searchLoc: 'JP', years: [2003, 2005, 2007, 2010, 2013] },
  // Axela (Mazda3)
  { make: 'MAZDA', model: 'Axela',           ctrModel: 'Axela',        searchLoc: 'JP', years: [2004, 2007, 2010, 2014] },
  // Familia (323)
  { make: 'MAZDA', model: 'Familia',         ctrModel: 'Familia',      searchLoc: 'JP', years: [2000, 2003, 2006] },
  // BT-50 pickup
  { make: 'MAZDA', model: 'BT-50',           ctrModel: 'BT-50',        searchLoc: 'JP', years: [2006, 2009, 2012, 2016] },

  // ─── MITSUBISHI ───────────────────────────────────────────────────────────
  { make: 'MITSUBISHI', model: 'Colt',       ctrModel: 'Colt',         searchLoc: 'JP', years: [2004, 2006, 2009, 2012] },
  { make: 'MITSUBISHI', model: 'Pajero',     ctrModel: 'Pajero',       searchLoc: 'JP', years: [2000, 2004, 2007, 2010] },
  { make: 'MITSUBISHI', model: 'L200',       ctrModel: 'L200',         searchLoc: 'JP', years: [2006, 2009, 2012, 2015] },
  { make: 'MITSUBISHI', model: 'Galant',     ctrModel: 'Galant',       searchLoc: 'JP', years: [2004, 2007, 2010] },

  // ─── ISUZU ────────────────────────────────────────────────────────────────
  { make: 'ISUZU', model: 'D-Max',           ctrModel: 'D-Max',        searchLoc: 'JP', years: [2004, 2007, 2010, 2014, 2017] },
  { make: 'ISUZU', model: 'KB',              ctrModel: 'KB',           searchLoc: 'ZA', years: [2004, 2007, 2010] },

  // ─── SUZUKI ───────────────────────────────────────────────────────────────
  { make: 'SUZUKI', model: 'Swift',          ctrModel: 'Swift',        searchLoc: 'JP', years: [2005, 2007, 2010, 2013] },
  { make: 'SUZUKI', model: 'Alto',           ctrModel: 'Alto',         searchLoc: 'JP', years: [2004, 2006, 2009, 2012] },

  // ─── SUBARU (growing presence) ────────────────────────────────────────────
  { make: 'SUBARU', model: 'Forester',       ctrModel: 'Forester',     searchLoc: 'JP', years: [2003, 2006, 2008, 2011, 2014] },
  { make: 'SUBARU', model: 'Impreza',        ctrModel: 'Impreza',      searchLoc: 'JP', years: [2003, 2006, 2009, 2012] },
];

// CTR part category groups — pass one or more to filter results
const CTR_GROUPS = [
  'SUSPENSION',   // ball joints, control arms, bushings, stabilizer links
  'STEERING',     // tie rod ends, inner tie rods, steering racks
  'BRAKE',        // brake pads, discs, calipers
  'DRIVESHAFT',   // CV joints, drive shafts
  'WHEEL_HUB',    // wheel bearings, hub assemblies
];

// Location codes used by CTR's catalog (determines which OEM number set to show)
const CTR_SEARCH_LOCATIONS = {
  JP: 'Japan (grey imports — most relevant for Zimbabwe)',
  ZA: 'South Africa (RHD African-spec vehicles)',
  GLOBAL: 'Global (all markets)',
  RU: 'Russia',
  KR: 'Korea',
  DE: 'Germany / Europe',
};

module.exports = { ZIMBABWE_VEHICLES, CTR_GROUPS, CTR_SEARCH_LOCATIONS };
