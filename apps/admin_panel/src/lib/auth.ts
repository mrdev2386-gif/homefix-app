'use client';

import {
  signInWithPopup,
  GoogleAuthProvider,
  UserCredential,
  User,
  IdTokenResult,
  signOut as firebaseSignOut
} from 'firebase/auth';
import { auth } from './firebaseClient';

/**
 * Sign in with Google using popup
 */
export async function signInWithGoogle(): Promise<UserCredential> {
  const provider = new GoogleAuthProvider();
  provider.setCustomParameters({
    prompt: 'select_account'
  });

  return signInWithPopup(auth, provider);
}

/**
 * Verify if user has admin claim
 */
export async function verifyAdminClaim(user: User): Promise<boolean> {
  try {
    const tokenResult = await getAdminToken(user);
    if (process.env.NODE_ENV === 'development') {
      console.log('User Claims:', tokenResult.claims);
    }
    return !!tokenResult.claims.admin;
  } catch (error) {
    console.error('Error verifying admin claim:', error);
    return false;
  }
}

/**
 * Get fresh ID token with claims
 */
export async function getAdminToken(user: User): Promise<IdTokenResult> {
  // Requirement: AFTER login, FORCE refresh ID token
  await user.getIdToken(true);
  const tokenResult = await user.getIdTokenResult();
  return tokenResult;
}

/**
 * Sign out and clear state
 */
export async function signOutUser(): Promise<void> {
  return firebaseSignOut(auth);
}

/**
 * Handle Firebase authentication errors
 */
export function handleAuthError(error: any): string {
  const errorCode = error?.code || '';

  switch (errorCode) {
    case 'auth/popup-blocked':
      return 'Popup blocked. Please enable popups and try again.';
    case 'auth/popup-closed-by-user':
      return ''; // Silent - user intentionally cancelled
    case 'auth/network-request-failed':
      return 'Network error. Please check your connection.';
    case 'auth/too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'auth/unauthorized-domain':
      return 'This domain is not authorized. Please contact support.';
    case 'auth/user-not-found':
    case 'auth/wrong-password':
      return 'Invalid email or password. Please try again.';
    default:
      return error?.message || 'Authentication failed. Please try again.';
  }
}
