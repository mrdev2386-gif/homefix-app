'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, onSnapshot } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { adminApi } from '@/lib/admin-api';
import StatusBadge from '@/components/ui/StatusBadge';
import {
    AlertTriangle, MessageSquare, Scale, Calendar, User,
    Wrench, ShieldAlert, CheckCircle2, XCircle, Search,
    Filter, MoreHorizontal, IndianRupee, Activity,
    ShieldCheck, Hash, Gavel, ArrowUpRight
} from 'lucide-react';
import { Card, CardHeader, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

export default function DisputesPage() {
    const [disputes, setDisputes] = useState<any[]>([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(true);
    const [processingId, setProcessingId] = useState<string | null>(null);
    const [selectedDispute, setSelectedDispute] = useState<any>(null);
    const [isModalOpen, setModalOpen] = useState(false);
    const [actionType, setActionType] = useState<string>('');
    const [actionPayload, setActionPayload] = useState<any>({});

    const handleAction = async (disputeId: string, action: string) => {
        setSelectedDispute(disputes.find(d => d.id === disputeId));
        setActionType(action);
        setActionPayload({});
        setModalOpen(true);
    };

    const executeAction = async () => {
        if (!selectedDispute) return;
        
        setProcessingId(selectedDispute.id);
        try {
            await adminApi.manageDispute(selectedDispute.id, actionType, actionPayload);
            alert('Action completed successfully!');
            setModalOpen(false);
        } catch (e: any) {
            console.error('Action failed:', e);
            alert(`Action failed: ${e.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    useEffect(() => {
        const q = query(collection(db, 'disputes'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snap) => {
            setDisputes(snap.docs.map(d => ({ id: d.id, ...d.data() })));
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    const filteredDisputes = disputes.filter(d =>
        d.id?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.subject?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.customerName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.technicianName?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase">Dispute Arbiter</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Mediate platform conflicts and monitor operational incidents.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-amber-500/10 text-amber-400 rounded-md border border-amber-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            {disputes.filter(d => d.status !== 'resolved').length} Pending Meditations
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-4">
                    <div className="relative w-full md:w-80 group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                        <Input
                            placeholder="Identify docket, petitioner or case..."
                            className="pl-10 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 gap-6">
                {loading ? (
                    [1, 2].map(i => (
                        <div key={i} className="h-64 rounded-3xl bg-slate-900/50 border border-slate-800 animate-pulse" />
                    ))
                ) : filteredDisputes.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-40 text-center border-2 border-dashed border-slate-800 rounded-3xl bg-slate-900/20">
                        <div className="w-16 h-16 bg-slate-800/50 rounded-2xl flex items-center justify-center mb-6 text-slate-600">
                            <Scale size={32} />
                        </div>
                        <h3 className="text-xl font-bold text-slate-300">Clean Registry</h3>
                        <p className="text-slate-500 max-w-xs mt-2">No operational conflicts detected in current session.</p>
                    </div>
                ) : filteredDisputes.map((dispute) => (
                    <Card key={dispute.id} className="overflow-hidden border-slate-800/50 bg-slate-900/40 backdrop-blur-sm group hover:border-slate-700 transition-all duration-300">
                        <div className="flex flex-col lg:flex-row divide-y lg:divide-y-0 lg:divide-x divide-slate-800/50">
                            <div className="flex-1 p-6 md:p-8">
                                <div className="flex flex-wrap items-center justify-between gap-4 mb-8">
                                    <div className="flex items-center gap-4">
                                        <StatusBadge status={dispute.status || 'open'} />
                                        <div className="flex items-center gap-1.5 ml-2 border-l border-slate-800 pl-4 py-1">
                                            <Calendar size={12} className="text-indigo-500" />
                                            <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest">
                                                {dispute.createdAt?.seconds ? new Date(dispute.createdAt.seconds * 1000).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' }) : 'LEGACY_LOG'}
                                            </span>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-1.5 px-3 py-1 bg-slate-950/50 border border-slate-800/50 rounded-lg">
                                        <Hash size={10} className="text-slate-600" />
                                        <span className="text-[9px] font-mono font-black text-slate-500 uppercase tracking-tighter">DOCKET-{dispute.id.substring(0, 8).toUpperCase()}</span>
                                    </div>
                                </div>

                                <div className="space-y-6">
                                    <div>
                                        <h3 className="text-2xl font-black text-white mb-4 tracking-tight group-hover:text-indigo-400 transition-colors uppercase">
                                            {dispute.subject || 'Incident Protocol Undetermined'}
                                        </h3>
                                        <div className="relative p-6 bg-slate-950/30 rounded-2xl border border-slate-800/50 group-hover:bg-slate-950/50 transition-colors">
                                            <MessageSquare size={16} className="absolute -top-2 -left-2 text-indigo-500 p-0.5 bg-slate-900 rounded-full" />
                                            <p className="text-slate-400 text-sm font-medium leading-relaxed italic opacity-80 line-clamp-3">
                                                &quot;{dispute.description || 'No detailed incident report provided by stakeholder.'}&quot;
                                            </p>
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                        <div className="p-4 bg-slate-800/20 border border-slate-800 rounded-2xl flex items-center gap-4">
                                            <div className="w-10 h-10 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center text-indigo-400">
                                                <User size={18} strokeWidth={2.5} />
                                            </div>
                                            <div>
                                                <p className="text-[9px] font-black text-slate-600 uppercase tracking-[0.2em] mb-0.5">Petitioner</p>
                                                <p className="text-sm font-black text-slate-200">{dispute.customerName || 'Anonymous'}</p>
                                            </div>
                                        </div>
                                        <div className="p-4 bg-slate-800/20 border border-slate-800 rounded-2xl flex items-center gap-4">
                                            <div className="w-10 h-10 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center text-emerald-400">
                                                <Wrench size={18} strokeWidth={2.5} />
                                            </div>
                                            <div>
                                                <p className="text-[9px] font-black text-slate-600 uppercase tracking-[0.2em] mb-0.5">Respondent</p>
                                                <p className="text-sm font-black text-slate-200">{dispute.technicianName || 'Operational Node'}</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="p-8 bg-slate-950/20 lg:w-96 flex flex-col justify-center gap-4">
                                <Button 
                                    onClick={() => handleAction(dispute.id, 'resolve')}
                                    disabled={processingId === dispute.id || dispute.status === 'resolved'}
                                    className="w-full bg-indigo-600 hover:bg-indigo-500 text-white h-14 rounded-2xl font-black uppercase text-[10px] tracking-widest shadow-xl shadow-indigo-600/10 transition-all border-none"
                                >
                                    <Gavel size={18} className="mr-3" /> Execute Arbitrage
                                </Button>

                                <div className="grid grid-cols-2 gap-3">
                                    <Button 
                                        variant="outline" 
                                        onClick={() => handleAction(dispute.id, 'approve')}
                                        disabled={processingId === dispute.id || dispute.status === 'resolved'}
                                        className="h-14 rounded-2xl border-slate-800 bg-slate-900/50 hover:bg-emerald-500/10 hover:border-emerald-500/30 hover:text-emerald-400 text-slate-500 font-black uppercase text-[9px] tracking-[0.15em] transition-all"
                                    >
                                        <CheckCircle2 size={16} className="mb-1 block mx-auto" strokeWidth={3} />
                                        Authorize
                                    </Button>
                                    <Button 
                                        variant="outline" 
                                        onClick={() => handleAction(dispute.id, 'reject')}
                                        disabled={processingId === dispute.id || dispute.status === 'resolved'}
                                        className="h-14 rounded-2xl border-slate-800 bg-slate-900/50 hover:bg-red-500/10 hover:border-red-500/30 hover:text-red-400 text-slate-500 font-black uppercase text-[9px] tracking-[0.15em] transition-all"
                                    >
                                        <XCircle size={16} className="mb-1 block mx-auto" strokeWidth={3} />
                                        Dismiss
                                    </Button>
                                </div>

                                <Button 
                                    variant="ghost" 
                                    onClick={() => handleAction(dispute.id, 'refund')}
                                    disabled={processingId === dispute.id || dispute.status === 'resolved'}
                                    className="w-full h-12 text-slate-600 hover:text-amber-500 hover:bg-amber-500/5 rounded-xl text-[9px] font-black uppercase tracking-widest transition-all"
                                >
                                    <IndianRupee size={14} className="mr-2" strokeWidth={3} />
                                    Initiate Reversal
                                </Button>

                                <div className="mt-2 pt-4 border-t border-slate-800/50">
                                    <div className="flex items-center justify-between text-[9px] font-black text-slate-700 uppercase tracking-tighter px-1">
                                        <span>Status: Under Mediation</span>
                                        <Activity size={10} className="animate-pulse" />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </Card>
                ))}
            </div>

            {/* Action Modal */}
            {isModalOpen && selectedDispute && (
                <div className="fixed inset-0 bg-[#0f172a]/95 backdrop-blur-xl flex items-center justify-center z-[100] p-4 animate-in fade-in duration-300">
                    <Card className="w-full max-w-lg bg-slate-900 border-slate-800 shadow-2xl shadow-black/50 overflow-hidden rounded-3xl">
                        <div className="p-6 border-b border-slate-800 flex items-center justify-between">
                            <div>
                                <h2 className="text-xl font-black text-white uppercase">
                                    {actionType === 'resolve' ? 'Resolve Dispute' : 
                                     actionType === 'approve' ? 'Approve Resolution' :
                                     actionType === 'reject' ? 'Reject Dispute' :
                                     'Initiate Refund'}
                                </h2>
                                <p className="text-slate-500 text-xs mt-1">Dispute: #{selectedDispute.id.substring(0, 8).toUpperCase()}</p>
                            </div>
                            <Button variant="ghost" onClick={() => setModalOpen(false)} className="text-slate-500 hover:text-white">
                                <XCircle size={20} />
                            </Button>
                        </div>
                        <CardContent className="p-6 space-y-4">
                            <div className="space-y-2">
                                <label className="text-xs font-black text-slate-500 uppercase tracking-widest">Resolution Notes</label>
                                <textarea
                                    className="flex min-h-[100px] w-full rounded-xl border border-slate-700 bg-slate-800/50 px-4 py-3 text-sm text-white placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 resize-none"
                                    placeholder="Enter resolution notes or reason..."
                                    value={actionPayload.notes || ''}
                                    onChange={(e) => setActionPayload({ ...actionPayload, notes: e.target.value })}
                                />
                            </div>
                            {actionType === 'refund' && (
                                <div className="space-y-2">
                                    <label className="text-xs font-black text-slate-500 uppercase tracking-widest">Refund Amount (₹)</label>
                                    <Input
                                        type="number"
                                        placeholder="Enter refund amount"
                                        value={actionPayload.amount || ''}
                                        onChange={(e) => setActionPayload({ ...actionPayload, amount: Number(e.target.value) })}
                                        className="bg-slate-800/50 border-slate-700 text-white"
                                    />
                                </div>
                            )}
                            <div className="flex gap-3 pt-2">
                                <Button
                                    variant="outline"
                                    onClick={() => setModalOpen(false)}
                                    className="flex-1 border-slate-700 text-slate-400 hover:text-white"
                                >
                                    Cancel
                                </Button>
                                <Button
                                    onClick={executeAction}
                                    disabled={processingId === selectedDispute.id}
                                    className="flex-1 bg-indigo-600 hover:bg-indigo-500 text-white"
                                >
                                    {processingId === selectedDispute.id ? 'Processing...' : 'Confirm'}
                                </Button>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            )}
        </div>
    );
}
