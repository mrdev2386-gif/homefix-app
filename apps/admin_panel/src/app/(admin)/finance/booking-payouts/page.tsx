'use client';

import { useEffect, useState } from 'react';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';
import {
    IndianRupee, Wallet, CheckCircle2,
    XCircle, Clock, Search, Filter, History, Send,
    ChevronRight, AlertCircle, Activity, ShieldCheck,
    RefreshCw, Download, ExternalLink, MoreVertical,
    ArrowUpRight, ArrowDownRight, CreditCard, Banknote,
    Lock, Unlock, AlertTriangle, Layers
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardFooter } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';
import StatusBadge from '@/components/ui/StatusBadge';
import Table from '@/components/ui/Table';

export default function BookingPayoutsPage() {
    const [pendingPayouts, setPendingPayouts] = useState<any[]>([]);
    const [payoutHistory, setPayoutHistory] = useState<any[]>([]);
    const [analytics, setAnalytics] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState<'pending' | 'on_hold' | 'history'>('pending');
    const [searchTerm, setSearchTerm] = useState('');
    const [processingId, setProcessingId] = useState<string | null>(null);

    // Modal state for marking as paid
    const [isPayModalOpen, setPayModalOpen] = useState(false);
    const [selectedPayout, setSelectedPayout] = useState<any>(null);
    const [payoutForm, setPayoutForm] = useState({
        paymentMethod: 'bank_transfer' as 'bank_transfer' | 'upi' | 'cash',
        transactionId: '',
        notes: ''
    });

    useEffect(() => {
        fetchAllData();
    }, []);

    const fetchAllData = async () => {
        setLoading(true);
        try {
            const getPendingFn = httpsCallable(functions, 'getPendingPayouts');
            const getHistoryFn = httpsCallable(functions, 'getPayoutHistory');
            const getAnalyticsFn = httpsCallable(functions, 'getPayoutAnalytics');

            const [pendingRes, historyRes, analyticsRes] = await Promise.all([
                getPendingFn({}),
                getHistoryFn({ limit: 20 }),
                getAnalyticsFn({})
            ]);

            setPendingPayouts((pendingRes.data as any).payouts || []);
            setPayoutHistory((historyRes.data as any).payouts || []);
            setAnalytics((analyticsRes.data as any).analytics || null);
        } catch (error) {
            console.error('Failed to fetch payout data:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleMarkAsPaid = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!selectedPayout) return;

        setProcessingId(selectedPayout.id);
        try {
            const markPaidFn = httpsCallable(functions, 'markPayoutPaid');
            await markPaidFn({
                bookingId: selectedPayout.id,
                paymentMethod: payoutForm.paymentMethod,
                transactionId: payoutForm.transactionId,
                notes: payoutForm.notes
            });

            alert('Payout marked as COMPLETED');
            setPayModalOpen(false);
            fetchAllData();
        } catch (error: any) {
            alert(`Error: ${error.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const handleToggleHold = async (bookingId: string, currentStatus: string) => {
        setProcessingId(bookingId);
        try {
            if (currentStatus === 'on_hold') {
                const releaseFn = httpsCallable(functions, 'releasePayoutFromHold');
                await releaseFn({ bookingId });
            } else {
                const reason = prompt('Enter reason for holding payout:');
                if (!reason) return;
                const holdFn = httpsCallable(functions, 'putPayoutOnHold');
                await holdFn({ bookingId, reason });
            }
            fetchAllData();
        } catch (error: any) {
            alert(`Error: ${error.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const filteredPayouts = (activeTab === 'history' ? payoutHistory : pendingPayouts).filter(p => {
        if (activeTab === 'pending') return p.payout.status === 'pending';
        if (activeTab === 'on_hold') return p.payout.status === 'on_hold';
        return true;
    }).filter(p =>
        p.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.bookingNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.technicianName?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const columns = [
        {
            key: 'booking',
            label: 'Booking Reference',
            render: (p: any) => (
                <div className="flex flex-col">
                    <span className="font-black text-white text-sm">#{p.bookingNumber}</span>
                    <span className="text-[10px] font-mono text-slate-500">{p.id.substring(0, 12)}</span>
                </div>
            )
        },
        {
            key: 'technician',
            label: 'Technician',
            render: (p: any) => (
                <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-slate-800 border border-slate-700 flex items-center justify-center font-black text-slate-400 text-xs">
                        {p.technicianName?.[0] || 'T'}
                    </div>
                    <div className="flex flex-col">
                        <span className="text-sm font-bold text-slate-200">{p.technicianName}</span>
                        <span className="text-[10px] text-slate-500 uppercase font-black tracking-widest">{p.serviceName}</span>
                    </div>
                </div>
            )
        },
        {
            key: 'amount',
            label: 'Payout Amount',
            render: (p: any) => (
                <div className="flex flex-col">
                    <div className="flex items-baseline gap-1">
                        <span className="text-emerald-400 font-black text-sm">₹{p.payout.technicianAmount.toLocaleString()}</span>
                        <span className="text-[10px] text-slate-500 line-through">₹{p.payout.totalAmount}</span>
                    </div>
                    <span className="text-[9px] text-slate-600 font-black uppercase tracking-widest">
                        Fee: ₹{p.payout.platformFee}
                    </span>
                </div>
            )
        },
        {
            key: 'status',
            label: 'State',
            render: (p: any) => (
                <div className="flex flex-col gap-1">
                    <StatusBadge status={p.payout.status} />
                    {p.payout.status === 'on_hold' && (
                        <span className="text-[9px] text-amber-500 italic font-medium px-1 truncate max-w-[120px]">
                            {p.payout.onHoldReason}
                        </span>
                    )}
                </div>
            )
        },
        {
            key: 'actions',
            label: '',
            align: 'right' as const,
            render: (p: any) => (
                <div className="flex justify-end gap-2 pr-4">
                    {p.payout.status !== 'paid' && (
                        <>
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={() => handleToggleHold(p.id, p.payout.status)}
                                disabled={processingId === p.id}
                                className={`h-8 w-8 p-0 rounded-lg ${p.payout.status === 'on_hold' ? 'text-emerald-400 border-emerald-500/20 bg-emerald-500/5' : 'text-amber-400 border-amber-500/20 bg-amber-500/5'}`}
                            >
                                {p.payout.status === 'on_hold' ? <Unlock size={14} /> : <Lock size={14} />}
                            </Button>
                            <Button
                                size="sm"
                                onClick={() => { setSelectedPayout(p); setPayModalOpen(true); }}
                                disabled={processingId === p.id || p.payout.status === 'on_hold'}
                                className="h-8 bg-white text-black hover:bg-slate-200 font-black uppercase text-[10px] tracking-widest px-3"
                            >
                                <Banknote size={14} className="mr-1.5" /> Mark Paid
                            </Button>
                        </>
                    )}
                    {p.payout.status === 'paid' && (
                        <div className="flex flex-col items-end">
                            <span className="text-[10px] font-black text-emerald-500 uppercase tracking-widest flex items-center gap-1">
                                <CheckCircle2 size={10} /> Paid
                            </span>
                            <span className="text-[9px] text-slate-500">{p.payout.paidAt?.seconds ? new Date(p.payout.paidAt.seconds * 1000).toLocaleDateString() : ''}</span>
                        </div>
                    )}
                </div>
            )
        }
    ];

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto pb-20">
            <header className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase tracking-tighter italic">Disbursement Hub</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Verify and manually execute technician equity distribution for verified bookings.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            <ShieldCheck size={10} />
                            Manual Guard Active
                        </div>
                    </div>
                </div>
                <div className="flex items-center gap-3">
                    <Button
                        variant="outline"
                        className="bg-slate-900/50 border-slate-800 text-slate-300 hover:text-white rounded-xl h-12 px-6 font-black uppercase text-[10px] tracking-widest"
                        onClick={() => fetchAllData()}
                    >
                        <RefreshCw size={14} className={`mr-2 ${loading ? 'animate-spin' : ''}`} /> Refresh Registry
                    </Button>
                </div>
            </header>

            {/* Analytics Stats */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                <Card className="bg-slate-900/40 border-slate-800/50 backdrop-blur-sm group hover:border-indigo-500/30 transition-all duration-300">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between mb-4">
                            <div className="p-2.5 bg-indigo-500/10 text-indigo-400 rounded-xl">
                                <Activity size={20} />
                            </div>
                            <span className="text-[9px] font-black text-slate-500 uppercase tracking-widest">Gross Revenue</span>
                        </div>
                        <div className="flex items-baseline gap-1">
                            <span className="text-slate-500 font-bold italic text-sm">₹</span>
                            <h3 className="text-2xl font-black text-white tracking-tighter italic">
                                {analytics?.totalRevenue?.toLocaleString() || '0'}
                            </h3>
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-slate-900/40 border-slate-800/50 backdrop-blur-sm group hover:border-emerald-500/30 transition-all duration-300">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between mb-4">
                            <div className="p-2.5 bg-emerald-500/10 text-emerald-400 rounded-xl">
                                <IndianRupee size={20} />
                            </div>
                            <span className="text-[9px] font-black text-slate-500 uppercase tracking-widest">Total Payouts</span>
                        </div>
                        <div className="flex items-baseline gap-1">
                            <span className="text-slate-500 font-bold italic text-sm">₹</span>
                            <h3 className="text-2xl font-black text-white tracking-tighter italic">
                                {analytics?.totalPaidPayouts?.toLocaleString() || '0'}
                            </h3>
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-slate-900/40 border-slate-800/50 backdrop-blur-sm group hover:border-blue-500/30 transition-all duration-300">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between mb-4">
                            <div className="p-2.5 bg-blue-500/10 text-blue-400 rounded-xl">
                                <CreditCard size={20} />
                            </div>
                            <span className="text-[9px] font-black text-slate-500 uppercase tracking-widest">Platform Fees</span>
                        </div>
                        <div className="flex items-baseline gap-1">
                            <span className="text-slate-500 font-bold italic text-sm">₹</span>
                            <h3 className="text-2xl font-black text-white tracking-tighter italic">
                                {analytics?.totalPlatformFees?.toLocaleString() || '0'}
                            </h3>
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-slate-900/40 border-slate-800/50 backdrop-blur-sm group hover:border-amber-500/30 transition-all duration-300">
                    <CardContent className="p-6">
                        <div className="flex items-center justify-between mb-4">
                            <div className="p-2.5 bg-amber-500/10 text-amber-400 rounded-xl">
                                <Clock size={20} />
                            </div>
                            <span className="text-[9px] font-black text-slate-500 uppercase tracking-widest">Pending Clear</span>
                        </div>
                        <div className="flex items-baseline gap-1">
                            <span className="text-slate-500 font-bold italic text-sm">₹</span>
                            <h3 className="text-2xl font-black text-white tracking-tighter italic">
                                {analytics?.pendingPayoutTotal?.toLocaleString() || '0'}
                            </h3>
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Main Content Area */}
            <Card className="border-slate-800/50 bg-slate-900/40 backdrop-blur-sm overflow-hidden rounded-[32px]">
                <CardHeader className="p-8 border-b border-slate-800/50">
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                        <div className="flex items-center gap-4">
                            <div
                                onClick={() => setActiveTab('pending')}
                                className={`px-5 py-2.5 rounded-2xl text-[10px] font-black uppercase tracking-[0.15em] cursor-pointer transition-all ${activeTab === 'pending' ? 'bg-white text-black shadow-lg shadow-white/5' : 'text-slate-500 hover:text-white hover:bg-slate-800/50'}`}
                            >
                                Pending ({pendingPayouts.filter(p => p.payout.status === 'pending').length})
                            </div>
                            <div
                                onClick={() => setActiveTab('on_hold')}
                                className={`px-5 py-2.5 rounded-2xl text-[10px] font-black uppercase tracking-[0.15em] cursor-pointer transition-all ${activeTab === 'on_hold' ? 'bg-amber-500 text-black shadow-lg shadow-amber-500/10' : 'text-slate-500 hover:text-white hover:bg-slate-800/50'}`}
                            >
                                On Hold ({pendingPayouts.filter(p => p.payout.status === 'on_hold').length})
                            </div>
                            <div
                                onClick={() => setActiveTab('history')}
                                className={`px-5 py-2.5 rounded-2xl text-[10px] font-black uppercase tracking-[0.15em] cursor-pointer transition-all ${activeTab === 'history' ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/10' : 'text-slate-500 hover:text-white hover:bg-slate-800/50'}`}
                            >
                                Historical
                            </div>
                        </div>
                        <div className="relative group">
                            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                            <Input
                                placeholder="Search by booking, tech or unit..."
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
                        data={filteredPayouts}
                        loading={loading}
                        emptyMessage="Awaiting new disbursement vectors..."
                    />
                </div>
            </Card>

            {/* Payout Modal */}
            {isPayModalOpen && (
                <div className="fixed inset-0 bg-[#0f172a]/95 backdrop-blur-xl flex items-center justify-center z-[101] p-4 animate-in fade-in duration-300">
                    <Card className="w-full max-w-lg bg-slate-900 border-slate-800 shadow-2xl shadow-indigo-500/10 overflow-hidden rounded-[32px]">
                        <div className="p-8 border-b border-slate-800 flex items-center justify-between bg-gradient-to-r from-slate-900 via-slate-900 to-emerald-950/20">
                            <div>
                                <h2 className="text-2xl font-black text-white tracking-tight flex items-center gap-3 italic">
                                    <Banknote className="text-emerald-500" />
                                    Confirm Disbursement
                                </h2>
                                <p className="text-slate-500 text-[10px] font-black uppercase tracking-widest mt-1">Manual execution of technician equity</p>
                            </div>
                        </div>

                        <form onSubmit={handleMarkAsPaid} className="p-8 space-y-6">
                            <div className="p-5 bg-slate-950/50 border border-slate-800 rounded-2xl space-y-3">
                                <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest text-slate-500">
                                    <span>Recipient Agent</span>
                                    <span>#{selectedPayout.bookingNumber}</span>
                                </div>
                                <div className="text-xl font-black text-white uppercase tracking-tight italic">
                                    {selectedPayout.technicianName}
                                </div>
                                <div className="flex justify-between items-center pt-2 border-t border-slate-800/50">
                                    <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Net Payable</span>
                                    <span className="text-xl font-black text-emerald-400 italic">₹{selectedPayout.payout.technicianAmount.toLocaleString()}</span>
                                </div>
                            </div>

                            <div className="space-y-4">
                                <div className="space-y-2">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Modal Vector</label>
                                    <select
                                        className="h-12 w-full rounded-xl border border-slate-800 bg-slate-950/50 px-4 text-sm text-white focus:ring-2 focus:ring-indigo-500/50 focus:outline-none appearance-none"
                                        value={payoutForm.paymentMethod}
                                        onChange={e => setPayoutForm({ ...payoutForm, paymentMethod: e.target.value as any })}
                                    >
                                        <option value="bank_transfer">Bank Transfer (IMPS/NEFT)</option>
                                        <option value="upi">UPI / Virtual Link</option>
                                        <option value="cash">Hand-to-Hand Cash</option>
                                    </select>
                                </div>

                                <div className="space-y-2">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Reference Hash / TXN ID</label>
                                    <Input
                                        value={payoutForm.transactionId}
                                        onChange={e => setPayoutForm({ ...payoutForm, transactionId: e.target.value })}
                                        placeholder="e.g. RBSL192837465"
                                        className="bg-slate-950/50 border-slate-800 text-white h-12 rounded-xl focus:ring-indigo-500/20"
                                        required
                                    />
                                </div>

                                <div className="space-y-2">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Admin Metadata</label>
                                    <textarea
                                        value={payoutForm.notes}
                                        onChange={e => setPayoutForm({ ...payoutForm, notes: e.target.value })}
                                        className="w-full bg-slate-950/50 border border-slate-800 text-white rounded-xl p-4 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
                                        rows={2}
                                        placeholder="Internal audit notes..."
                                    />
                                </div>
                            </div>

                            <div className="flex gap-4 pt-4">
                                <Button
                                    type="button"
                                    variant="outline"
                                    onClick={() => setPayModalOpen(false)}
                                    className="flex-1 bg-transparent border-slate-800 text-slate-500 hover:text-white h-14 rounded-2xl font-black uppercase text-[10px] tracking-widest"
                                >
                                    Abort
                                </Button>
                                <Button
                                    type="submit"
                                    disabled={!!processingId}
                                    className="flex-[2] bg-emerald-600 hover:bg-emerald-500 text-white h-14 rounded-2xl font-black uppercase text-[10px] tracking-widest shadow-xl shadow-emerald-600/10"
                                >
                                    {processingId ? <Loader2 className="animate-spin" /> : 'Confirm Payment'}
                                </Button>
                            </div>
                        </form>
                    </Card>
                </div>
            )}
        </div>
    );
}

function Loader2({ className }: { className?: string }) {
    return <RefreshCw className={`animate-spin ${className}`} />;
}
