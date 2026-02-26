'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, limit, startAfter, where, getDocs, QueryDocumentSnapshot } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';
import { ShieldAlert, Search, User, Wrench, Ban, CheckCircle2, RefreshCw, Zap, Hash, AlertTriangle } from 'lucide-react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

const LIMIT = 20;

export default function RiskPage() {
    const [signals, setSignals] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [scoreFilter, setScoreFilter] = useState<string>('all');
    const [statusFilter, setStatusFilter] = useState<string>('all');
    const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot | null>(null);
    const [hasMore, setHasMore] = useState(true);
    const [processingId, setProcessingId] = useState<string | null>(null);

    const fetchSignals = async (isLoadMore = false) => {
        try {
            setLoading(true);
            let q = query(collection(db, 'riskSignals'), orderBy('createdAt', 'desc'), limit(LIMIT));

            if (statusFilter !== 'all') q = query(q, where('status', '==', statusFilter));
            if (isLoadMore && lastDoc) q = query(q, startAfter(lastDoc));

            const snap = await getDocs(q);
            const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));

            setSignals(isLoadMore ? [...signals, ...data] : data);
            setLastDoc(snap.docs[snap.docs.length - 1] || null);
            setHasMore(snap.docs.length === LIMIT);
        } catch (e) {
            console.error('Fetch risk signals error:', e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchSignals();
    }, [statusFilter]);

    const handleAction = async (entityId: string, action: string) => {
        const reason = action === 'reset' ? prompt('Enter reason for reset:') : null;
        if (action === 'reset' && !reason) return;
        if (!confirm(`Confirm ${action} action?`)) return;

        setProcessingId(entityId);
        try {
            const fn = httpsCallable(functions, 'admin_manageRiskProfile');
            await fn({ entityId, action, reason, newStatus: action === 'suspend' ? 'suspended' : 'monitored' });
            await fetchSignals();
        } catch (e: any) {
            alert(`Failed: ${e.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const filteredSignals = signals.filter(s => {
        const matchesSearch = s.userId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            s.triggerReason?.toLowerCase().includes(searchTerm.toLowerCase());
        
        let matchesScore = true;
        if (scoreFilter === 'critical') matchesScore = s.riskScore >= 70;
        else if (scoreFilter === 'high') matchesScore = s.riskScore >= 40 && s.riskScore < 70;
        else if (scoreFilter === 'medium') matchesScore = s.riskScore >= 20 && s.riskScore < 40;
        else if (scoreFilter === 'low') matchesScore = s.riskScore < 20;

        return matchesSearch && matchesScore;
    });

    const getRiskColor = (score: number) => {
        if (score >= 70) return 'text-rose-500';
        if (score >= 40) return 'text-amber-500';
        return 'text-indigo-500';
    };

    const getRiskBadge = (score: number) => {
        if (score >= 70) return { label: 'Critical', className: 'bg-rose-500/10 text-rose-500 border-rose-500/20' };
        if (score >= 40) return { label: 'High', className: 'bg-amber-500/10 text-amber-500 border-amber-500/20' };
        if (score >= 20) return { label: 'Medium', className: 'bg-indigo-500/10 text-indigo-500 border-indigo-500/20' };
        return { label: 'Low', className: 'bg-slate-500/10 text-slate-500 border-slate-500/20' };
    };

    return (
        <div className="space-y-6 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black text-white uppercase">Risk Management</h1>
                    <p className="text-slate-500 text-sm">Monitor and manage platform security</p>
                </div>
                <div className="relative w-full md:w-80">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4" />
                    <Input
                        placeholder="Search risk signals..."
                        className="pl-10 bg-slate-900/50 border-slate-800"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            <div className="flex gap-2 flex-wrap">
                <div className="flex gap-2">
                    {['all', 'open', 'reviewed', 'cleared'].map(tab => (
                        <Button
                            key={tab}
                            variant={statusFilter === tab ? 'default' : 'outline'}
                            onClick={() => setStatusFilter(tab)}
                            className="text-xs capitalize"
                        >
                            {tab}
                        </Button>
                    ))}
                </div>
                <div className="h-6 w-px bg-slate-800 mx-2" />
                <div className="flex gap-2">
                    {['all', 'critical', 'high', 'medium', 'low'].map(filter => (
                        <Button
                            key={filter}
                            variant={scoreFilter === filter ? 'default' : 'outline'}
                            onClick={() => setScoreFilter(filter)}
                            className="text-xs capitalize"
                        >
                            {filter}
                        </Button>
                    ))}
                </div>
            </div>

            <div className="space-y-4">
                {loading && signals.length === 0 ? (
                    [1, 2].map(i => <div key={i} className="h-40 rounded-2xl bg-slate-900/50 animate-pulse" />)
                ) : filteredSignals.length === 0 ? (
                    <div className="text-center py-20 border-2 border-dashed border-slate-800 rounded-2xl">
                        <ShieldAlert size={48} className="mx-auto text-emerald-500 mb-4" />
                        <p className="text-slate-500">No risk signals found</p>
                    </div>
                ) : (
                    filteredSignals.map((signal) => {
                        const riskBadge = getRiskBadge(signal.riskScore);
                        return (
                            <Card key={signal.id} className="border-slate-800 bg-slate-900/40">
                                <div className="flex flex-col lg:flex-row divide-y lg:divide-y-0 lg:divide-x divide-slate-800">
                                    <div className="p-6 lg:w-32 flex flex-col items-center justify-center bg-slate-950/20">
                                        <div className={`text-5xl font-black ${getRiskColor(signal.riskScore)}`}>
                                            {signal.riskScore}
                                        </div>
                                        <div className="text-xs font-bold uppercase text-slate-600 mt-2">Risk Score</div>
                                    </div>

                                    <div className="flex-1 p-6 space-y-4">
                                        <div className="flex items-center justify-between">
                                            <div className="flex items-center gap-2">
                                                <Badge className={`${riskBadge.className} text-xs font-bold`}>
                                                    {riskBadge.label}
                                                </Badge>
                                                <Badge className={`text-xs font-bold ${signal.userType === 'customer' ? 'bg-blue-500/10 text-blue-400' : 'bg-purple-500/10 text-purple-400'}`}>
                                                    {signal.userType === 'customer' ? <User size={10} className="mr-1" /> : <Wrench size={10} className="mr-1" />}
                                                    {signal.userType}
                                                </Badge>
                                            </div>
                                            <div className="flex items-center gap-2 px-3 py-1 bg-slate-950/50 border border-slate-800 rounded-lg">
                                                <Hash size={10} className="text-slate-600" />
                                                <span className="text-xs font-mono text-slate-500">{signal.userId?.substring(0, 12)}</span>
                                            </div>
                                        </div>

                                        <div>
                                            <p className="text-xs text-slate-500 mb-1">Risk Type</p>
                                            <p className="text-sm font-bold text-white">{signal.riskType || 'General'}</p>
                                        </div>

                                        <div>
                                            <p className="text-xs text-slate-500 mb-1">Trigger Reason</p>
                                            <p className="text-sm text-slate-300">{signal.triggerReason || 'No details provided'}</p>
                                        </div>

                                        {signal.adminNotes && (
                                            <div className="p-3 bg-slate-800/30 rounded-xl">
                                                <p className="text-xs text-slate-500 mb-1">Admin Notes</p>
                                                <p className="text-sm text-slate-300">{signal.adminNotes}</p>
                                            </div>
                                        )}
                                    </div>

                                    <div className="p-6 lg:w-56 flex flex-col gap-2">
                                        {signal.status !== 'cleared' && (
                                            <>
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    disabled={processingId === signal.userId}
                                                    onClick={() => handleAction(signal.userId, 'update_status')}
                                                    className="w-full text-rose-500 hover:text-rose-400"
                                                >
                                                    <Ban size={14} className="mr-2" /> Block User
                                                </Button>
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    disabled={processingId === signal.userId}
                                                    onClick={() => handleAction(signal.userId, 'reset')}
                                                    className="w-full"
                                                >
                                                    <RefreshCw size={14} className="mr-2" /> Reset Score
                                                </Button>
                                            </>
                                        )}
                                        {signal.status === 'cleared' && (
                                            <div className="flex items-center justify-center gap-2 text-emerald-500 text-sm">
                                                <CheckCircle2 size={16} />
                                                <span>Cleared</span>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </Card>
                        );
                    })
                )}
            </div>

            {hasMore && !loading && (
                <Button onClick={() => fetchSignals(true)} className="w-full">
                    Load More
                </Button>
            )}
        </div>
    );
}
