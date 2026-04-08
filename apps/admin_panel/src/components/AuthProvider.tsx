'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { onAuthStateChanged, User } from 'firebase/auth';
import { useRouter, usePathname } from 'next/navigation';
import { auth } from '@/lib/firebaseClient';
import { signOutUser } from '@/lib/auth';

interface AuthContextType {
    user: User | null;
    loading: boolean;
    isAdmin: boolean;
    signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
    user: null,
    loading: true,
    isAdmin: false,
    signOut: async () => { }
});

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
    const [user, setUser] = useState<User | null>(null);
    const [isAdmin, setIsAdmin] = useState(false);
    const [loading, setLoading] = useState(true);
    const router = useRouter();
    const pathname = usePathname();

    // 1. Initial Auth Check (Runs ONCE on mount)
    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
            if (currentUser) {
                try {
                    // Force refresh token to get latest claims as per request
                    await currentUser.getIdToken(true);
                    const tokenResult = await currentUser.getIdTokenResult();

                    if (tokenResult.claims.admin === true) {
                        setUser(currentUser);
                        setIsAdmin(true);
                    } else {
                        console.error('Non-admin user attempted access');
                        await signOutUser();
                        setUser(null);
                        setIsAdmin(false);
                    }
                } catch (error) {
                    console.error('Auth verification error:', error);
                    setUser(null);
                    setIsAdmin(false);
                }
            } else {
                setUser(null);
                setIsAdmin(false);
            }
            setLoading(false); // This acts as authReady
        });

        return () => unsubscribe();
    }, []);


    // 2. Route Protection (Runs on path change, but fast)
    useEffect(() => {
        if (loading) return;

        const publicPaths = ['/', '/login'];
        const isPublicPath = publicPaths.includes(pathname);

        if (!user && !isPublicPath) {
            router.push('/login');
        } else if (user && !isAdmin && !isPublicPath) {
            router.push('/login?error=not_admin');
        } else if (user && isAdmin && pathname === '/login') {
            router.push('/admin');
        }
    }, [user, isAdmin, loading, pathname, router]);

    const handleSignOut = async () => {
        try {
            await signOutUser();
            setUser(null);
            setIsAdmin(false);
            router.push('/login');
        } catch (error) {
            console.error('Error signing out:', error);
        }
    };

    if (loading) {
        return (
            <div className="h-screen w-full flex flex-col items-center justify-center bg-[#020617] gap-4">
                <div className="relative">
                    <div className="w-12 h-12 border-4 border-indigo-500/20 rounded-full"></div>
                    <div className="w-12 h-12 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin absolute top-0 left-0"></div>
                </div>
                <p className="text-indigo-400/80 text-[10px] font-black uppercase tracking-[0.3em] animate-pulse">Verifying Credentials</p>
            </div>
        );
    }

    return (
        <AuthContext.Provider value={{ user, loading, isAdmin, signOut: handleSignOut }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => useContext(AuthContext);
