/**
 * MySpot Share — demo/seed data.
 *
 * Populates Firestore with realistic, Africa-first demo content so the feed,
 * discover, journeys, business directory and stories look alive for screenshots
 * and first-run. Idempotent: deterministic document ids, so re-running overwrites
 * rather than duplicating.
 *
 * Run against the EMULATOR (recommended):
 *   firebase emulators:exec --only firestore --project demo-myspot "node seed/seed.js"
 *   # or, with the emulator already running:
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 node seed/seed.js
 *
 * Run against a DEV project (writes for real — uses Admin credentials):
 *   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json \
 *   GCLOUD_PROJECT=myspot-dev node seed/seed.js
 *
 * Optional: also seed messages + notifications FOR a signed-in test user, so
 * the Messages and Notifications tabs are populated for that account:
 *   SEED_FOR_UID=<your-test-uid> node seed/seed.js
 */
const admin = require("firebase-admin");

const projectId =
  process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT || "demo-myspot";
admin.initializeApp({ projectId });
const db = admin.firestore();
const { Timestamp, FieldValue } = admin.firestore;

const NOW = Date.now();
const ago = (mins) => Timestamp.fromMillis(NOW - mins * 60000);
const avatar = (n) => `https://i.pravatar.cc/300?img=${n}`;
const pic = (k) => `https://picsum.photos/seed/${k}/900/600`;

// ----------------------------------------------------------------- users
const USERS = [
  { id: "seed_amara", handle: "amaraokeke", name: "Amara Okeke", img: 47,
    type: "business_owner", industry: "Technology", verified: true, premium: true,
    bio: "Founder & CEO at PayFlow • building inclusive fintech for African SMEs 🇳🇬",
    followers: 12840, following: 312, posts: 86 },
  { id: "seed_kwame", handle: "kwamebuilds", name: "Kwame Mensah", img: 12,
    type: "business_owner", industry: "Food & Beverage", verified: true, premium: false,
    bio: "Bootstrapped Accra's favourite jollof chain from one stall to 9 branches 🇬🇭",
    followers: 8210, following: 540, posts: 132 },
  { id: "seed_zanele", handle: "zanele", name: "Zanele Dlamini", img: 5,
    type: "creator", industry: "Media & Content", verified: true, premium: true,
    bio: "Storyteller. I help founders tell theirs. 🎙️ Joburg",
    followers: 24500, following: 198, posts: 410 },
  { id: "seed_david", handle: "davidmwangi", name: "David Mwangi", img: 33,
    type: "investor", industry: "Finance", verified: true, premium: false,
    bio: "Early-stage investor • ex-banker • cheque sizes $10k–250k • Nairobi 🇰🇪",
    followers: 15300, following: 421, posts: 64 },
  { id: "seed_fatima", handle: "fatimab", name: "Fatima Bello", img: 44,
    type: "business_owner", industry: "Retail & E-commerce", verified: false, premium: false,
    bio: "Founder, Bello Beauty • clean skincare made in Lagos",
    followers: 3120, following: 280, posts: 51 },
  { id: "seed_aisha", handle: "aishah", name: "Aisha Hassan", img: 32,
    type: "business_owner", industry: "Health & Wellness", verified: true, premium: false,
    bio: "Telehealth for mothers • founder @MamaCare • Dar es Salaam 🇹🇿",
    followers: 6740, following: 190, posts: 73 },
  { id: "seed_thabo", handle: "thabo", name: "Thabo Nkosi", img: 51,
    type: "investor", industry: "Professional Services", verified: false, premium: false,
    bio: "Startup lawyer & angel • I read your term sheet so you don't have to.",
    followers: 4980, following: 333, posts: 29 },
  { id: "seed_chidi", handle: "chidieze", name: "Chidi Eze", img: 15,
    type: "creator", industry: "Technology", verified: false, premium: true,
    bio: "Dev tooling • I tweet code & ship side projects 🚀",
    followers: 9050, following: 612, posts: 287 },
];
const byId = Object.fromEntries(USERS.map((u) => [u.id, u]));
const authorRef = (u) => ({
  uid: u.id, handle: u.handle, displayName: u.name, photoUrl: avatar(u.img),
  verified: u.verified,
});

