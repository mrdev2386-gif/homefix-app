'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import { adminApi } from '@/lib/admin-api';
import {
    Wrench, Search, Filter, Mail, Smartphone,
    ShieldCheck, ShieldAlert, Star, Activity,
    Clock, Hash, MapPin, Eye, ChevronLeft, ChevronRight,
    CheckCircle2, XCircle
} from 'lucide-react';

import Table from '@/components/ui/Table';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Card, CardContent } from '@/components/ui/Card';

export default function TechniciansPage() {
    const [techs, setTechs] = useState<any[]>([]);
    const [total, setTotal] = useState(0);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(true);
    const [processingId, setProcessingId] = useState<string | null>(null);
    const [page, setPage] = useState(1);
    const [limit] = useState(10);
    const [statusFilter, setStatusFilter] = useState('');
    const [cityFilter, setCityFilter] = useState('');
    const [showPendingKyc, setShowPendingKyc] = useState(false);

    const fetchTechs = useCallback(async () => {
        setLoading(true);
        try {
            const data = await adminApi.getTechnicians({
                limit,
                offset: (page - 1) * limit,
                search: searchTerm,
                status: statusFilter || undefined,
                city: cityFilter || undefined,
                kycPending: showPendingKyc || undefined
            });
            setTechs(data.techs);
            setTotal(data.total);
        } catch (e) {
            console.error('Failed to fetch technicians:', e);
        } finally {
            setLoading(false);
        }
    }, [page, limit, searchTerm, statusFilter, cityFilter, showPendingKyc]);

    useEffect(() => {
        const timeout = setTimeout(fetchTechs, 500);
        return () => clearTimeout(timeout);
    }, [fetchTechs]);

    const handleApprove = async (techId: string, approve: boolean) => {
        const action = approve ? 'verify' : 'suspend';
        if (!confirm(`Are you sure you want to ${action} this technician?`)) return;

        console.log('[ADMIN APPROVAL] Calling approve for uid:', techId, 'approve:', approve);
        
        setProcessingId(techId);
        const previousTechs = [...techs];

        // Optimistic update
        setTechs(techs.map(t => t.id === techId ? { ...t, status: approve ? 'approved' : 'suspended', isVerified: approve } : t));

        try {
            await adminApi.approveTechnician(techId, approve);
            console.log('[ADMIN APPROVAL] Success for uid:', techId);
        } catch (e: any) {
            console.error('[ADMIN PANEL ❌]', e);
            setTechs(previousTechs);
            alert(`Action failed: ${e.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const columns = [
        {
            key: 'name',
            label: 'Technician',
            render: (t: any) => (
                <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-2xl bg-slate-800 border border-slate-700 flex items-center justify-center overflow-hidden">
                        {t.profileImage ? (
                            <img src={t.profileImage} alt={t.name} className="w-full h-full object-cover" />
                        ) : (
                            <Wrench size={18} className="text-slate-600" />
                        )}
                    </div>
                    <div className="flex flex-col">
                        <span className="font-black text-white text-sm tracking-tight">{t.name || 'Anonymous Pro'}</span>
                        <div className="flex items-center gap-1.5 mt-0.5 text-[9px] font-bold text-slate-500 uppercase tracking-widest">
                            <MapPin size={10} className="text-indigo-500" />
                            {t.city || 'Global'}
                        </div>
                    </div>
                </div>
            )
        },
        {
            key: 'skills',
            label: 'Expertise',
            render: (t: any) => (
                <div className="flex flex-wrap gap-1.5 max-w-[200px]">
                    {t.skills?.slice(0, 2).map((s: string) => (
                        <Badge key={s} className="bg-slate-800/80 text-slate-400 border-slate-700/50 font-bold px-2 py-0.5 text-[8px] uppercase tracking-wider">
                            {s}
                        </Badge>
                    ))}
                    {t.skills?.length > 2 && (
                        <Badge className="bg-indigo-500/10 text-indigo-400 border-indigo-500/20 font-bold px-2 py-0.5 text-[8px]">+ {t.skills.length - 2}</Badge>
                    )}
                </div>
            )
        },
        {
            key: 'rating',
            label: 'Performance',
            render: (t: any) => (
                <div className="flex items-center gap-2">
                    <div className="flex items-center gap-1.5 px-2.5 py-1 bg-amber-500/10 border border-amber-500/20 rounded-lg">
                        <Star size={12} className="text-amber-400 fill-amber-400" />
                        <span className="text-[11px] font-black text-white">{t.rating?.toFixed(1) || '5.0'}</span>
                    </div>
                    <div className="flex flex-col">
                        <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Jobs</span>
                        <span className="text-[11px] font-bold text-slate-300">{t.jobsCompleted || 0}</span>
                    </div>
                </div>
            )
        },
        {
            key: 'status',
            label: 'Status',
            render: (t: any) => (
                <Badge className={`font-black text-[9px] uppercase tracking-widest px-2.5 py-1 ${t.status === 'approved' ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20" :
                        t.status === 'pending' ? "bg-amber-500/10 text-amber-400 border-amber-500/20" :
                            "bg-red-500/10 text-red-400 border-red-500/20"
                    }`}>
                    {t.status || 'pending'}
                </Badge>
            )
        },
        {
            key: 'joined',
            label: 'Onboarded',
            render: (t: any) => (
                <div className="flex items-center gap-2 text-slate-500">
                    <Clock size={12} />
                    <span className="text-[11px] font-bold">
                        {t.createdAt?.seconds ? new Date(t.createdAt.seconds * 1000).toLocaleDateString() : 'LEGACY'}
                    </span>
                </div>
            )
        },
        {
            key: 'actions',
            label: 'Governance',
            align: 'right' as const,
            render: (t: any) => (
                <div className="flex items-center justify-end gap-2">
                    <Link href={`/technicians/${t.id}`}>
                        <Button variant="outline" size="sm" className="h-9 border-slate-800 text-[10px] font-black uppercase tracking-widest rounded-xl bg-slate-900/50 text-slate-400 hover:text-white hover:border-indigo-500/30">
                            <Eye size={14} className="mr-2" /> Details
                        </Button>
                    </Link>
                    {t.status !== 'approved' ? (
                        <Button
                            disabled={processingId === t.id}
                            variant="outline"
                            size="sm"
                            className="h-9 w-9 p-0 border-slate-800 bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500 hover:text-white rounded-xl transition-all"
                            onClick={() => handleApprove(t.id, true)}
                        >
                            <CheckCircle2 size={16} />
                        </Button>
                    ) : (
                        <Button
                            disabled={processingId === t.id}
                            variant="outline"
                            size="sm"
                            className="h-9 w-9 p-0 border-slate-800 bg-red-500/10 text-red-400 hover:bg-red-500 hover:text-white rounded-xl transition-all"
                            onClick={() => handleApprove(t.id, false)}
                        >
                            <XCircle size={16} />
                        </Button>
                    )}
                </div>
            )
        }
    ];

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto pb-20">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase">Specialized Forces</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Global authority for field operative management and verification.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-emerald-500/10 text-emerald-400 rounded-md border border-emerald-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            {total} Verified Pros
                        </div>
                    </div>
                </div>

                <div className="flex flex-wrap items-center gap-3">
                    <Button
                        variant={showPendingKyc ? "default" : "outline"}
                        size="sm"
                        onClick={() => {
                            setShowPendingKyc(!showPendingKyc);
                            if (!showPendingKyc) setStatusFilter('');
                        }}
                        className={`h-12 rounded-xl font-black uppercase tracking-widest text-[10px] px-6 ${
                            showPendingKyc 
                                ? 'bg-amber-500 text-white hover:bg-amber-400 border-none shadow-lg shadow-amber-500/20' 
                                : 'border-slate-800 bg-slate-900/50 text-slate-400 hover:text-white'
                        }`}
                    >
                        {showPendingKyc ? '✅ Showing Pending KYC' : '📋 Show Pending KYC'}
                    </Button>

                    <div className="flex items-center gap-2 bg-slate-900/50 border border-slate-800 rounded-xl px-3 h-12">
                        <Filter size={14} className="text-slate-500" />
                        <select
                            className="bg-transparent text-xs font-black text-slate-400 uppercase tracking-widest focus:outline-none"
                            value={statusFilter}
                            onChange={(e) => setStatusFilter(e.target.value)}
                        >
                            <option value="">All Statuses</option>
                            <option value="approved">Approved</option>
                            <option value="pending">Pending</option>
                            <option value="suspended">Suspended</option>
                        </select>
                        <div className="w-px h-4 bg-slate-800 mx-2" />
                        <Input
                            placeholder="CITY FILTER"
                            className="bg-transparent border-none text-[10px] font-black text-white uppercase placeholder:text-slate-700 w-24 h-auto p-0"
                            value={cityFilter}
                            onChange={(e) => setCityFilter(e.target.value)}
                        />
                    </div>

                    <div className="relative group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                        <Input
                            placeholder="Identify operative..."
                            className="w-full md:w-80 pl-10 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50 focus:border-indigo-500/50"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                </div>
            </div>

            <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-3xl">
                <CardContent className="p-0">
                    <Table
                        columns={columns}
                        data={techs}
                        loading={loading}
                        emptyMessage="The operative roster is currently clear."
                        className="[&_tr]:border-slate-800/50 [&_th]:bg-transparent [&_th]:text-slate-500 [&_th]:text-[10px] [&_th]:font-black [&_th]:uppercase [&_th]:tracking-[0.2em] [&_th]:py-6"
                    />

                    <div className="flex items-center justify-between p-6 border-t border-slate-800/50">
                        <span className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">
                            Displaying {(page - 1) * limit + 1} to {Math.min(page * limit, total)} of {total} operatives
                        </span>
                        <div className="flex items-center gap-2">
                            <Button
                                variant="outline"
                                size="sm"
                                disabled={page === 1}
                                onClick={() => setPage(p => p - 1)}
                                className="h-8 w-8 p-0 rounded-lg border-slate-800 bg-slate-900/50 text-slate-400 hover:text-white"
                            >
                                <ChevronLeft size={14} />
                            </Button>
                            <div className="h-8 px-3 flex items-center bg-emerald-500/10 border border-emerald-500/20 rounded-lg">
                                <span className="text-xs font-black text-emerald-400">{page}</span>
                            </div>
                            <Button
                                variant="outline"
                                size="sm"
                                disabled={page * limit >= total}
                                onClick={() => setPage(p => p + 1)}
                                className="h-8 w-8 p-0 rounded-lg border-slate-800 bg-slate-900/50 text-slate-400 hover:text-white"
                            >
                                <ChevronRight size={14} />
                            </Button>
                        </div>
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}
