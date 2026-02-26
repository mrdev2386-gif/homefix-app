'use client';

import { useEffect, useState, useCallback } from 'react';
import { 
    Search, Mail, Smartphone, 
    Activity, ShieldAlert, ShieldCheck, Clock, Hash,
    Eye, ChevronLeft, ChevronRight, Users
} from 'lucide-react';

import { db } from '@/lib/firebase';
import { 
    collection, 
    query, 
    orderBy, 
    limit, 
    startAfter, 
    getDocs, 
    getCountFromServer,
    Timestamp 
} from 'firebase/firestore';
import { adminApi } from '@/lib/admin-api';
import CustomerDetailDrawer from '@/components/CustomerDetailDrawer';

import Table from '@/components/ui/Table';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Card, CardContent } from '@/components/ui/Card';

// Customer type based on Firestore schema
interface Customer {
    uid: string;
    name: string;
    phone: string;
    email?: string;
    photoUrl?: string;
    createdAt: Timestamp | { seconds: number; nanoseconds: number };
    lastActiveAt?: Timestamp | { seconds: number; nanoseconds: number };
    isBlocked?: boolean;
    walletBalance?: number;
    totalBookings?: number;
}

// Skeleton row component
function SkeletonRow() {
    return (
        <tr className="border-b border-slate-800/50">
            <td className="py-4 px-4">
                <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-2xl bg-slate-800 animate-pulse" />
                    <div className="space-y-2">
                        <div className="h-4 w-32 bg-slate-800 rounded animate-pulse" />
                        <div className="h-3 w-20 bg-slate-800 rounded animate-pulse" />
                    </div>
                </div>
            </td>
            <td className="py-4 px-4"><div className="h-4 w-24 bg-slate-800 rounded animate-pulse" /></td>
            <td className="py-4 px-4"><div className="h-4 w-40 bg-slate-800 rounded animate-pulse" /></td>
            <td className="py-4 px-4"><div className="h-4 w-24 bg-slate-800 rounded animate-pulse" /></td>
            <td className="py-4 px-4"><div className="h-4 w-24 bg-slate-800 rounded animate-pulse" /></td>
            <td className="py-4 px-4"><div className="h-6 w-16 bg-slate-800 rounded animate-pulse" /></td>
            <td className="py-4 px-4"><div className="h-8 w-24 bg-slate-800 rounded animate-pulse" /></td>
        </tr>
    );
}

// Empty state component
function EmptyState({ searchTerm }: { searchTerm: string }) {
    return (
        <tr>
            <td colSpan={7} className="py-16">
                <div className="flex flex-col items-center justify-center text-center">
                    <div className="w-20 h-20 rounded-3xl bg-slate-800/50 flex items-center justify-center mb-4">
                        <Users size={40} className="text-slate-600" />
                    </div>
                    <h3 className="text-lg font-black text-white uppercase tracking-wide mb-2">
                        {searchTerm ? 'No Results Found' : 'No Customers Yet'}
                    </h3>
                    <p className="text-sm font-medium text-slate-500 max-w-sm">
                        {searchTerm 
                            ? `No customers found matching "${searchTerm}". Try a different search term.`
                            : 'There are no customers in the system yet.'
                        }
                    </p>
                </div>
            </td>
        </tr>
    );
}

