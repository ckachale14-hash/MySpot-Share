/**
 * Firestore security-rules unit tests.
 * Run with:  firebase emulators:exec --only firestore --project demo-myspot "npm --prefix test test"
 *
 * These assert the trust boundaries described in docs/03-security-rules.md:
 * users can't self-grant privileges, can't touch others' data, and money/
 * verification collections reject all client writes.
 */
const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, updateDoc, Timestamp } = require("firebase/firestore");

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-myspot",
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, "../firestore.rules"), "utf8"),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

function db(uid, claims = {}) {
  return testEnv.authenticatedContext(uid, claims).firestore();
}

async function seed(pathStr, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), pathStr), data);
  });
}

const baseUser = (uid) => ({
  uid,
  displayName: "Test",
  verified: false,
  premium: false,
  role: "user",
  onboardingComplete: false,
  followerCount: 0,
  followingCount: 0,
  postCount: 0,
});

describe("users", () => {
  it("owner can read and edit their profile", async () => {
    await seed("users/alice", baseUser("alice"));
    await assertSucceeds(getDoc(doc(db("alice"), "users/alice")));
    await assertSucceeds(updateDoc(doc(db("alice"), "users/alice"), { bio: "hi" }));
  });

  it("user cannot self-verify", async () => {
    await seed("users/alice", baseUser("alice"));
    await assertFails(updateDoc(doc(db("alice"), "users/alice"), { verified: true }));
  });

  it("user cannot grant themselves admin", async () => {
    await seed("users/alice", baseUser("alice"));
    await assertFails(updateDoc(doc(db("alice"), "users/alice"), { role: "admin" }));
  });

  it("user cannot inflate their follower count", async () => {
    await seed("users/alice", baseUser("alice"));
    await assertFails(updateDoc(doc(db("alice"), "users/alice"), { followerCount: 9999 }));
  });
});

describe("payments & subscriptions (server-owned)", () => {
  it("rejects all client writes to payments", async () => {
    await assertFails(setDoc(doc(db("alice"), "payments/p1"), { userId: "alice", amount: 100 }));
  });

  it("lets a user read only their own subscription", async () => {
    await seed("subscriptions/alice", { plan: "pro", status: "active" });
    await assertSucceeds(getDoc(doc(db("alice"), "subscriptions/alice")));
    await assertFails(getDoc(doc(db("bob"), "subscriptions/alice")));
  });
});

describe("conversations", () => {
  it("only members can read", async () => {
    await seed("conversations/c1", { memberIds: ["alice", "carol"] });
    await assertSucceeds(getDoc(doc(db("alice"), "conversations/c1")));
    await assertFails(getDoc(doc(db("bob"), "conversations/c1")));
  });
});

describe("verification", () => {
  it("can be created only as pending_payment", async () => {
    await assertSucceeds(
      setDoc(doc(db("alice"), "verificationRequests/r1"), {
        userId: "alice",
        status: "pending_payment",
        subjectType: "user",
        subjectId: "alice",
      })
    );
    await assertFails(
      setDoc(doc(db("alice"), "verificationRequests/r2"), {
        userId: "alice",
        status: "in_review",
        subjectType: "user",
        subjectId: "alice",
      })
    );
  });
});

describe("posts (P1)", () => {
  it("author can create a public post with zeroed counters", async () => {
    await assertSucceeds(
      setDoc(doc(db("alice"), "posts/p1"), {
        authorId: "alice",
        type: "text",
        text: "hello",
        visibility: "public",
      })
    );
  });

  it("rejects a post that seeds its own ranking score", async () => {
    await assertFails(
      setDoc(doc(db("alice"), "posts/p2"), {
        authorId: "alice",
        visibility: "public",
        score: 9999,
      })
    );
  });

  it("rejects a post authored as someone else", async () => {
    await assertFails(
      setDoc(doc(db("bob"), "posts/p3"), { authorId: "alice", visibility: "public" })
    );
  });
});

describe("likes (P1)", () => {
  it("a user may like as themselves, not as others", async () => {
    await seed("posts/p10", { authorId: "carol", visibility: "public" });
    await assertSucceeds(setDoc(doc(db("alice"), "posts/p10/likes/alice"), {}));
    await assertFails(setDoc(doc(db("alice"), "posts/p10/likes/bob"), {}));
  });
});

describe("poll votes (P1)", () => {
  it("votes as self with an int option; rejects others and non-int", async () => {
    await seed("posts/pp", { authorId: "carol", type: "poll", visibility: "public" });
    await assertSucceeds(
      setDoc(doc(db("alice"), "posts/pp/votes/alice"), { option: 1 })
    );
    await assertFails(
      setDoc(doc(db("alice"), "posts/pp/votes/bob"), { option: 1 })
    );
    await assertFails(
      setDoc(doc(db("alice"), "posts/pp/votes/alice"), { option: "two" })
    );
  });

  it("a poll cannot be created with a pre-seeded tally", async () => {
    await assertFails(
      setDoc(doc(db("alice"), "posts/pp2"), {
        authorId: "alice",
        type: "poll",
        visibility: "public",
        poll: { options: ["a", "b"], totalVotes: 5, tally: { "0": 5 } },
      })
    );
    await assertSucceeds(
      setDoc(doc(db("alice"), "posts/pp3"), {
        authorId: "alice",
        type: "poll",
        visibility: "public",
        poll: { options: ["a", "b"], totalVotes: 0, tally: {} },
      })
    );
  });
});

