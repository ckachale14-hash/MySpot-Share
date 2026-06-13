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
const { doc, getDoc, setDoc, updateDoc } = require("firebase/firestore");

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
