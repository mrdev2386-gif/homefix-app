'use client';

import { useEffect, useState } from 'react';
import { collection, query, onSnapshot, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { adminApi } from '@/lib/admin-api';
import {
    ClipboardList, Search, Mail, Phone,
    UserCircle, CheckCircle, XCircle, Clock, MapPin,
    ArrowRight, Fingerprint, Calendar
} from 'lucide-react';
import StatusBadge from '@/components/ui/StatusBadge';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

export default function ApplicationsPage() {
    const [applications, setApplications] = useState<any[]>([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(true);
    const [processingId, setProcessingId] = useState<string | null>(null);

    useEffect(() => {
        const q = query(collection(db, 'technician_applications'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snap) => {
            setApplications(snap.docs.map(d => ({ id: d.id, ...d.data() })));
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    const handleAction = async (appId: string, approve: boolean) => {
        const reason = !approve ? prompt('Enter rejection reason:') : null;
        if (!approve && reason === null) return;

        setProcessingId(appId);
        try {
            await adminApi.approveTechnicianApplication(appId, approve, reason || undefined);
        } catch (e: any) {
            console.error('Action failed:', e);
            alert(`Action failed: ${e.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const filteredApps = applications.filter(a =>
        a.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        a.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        a.phone?.includes(searchTerm)
    );

    const pendingCount = applications.filter(a => a.status === 'pending').length;

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight">Vetting Portal</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Evaluate and onboard technician applications.</p>
                        {pendingCount > 0 && (
                            <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                                <Clock size={10} className="animate-pulse" />
                                {pendingCount} Pending
                            </div>
                        )}
                    </div>
                </div>

                <div className="relative w-full md:w-80 group">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                    <Input
                        placeholder="Search by name, email or phone..."
                        className="pl-10 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            {loading ? (
                <div className="py-20 flex flex-col items-center justify-center gap-4">
                    <div className="w-10 h-10 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin"></div>
                    <p className="text-slate-500 text-[10px] font-black uppercase tracking-widest animate-pulse">Loading Pipeline...</p>
                </div>
            ) : filteredApps.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-24 text-center border-2 border-dashed border-slate-800 rounded-3xl bg-slate-900/20">
                    <div className="w-16 h-16 bg-slate-800/50 rounded-2xl flex items-center justify-center mb-6 text-slate-600">
                        <ClipboardList size={32} />
                    </div>
                    <h3 className="text-xl font-bold text-slate-300">No applications found</h3>
                    <p className="text-slate-500 max-w-xs mt-2">Adjust your search or check back later for new talent.</p>
                </div>
            ) : (
                <div className="grid gap-6">
                    {filteredApps.map((app) => (
                        <Card key={app.id} className="overflow-hidden border-slate-800/50 bg-slate-900/40 backdrop-blur-sm group hover:border-slate-700 transition-all duration-300">
                            <div className="flex flex-col md:flex-row">
                                <div className="p-8 flex-1">
                                    <div className="flex items-start gap-6">
                                        <div className="h-24 w-24 rounded-2xl bg-slate-800 border border-slate-700 flex items-center justify-center flex-shrink-0 overflow-hidden shadow-lg group-hover:border-indigo-500/30 transition-all duration-300">
                                            {app.profileImage ? (
                                                <img src={app.profileImage} alt={app.name} className="h-full w-full object-cover" />
                                            ) : (
                                                <UserCircle className="h-12 w-12 text-slate-600" />
                                            )}
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-center justify-between mb-2">
                                                <div>
                                                    <h3 className="text-2xl font-black text-white hover:text-indigo-400 transition-colors truncate cursor-default">{app.name}</h3>
                                                    <div className="flex items-center gap-2 mt-0.5">
                                                        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest flex items-center gap-1">
                                                            <Fingerprint size={12} />
                                                            ID: {app.id.substring(0, 8).toUpperCase()}
                                                        </span>
                                                        <span className="w-1 h-1 rounded-full bg-slate-800"></span>
                                                        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest flex items-center gap-1">
                                                            <Calendar size={12} />
                                                            {new Date(app.createdAt?.seconds * 1000).toLocaleDateString()}
                                                        </span>
                                                    </div>
                                                </div>
                                                <StatusBadge status={app.status || 'pending'} />
                                            </div>

                                            <div className="flex flex-wrap gap-x-6 gap-y-2 text-sm text-slate-400 font-medium mb-6">
                                                <div className="flex items-center gap-2">
                                                    <div className="p-1.5 bg-slate-800 rounded-lg text-slate-500"><Mail size={14} /></div>
                                                    {app.email}
                                                </div>
                                                <div className="flex items-center gap-2">
                                                    <div className="p-1.5 bg-slate-800 rounded-lg text-slate-500"><Phone size={14} /></div>
                                                    {app.phone}
                                                </div>
                                                <div className="flex items-center gap-2">
                                                    <div className="p-1.5 bg-slate-800 rounded-lg text-slate-500"><MapPin size={14} /></div>
                                                    {app.city || 'Delhi NCR'}
                                                </div>
                                            </div>

                                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                                                <div className="space-y-3">
                                                    <p className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 underline decoration-indigo-500/50 decoration-2 underline-offset-4">Skillset Specialties</p>
                                                    <div className="flex flex-wrap gap-2">
                                                        {app.services?.map((s: string) => (
                                                            <Badge key={s} className="bg-slate-800 text-slate-300 border-slate-700 hover:bg-slate-700 transition-colors font-bold px-3 py-1 text-[10px] uppercase tracking-wider">{s}</Badge>
                                                        )) || <span className="text-xs text-slate-600 italic">No services listed</span>}
                                                    </div>
                                                </div>
                                                <div className="space-y-3">
                                                    <p className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 underline decoration-indigo-500/50 decoration-2 underline-offset-4">Identity Verification</p>
                                                    <div className="flex gap-2">
                                                        <Button variant="outline" size="sm" className="bg-slate-800/50 border-slate-700 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg text-[10px] font-bold uppercase tracking-widest px-3">View KYCDocs.pdf</Button>
                                                        <Button variant="outline" size="sm" className="bg-slate-800/50 border-slate-700 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg text-[10px] font-bold uppercase tracking-widest px-3">Background Check</Button>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div className="bg-slate-900/50 border-t md:border-t-0 md:border-l border-slate-800/50 p-8 flex flex-row md:flex-col items-center justify-center gap-3 md:w-56 flex-shrink-0">
                                    {app.status === 'pending' ? (
                                        <>
                                            <Button
                                                className="w-full bg-emerald-600 hover:bg-emerald-500 text-white font-black uppercase tracking-widest text-[10px] h-12 rounded-xl shadow-lg shadow-emerald-600/10 transition-all hover:scale-[1.02] active:scale-[0.98]"
                                                disabled={processingId === app.id}
                                                onClick={() => handleAction(app.id, true)}
                                            >
                                                {processingId === app.id ? (
                                                    <div className="w-5 h-5 border-2 border-white/20 border-t-white rounded-full animate-spin"></div>
                                                ) : (
                                                    <><CheckCircle className="mr-2 h-4 w-4" /> Approve</>
                                                )}
                                            </Button>
                                            <Button
                                                variant="destructive"
                                                className="w-full bg-red-600 hover:bg-red-500 text-white font-black uppercase tracking-widest text-[10px] h-12 rounded-xl shadow-lg shadow-red-600/10 transition-all hover:scale-[1.02] active:scale-[0.98]"
                                                disabled={processingId === app.id}
                                                onClick={() => handleAction(app.id, false)}
                                            >
                                                <XCircle className="mr-2 h-4 w-4" /> Reject
                                            </Button>
                                        </>
                                    ) : (
                                        <div className="text-center p-6 bg-slate-800/30 rounded-2xl border border-slate-800/50 w-full animate-in fade-in zoom-in duration-500">
                                            <div className={`mx-auto h-12 w-12 rounded-full flex items-center justify-center mb-3 ${app.status === 'approved' ? 'bg-emerald-500/10 text-emerald-500' : 'bg-red-500/10 text-red-500'}`}>
                                                {app.status === 'approved' ? <CheckCircle size={24} /> : <XCircle size={24} />}
                                            </div>
                                            <span className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-500">Decision Recorded</span>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </Card>
                    ))}
                </div>
            )}
        </div>
    );
}
