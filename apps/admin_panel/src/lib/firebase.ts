'use client';
import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
    apiKey: "AIzaSyADfM4cMfTlz3Cth0QwalYntQv3AoU9daI",
    authDomain: "homefix-aa42d.firebaseapp.com",
    projectId: "homefix-aa42d",
    storageBucket: "homefix-aa42d.firebasestorage.app",
    messagingSenderId: "663243229047",
    appId: "1:663243229047:web:generic_web_id"
};

import { getFunctions } from "firebase/functions";

let app, auth, db, storage, functions;

if (typeof window !== 'undefined') {
    app = !getApps().length ? initializeApp(firebaseConfig) : getApp();
    auth = getAuth(app);
    db = getFirestore(app);
    storage = getStorage(app);
    functions = getFunctions(app);
}

export { app, auth, db, storage, functions };
