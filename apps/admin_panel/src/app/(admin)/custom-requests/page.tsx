'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, onSnapshot, where, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { adminApi } from '@/lib/admin-api';
import StatusBadge from '@/components/ui/StatusBadge';
import Table from '@/components/ui/Table';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import {
    Search, Calendar, Filter, MoreHorizontal, IndianRupee,
    User, Wrench, Clock, MapPin, ChevronRight, CheckCircle2,
    XCircle, Send, Activity, Eye, Layers, ArrowRight, Hash,
    ArrowUpRight, ClipboardList
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';

export default function CustomRequestsPage() {
    const [requests, setRequests] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [processingId, setProcessingId] = useState<string | null>(null);
    const [selectedRequest, setSelectedRequest] = useState<any>(null);
    const [isApproveModalOpen, setApproveModalOpen] = useState(false);
    const [technicians, setTechnicians] = useState<any[]>([]);
    const [selectedTech, setSelectedTech] = useState('');
    const [loadingTechs, setLoadingTechs] = useState(false);

    useEffect(() => {
        if (!db) return;
        const q = query(collection(db, 'service_requests'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snap) => {
            setRequests(snap.docs.map(d => ({ id: d.id, ...d.data() })));
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    const fetchTechnicians = async (district: string, categoryId: string) => {
        if (!db) return;
        setLoadingTechs(true);
        try {
            // Fetch technicians matching district and approved status
            const q = query(
                collection(db, 'technicians'),
                where('district', '==', district),
                where('status', 'in', ['approved', 'active'])
            );
            const snap = await getDocs(q);
            const techs = snap.docs
                .map(d => ({ id: d.id, ...d.data() } as any))
                .filter(t => t.serviceCategories?.includes(categoryId));
            setTechnicians(techs);
        } catch (e) {
            console.error('Failed to fetch techs:', e);
        } finally {
            setLoadingTechs(false);
        }
    };

    const handleApprove = (request: any) => {
        setSelectedRequest(request);
        setApproveModalOpen(true);
        fetchTechnicians(request.district, request.categoryId);
    };

    const executeApprove = async () => {
        if (!selectedRequest || !selectedTech) return;
        setProcessingId(selectedRequest.id);
        try {
            await adminApi.approveServiceRequest(selectedRequest.id, selectedTech);
            setApproveModalOpen(false);
            setSelectedTech('');
            alert('Technician assigned successfully!');
        } catch (e: any) {
            alert('Approval failed: ' + e.message);
        } finally {
            setProcessingId(null);
        }
    };

    const executeReject = async (requestId: string) => {
        const reason = prompt('Enter rejection reason:');
        if (reason === null) return;

        setProcessingId(requestId);
        try {
            await adminApi.rejectServiceRequest(requestId, reason);
            alert('Request rejected.');
        } catch (e: any) {
            alert('Rejection failed: ' + e.message);
        } finally {
            setProcessingId(null);
        }
    };

    const columns = [
        {
            key: 'id',
            label: 'Reference',
            render: (r: any) => (
                <div className="flex flex-col">
                    <span className="font-mono text-[10px] font-black text-indigo-400 tracking-wider">#{r.id.substring(0, 8).toUpperCase()}</span>
                    <span className="text-[9px] text-slate-500 font-bold uppercase tracking-widest mt-0.5">{r.district}</span>
                </div>
            )
        },
        {
            key: 'details',
            label: 'Request Details',
            render: (r: any) => (
                <div className="flex flex-col max-w-xs">
                    <span className="font-black text-white text-sm tracking-tight truncate">{r.description || 'Custom Service'}</span>
                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest mt-1">{r.categoryId}</span>
                </div>
            )
        },
        {
            key: 'customer',
            label: 'Customer',
            render: (r: any) => (
                <div className="flex items-center gap-3">
                    <div className="flex flex-col">
                        <span className="text-sm font-bold text-slate-200">{r.customerName}</span>
                        <span className="text-[10px] font-medium text-slate-500">{r.customerPhone}</span>
                    </div>
                </div>
            )
        },
        {
            key: 'status',
            label: 'Status',
            render: (r: any) => <StatusBadge status={r.status} />
        },
        {
            key: 'actions',
            label: 'Actions',
            align: 'right' as const,
            render: (r: any) => (
                <div className="flex justify-end gap-2 pr-2">
                    {r.status === 'pending_admin' && (
                        <>
                            <Button
                                size="sm"
                                className="bg-indigo-600 hover:bg-indigo-500 text-white font-black text-[9px] uppercase tracking-widest px-4 h-9 rounded-xl"
                                onClick={() => handleApprove(r)}
                                disabled={processingId === r.id}
                            >
                                Review & Assign
                            </Button>
                            <Button
                                size="sm"
                                variant="ghost"
                                className="text-slate-500 hover:text-red-400 hover:bg-red-500/10 font-black text-[9px] uppercase tracking-widest px-4 h-9 rounded-xl"
                                onClick={() => executeReject(r.id)}
                                disabled={processingId === r.id}
                            >
                                Reject
                            </Button>
                        </>
                    )}
                </div>
            )
        }
    ];

    const filteredRequests = requests.filter(r =>
        r.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.description.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto p-4 md:p-8">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase">Custom Job Requests</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Review and assign technicians to custom service requests based on district.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            {requests.filter(r => r.status === 'pending_admin').length} Pending Review
                        </div>
                    </div>
                </div>

                <div className="relative w-full md:w-80">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4" />
                    <Input
                        placeholder="Search requests..."
                        className="pl-12 bg-slate-900/50 border-slate-800 text-white h-12 rounded-2xl"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-3xl">
                <CardContent className="p-0">
                    <Table
                        columns={columns}
                        data={filteredRequests}
                        loading={loading}
                        emptyMessage="The custom request queue is currently empty."
                        className="[&_tr]:border-slate-800/50 [&_th]:text-slate-500 [&_th]:text-[10px] [&_th]:font-black [&_th]:uppercase [&_th]:tracking-widest [&_th]:py-6"
                    />
                </CardContent>
            </Card>

            {isApproveModalOpen && selectedRequest && (
                <div className="fixed inset-0 bg-[#0f172a]/95 backdrop-blur-xl flex items-center justify-center z-[100] p-4 animate-in fade-in duration-300">
                    <Card className="w-full max-w-lg bg-slate-900 border-slate-800 rounded-3xl overflow-hidden shadow-2xl">
                        <div className="p-6 border-b border-slate-800 flex justify-between items-center">
                            <div>
                                <h2 className="text-xl font-black text-white uppercase tracking-tight">Approve Request</h2>
                                <p className="text-slate-500 text-xs font-bold mt-0.5 tracking-wider uppercase">District: {selectedRequest.district}</p>
                            </div>
                            <Button variant="ghost" onClick={() => setApproveModalOpen(false)} className="text-slate-500 hover:text-white rounded-full h-10 w-10 p-0">
                                <XCircle size={24} />
                            </Button>
                        </div>
                        <div className="p-6 space-y-6">
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] px-1">Job Details</label>
                                <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800 text-slate-200 text-sm leading-relaxed">
                                    {selectedRequest.description}
                                </div>
                            </div>

                            <div className="space-y-4">
                                <div className="flex items-center justify-between px-1">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Select Technician</label>
                                    <Badge className="bg-indigo-500/10 text-indigo-400 border-indigo-500/20 font-black text-[9px] uppercase tracking-widest">{selectedRequest.categoryId}</Badge>
                                </div>
                                {loadingTechs ? (
                                    <div className="bg-slate-800/30 border border-slate-800 rounded-2xl p-8 flex flex-col items-center justify-center gap-4">
                                        <Activity size={24} className="animate-spin text-indigo-500" />
                                        <p className="text-xs font-bold text-slate-500 uppercase tracking-widest">Scanning Workforce...</p>
                                    </div>
                                ) : technicians.length > 0 ? (
                                    <div className="space-y-2 max-h-60 overflow-y-auto pr-2 no-scrollbar">
                                        {technicians.map(t => (
                                            <div
                                                key={t.id}
                                                onClick={() => setSelectedTech(t.id)}
                                                className={`p-4 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${selectedTech === t.id
                                                        ? 'bg-indigo-600/10 border-indigo-500 text-white shadow-lg shadow-indigo-500/10'
                                                        : 'bg-slate-800/50 border-slate-700 text-slate-400 hover:border-slate-500'
                                                    }`}
                                            >
                                                <div className="flex items-center gap-3">
                                                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center font-black ${selectedTech === t.id ? 'bg-indigo-500 text-white' : 'bg-slate-700 text-slate-500'}`}>
                                                        {t.name?.[0].toUpperCase()}
                                                    </div>
                                                    <div className="flex flex-col">
                                                        <span className="text-sm font-bold tracking-tight">{t.name}</span>
                                                        <span className="text-[10px] font-medium opacity-60">ID: {t.id.substring(0, 8).toUpperCase()}</span>
                                                    </div>
                                                </div>
                                                {selectedTech === t.id && <CheckCircle2 size={18} className="text-indigo-400" />}
                                            </div>
                                        ))}
                                    </div>
                                ) : (
                                    <div className="bg-red-500/5 border border-red-500/10 rounded-2xl p-8 flex flex-col items-center justify-center gap-4">
                                        <AlertTriangle size={24} className="text-red-500/30" />
                                        <p className="text-xs font-bold text-red-400/70 text-center uppercase tracking-widest leading-relaxed">
                                            No qualified technicians found in<br />{selectedRequest.district} for category {selectedRequest.categoryId}
                                        </p>
                                    </div>
                                )}
                            </div>

                            <div className="flex gap-3 pt-4">
                                <Button variant="outline" className="flex-1 h-12 rounded-2xl font-black text-[10px] uppercase tracking-widest" onClick={() => setApproveModalOpen(false)}>Abort</Button>
                                <Button
                                    className="flex-1 bg-indigo-600 hover:bg-indigo-500 text-white h-12 rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-lg shadow-indigo-600/20"
                                    disabled={!selectedTech || processingId === selectedRequest.id}
                                    onClick={executeApprove}
                                >
                                    {processingId === selectedRequest.id ? 'Processing...' : 'Confirm Assignment'}
                                </Button>
                            </div>
                        </div>
                    </Card>
                </div>
            )}
        </div>
    );
}

const AlertTriangle = ({ size, className }: { size: number, className: string }) => (
    <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z" /><path d="M12 9v4" /><path d="M12 17h.01" /></svg>
);
