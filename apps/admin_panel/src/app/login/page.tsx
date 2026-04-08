'use client';

import React, { useState, useEffect } from 'react';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '@/lib/firebaseClient';
import { signInWithGoogle, verifyAdminClaim, handleAuthError, signOutUser } from '@/lib/auth';
import { useRouter, useSearchParams } from 'next/navigation';
import { Shield, Mail, Lock, Eye, EyeOff, AlertCircle, Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { useAuth } from '@/components/AuthProvider';


export default function LoginPage() {
    return (
        <React.Suspense fallback={
            <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
                <div className="w-12 h-12 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
            </div>
        }>
            <LoginForm />
        </React.Suspense>
    );
}

function LoginForm() {
    const { isAdmin } = useAuth();
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const router = useRouter();
    const searchParams = useSearchParams();

    useEffect(() => {
        const errorMsg = searchParams.get('error');
        if (errorMsg === 'not_admin') {
            setError('Access Denied: Your account does not have administrator privileges.');
        }
    }, [searchParams]);

    const handleEmailLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            const userCredential = await signInWithEmailAndPassword(auth, email, password);
            const user = userCredential.user;

            await user.getIdToken(true);
            const tokenResult = await user.getIdTokenResult();
            console.log('Email Login Claims:', tokenResult.claims);

            const authorizedEmail = 'cryptosourav23@gmail.com';

            if (tokenResult.claims.admin === true && (user.email === authorizedEmail)) {
                router.push('/admin');
            } else {
                await signOutUser();
                setError(user.email === authorizedEmail
                    ? 'Access Denied: Your account claim is missing administrative privileges.'
                    : `Access Denied: ${user.email} is not the authorized administrator account.`);
            }
        } catch (err: any) {
            setError(handleAuthError(err));
        } finally {
            setLoading(false);
        }
    };

    const handleGoogleSignIn = async () => {
        setLoading(true);
        setError('');
        try {
            const userCredential = await signInWithGoogle();
            const user = userCredential.user;

            // REQUIREMENT: AFTER successful login, FORCE refresh ID token
            console.log('Refreshing ID token for user:', user.email);
            await user.getIdToken(true);
            const tokenResult = await user.getIdTokenResult();

            // REQUIREMENT: console log to verify claims
            console.log('Login Claims:', tokenResult.claims);

            // REQUIREMENT: Check admin access ONLY after login completes
            const authorizedEmail = 'cryptosourav23@gmail.com';

            if (tokenResult.claims.admin === true && (user.email === authorizedEmail)) {
            console.log('Admin access granted for:', user.email);
            router.push('/admin');
            } else {
                console.log('Access Denied for:', user.email);
                await signOutUser();
                setError(user.email === authorizedEmail
                    ? 'Access Denied: Your account claim is missing administrative privileges.'
                    : `Access Denied: ${user.email} is not the authorized administrator account.`);
            }
        } catch (err: any) {
            if (err?.code === 'auth/popup-closed-by-user') return;
            const msg = handleAuthError(err);
            if (msg) setError(msg);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4 sm:p-6 lg:p-8">
            <div className="max-w-md w-full bg-white rounded-2xl shadow-xl overflow-hidden border border-slate-100">
                <div className="p-8 pb-6 text-center">
                    <div className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-indigo-600 text-white mb-6 shadow-lg shadow-indigo-200">
                        <Shield className="w-6 h-6" />
                    </div>
                    <h1 className="text-2xl font-bold text-slate-900 mb-2">Welcome Back</h1>
                    <p className="text-slate-500 text-sm">Sign in to access the admin dashboard</p>
                </div>

                <div className="px-8 pb-8">
                    {/* Error Display */}
                    {error && (
                        <div className="mb-6 p-4 bg-red-50 border border-red-100 rounded-lg flex items-start gap-3 text-red-600 animate-in fade-in slide-in-from-top-2">
                            <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
                            <div className="text-sm font-medium leading-tight">{error}</div>
                        </div>
                    )}

                    {/* Google Sign In */}
                    <button
                        onClick={handleGoogleSignIn}
                        disabled={loading}
                        className="w-full h-12 bg-white border border-slate-200 hover:bg-slate-50 hover:border-slate-300 text-slate-700 font-medium rounded-xl flex items-center justify-center gap-3 transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-slate-200 disabled:opacity-50 disabled:cursor-not-allowed group"
                    >
                        {loading ? (
                            <Loader2 className="w-5 h-5 animate-spin text-indigo-600" />
                        ) : (
                            <>
                                <svg className="w-5 h-5" viewBox="0 0 24 24">
                                    <path
                                        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                                        fill="#4285F4"
                                    />
                                    <path
                                        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                                        fill="#34A853"
                                    />
                                    <path
                                        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.84z"
                                        fill="#FBBC05"
                                    />
                                    <path
                                        d="M12 4.36c1.61 0 3.06.56 4.23 1.64l3.18-3.18C17.46 1.01 14.97 0 12 0 7.7 0 3.99 2.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                                        fill="#EA4335"
                                    />
                                </svg>
                                <span>Sign in with Google</span>
                            </>
                        )}
                    </button>

                    <div className="relative my-8">
                        <div className="absolute inset-0 flex items-center">
                            <div className="w-full border-t border-slate-200"></div>
                        </div>
                        <div className="relative flex justify-center text-xs uppercase">
                            <span className="bg-white px-2 text-slate-400 font-medium tracking-wider">Or continue with email</span>
                        </div>
                    </div>

                    {/* Email Form */}
                    <form onSubmit={handleEmailLogin} className="space-y-5">
                        <Input
                            label="Email Address"
                            type="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            placeholder="name@company.com"
                            autoComplete="email"
                            required
                            leftIcon={<Mail className="w-4 h-4" />}
                            className="h-11"
                            disabled={loading}
                        />

                        <div className="space-y-1.5">
                            <Input
                                label="Password"
                                type={showPassword ? 'text' : 'password'}
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                placeholder="Enter your password"
                                autoComplete="current-password"
                                required
                                disabled={loading}
                                leftIcon={<Lock className="w-4 h-4" />}
                                rightIcon={
                                    <button
                                        type="button"
                                        onClick={() => setShowPassword(!showPassword)}
                                        className="text-slate-400 hover:text-slate-600 transition-colors"
                                        tabIndex={-1}
                                    >
                                        {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                                    </button>
                                }
                                className="h-11"
                            />
                            <div className="flex justify-between items-center px-0.5">
                                <label className="flex items-center gap-2 cursor-pointer group">
                                    <input
                                        type="checkbox"
                                        className="w-3.5 h-3.5 rounded border-slate-300 text-indigo-600 focus:ring-indigo-600/20"
                                    />
                                    <span className="text-xs text-slate-500 group-hover:text-slate-700 transition-colors">Remember me</span>
                                </label>
                                <button type="button" className="text-xs font-semibold text-indigo-600 hover:text-indigo-700 transition-colors">
                                    Forgot password?
                                </button>
                            </div>
                        </div>

                        <Button
                            type="submit"
                            className="w-full h-11 mt-2 shadow-lg shadow-indigo-100"
                            isLoading={loading}
                        >
                            Sign in
                        </Button>
                    </form>
                </div>

                <div className="bg-slate-50 p-4 text-center border-t border-slate-100">
                    <p className="text-xs text-slate-400 font-medium">
                        Protected by HomeFix Secure Access
                    </p>
                </div>
            </div>
        </div>
    );
}

