import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

// Initialize the Admin SDK exactly once (Functions may reuse warm instances).
if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();
export const adminAuth = getAuth();
