'use client';

import { getAuth, Auth } from "firebase/auth";
import { getFunctions, Functions } from "firebase/functions";
import { app } from "./firebase";

// Client-only Firebase instances (auth-aware)
// MUST only be imported in client components
export const auth: Auth = getAuth(app);

// Functions initialized on the same app as auth so ID token is auto-attached
export const functions: Functions = getFunctions(app, 'asia-south1');