async function seedUsers() {
  const batch = db.batch();
  for (const u of USERS) {
    batch.set(db.doc(`users/${u.id}`), {
      uid: u.id, handle: u.handle, displayName: u.name, bio: u.bio,
      photoUrl: avatar(u.img), coverUrl: pic(`cover_${u.handle}`),
      accountType: u.type, industry: u.industry,
      verified: u.verified, premium: u.premium, role: "user",
      onboardingComplete: true, isNewUser: false,
      followerCount: u.followers, followingCount: u.following, postCount: u.posts,
      createdAt: ago(60 * 24 * 90), lastActiveAt: ago(30),
    });
    batch.set(db.doc(`handles/${u.handle}`), { uid: u.id, createdAt: ago(60 * 24 * 90) });
  }
  await batch.commit();
  return USERS.length;
}

// ----------------------------------------------------------------- posts
const POSTS = [
  { id: "seed_post_1", by: "seed_amara", mins: 35, likes: 412, comments: 2, shares: 31,
    text: "We just crossed ₦1B processed on PayFlow 🎉 Three years ago this was a Google Sheet and a dream. To every founder grinding in silence: keep going. #fintech #africa #startup" },
  { id: "seed_post_2", by: "seed_kwame", mins: 90, type: "image", img: "jollof",
    likes: 980, comments: 1, shares: 64,
    text: "Branch #9 is officially open in Kumasi! 🔥 The secret was never the recipe — it was hiring people who care. #foodbusiness #ghana" },
  { id: "seed_post_3", by: "seed_zanele", mins: 150, type: "poll", likes: 233, comments: 0, shares: 12,
    text: "Founders — what stops you from sharing your story publicly?",
    poll: { options: ["Fear of judgement", "No time", "Don't know where to start", "Nothing, I post!"],
      tally: { "0": 142, "1": 88, "2": 61, "3": 45 }, totalVotes: 336 } },
  { id: "seed_post_4", by: "seed_david", mins: 220, likes: 521, comments: 1, shares: 47,
    text: "Unpopular take: most African startups don't need more funding, they need more distribution. Solve how you'll reach 1,000 paying customers before you raise. #investing #vc" },
  { id: "seed_post_5", by: "seed_aisha", mins: 320, type: "image", img: "mamacare",
    likes: 188, comments: 0, shares: 9,
    text: "10,000 mothers have now had a consultation through MamaCare 💙 Healthcare access shouldn't depend on your postcode. #healthtech #impact" },
  { id: "seed_post_6", by: "seed_chidi", mins: 500, type: "article", img: "devtools",
    title: "How we cut our cloud bill by 71% in one weekend",
    likes: 642, comments: 0, shares: 120,
    text: "Everyone obsesses over revenue, but your margins hide in your infrastructure. Here's exactly what we changed — caching, right-sizing, and killing three zombie services nobody owned. The numbers, the mistakes, and the scripts we used are all below…\n\nFirst, we instrumented everything. You cannot cut what you cannot see…" },
  { id: "seed_post_7", by: "seed_fatima", mins: 720, likes: 96, comments: 0, shares: 4,
    text: "First wholesale order shipped today 📦 From my kitchen table to 40 stores nationwide. Bootstrapping is hard but it's MINE. #smallbusiness #beauty #lagos" },
  { id: "seed_post_8", by: "seed_thabo", mins: 1010, likes: 154, comments: 0, shares: 22,
    text: "PSA: that 50/50 co-founder split with no vesting will end your company. Vest over 4 years with a 1-year cliff. Always. #legal #founders" },
];

