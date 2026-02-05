'use client';

import { useEffect, useState } from 'react';
import { collection, query, getDocs, where, orderBy, limit, doc, getDoc, onSnapshot } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '@/lib/firebase';
import StatusBadge from '@/components/ui/StatusBadge';
import {
    IndianRupee, Wallet, ArrowRight, CheckCircle2,
    XCircle, Clock, Search, Filter, History, Send,
    ChevronRight, AlertCircle, Activity, ShieldCheck,
    Cpu, Globe, Zap, ArrowUpRight, MoreVertical,
    Download, ExternalLink, RefreshCw
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

export default function PayoutsPage() {
    const [techsWithBalance, setTechsWithBalance] = useState<any[]>([]);
    const [payouts, setPayouts] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedTech, setSelectedTech] = useState<any>(null);
    const [payoutAmount, setPayoutAmount] = useState('');
    const [processing, setProcessing] = useState(false);

    useEffect(() => {
        fetchData();

        // Real-time payouts feed
        const q = query(collection(db, 'payouts'), orderBy('createdAt', 'desc'), limit(20));
        const unsubscribe = onSnapshot(q, (snap) => {
            setPayouts(snap.docs.map(d => ({ id: d.id, ...d.data() })));
        });

        return () => unsubscribe();
    }, []);

    const fetchData = async () => {
        setLoading(true);
        try {
            const techSnap = await getDocs(query(collection(db, 'technicians'), where('status', '==', 'approved')));
            const techs = await Promise.all(techSnap.docs.map(async (d) => {
                const walletSnap = await getDoc(doc(db, 'technicians', d.id, 'wallet', 'main'));
                const wallet = walletSnap.data();
                return { id: d.id, ...d.data(), wallet: wallet || { availableBalance: 0, pendingBalance: 0 } };
            }));

            setTechsWithBalance(techs.filter(t => t.wallet.availableBalance > 0 || t.wallet.pendingBalance > 0));
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const handlePayout = async () => {
        if (!selectedTech || !payoutAmount || Number(payoutAmount) <= 0) return;
        if (Number(payoutAmount) > selectedTech.wallet.availableBalance) {
            alert('Amount exceeds available balance');
            return;
        }

        if (!confirm(`Confirm payout of ₹${payoutAmount} to ${selectedTech.name}?`)) return;

        setProcessing(true);
        try {
            const triggerPayoutFn = httpsCallable(functions, 'triggerTechnicianPayout');
            await triggerPayoutFn({
                technicianId: selectedTech.id,
                amount: Number(payoutAmount)
            });
            alert('Payout initiated successfully');
            setSelectedTech(null);
            setPayoutAmount('');
            fetchData();
        } catch (error: any) {
            console.error(error);
            alert(`Payout failed: ${error.message}`);
        } finally {
            setProcessing(false);
        }
    };

    const handleSettle = async (techId: string) => {
        try {
            const settleFn = httpsCallable(functions, 'settleTechnicianBalance');
            await settleFn({ technicianId: techId });
            alert('Balance settled to available');
            fetchData();
        } catch (e) { alert('Settlement failed'); }
    }

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto pb-20">
            <header className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase tracking-tighter">Payout Control</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Coordinate asset disbursement and manage service force liquidity.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            Cluster Synchronized
                        </div>
                    </div>
                </div>
                <div className="flex items-center gap-3">
                    <Button variant="outline" className="bg-slate-900/50 border-slate-800 text-slate-300 hover:text-white rounded-xl h-12 px-6 font-black uppercase text-[10px] tracking-widest" onClick={() => fetchData()}>
                        <RefreshCw size={14} className={`mr-2 ${loading ? 'animate-spin' : ''}`} /> Sync Nodes
                    </Button>
                </div>
            </header>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                <div className="lg:col-span-8 space-y-8">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-indigo-500/10 text-indigo-400 rounded-xl flex items-center justify-center border border-indigo-500/20">
                                <Wallet size={20} />
                            </div>
                            <h2 className="text-xl font-black text-white uppercase tracking-tight">Vested Liquidity</h2>
                        </div>
                        <Badge className="bg-slate-800 text-slate-400 border-slate-700 h-6 px-3 text-[9px] font-black uppercase tracking-widest">
                            {techsWithBalance.length} Agents Identified
                        </Badge>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {loading && techsWithBalance.length === 0 ? (
                            [1, 2, 3, 4].map(i => <div key={i} className="h-44 rounded-3xl bg-slate-950/20 border border-slate-800 animate-pulse" />)
                        ) : techsWithBalance.length === 0 ? (
                            <div className="col-span-full py-20 text-center border-2 border-dashed border-slate-800 rounded-3xl bg-slate-950/20">
                                <div className="w-16 h-16 bg-slate-800/50 rounded-2xl flex items-center justify-center mx-auto mb-6 text-slate-600">
                                    <ShieldCheck size={32} />
                                </div>
                                <h3 className="text-xl font-black text-slate-400 uppercase tracking-tight">Zero Disbursement Vectors</h3>
                                <p className="text-slate-600 text-xs font-medium mt-2">All agent balances currently below payout threshold.</p>
                            </div>
                        ) : techsWithBalance.map((tech) => (
                            <Card
                                key={tech.id}
                                onClick={() => setSelectedTech(tech)}
                                className={`overflow-hidden border-2 transition-all duration-300 cursor-pointer group rounded-3xl bg-slate-900/40 backdrop-blur-sm ${selectedTech?.id === tech.id ? 'border-indigo-600 ring-4 ring-indigo-500/10' : 'border-slate-800/50 hover:border-slate-700'
                                    }`}
                            >
                                <CardContent className="p-6">
                                    <div className="flex items-center justify-between mb-6">
                                        <div className="flex items-center gap-3">
                                            <div className="w-10 h-10 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center font-black text-slate-400 group-hover:bg-indigo-600 group-hover:text-white group-hover:border-indigo-500 transition-all">
                                                {tech.name?.[0].toUpperCase()}
                                            </div>
                                            <div className="flex flex-col">
                                                <span className="text-sm font-black text-white uppercase tracking-tight leading-tight">{tech.name}</span>
                                                <span className="text-[10px] font-mono font-bold text-slate-500 tracking-tighter uppercase">{tech.id.substring(0, 12)}</span>
                                            </div>
                                        </div>
                                        <ChevronRight size={16} className={`text-slate-600 group-hover:text-indigo-400 transition-all ${selectedTech?.id === tech.id ? 'rotate-90 text-indigo-400' : ''}`} />
                                    </div>

                                    <div className="grid grid-cols-2 gap-3">
                                        <div className="p-3 bg-slate-950/50 border border-slate-800/50 rounded-2xl">
                                            <span className="text-[9px] font-black text-slate-500 uppercase tracking-widest block mb-1">Liquid</span>
                                            <div className="flex items-baseline gap-1">
                                                <span className="text-slate-600 text-[10px] italic font-bold">₹</span>
                                                <span className="text-lg font-black text-white">{tech.wallet.availableBalance?.toLocaleString()}</span>
                                            </div>
                                        </div>
                                        <div className="p-3 bg-amber-500/5 border border-amber-500/10 rounded-2xl">
                                            <span className="text-[9px] font-black text-amber-500/50 uppercase tracking-widest block mb-1">Pending</span>
                                            <div className="flex items-baseline gap-1">
                                                <span className="text-amber-500/30 text-[10px] italic font-bold">₹</span>
                                                <span className="text-lg font-black text-amber-500/80">{tech.wallet.pendingBalance?.toLocaleString() || 0}</span>
                                            </div>
                                        </div>
                                    </div>

                                    {tech.wallet.pendingBalance > 0 && (
                                        <Button
                                            variant="ghost"
                                            className="w-full mt-3 h-8 text-[9px] font-black uppercase tracking-widest text-indigo-400 hover:text-white hover:bg-indigo-600/20"
                                            onClick={(e) => { e.stopPropagation(); handleSettle(tech.id); }}
                                        >
                                            <RefreshCw size={10} className="mr-2" /> Settle Escrow
                                        </Button>
                                    )}
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                </div>

                <div className="lg:col-span-4 space-y-8">
                    <Card className="border-none bg-slate-900 border-slate-800 overflow-hidden rounded-[32px] shadow-2xl shadow-indigo-900/20 ring-1 ring-white/5">
                        <CardHeader className="p-8 pb-4">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 bg-indigo-500/10 text-indigo-400 rounded-xl flex items-center justify-center border border-indigo-500/20">
                                    <Send size={20} />
                                </div>
                                <h2 className="text-xl font-black text-white uppercase tracking-tight">Capital Disbursement</h2>
                            </div>
                        </CardHeader>
                        <CardContent className="p-8 pt-0 space-y-6">
                            {selectedTech ? (
                                <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
                                    <div className="p-5 p-6 bg-slate-950/50 border border-slate-800 rounded-[24px]">
                                        <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest block mb-1">Target Entity</span>
                                        <p className="font-black text-white text-lg tracking-tight uppercase leading-tight">{selectedTech.name}</p>
                                        <div className="flex items-center gap-2 mt-2">
                                            <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                                            <span className="text-[10px] font-black text-emerald-400 uppercase tracking-widest">Authorized for Payout</span>
                                        </div>
                                    </div>

                                    <div className="space-y-3">
                                        <div className="flex items-center justify-between px-1">
                                            <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Quantum (INR)</label>
                                            <button
                                                onClick={() => setPayoutAmount(selectedTech.wallet.availableBalance.toString())}
                                                className="text-[10px] font-black text-indigo-400 uppercase tracking-widest hover:text-white transition-colors"
                                            >
                                                Max: ₹{selectedTech.wallet.availableBalance.toLocaleString()}
                                            </button>
                                        </div>
                                        <div className="relative group">
                                            <span className="absolute left-6 top-1/2 -translate-y-1/2 font-black text-indigo-400 text-3xl italic">₹</span>
                                            <Input
                                                type="number"
                                                className="bg-slate-950/50 border-slate-800 text-white rounded-[24px] h-20 pl-14 text-3xl font-black tracking-tighter focus:ring-indigo-500/30 transition-all border-none shadow-inner"
                                                placeholder="0.00"
                                                value={payoutAmount}
                                                onChange={(e) => setPayoutAmount(e.target.value)}
                                            />
                                        </div>
                                    </div>

                                    <Button
                                        onClick={handlePayout}
                                        disabled={processing || !payoutAmount || Number(payoutAmount) <= 0}
                                        className="w-full h-16 bg-indigo-600 hover:bg-indigo-500 text-white font-black uppercase text-[11px] tracking-widest rounded-[24px] shadow-xl shadow-indigo-600/20 border-none transition-all active:scale-95"
                                    >
                                        {processing ? <RefreshCw className="animate-spin mr-2" /> : <Zap className="mr-2 h-4 w-4 fill-white" />}
                                        Initialize Disbursement
                                    </Button>

                                    <button
                                        onClick={() => { setSelectedTech(null); setPayoutAmount(''); }}
                                        className="w-full py-2 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] hover:text-white transition-colors"
                                    >
                                        Abort Command
                                    </button>
                                </div>
                            ) : (
                                <div className="py-16 text-center space-y-6">
                                    <div className="w-20 h-20 bg-slate-950/50 rounded-full border border-slate-800 mx-auto flex items-center justify-center">
                                        <Search size={32} className="text-slate-800" />
                                    </div>
                                    <div className="space-y-2">
                                        <p className="text-[11px] font-black text-slate-500 uppercase tracking-[0.2em] leading-relaxed">
                                            Awaiting node selection<br />from disbursement pool
                                        </p>
                                    </div>
                                </div>
                            )}
                        </CardContent>
                    </Card>

                    <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-sm overflow-hidden rounded-[32px]">
                        <CardHeader className="p-8 pb-4">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <div className="w-8 h-8 bg-slate-800 border border-slate-700 rounded-lg flex items-center justify-center text-slate-400">
                                        <History size={16} />
                                    </div>
                                    <h3 className="font-black text-white uppercase text-xs tracking-widest">Audit Logs</h3>
                                </div>
                                <button className="text-[9px] font-black text-indigo-400 uppercase tracking-widest hover:text-white transition-colors">Stream Monitor</button>
                            </div>
                        </CardHeader>
                        <CardContent className="p-8 pt-0">
                            <div className="space-y-4 max-h-[400px] overflow-y-auto pr-2 scrollbar-thin scrollbar-thumb-slate-800">
                                {payouts.map(p => (
                                    <div key={p.id} className="flex items-center gap-4 p-4 bg-slate-950/30 border border-slate-800/50 rounded-2xl hover:bg-slate-800/20 transition-all group">
                                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center border ${p.status === 'success' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : 'bg-amber-500/10 text-amber-400 border-amber-500/20'
                                            }`}>
                                            <IndianRupee size={16} />
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <div className="flex justify-between items-start">
                                                <p className="font-black text-white text-sm">₹{p.amount.toLocaleString()}</p>
                                                <span className="text-[8px] font-black text-slate-500 uppercase tracking-tighter">
                                                    {p.createdAt?.seconds ? new Date(p.createdAt.seconds * 1000).toLocaleDateString() : 'SYNC_PND'}
                                                </span>
                                            </div>
                                            <div className="flex items-center justify-between mt-1">
                                                <p className="text-[9px] font-black text-slate-500 uppercase tracking-widest truncate max-w-[120px]">
                                                    {p.status} • {p.razorpayPayoutId?.substring(0, 8) || 'PLATFORM_LEDGER'}
                                                </p>
                                                <ExternalLink size={10} className="text-slate-700 group-hover:text-indigo-400 cursor-pointer" />
                                            </div>
                                        </div>
                                    </div>
                                ))}
                                {payouts.length === 0 && (
                                    <div className="py-10 text-center text-slate-600">
                                        <p className="text-[10px] font-black uppercase tracking-widest">No Recent Logs</p>
                                    </div>
                                )}
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    );
}
