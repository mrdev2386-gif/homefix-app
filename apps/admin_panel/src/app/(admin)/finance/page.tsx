'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, limit, getDocs } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '@/lib/firebase';
import StatusBadge from '@/components/ui/StatusBadge';
import {
    RefreshCcw, DollarSign, ArrowUpRight, ArrowDownLeft,
    FileText, Calendar, Wallet, Search, Filter,
    MoreHorizontal, IndianRupee, TrendingUp, CreditCard,
    Activity, ShieldCheck, History, ArrowDownRight,
    ArrowRightCircle, Download, ExternalLink, MoreVertical, Globe
} from 'lucide-react';

import Table from '@/components/ui/Table';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';

export default function FinancePage() {
    const [payments, setPayments] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        fetchPayments();
    }, []);

    const fetchPayments = async () => {
        try {
            const q = query(collection(db, 'payments'), orderBy('createdAt', 'desc'), limit(50));
            const snap = await getDocs(q);
            setPayments(snap.docs.map(d => ({ id: d.id, ...d.data() })));
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const handleRefund = async (bookingId: string) => {
        if (!confirm('Process refund for this booking?')) return;
        try {
            const fn = httpsCallable(functions, 'admin_refundBooking');
            await fn({ bookingId });
            alert('Refund processed successfully');
            fetchPayments();
        } catch (e) { alert('Refund failed'); }
    };

    const handleWalletAdjust = async () => {
        const userId = prompt('Enter User ID (Cust/Tech):');
        if (!userId) return;
        const type = prompt('Type (credit/debit):');
        if (type !== 'credit' && type !== 'debit') {
            alert('Type must be "credit" or "debit"');
            return;
        }
        const amount = Number(prompt('Amount:'));
        if (!amount) return;
        const reason = prompt('Reason:');

        try {
            const fn = httpsCallable(functions, 'admin_adjustWallet');
            await fn({ userId, type, amount, reason });
            alert('Wallet adjusted successfully');
        } catch (e) { alert('Operation failed'); }
    };

    const filteredPayments = payments.filter(p =>
        p.id?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.orderId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.bookingId?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const successfulCredits = payments.filter(p => p.status === 'success' && !p.type?.includes('refund')).reduce((acc, curr) => acc + (curr.amount || 0), 0);
    const pendingSettlements = payments.filter(p => p.status === 'pending').reduce((acc, curr) => acc + (curr.amount || 0), 0);

    const columns = [
        {
            key: 'id',
            label: 'Transaction Vector',
            render: (p: any) => (
                <div className="flex items-center gap-4">
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center border ${p.status === 'success' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' :
                        p.status === 'pending' ? 'bg-amber-500/10 text-amber-400 border-amber-500/20' :
                            'bg-slate-800 text-slate-400 border-slate-700'
                        }`}>
                        <RefreshCcw size={18} className={p.status === 'pending' ? 'animate-spin' : ''} />
                    </div>
                    <div className="flex flex-col">
                        <span className="font-black text-white text-sm tracking-tight uppercase leading-tight">
                            {p.orderId ? `ORD-${p.orderId.substring(0, 8).toUpperCase()}` : `TRX-${p.id.substring(0, 8).toUpperCase()}`}
                        </span>
                        <span className="text-[10px] font-mono font-bold text-slate-500 mt-1 tracking-tighter">
                            SETTLEMENT_ID: {p.id.substring(0, 16).toUpperCase()}
                        </span>
                    </div>
                </div>
            )
        },
        {
            key: 'related',
            label: 'Entity Linkage',
            render: (p: any) => (
                <div className="flex flex-wrap gap-2">
                    {p.bookingId && (
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-slate-800/50 border border-slate-700/50 rounded-md">
                            <span className="text-[9px] font-black text-slate-500 uppercase tracking-widest">BK</span>
                            <span className="text-[10px] font-mono text-slate-300">{p.bookingId.substring(0, 8)}</span>
                        </div>
                    )}
                    {p.customerId && (
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 border border-indigo-500/20 rounded-md">
                            <span className="text-[9px] font-black text-indigo-400 uppercase tracking-widest">US</span>
                            <span className="text-[10px] font-mono text-slate-300">{p.customerId.substring(0, 8)}</span>
                        </div>
                    )}
                </div>
            )
        },
        {
            key: 'amount',
            label: 'Liquid Capital',
            render: (p: any) => (
                <div className="flex items-baseline gap-1">
                    <span className="text-slate-500 text-[10px] font-black italic">INR</span>
                    <span className="font-black text-white text-base tracking-tighter">
                        {p.amount?.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                    </span>
                </div>
            )
        },
        {
            key: 'status',
            label: 'Verification',
            render: (p: any) => <StatusBadge status={p.status} />
        },
        {
            key: 'date',
            label: 'Timeline',
            render: (p: any) => (
                <div className="flex flex-col">
                    <span className="text-sm font-bold text-slate-300">
                        {p.createdAt?.seconds ? new Date(p.createdAt.seconds * 1000).toLocaleDateString('en-US', { day: '2-digit', month: 'short', year: 'numeric' }) : 'Real-time'}
                    </span>
                    <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest mt-0.5">ESTIMATED_SETTLE</span>
                </div>
            )
        },
        {
            key: 'actions',
            label: '',
            align: 'right' as const,
            render: (p: any) => (
                <div className="flex justify-end pr-4">
                    {p.status === 'success' && (
                        <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => handleRefund(p.bookingId)}
                            className="h-8 w-8 text-slate-500 hover:text-rose-400 hover:bg-rose-400/10 rounded-lg transition-colors"
                        >
                            <RefreshCcw size={14} />
                        </Button>
                    )}
                </div>
            )
        }
    ];

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto pb-20">
            <header className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase tracking-tighter">Financial Registry</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium italic">Monitor global system liquidity and manage multi-nodal stakeholder equity.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-emerald-500/10 text-emerald-400 rounded-md border border-emerald-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            Live Ticker
                        </div>
                    </div>
                </div>
                <div className="flex items-center gap-3">
                    <Button variant="outline" className="bg-slate-900/50 border-slate-800 text-slate-300 hover:text-white rounded-xl h-12 px-6 font-black uppercase text-[10px] tracking-widest">
                        <Download size={14} className="mr-2" /> Export Ledger
                    </Button>
                    <Button
                        onClick={handleWalletAdjust}
                        className="bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl h-12 px-6 font-black uppercase text-[10px] tracking-widest shadow-xl shadow-indigo-600/20 border-none"
                    >
                        <Wallet size={14} className="mr-2" /> Balance Override
                    </Button>
                </div>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <Card className="overflow-hidden border-slate-800/50 bg-slate-900/40 backdrop-blur-sm group hover:border-emerald-500/30 transition-all duration-300">
                    <CardContent className="p-8">
                        <div className="flex items-center justify-between mb-6">
                            <div className="p-3 bg-emerald-500/10 text-emerald-400 rounded-2xl border border-emerald-500/20 group-hover:bg-emerald-600 group-hover:text-white transition-all">
                                <TrendingUp size={24} />
                            </div>
                            <div className="flex flex-col items-end">
                                <span className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-500">Gross Liquidity</span>
                                <div className="flex items-center gap-1 text-emerald-400 text-[10px] font-black uppercase mt-1">
                                    <ArrowUpRight size={10} /> 12.4% yield
                                </div>
                            </div>
                        </div>
                        <div className="flex items-baseline gap-2">
                            <span className="text-slate-500 font-bold italic text-lg uppercase">₹</span>
                            <h3 className="text-4xl font-black text-white tracking-tighter italic">{successfulCredits.toLocaleString()}</h3>
                        </div>
                        <p className="text-[10px] font-black text-slate-600 uppercase tracking-widest mt-4">Calculated from 50 transaction window</p>
                    </CardContent>
                </Card>

                <Card className="overflow-hidden border-slate-800/50 bg-slate-900/40 backdrop-blur-sm group hover:border-amber-500/30 transition-all duration-300">
                    <CardContent className="p-8">
                        <div className="flex items-center justify-between mb-6">
                            <div className="p-3 bg-amber-500/10 text-amber-400 rounded-2xl border border-amber-500/20 group-hover:bg-amber-600 group-hover:text-white transition-all">
                                <RefreshCcw size={24} className="animate-spin-slow" />
                            </div>
                            <div className="flex flex-col items-end">
                                <span className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-500">Escrow Lock</span>
                                <div className="flex items-center gap-1 text-amber-400 text-[10px] font-black uppercase mt-1">
                                    <Activity size={10} className="animate-pulse" /> Pending clearing
                                </div>
                            </div>
                        </div>
                        <div className="flex items-baseline gap-2">
                            <span className="text-slate-500 font-bold italic text-lg uppercase">₹</span>
                            <h3 className="text-4xl font-black text-white tracking-tighter italic">{pendingSettlements.toLocaleString()}</h3>
                        </div>
                        <p className="text-[10px] font-black text-slate-600 uppercase tracking-widest mt-4">System reserves for active engagements</p>
                    </CardContent>
                </Card>

                <Card className="overflow-hidden border-slate-800/50 bg-slate-900/40 backdrop-blur-sm group hover:border-indigo-500/30 transition-all duration-300">
                    <CardContent className="p-8">
                        <div className="flex items-center justify-between mb-6">
                            <div className="p-3 bg-indigo-500/10 text-indigo-400 rounded-2xl border border-indigo-500/20 group-hover:bg-indigo-600 group-hover:text-white transition-all">
                                <CreditCard size={24} />
                            </div>
                            <div className="flex flex-col items-end">
                                <span className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-500">Atomic Nodes</span>
                                <div className="flex items-center gap-1 text-indigo-400 text-[10px] font-black uppercase mt-1">
                                    <Globe size={10} /> Active Cluster
                                </div>
                            </div>
                        </div>
                        <h3 className="text-4xl font-black text-white tracking-tighter italic">{payments.length}</h3>
                        <p className="text-[10px] font-black text-slate-600 uppercase tracking-widest mt-4">Verified financial ledger entries</p>
                    </CardContent>
                </Card>
            </div>

            <Card className="border-slate-800/50 bg-slate-900/40 backdrop-blur-sm overflow-hidden rounded-[32px]">
                <CardHeader className="p-8 border-b border-slate-800/50">
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                        <div>
                            <CardTitle className="text-2xl font-black text-white uppercase tracking-tight">Ledger Stream</CardTitle>
                            <p className="text-slate-500 text-[10px] font-black uppercase tracking-widest mt-1">Streaming real-time financial transitions</p>
                        </div>
                        <div className="relative group">
                            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                            <Input
                                placeholder="Locate reference, order, or entity..."
                                className="w-full md:w-80 pl-11 bg-slate-950/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-2xl h-12 focus:ring-indigo-500/50 shadow-inner"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                    </div>
                </CardHeader>
                <div className="px-0">
                    <Table
                        columns={columns}
                        data={filteredPayments}
                        loading={loading}
                        emptyMessage="Awaiting fresh capital flow events..."
                    />
                </div>
            </Card>
        </div>
    );
}

