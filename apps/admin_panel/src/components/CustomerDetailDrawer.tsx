'use client';

import { useState, useEffect } from 'react';
import { 
    X, Mail, Smartphone, Wallet, ShieldAlert,
    ShieldCheck, Clock, Hash, Calendar, History,
    User, AlertTriangle, Loader2
} from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { adminApi } from '@/lib/admin-api';

interface Customer {
    uid: string;
    name: string;
    phone: string;
    email?: string;
    photoUrl?: string;
    createdAt: any;
    lastActiveAt?: any;
    isBlocked?: boolean;
    walletBalance?: number;
    totalBookings?: number;
}

interface CustomerDetailDrawerProps {
    customerId: string | null;
    isOpen: boolean;
    onClose: () => void;
    onActionComplete: () => void;
}

export default function CustomerDetailDrawer({ 
    customerId, 
    isOpen, 
    onClose,
    onActionComplete 
}: CustomerDetailDrawerProps) {
    const [customer, setCustomer] = useState<Customer | null>(null);
    const [loading, setLoading] = useState(true);
    const [processing, setProcessing] = useState(false);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (customerId && isOpen) {
            fetchCustomerDetails();
        }
    }, [customerId, isOpen]);

    const fetchCustomerDetails = async () => {
        if (!customerId) return;
        
        setLoading(true);
        setError(null);
        
        try {
            const data = await adminApi.getUserById(customerId) as Customer;
            setCustomer(data);
        } catch (e: any) {
            console.error('Failed to fetch customer:', e);
            setError(e.message || 'Failed to load customer details');
        } finally {
            setLoading(false);
        }
    };

    const handleBlockCustomer = async () => {
        if (!customerId || !customer) return;
        
        if (!confirm(`Are you sure you want to BLOCK this customer? They will lose access to their account.`)) return;

        setProcessing(true);
        try {
            await adminApi.blockUser(customerId, true);
            setCustomer(prev => prev ? { ...prev, isBlocked: true } : null);
            onActionComplete();
        } catch (e: any) {
            alert(`Failed to block customer: ${e.message}`);
        } finally {
            setProcessing(false);
        }
    };

    const handleUnblockCustomer = async () => {
        if (!customerId || !customer) return;
        
        if (!confirm(`Are you sure you want to UNBLOCK this customer? They will regain access to their account.`)) return;

        setProcessing(true);
        try {
            await adminApi.blockUser(customerId, false);
            setCustomer(prev => prev ? { ...prev, isBlocked: false } : null);
            onActionComplete();
        } catch (e: any) {
            alert(`Failed to unblock customer: ${e.message}`);
        } finally {
            setProcessing(false);
        }
    };

    const formatDate = (timestamp: any) => {
        if (!timestamp) return 'N/A';
        if (timestamp.seconds) {
            return new Date(timestamp.seconds * 1000).toLocaleDateString('en-IN', {
                day: 'numeric',
                month: 'short',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        }
        return new Date(timestamp).toLocaleDateString('en-IN');
    };

    if (!isOpen) return null;

    return (
        <>
            {/* Backdrop */}
            <div 
                className="fixed inset-0 bg-black/60 backdrop-blur-sm z-40"
                onClick={onClose}
            />
            
            {/* Drawer */}
            <div className="fixed right-0 top-0 h-full w-full max-w-lg bg-slate-900 border-l border-slate-800 z-50 shadow-2xl overflow-hidden flex flex-col">
                {/* Header */}
                <div className="flex items-center justify-between p-6 border-b border-slate-800 bg-slate-900/50">
                    <div className="flex items-center gap-3">
                        <h2 className="text-xl font-black text-white uppercase tracking-tight">Customer Profile</h2>
                        {customer?.isBlocked && (
                            <Badge className="bg-red-500/10 text-red-400 border-red-500/20 font-black text-[9px] uppercase tracking-widest">
                                <ShieldAlert size={10} className="mr-1" /> Blocked
                            </Badge>
                        )}
                    </div>
                    <button
                        onClick={onClose}
                        className="p-2 rounded-xl bg-slate-800/50 text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                    >
                        <X size={20} />
                    </button>
                </div>

                {/* Content */}
                <div className="flex-1 overflow-y-auto">
                    {loading ? (
                        <div className="flex items-center justify-center h-64">
                            <Loader2 className="w-8 h-8 animate-spin text-indigo-500" />
                        </div>
                    ) : error ? (
                        <div className="p-6">
                            <div className="p-4 rounded-2xl bg-red-500/10 border border-red-500/20">
                                <p className="text-red-400 text-sm font-medium">{error}</p>
                                <Button 
                                    variant="outline" 
                                    size="sm" 
                                    onClick={fetchCustomerDetails}
                                    className="mt-4"
                                >
                                    Retry
                                </Button>
                            </div>
                        </div>
                    ) : !customer ? (
                        <div className="p-6">
                            <div className="p-8 text-center text-slate-400">
                                <User size={48} className="mx-auto mb-4 text-slate-600" />
                                <p>Customer not found</p>
                            </div>
                        </div>
                    ) : (
                        <div className="p-6 space-y-6">
                            {/* A) BASIC INFO */}
                            <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md rounded-3xl overflow-hidden">
                                <CardHeader className="p-6 border-b border-slate-800/50">
                                    <div className="flex items-center gap-3">
                                        <div className="w-8 h-8 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center">
                                            <User size={16} className="text-indigo-400" />
                                        </div>
                                        <CardTitle className="text-sm font-black text-white uppercase tracking-tight">Basic Information</CardTitle>
                                    </div>
                                </CardHeader>
                                <CardContent className="p-6 space-y-4">
                                    {/* Avatar & Name */}
                                    <div className="flex items-center gap-4">
                                        <div className="w-16 h-16 rounded-2xl bg-slate-800 border border-slate-700 flex items-center justify-center overflow-hidden">
                                            {customer.photoUrl ? (
                                                <img src={customer.photoUrl} alt={customer.name} className="w-full h-full object-cover" />
                                            ) : (
                                                <span className="text-2xl font-black text-slate-500">{customer.name?.[0] || 'U'}</span>
                                            )}
                                        </div>
                                        <div>
                                            <div className="text-lg font-black text-white">{customer.name || 'Anonymous User'}</div>
                                            <div className="flex items-center gap-1 mt-1">
                                                <Hash size={12} className="text-indigo-500" />
                                                <span className="text-xs font-mono text-slate-500 uppercase">{customer.uid.substring(0, 12)}...</span>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Phone */}
                                    <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-950/50">
                                        <div className="w-8 h-8 rounded-lg bg-emerald-500/10 flex items-center justify-center">
                                            <Smartphone size={14} className="text-emerald-400" />
                                        </div>
                                        <div>
                                            <div className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Phone</div>
                                            <div className="text-sm font-bold text-slate-200 uppercase tracking-wider">
                                                {customer.phone || 'Not provided'}
                                            </div>
                                        </div>
                                    </div>

                                    {/* Email */}
                                    <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-950/50">
                                        <div className="w-8 h-8 rounded-lg bg-indigo-500/10 flex items-center justify-center">
                                            <Mail size={14} className="text-indigo-400" />
                                        </div>
                                        <div>
                                            <div className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Email</div>
                                            <div className="text-sm font-bold text-slate-200">
                                                {customer.email || 'Not provided'}
                                            </div>
                                        </div>
                                    </div>

                                    {/* Account Status */}
                                    <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-950/50">
                                        <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${customer.isBlocked ? 'bg-red-500/10' : 'bg-emerald-500/10'}`}>
                                            {customer.isBlocked ? (
                                                <ShieldAlert size={14} className="text-red-400" />
                                            ) : (
                                                <ShieldCheck size={14} className="text-emerald-400" />
                                            )}
                                        </div>
                                        <div>
                                            <div className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Account Status</div>
                                            <div className={`text-sm font-bold ${customer.isBlocked ? 'text-red-400' : 'text-emerald-400'}`}>
                                                {customer.isBlocked ? 'Blocked' : 'Active'}
                                            </div>
                                        </div>
                                    </div>
                                </CardContent>
                            </Card>

                            {/* B) ACCOUNT TIMELINE */}
                            <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md rounded-3xl overflow-hidden">
                                <CardHeader className="p-6 border-b border-slate-800/50">
                                    <div className="flex items-center gap-3">
                                        <div className="w-8 h-8 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center">
                                            <History size={16} className="text-amber-400" />
                                        </div>
                                        <CardTitle className="text-sm font-black text-white uppercase tracking-tight">Account Timeline</CardTitle>
                                    </div>
                                </CardHeader>
                                <CardContent className="p-6 space-y-4">
                                    {/* Joined Date */}
                                    <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-950/50">
                                        <div className="w-8 h-8 rounded-lg bg-blue-500/10 flex items-center justify-center">
                                            <Calendar size={14} className="text-blue-400" />
                                        </div>
                                        <div>
                                            <div className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Joined Date</div>
                                            <div className="text-sm font-bold text-slate-200">
                                                {formatDate(customer.createdAt)}
                                            </div>
                                        </div>
                                    </div>

                                    {/* Last Active */}
                                    <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-950/50">
                                        <div className="w-8 h-8 rounded-lg bg-purple-500/10 flex items-center justify-center">
                                            <Clock size={14} className="text-purple-400" />
                                        </div>
                                        <div>
                                            <div className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Last Active</div>
                                            <div className="text-sm font-bold text-slate-200">
                                                {customer.lastActiveAt ? formatDate(customer.lastActiveAt) : 'Never'}
                                            </div>
                                        </div>
                                    </div>

                                    {/* Total Bookings (if exists) */}
                                    <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-950/50">
                                        <div className="w-8 h-8 rounded-lg bg-cyan-500/10 flex items-center justify-center">
                                            <History size={14} className="text-cyan-400" />
                                        </div>
                                        <div>
                                            <div className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Total Bookings</div>
                                            <div className="text-sm font-bold text-slate-200">
                                                {customer.totalBookings !== undefined ? customer.totalBookings : 'N/A'}
                                            </div>
                                        </div>
                                    </div>

                                    {/* Wallet Balance */}
                                    <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-950/50">
                                        <div className="w-8 h-8 rounded-lg bg-indigo-500/10 flex items-center justify-center">
                                            <Wallet size={14} className="text-indigo-400" />
                                        </div>
                                        <div>
                                            <div className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Wallet Balance</div>
                                            <div className="text-sm font-bold text-slate-200">
                                                ₹{(customer.walletBalance || 0).toLocaleString()}
                                            </div>
                                        </div>
                                    </div>
                                </CardContent>
                            </Card>

                            {/* C) QUICK ACTIONS */}
                            <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md rounded-3xl overflow-hidden">
                                <CardHeader className="p-6 border-b border-slate-800/50">
                                    <div className="flex items-center gap-3">
                                        <div className="w-8 h-8 rounded-xl bg-red-500/10 border border-red-500/20 flex items-center justify-center">
                                            <ShieldAlert size={16} className="text-red-400" />
                                        </div>
                                        <CardTitle className="text-sm font-black text-white uppercase tracking-tight">Quick Actions</CardTitle>
                                    </div>
                                </CardHeader>
                                <CardContent className="p-6 space-y-3">
                                    {customer.isBlocked ? (
                                        <Button
                                            onClick={handleUnblockCustomer}
                                            disabled={processing}
                                            className="w-full h-12 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 hover:bg-emerald-500 hover:text-white font-black uppercase tracking-widest text-xs transition-all"
                                        >
                                            {processing ? (
                                                <Loader2 size={16} className="animate-spin mr-2" />
                                            ) : (
                                                <ShieldCheck size={16} className="mr-2" />
                                            )}
                                            Unblock Customer
                                        </Button>
                                    ) : (
                                        <Button
                                            onClick={handleBlockCustomer}
                                            disabled={processing}
                                            className="w-full h-12 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 hover:bg-red-500 hover:text-white font-black uppercase tracking-widest text-xs transition-all"
                                        >
                                            {processing ? (
                                                <Loader2 size={16} className="animate-spin mr-2" />
                                            ) : (
                                                <ShieldAlert size={16} className="mr-2" />
                                            )}
                                            Block Customer
                                        </Button>
                                    )}

                                    <div className="p-3 rounded-xl bg-amber-500/5 border border-amber-500/10">
                                        <div className="flex gap-2">
                                            <AlertTriangle size={14} className="text-amber-500 shrink-0 mt-0.5" />
                                            <p className="text-[10px] font-bold text-amber-500/80 uppercase leading-relaxed tracking-wide">
                                                Blocking a customer will immediately revoke their access to the platform.
                                            </p>
                                        </div>
                                    </div>
                                </CardContent>
                            </Card>
                        </div>
                    )}
                </div>
            </div>
        </>
    );
}