async function seedPosts() {
  const batch = db.batch();
  for (const p of POSTS) {
    const u = byId[p.by];
    const doc = {
      authorId: u.id, author: authorRef(u),
      type: p.type || "text", text: p.text,
      media: p.img ? [{ url: pic(p.img), type: "image" }] : [],
      hashtags: (p.text.match(/#(\w+)/g) || []).map((h) => h.slice(1).toLowerCase()),
      mentions: [], visibility: "public",
      likeCount: p.likes || 0, commentCount: p.comments || 0,
      shareCount: p.shares || 0, saveCount: Math.floor((p.likes || 0) / 7),
      viewCount: (p.likes || 0) * 9, score: p.likes || 0,
      removed: false, isSponsored: false, createdAt: p.mins ? ago(p.mins) : FieldValue.serverTimestamp(),
    };
    if (p.title) doc.title = p.title;
    if (p.poll) doc.poll = p.poll;
    batch.set(db.doc(`posts/${p.id}`), doc);
  }
  await batch.commit();

  // a few comments so post detail looks alive
  const comments = [
    { post: "seed_post_1", by: "seed_david", text: "Massive. The distribution discipline shows." },
    { post: "seed_post_1", by: "seed_zanele", text: "Founder story of the week 👏" },
    { post: "seed_post_2", by: "seed_fatima", text: "Congratulations Kwame! The jollof is unmatched 🔥" },
    { post: "seed_post_4", by: "seed_amara", text: "1,000 paying customers > a big round. Co-signed." },
  ];
  const cb = db.batch();
  comments.forEach((c, i) => {
    const u = byId[c.by];
    cb.set(db.doc(`posts/${c.post}/comments/seed_c${i}`), {
      authorId: u.id, author: authorRef(u), text: c.text, likeCount: 0,
      createdAt: ago(10 + i),
    });
  });
  await cb.commit();
  return POSTS.length;
}

// -------------------------------------------------------- founder journeys
const JOURNEYS = [
  { id: "seed_journey_1", by: "seed_amara", title: "From a spreadsheet to ₦1B processed",
    industry: "Technology", stage: "growth", amount: 5000, currency: "USD", disclosed: true,
    challenges: ["No banking partner would take us seriously", "Hiring engineers on a tiny budget"],
    mistakes: ["Built for 6 months before talking to a single merchant", "Hired for pedigree over hunger"],
    lessons: ["Distribution beats product polish early", "Your first 10 customers should be on speed-dial"] },
  { id: "seed_journey_2", by: "seed_kwame", title: "One jollof stall to nine branches",
    industry: "Food & Beverage", stage: "scaled", amount: 800, currency: "USD", disclosed: true,
    challenges: ["Cash-flow during the rainy season", "Theft before I fixed processes"],
    mistakes: ["Opened branch #2 too fast, nearly went under", "Didn't track food cost for a year"],
    lessons: ["Systems let you leave and the business still runs", "Hire for character, train for skill"] },
  { id: "seed_journey_3", by: "seed_aisha", title: "Building telehealth mothers actually trust",
    industry: "Health & Wellness", stage: "revenue", amount: 0, currency: "USD", disclosed: false,
    challenges: ["Convincing mothers to trust a phone consult", "Regulatory uncertainty"],
    mistakes: ["Underpriced the first year out of fear"],
    lessons: ["Trust is the product in healthcare", "Charge what it's worth from day one"] },
];

async function seedJourneys() {
  const batch = db.batch();
  for (const j of JOURNEYS) {
    const u = byId[j.by];
    batch.set(db.doc(`founderJourneys/${j.id}`), {
      authorId: u.id, author: authorRef(u), title: j.title, industry: j.industry,
      currentStage: j.stage,
      startupCapital: { amount: j.amount, currency: j.currency, disclosed: j.disclosed },
      timeline: [], challenges: j.challenges, mistakes: j.mistakes, lessons: j.lessons,
      likeCount: 200 + Math.floor(Math.random() * 600), saveCount: 40, viewCount: 3000,
      featured: j.id === "seed_journey_1",
      createdAt: ago(60 * 24 * 10), updatedAt: ago(60 * 24 * 2),
    });
  }
  await batch.commit();
  return JOURNEYS.length;
}

// ---------------------------------------------------------------- businesses
const BUSINESSES = [
  { id: "seed_biz_1", owner: "seed_amara", name: "PayFlow", category: "Technology",
    desc: "Payments & working-capital for African SMEs.", logo: "payflow",
    products: ["Checkout", "Invoicing"], services: ["Merchant loans"], rating: 4.8, reviews: 126,
    phone: "+234 800 000 0001", email: "hello@payflow.africa", website: "https://payflow.africa",
    address: "Yaba, Lagos", verified: true },
  { id: "seed_biz_2", owner: "seed_kwame", name: "Kwame's Kitchen", category: "Food & Beverage",
    desc: "Ghana's favourite jollof, now in 9 branches.", logo: "kwame",
    products: ["Jollof bowls", "Catering"], services: ["Events"], rating: 4.9, reviews: 412,
    phone: "+233 20 000 0002", email: "eat@kwames.gh", website: "https://kwames.gh",
    address: "Osu, Accra", verified: true },
  { id: "seed_biz_3", owner: "seed_fatima", name: "Bello Beauty", category: "Retail & E-commerce",
    desc: "Clean, affordable skincare made in Lagos.", logo: "bello",
    products: ["Cleanser", "Shea balm"], services: [], rating: 4.6, reviews: 58,
    phone: "+234 800 000 0003", email: "care@bellobeauty.ng", website: "https://bellobeauty.ng",
    address: "Lekki, Lagos", verified: false },
  { id: "seed_biz_4", owner: "seed_aisha", name: "MamaCare", category: "Health & Wellness",
    desc: "Telehealth & support for mothers, on any phone.", logo: "mamacare",
    products: ["Consults"], services: ["Antenatal support"], rating: 4.9, reviews: 203,
    phone: "+255 700 000 004", email: "hello@mamacare.co.tz", website: "https://mamacare.co.tz",
    address: "Masaki, Dar es Salaam", verified: true },
];

async function seedBusinesses() {
  const batch = db.batch();
  for (const b of BUSINESSES) {
    const avg = b.rating, count = b.reviews;
    batch.set(db.doc(`businesses/${b.id}`), {
      ownerId: b.owner, name: b.name, category: b.category, description: b.desc,
      logoUrl: pic(b.logo), products: b.products, services: b.services,
      contact: { phone: b.phone, email: b.email, whatsapp: b.phone, address: b.address },
      links: { website: b.website },
      verified: b.verified, ratingAvg: avg, ratingCount: count,
      ratingSum: Math.round(avg * count), followerCount: Math.floor(count * 3.5),
      createdAt: ago(60 * 24 * 30),
    });
  }
  await batch.commit();

  // a couple of reviews on the top business
  const reviewers = ["seed_david", "seed_zanele", "seed_thabo"];
  const rb = db.batch();
  reviewers.forEach((rid, i) => {
    const u = byId[rid];
    rb.set(db.doc(`businesses/seed_biz_2/reviews/${u.id}`), {
      rating: 5, text: ["Best jollof in Accra, full stop.", "Catered our launch — flawless.",
        "Consistent quality across every branch."][i],
      author: authorRef(u), createdAt: ago(60 * (i + 1)),
    });
  });
  await rb.commit();
  return BUSINESSES.length;
}

// ------------------------------------------------------------------- stories
async function seedStories() {
  const expires = Timestamp.fromMillis(NOW + 20 * 3600 * 1000);
  const items = [
    { id: "seed_story_1", by: "seed_amara", type: "text", text: "Shipping day 🚀", bg: 0xff0052b4 },
    { id: "seed_story_2", by: "seed_kwame", type: "image", img: "story_kwame" },
    { id: "seed_story_3", by: "seed_zanele", type: "text", text: "New episode out now 🎙️", bg: 0xff329b32 },
    { id: "seed_story_4", by: "seed_chidi", type: "image", img: "story_chidi" },
    { id: "seed_story_5", by: "seed_fatima", type: "text", text: "Restock alert ✨", bg: 0xfffa4b4b },
  ];
  const batch = db.batch();
  for (const s of items) {
    const u = byId[s.by];
    const doc = {
      authorId: u.id, author: authorRef(u), type: s.type, viewCount: 120,
      createdAt: ago(60), expiresAt: expires,
    };
    if (s.type === "text") { doc.text = s.text; doc.bgColor = s.bg; }
    else { doc.media = { url: pic(s.img) }; }
    batch.set(db.doc(`stories/${s.id}`), doc);
  }
  await batch.commit();
  return items.length;
}

// -------------------------------------------------------------------- follows
async function seedFollows() {
  // everyone follows Amara, Zanele & David; a few cross-follows for texture.
  const targets = ["seed_amara", "seed_zanele", "seed_david"];
  const batch = db.batch();
  let n = 0;
  for (const u of USERS) {
    for (const t of targets) {
      if (u.id === t) continue;
      batch.set(db.doc(`follows/${u.id}_${t}`), {
        followerId: u.id, followingId: t, createdAt: ago(60 * 24 * 5),
      });
      n++;
    }
  }
  await batch.commit();
  return n;
}

// --------------------------------------- optional: per-test-user inbox/notifs
async function seedForUser(uid) {
  // DM conversations between the test user and two seed users
  const partners = ["seed_amara", "seed_david"];
  for (const pid of partners) {
    const p = byId[pid];
    const ids = [uid, p.id].sort();
    const cid = `${ids[0]}_${ids[1]}`;
    await db.doc(`conversations/${cid}`).set({
      memberIds: [uid, p.id],
      members: {
        [p.id]: authorRef(p),
        [uid]: { uid, handle: "you", displayName: "You", photoUrl: "", verified: false },
      },
      type: "direct", unread: { [uid]: 1, [p.id]: 0 },
      lastMessage: { text: pid === "seed_amara" ? "Welcome to MySpot! 👋" : "Saw your profile — let's talk.",
        senderId: p.id, type: "text", createdAt: ago(5) },
      createdAt: ago(120), updatedAt: ago(5),
    });
    const msgs = pid === "seed_amara"
      ? ["Hey, welcome to MySpot Share! 👋", "Loved your first post — keep going!"]
      : ["Hi — I invest in early-stage founders.", "Saw your profile. Free for a call this week?"];
    const mb = db.batch();
    msgs.forEach((m, i) => mb.set(db.doc(`conversations/${cid}/messages/seed_m${i}`), {
      senderId: p.id, type: "text", text: m, readBy: [p.id], createdAt: ago(8 - i),
    }));
    await mb.commit();
  }

  // notifications for the test user
  const nb = db.batch();
  const notifs = [
    { by: "seed_zanele", type: "follow", text: null },
    { by: "seed_kwame", type: "like", postId: "seed_post_1", text: "liked your post" },
    { by: "seed_david", type: "comment", postId: "seed_post_1", text: "commented: great milestone!" },
  ];
  notifs.forEach((x, i) => {
    const u = byId[x.by];
    nb.set(db.doc(`users/${uid}/notifications/seed_n${i}`), {
      type: x.type, actor: authorRef(u), postId: x.postId || null,
      text: x.text, read: false, createdAt: ago(15 + i * 20),
    });
  });
  await nb.commit();
  return partners.length;
}

// ----------------------------------------------------------------------- run
(async () => {
  const usingEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
  console.log(`Seeding project "${projectId}" ${usingEmulator ? "(emulator)" : "(LIVE — admin)"}…`);
  const u = await seedUsers();    console.log(`  users:        ${u}`);
  const p = await seedPosts();    console.log(`  posts:        ${p} (+ comments)`);
  const j = await seedJourneys(); console.log(`  journeys:     ${j}`);
  const b = await seedBusinesses(); console.log(`  businesses:   ${b} (+ reviews)`);
  const s = await seedStories();  console.log(`  stories:      ${s}`);
  const f = await seedFollows();  console.log(`  follows:      ${f}`);
  const forUid = process.env.SEED_FOR_UID;
  if (forUid) {
    const c = await seedForUser(forUid);
    console.log(`  inbox/notifs: seeded for ${forUid} (${c} conversations)`);
  } else {
    console.log("  (set SEED_FOR_UID=<your-test-uid> to also seed Messages + Notifications)");
  }
  console.log("✅ Seed complete.");
  process.exit(0);
})().catch((e) => { console.error("Seed failed:", e); process.exit(1); });