export default function CustomersPage() {
    const [customers, setCustomers] = useState<Customer[]>([]);
    const [totalCount, setTotalCount] = useState(0);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(true);
    const [initialLoading, setInitialLoading] = useState(true);
    const [lastDoc, setLastDoc] = useState<any>(null);
    const [hasMore, setHasMore] = useState(true);
    const [page, setPage] = useState(1);
    const [selectedCustomerId, setSelectedCustomerId] = useState<string | null>(null);
    const [drawerOpen, setDrawerOpen] = useState(false);
    const LIMIT = 20;

    // Debounced search term
    const [debouncedSearch, setDebouncedSearch] = useState('');

    // Debounce search (300ms)
    useEffect(() => {
        const timer = setTimeout(() => {
            setDebouncedSearch(searchTerm);
            setPage(1);
            setLastDoc(null);
        }, 300);
        return () => clearTimeout(timer);
    }, [searchTerm]);

    // Fetch customers from Firestore
    const fetchCustomers = useCallback(async (isSearch: boolean = false) => {
        setLoading(true);
        try {
            const customersRef = collection(db, 'customers');
            
            let q;
            
            if (isSearch && debouncedSearch) {
                // For search, we need to get all and filter client-side since Firestore doesn't support full-text search
                // Get total count first
                const countSnapshot = await getCountFromServer(customersRef);
                setTotalCount(countSnapshot.data().count);
                
                // Query all customers ordered by createdAt
                q = query(
                    customersRef,
                    orderBy('createdAt', 'desc'),
                    limit(1000) // Get enough for search filtering
                );
            } else {
                // Get total count
                const countSnapshot = await getCountFromServer(customersRef);
                setTotalCount(countSnapshot.data().count);
                
                if (lastDoc) {
                    q = query(
                        customersRef,
                        orderBy('createdAt', 'desc'),
                        startAfter(lastDoc),
                        limit(LIMIT)
                    );
                } else {
                    q = query(
                        customersRef,
                        orderBy('createdAt', 'desc'),
                        limit(LIMIT)
                    );
                }
            }

            const snapshot = await getDocs(q);
            
            let fetchedCustomers = snapshot.docs.map(doc => {
                const data = doc.data() as Record<string, any>;
                return {
                    uid: doc.id,
                    ...data
                } as Customer;
            });

            // Client-side search filtering if needed
            if (isSearch && debouncedSearch) {
                const searchLower = debouncedSearch.toLowerCase();
                fetchedCustomers = fetchedCustomers.filter(c => 
                    (c.name?.toLowerCase().includes(searchLower)) ||
                    (c.phone?.toLowerCase().includes(searchLower)) ||
                    (c.email?.toLowerCase().includes(searchLower))
                );
                // Apply pagination to filtered results
                const startIdx = (page - 1) * LIMIT;
                fetchedCustomers = fetchedCustomers.slice(startIdx, startIdx + LIMIT);
            }

            setCustomers(fetchedCustomers);
            setHasMore(snapshot.docs.length === LIMIT);

            // Set last doc for next page
            if (snapshot.docs.length > 0 && !isSearch) {
                setLastDoc(snapshot.docs[snapshot.docs.length - 1]);
            }
        } catch (e: any) {
            console.error('Failed to fetch customers:', e);
            
            // Handle specific Firestore errors
            if (e.code === 'permission-denied') {
                alert('Permission denied. You do not have access to customer data.');
            } else if (e.code === 'unavailable') {
                alert('Service unavailable. Please check your connection and try again.');
            } else if (e.code === 'internal') {
                alert('Internal error. Please try again later.');
            }
        } finally {
            setLoading(false);
            setInitialLoading(false);
        }
    }, [debouncedSearch, lastDoc, page]);

    // Initial fetch and search
    useEffect(() => {
        const isSearch = debouncedSearch.length > 0;
        fetchCustomers(isSearch);
    }, [debouncedSearch, page]);

    // Handle pagination
    const handleNextPage = () => {
        if (hasMore && !loading) {
            setPage(p => p + 1);
        }
    };

    const handlePrevPage = () => {
        if (page > 1 && !loading) {
            setPage(p => p - 1);
            setLastDoc(null); // Reset for simplicity
        }
    };

    // Handle view details
    const handleViewDetails = (customerId: string) => {
        setSelectedCustomerId(customerId);
        setDrawerOpen(true);
    };

    // Handle action complete (block/unblock)
    const handleActionComplete = () => {
        fetchCustomers(debouncedSearch.length > 0);
    };

    // Format date helper
    const formatDate = (timestamp: any) => {
        if (!timestamp) return 'N/A';
        const date = timestamp.seconds ? new Date(timestamp.seconds * 1000) : new Date(timestamp);
        return date.toLocaleDateString('en-IN', {
            day: 'numeric',
            month: 'short',
            year: 'numeric'
        });
    };

    // Table columns
    const columns = [
        {
            key: 'customer',
            label: 'Customer',
            render: (c: Customer) => (
                <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-2xl bg-slate-800 border border-slate-700 flex items-center justify-center overflow-hidden">
                        {c.photoUrl ? (
                            <img src={c.photoUrl} alt={c.name} className="w-full h-full object-cover" />
                        ) : (
                            <span className="text-xs font-black text-slate-500">{c.name?.[0] || 'U'}</span>
                        )}
                    </div>
                    <div className="flex flex-col">
                        <span className="font-black text-white text-sm tracking-tight">{c.name || 'Anonymous User'}</span>
                        <div className="flex items-center gap-1 mt-0.5">
                            <Hash size={10} className="text-indigo-500" />
                            <span className="text-[10px] font-mono font-bold text-slate-500 uppercase tracking-tighter">{c.uid.substring(0, 10)}</span>
                        </div>
                    </div>
                </div>
            )
        },
        {
            key: 'phone',
            label: 'Phone',
            render: (c: Customer) => (
                <div className="flex items-center gap-2">
                    <Smartphone size={12} className="text-emerald-500" />
                    <span className="text-sm font-bold text-slate-300 uppercase tracking-wider">{c.phone || 'N/A'}</span>
                </div>
            )
        },
        {
            key: 'email',
            label: 'Email',
            render: (c: Customer) => (
                <div className="flex items-center gap-2">
                    <Mail size={12} className="text-indigo-500" />
                    <span className="text-sm font-medium text-slate-400">{c.email || 'N/A'}</span>
                </div>
            )
        },
        {
            key: 'joinedAt',
            label: 'Joined Date',
            render: (c: Customer) => (
                <div className="flex items-center gap-2">
                    <Clock size={12} className="text-slate-600" />
                    <span className="text-sm font-medium text-slate-300">{formatDate(c.createdAt)}</span>
                </div>
            )
        },
        {
            key: 'lastActive',
            label: 'Last Active',
            render: (c: Customer) => (
                <div className="flex items-center gap-2">
                    <Clock size={12} className="text-purple-500" />
                    <span className="text-sm font-medium text-slate-300">
                        {c.lastActiveAt ? formatDate(c.lastActiveAt) : 'Never'}
                    </span>
                </div>
            )
        },
        {
            key: 'status',
            label: 'Status',
            render: (c: Customer) => (
                c.isBlocked ? (
                    <Badge className="bg-red-500/10 text-red-400 border-red-500/20 font-black text-[9px] uppercase tracking-widest px-2.5 py-1">
                        <ShieldAlert size={10} className="mr-1.5" /> Blocked
                    </Badge>
                ) : (
                    <Badge className="bg-emerald-500/10 text-emerald-400 border-emerald-500/20 font-black text-[9px] uppercase tracking-widest px-2.5 py-1">
                        <ShieldCheck size={10} className="mr-1.5" /> Active
                    </Badge>
                )
            )
        },
        {
            key: 'actions',
            label: 'Actions',
            align: 'right' as const,
            render: (c: Customer) => (
                <div className="flex items-center justify-end gap-2">
                    <Button 
                        variant="outline" 
                        size="sm" 
                        onClick={() => handleViewDetails(c.uid)}
                        className="h-9 border-slate-800 text-[10px] font-black uppercase tracking-widest rounded-xl bg-slate-900/50 text-slate-400 hover:text-white hover:border-indigo-500/30"
                    >
                        <Eye size={14} className="mr-2" /> Details
                    </Button>
                </div>
            )
        }
    ];

    return (
        <>
            <div className="space-y-8 max-w-[1600px] mx-auto pb-20">
                {/* Header */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                    <div>
                        <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase">Customer Registry</h1>
                        <div className="flex items-center gap-2 mt-1">
                            <p className="text-slate-500 text-sm font-medium">Manage and view all registered customers.</p>
                            <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                                <Activity size={10} className="animate-pulse" />
                                {totalCount} Total
                            </div>
                        </div>
                    </div>

                    {/* Search */}
                    <div className="relative group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                        <Input
                            placeholder="Search by name or phone..."
                            className="w-full md:w-80 pl-10 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50 focus:border-indigo-500/50"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                </div>

                {/* Table */}
                <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-3xl">
                    <CardContent className="p-0">
                        {/* Table Header */}
                        <div className="overflow-x-auto">
                            <table className="w-full">
                                <thead>
                                    <tr className="border-b border-slate-800/50">
                                        {columns.map((col) => (
                                            <th 
                                                key={col.key} 
                                                className={`py-4 px-4 text-left text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] ${col.align === 'right' ? 'text-right' : ''}`}
                                            >
                                                {col.label}
                                            </th>
                                        ))}
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-800/50">
                                    {initialLoading ? (
                                        // Show skeleton while initial loading
                                        Array.from({ length: 5 }).map((_, i) => (
                                            <SkeletonRow key={i} />
                                        ))
                                    ) : customers.length === 0 ? (
                                        <EmptyState searchTerm={debouncedSearch} />
                                    ) : (
                                        customers.map((customer) => (
                                            <tr 
                                                key={customer.uid} 
                                                className="hover:bg-white/[0.02] transition-colors"
                                            >
                                                {columns.map((col) => (
                                                    <td 
                                                        key={col.key} 
                                                        className={`py-4 px-4 ${col.align === 'right' ? 'text-right' : ''}`}
                                                    >
                                                        {col.render(customer)}
                                                    </td>
                                                ))}
                                            </tr>
                                        ))
                                    )}
                                </tbody>
                            </table>
                        </div>

                        {/* Pagination */}
                        {!initialLoading && customers.length > 0 && (
                            <div className="flex items-center justify-between p-6 border-t border-slate-800/50">
                                <span className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">
                                    Showing {(page - 1) * LIMIT + 1} to {Math.min(page * LIMIT, totalCount)} of {totalCount} records
                                </span>
                                <div className="flex items-center gap-2">
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        disabled={page === 1 || loading}
                                        onClick={handlePrevPage}
                                        className="h-8 w-8 p-0 rounded-lg border-slate-800 bg-slate-900/50 text-slate-400 hover:text-white disabled:opacity-50"
                                    >
                                        <ChevronLeft size={14} />
                                    </Button>
                                    <div className="h-8 px-3 flex items-center bg-indigo-500/10 border border-indigo-500/20 rounded-lg">
                                        <span className="text-xs font-black text-indigo-400">{page}</span>
                                    </div>
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        disabled={!hasMore || loading}
                                        onClick={handleNextPage}
                                        className="h-8 w-8 p-0 rounded-lg border-slate-800 bg-slate-900/50 text-slate-400 hover:text-white disabled:opacity-50"
                                    >
                                        <ChevronRight size={14} />
                                    </Button>
                                </div>
                            </div>
                        )}
                    </CardContent>
                </Card>
            </div>

            {/* Customer Detail Drawer */}
            <CustomerDetailDrawer
                customerId={selectedCustomerId}
                isOpen={drawerOpen}
                onClose={() => setDrawerOpen(false)}
                onActionComplete={handleActionComplete}
            />
        </>
    );
}