describe("blocks", () => {
  it("a user manages their own block list, not someone else's", async () => {
    await assertSucceeds(
      setDoc(doc(db("alice"), "users/alice/blocks/bob"), {})
    );
    await assertFails(
      setDoc(doc(db("alice"), "users/bob/blocks/carol"), {})
    );
  });
});

describe("follows (P1)", () => {
  it("edge id must match the follower; can't forge another's follow", async () => {
    await assertSucceeds(
      setDoc(doc(db("alice"), "follows/alice_bob"), {
        followerId: "alice",
        followingId: "bob",
      })
    );
    await assertFails(
      setDoc(doc(db("alice"), "follows/bob_carol"), {
        followerId: "alice",
        followingId: "carol",
      })
    );
  });
});

describe("comments (P1)", () => {
  it("author must be the signer", async () => {
    await assertSucceeds(
      setDoc(doc(db("alice"), "posts/pc/comments/c1"), {
        authorId: "alice",
        text: "nice",
      })
    );
    await assertFails(
      setDoc(doc(db("alice"), "posts/pc/comments/c2"), {
        authorId: "bob",
        text: "spoofed",
      })
    );
  });
});

describe("stories (P1)", () => {
  it("requires authorId == signer and a timestamp expiry", async () => {
    await assertSucceeds(
      setDoc(doc(db("alice"), "stories/s1"), {
        authorId: "alice",
        type: "text",
        text: "hi",
        expiresAt: Timestamp.fromMillis(Date.now() + 86400000),
      })
    );
    await assertFails(
      setDoc(doc(db("alice"), "stories/s2"), {
        authorId: "bob",
        expiresAt: Timestamp.fromMillis(Date.now() + 86400000),
      })
    );
  });
});

describe("founder journeys (P1)", () => {
  it("author can publish; cannot self-feature", async () => {
    await assertSucceeds(
      setDoc(doc(db("alice"), "founderJourneys/j1"), {
        authorId: "alice",
        title: "From 0 to 1",
        featured: false,
      })
    );
    await assertFails(
      setDoc(doc(db("alice"), "founderJourneys/j2"), {
        authorId: "alice",
        title: "Boosted",
        featured: true,
      })
    );
  });
});

describe("businesses", () => {
  it("owner creates unverified; cannot self-verify", async () => {
    await assertSucceeds(
      setDoc(doc(db("alice"), "businesses/b1"), {
        ownerId: "alice",
        name: "Acme",
        verified: false,
      })
    );
    await assertFails(
      setDoc(doc(db("alice"), "businesses/b2"), {
        ownerId: "alice",
        name: "X",
        verified: true,
      })
    );
  });

  it("owner cannot flip verified on update", async () => {
    await seed("businesses/b3", {
      ownerId: "alice",
      name: "Acme",
      verified: false,
      ratingCount: 0,
    });
    await assertSucceeds(updateDoc(doc(db("alice"), "businesses/b3"), { description: "hi" }));
    await assertFails(updateDoc(doc(db("alice"), "businesses/b3"), { verified: true }));
  });
});

describe("business reviews", () => {
  it("rating must be 1..5 and authored by the signer", async () => {
    await assertSucceeds(
      setDoc(doc(db("alice"), "businesses/b3/reviews/alice"), { rating: 5, text: "great" })
    );
    await assertFails(
      setDoc(doc(db("alice"), "businesses/b3/reviews/alice"), { rating: 6, text: "bad" })
    );
    await assertFails(
      setDoc(doc(db("alice"), "businesses/b3/reviews/bob"), { rating: 5 })
    );
  });
});

describe("payment intents (P2)", () => {
  it("owner reads own intent; others can't; clients never write", async () => {
    await seed("paymentIntents/premium_alice_1", {
      userId: "alice",
      purpose: "premium",
      status: "pending",
    });
    await assertSucceeds(
      getDoc(doc(db("alice"), "paymentIntents/premium_alice_1"))
    );
    await assertFails(getDoc(doc(db("bob"), "paymentIntents/premium_alice_1")));
    await assertFails(
      setDoc(doc(db("alice"), "paymentIntents/forged"), {
        userId: "alice",
        status: "succeeded",
      })
    );
  });
});

describe("video jobs (AI)", () => {
  it("owner reads own; others can't; clients never write", async () => {
    await seed("videoJobs/v1", { userId: "alice", status: "queued" });
    await assertSucceeds(getDoc(doc(db("alice"), "videoJobs/v1")));
    await assertFails(getDoc(doc(db("bob"), "videoJobs/v1")));
    await assertFails(
      setDoc(doc(db("alice"), "videoJobs/forged"), { userId: "alice" })
    );
  });
});

describe("reports (moderation)", () => {
  it("a user files an open report as themselves; can't preset resolved or forge reporter", async () => {
    await assertSucceeds(
      setDoc(doc(db("alice"), "reports/r1"), {
        reporterId: "alice",
        targetType: "post",
        targetId: "p1",
        reason: "Spam",
        status: "open",
      })
    );
    await assertFails(
      setDoc(doc(db("alice"), "reports/r2"), {
        reporterId: "alice",
        targetType: "post",
        targetId: "p1",
        status: "resolved",
      })
    );
    await assertFails(
      setDoc(doc(db("alice"), "reports/r3"), {
        reporterId: "bob",
        targetType: "post",
        targetId: "p1",
        status: "open",
      })
    );
  });

  it("non-moderators cannot read the report queue", async () => {
    await seed("reports/r4", {
      reporterId: "alice",
      targetType: "post",
      targetId: "p1",
      status: "open",
    });
    await assertFails(getDoc(doc(db("bob"), "reports/r4")));
    await assertSucceeds(getDoc(doc(db("mod", { role: "moderator" }), "reports/r4")));
  });
});
