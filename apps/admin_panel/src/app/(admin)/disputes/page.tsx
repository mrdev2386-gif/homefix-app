'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, limit, startAfter, where, getDocs, QueryDocumentSnapshot } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';
import { Scale, Search, User, Wrench, Calendar, IndianRupee, MessageSquare, XCircle, CheckCircle2, AlertTriangle, Gavel } from 'lucide-react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';
import StatusBadge from '@/components/ui/StatusBadge';

const LIMIT = 20;

export default function DisputesPage() {
    const [disputes, setDisputes] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [statusTab, setStatusTab] = useState<string>('open');
    const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot | null>(null);
    const [hasMore, setHasMore] = useState(true);
    const [processingId, setProcessingId] = useState<string | null>(null);
    const [selectedDispute, setSelectedDispute] = useState<any>(null);
    const [actionModal, setActionModal] = useState<{ action: string; notes: string; amount: number } | null>(null);

    const fetchDisputes = async (isLoadMore = false) => {
        try {
            setLoading(true);
            let q = query(collection(db, 'disputes'), orderBy('createdAt', 'desc'), limit(LIMIT));

            if (statusTab !== 'all') q = query(q, where('status', '==', statusTab));
            if (isLoadMore && lastDoc) q = query(q, startAfter(lastDoc));

            const snap = await getDocs(q);
            const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));

            setDisputes(isLoadMore ? [...disputes, ...data] : data);
            setLastDoc(snap.docs[snap.docs.length - 1] || null);
            setHasMore(snap.docs.length === LIMIT);
        } catch (e) {
            console.error('Fetch disputes error:', e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchDisputes();
    }, [statusTab]);

    const handleAction = async () => {
        if (!selectedDispute || !actionModal) return;
        setProcessingId(selectedDispute.id);
        try {
            const fn = httpsCallable(functions, 'admin_manageDispute');
            await fn({
                disputeId: selectedDispute.id,
                action: actionModal.action,
                notes: actionModal.notes,
                amount: actionModal.amount
            });
            setActionModal(null);
            setSelectedDispute(null);
            await fetchDisputes();
        } catch (e: any) {
            alert(`Failed: ${e.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const filteredDisputes = disputes.filter(d =>
        d.id?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.customerName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.technicianName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.description?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="space-y-6 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black text-white uppercase">Disputes</h1>
                    <p className="text-slate-500 text-sm">Resolve platform conflicts</p>
                </div>
                <div className="relative w-full md:w-80">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4" />
                    <Input
                        placeholder="Search disputes..."
                        className="pl-10 bg-slate-900/50 border-slate-800"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            <div className="flex gap-2 flex-wrap">
                {['all', 'open', 'investigating', 'resolved', 'rejected'].map(tab => (
                    <Button
                        key={tab}
                        variant={statusTab === tab ? 'default' : 'outline'}
                        onClick={() => setStatusTab(tab)}
                        className="text-xs capitalize"
                    >
                        {tab}
                    </Button>
                ))}
            </div>

            <div className="space-y-4">
                {loading && disputes.length === 0 ? (
                    [1, 2].map(i => <div key={i} className="h-48 rounded-2xl bg-slate-900/50 animate-pulse" />)
                ) : filteredDisputes.length === 0 ? (
                    <div className="text-center py-20 border-2 border-dashed border-slate-800 rounded-2xl">
                        <Scale size={48} className="mx-auto text-slate-700 mb-4" />
                        <p className="text-slate-500">No disputes found</p>
                    </div>
                ) : (
                    filteredDisputes.map((dispute) => (
                        <Card key={dispute.id} className="border-slate-800 bg-slate-900/40">
                            <div className="flex flex-col lg:flex-row divide-y lg:divide-y-0 lg:divide-x divide-slate-800">
                                <div className="flex-1 p-6 space-y-4">
                                    <div className="flex items-center justify-between">
                                        <StatusBadge status={dispute.status || 'open'} />
                                        <div className="flex items-center gap-2 text-xs text-slate-500">
                                            <Calendar size={12} />
                                            {dispute.createdAt?.seconds ? new Date(dispute.createdAt.seconds * 1000).toLocaleDateString() : 'N/A'}
                                        </div>
                                    </div>

                                    <div>
                                        <h3 className="text-lg font-bold text-white mb-2">{dispute.issueType || 'General Issue'}</h3>
                                        <div className="p-4 bg-slate-950/30 rounded-xl border border-slate-800">
                                            <MessageSquare size={14} className="text-indigo-500 mb-2" />
                                            <p className="text-slate-400 text-sm italic line-clamp-2">"{dispute.description || 'No description'}"</p>
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="flex items-center gap-3 p-3 bg-slate-800/20 rounded-xl">
                                            <div className="w-10 h-10 rounded-xl bg-slate-800 flex items-center justify-center">
                                                <User size={18} className="text-indigo-400" />
                                            </div>
                                            <div>
                                                <p className="text-xs text-slate-500">Customer</p>
                                                <p className="text-sm font-bold text-slate-200">{dispute.customerName || 'N/A'}</p>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-3 p-3 bg-slate-800/20 rounded-xl">
                                            <div className="w-10 h-10 rounded-xl bg-slate-800 flex items-center justify-center">
                                                <Wrench size={18} className="text-emerald-400" />
                                            </div>
                                            <div>
                                                <p className="text-xs text-slate-500">Technician</p>
                                                <p className="text-sm font-bold text-slate-200">{dispute.technicianName || 'N/A'}</p>
                                            </div>
                                        </div>
                                    </div>

                                    {dispute.amountInvolved && (
                                        <div className="flex items-center gap-2 text-amber-400">
                                            <IndianRupee size={14} />
                                            <span className="font-bold">₹{dispute.amountInvolved}</span>
                                        </div>
                                    )}
                                </div>

                                <div className="p-6 lg:w-64 flex flex-col gap-2">
                                    <Button
                                        size="sm"
                                        onClick={() => setSelectedDispute(dispute)}
                                        className="w-full"
                                    >
                                        View Details
                                    </Button>
                                    {dispute.status !== 'resolved' && dispute.status !== 'rejected' && (
                                        <>
                                            <Button
                                                size="sm"
                                                variant="outline"
                                                disabled={processingId === dispute.id}
                                                onClick={() => {
                                                    setSelectedDispute(dispute);
                                                    setActionModal({ action: 'investigating', notes: '', amount: 0 });
                                                }}
                                                className="w-full"
                                            >
                                                <AlertTriangle size={14} className="mr-2" /> Investigate
                                            </Button>
                                            <Button
                                                size="sm"
                                                variant="outline"
                                                disabled={processingId === dispute.id}
                                                onClick={() => {
                                                    setSelectedDispute(dispute);
                                                    setActionModal({ action: 'resolve', notes: '', amount: 0 });
                                                }}
                                                className="w-full text-emerald-500 hover:text-emerald-400"
                                            >
                                                <CheckCircle2 size={14} className="mr-2" /> Resolve
                                            </Button>
                                            <Button
                                                size="sm"
                                                variant="outline"
                                                disabled={processingId === dispute.id}
                                                onClick={() => {
                                                    setSelectedDispute(dispute);
                                                    setActionModal({ action: 'reject', notes: '', amount: 0 });
                                                }}
                                                className="w-full text-red-500 hover:text-red-400"
                                            >
                                                <XCircle size={14} className="mr-2" /> Reject
                                            </Button>
                                            <Button
                                                size="sm"
                                                variant="outline"
                                                disabled={processingId === dispute.id}
                                                onClick={() => {
                                                    setSelectedDispute(dispute);
                                                    setActionModal({ action: 'refund', notes: '', amount: dispute.amountInvolved || 0 });
                                                }}
                                                className="w-full text-amber-500 hover:text-amber-400"
                                            >
                                                <IndianRupee size={14} className="mr-2" /> Refund
                                            </Button>
                                        </>
                                    )}
                                </div>
                            </div>
                        </Card>
                    ))
                )}
            </div>

            {hasMore && !loading && (
                <Button onClick={() => fetchDisputes(true)} className="w-full">
                    Load More
                </Button>
            )}

            {actionModal && selectedDispute && (
                <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <Card className="w-full max-w-lg bg-slate-900 border-slate-800">
                        <div className="p-6 border-b border-slate-800">
                            <h2 className="text-xl font-bold text-white capitalize">{actionModal.action} Dispute</h2>
                            <p className="text-slate-500 text-sm">#{selectedDispute.id.substring(0, 8)}</p>
                        </div>
                        <div className="p-6 space-y-4">
                            <div>
                                <label className="text-xs font-bold text-slate-400 uppercase mb-2 block">Notes</label>
                                <textarea
                                    className="w-full min-h-[100px] rounded-xl border border-slate-700 bg-slate-800/50 px-4 py-3 text-sm text-white resize-none"
                                    placeholder="Enter resolution notes..."
                                    value={actionModal.notes}
                                    onChange={(e) => setActionModal({ ...actionModal, notes: e.target.value })}
                                />
                            </div>
                            {actionModal.action === 'refund' && (
                                <div>
                                    <label className="text-xs font-bold text-slate-400 uppercase mb-2 block">Refund Amount (₹)</label>
                                    <Input
                                        type="number"
                                        value={actionModal.amount}
                                        onChange={(e) => setActionModal({ ...actionModal, amount: Number(e.target.value) })}
                                        className="bg-slate-800/50 border-slate-700"
                                    />
                                </div>
                            )}
                            <div className="flex gap-3">
                                <Button variant="outline" onClick={() => setActionModal(null)} className="flex-1">
                                    Cancel
                                </Button>
                                <Button onClick={handleAction} disabled={processingId === selectedDispute.id} className="flex-1">
                                    {processingId === selectedDispute.id ? 'Processing...' : 'Confirm'}
                                </Button>
                            </div>
                        </div>
                    </Card>
                </div>
            )}

            {selectedDispute && !actionModal && (
                <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4" onClick={() => setSelectedDispute(null)}>
                    <Card className="w-full max-w-2xl bg-slate-900 border-slate-800 max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
                        <div className="p-6 border-b border-slate-800 flex items-center justify-between sticky top-0 bg-slate-900 z-10">
                            <h2 className="text-xl font-bold text-white">Dispute Details</h2>
                            <Button variant="ghost" size="sm" onClick={() => setSelectedDispute(null)}>
                                <XCircle size={20} />
                            </Button>
                        </div>
                        <div className="p-6 space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <p className="text-xs text-slate-500 mb-1">Status</p>
                                    <StatusBadge status={selectedDispute.status} />
                                </div>
                                <div>
                                    <p className="text-xs text-slate-500 mb-1">Issue Type</p>
                                    <p className="text-sm font-bold">{selectedDispute.issueType}</p>
                                </div>
                                <div>
                                    <p className="text-xs text-slate-500 mb-1">Booking ID</p>
                                    <p className="text-sm font-mono">{selectedDispute.bookingId}</p>
                                </div>
                                <div>
                                    <p className="text-xs text-slate-500 mb-1">Amount</p>
                                    <p className="text-sm font-bold">₹{selectedDispute.amountInvolved || 0}</p>
                                </div>
                            </div>
                            <div>
                                <p className="text-xs text-slate-500 mb-2">Description</p>
                                <p className="text-slate-300">{selectedDispute.description}</p>
                            </div>
                            {selectedDispute.adminNotes && (
                                <div>
                                    <p className="text-xs text-slate-500 mb-2">Admin Notes</p>
                                    <p className="text-slate-300 bg-slate-800/30 p-4 rounded-xl">{selectedDispute.adminNotes}</p>
                                </div>
                            )}
                        </div>
                    </Card>
                </div>
            )}
        </div>
    );
}
