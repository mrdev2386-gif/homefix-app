import { initializeApp, getApps, getApp, FirebaseApp } from "firebase/app";
import { getFirestore, Firestore } from "firebase/firestore";

const firebaseConfig = {
    apiKey: "AIzaSyADfM4cMfTlz3Cth0QwalYntQv3AoU9daI",
    authDomain: "homefix-aa42d.firebaseapp.com",
    projectId: "homefix-aa42d",
    storageBucket: "homefix-aa42d.firebasestorage.app",
    messagingSenderId: "663243229047",
    appId: "1:663243229047:web:generic_web_id"
};

// Initialize Firebase (shared config - NO AUTH here to prevent SSR issues)
const app: FirebaseApp = !getApps().length ? initializeApp(firebaseConfig) : getApp();
const db: Firestore = getFirestore(app);

export { app, db };
