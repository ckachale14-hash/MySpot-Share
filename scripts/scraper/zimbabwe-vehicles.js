/**
 * Most common vehicles in Zimbabwe based on market data.
 * Zimbabwe primarily imports Japanese used cars (Toyota, Honda, Nissan, Mazda)
 * and some newer Asian brands. These are the most frequently seen makes/models.
 */
const ZIMBABWE_VEHICLES = [
  // ─── TOYOTA (dominant market share ~60%) ───────────────────────────────────
  { make: 'TOYOTA', model: 'COROLLA',       years: [2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014] },
  { make: 'TOYOTA', model: 'HILUX',         years: [2005, 2008, 2010, 2012, 2015, 2016, 2018] },
  { make: 'TOYOTA', model: 'LAND CRUISER',  years: [2000, 2005, 2008, 2010, 2015] },
  { make: 'TOYOTA', model: 'VITZ',          years: [2002, 2005, 2008, 2010, 2012, 2014] },
  { make: 'TOYOTA', model: 'RAV4',          years: [2005, 2008, 2010, 2013, 2016] },
  { make: 'TOYOTA', model: 'CAMRY',         years: [2002, 2006, 2009, 2012, 2015] },
  { make: 'TOYOTA', model: 'HIACE',         years: [2005, 2008, 2010, 2014] },
  { make: 'TOYOTA', model: 'PRADO',         years: [2005, 2008, 2010, 2014] },
  { make: 'TOYOTA', model: 'WISH',          years: [2003, 2005, 2007, 2009] },
  { make: 'TOYOTA', model: 'IST',           years: [2002, 2004, 2007] },

  // ─── HONDA (~15% market share) ─────────────────────────────────────────────
  { make: 'HONDA', model: 'FIT',            years: [2002, 2004, 2007, 2009, 2011, 2014] },
  { make: 'HONDA', model: 'CIVIC',          years: [2001, 2004, 2006, 2009, 2012, 2015] },
  { make: 'HONDA', model: 'CR-V',           years: [2002, 2005, 2007, 2010, 2013] },
  { make: 'HONDA', model: 'ACCORD',         years: [2003, 2006, 2009, 2012] },
  { make: 'HONDA', model: 'JAZZ',           years: [2002, 2004, 2007, 2009] },

  // ─── NISSAN (~10% market share) ────────────────────────────────────────────
  { make: 'NISSAN', model: 'MARCH',         years: [2003, 2005, 2007, 2010, 2013] },
  { make: 'NISSAN', model: 'TIIDA',         years: [2004, 2006, 2009, 2012] },
  { make: 'NISSAN', model: 'X-TRAIL',       years: [2001, 2004, 2007, 2010, 2014] },
  { make: 'NISSAN', model: 'NAVARA',        years: [2005, 2008, 2011, 2015] },
  { make: 'NISSAN', model: 'NOTE',          years: [2005, 2007, 2009, 2012] },
  { make: 'NISSAN', model: 'HARDBODY',      years: [2005, 2008, 2011] },

  // ─── MAZDA (~5% market share) ──────────────────────────────────────────────
  { make: 'MAZDA', model: 'DEMIO',          years: [2003, 2005, 2007, 2010, 2013] },
  { make: 'MAZDA', model: 'FAMILIA',        years: [2000, 2003, 2006] },
  { make: 'MAZDA', model: 'AXELA',          years: [2004, 2007, 2010, 2014] },
  { make: 'MAZDA', model: 'BT-50',          years: [2006, 2009, 2012, 2016] },

  // ─── MITSUBISHI ────────────────────────────────────────────────────────────
  { make: 'MITSUBISHI', model: 'COLT',      years: [2004, 2006, 2009, 2012] },
  { make: 'MITSUBISHI', model: 'PAJERO',    years: [2000, 2004, 2007, 2010] },
  { make: 'MITSUBISHI', model: 'L200',      years: [2006, 2009, 2012, 2015] },

  // ─── ISUZU ─────────────────────────────────────────────────────────────────
  { make: 'ISUZU', model: 'D-MAX',          years: [2004, 2007, 2010, 2014, 2017] },
  { make: 'ISUZU', model: 'KB',             years: [2004, 2007, 2010] },

  // ─── SUZUKI ────────────────────────────────────────────────────────────────
  { make: 'SUZUKI', model: 'SWIFT',         years: [2005, 2007, 2010, 2013] },
  { make: 'SUZUKI', model: 'ALTO',          years: [2004, 2006, 2009, 2012] },
];

module.exports = ZIMBABWE_VEHICLES;
