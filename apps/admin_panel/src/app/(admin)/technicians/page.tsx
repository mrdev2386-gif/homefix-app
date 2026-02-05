'use client';

import { useEffect, useState } from 'react';
import { collection, query, onSnapshot, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { adminApi } from '@/lib/admin-api';
import {
    Wrench, Search, Filter, Mail, Phone, Calendar,
    ShieldCheck, ShieldAlert, Award, Briefcase,
    Star, CheckCircle2, XCircle, Activity, LayoutGrid, MoreVertical,
    UserCircle, TrendingUp, MapPin
} from 'lucide-react';
import StatusBadge from '@/components/ui/StatusBadge';
import { Card, CardHeader, CardContent, CardDescription, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

export default function TechniciansPage() {
    const [techs, setTechs] = useState<any[]>([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(true);
    const [processingId, setProcessingId] = useState<string | null>(null);

    useEffect(() => {
        const q = query(collection(db, 'technicians'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snap) => {
            setTechs(snap.docs.map(d => ({ id: d.id, ...d.data() })));
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    const handleApprove = async (techId: string, approve: boolean) => {
        const action = approve ? 'verify' : 'suspend';
        if (!confirm(`Are you sure you want to ${action} this technician?`)) return;

        setProcessingId(techId);
        try {
            await adminApi.approveTechnician(techId, approve);
        } catch (e: any) {
            console.error('Action failed:', e);
            alert(`Action failed: ${e.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const toggleAvailability = async (techId: string, current: boolean) => {
        setProcessingId(techId);
        try {
            await adminApi.toggleTechAvailability(techId, !current);
        } catch (e: any) {
            console.error('Toggle failed:', e);
            alert(`Toggle failed: ${e.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const filteredTechs = techs.filter(t =>
        t.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.id?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.email?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const activeCount = techs.filter(t => t.isAvailable).length;

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight">Elite Force</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Manage and monitor verified service professionals.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-emerald-500/10 text-emerald-400 rounded-md border border-emerald-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            {activeCount} Online
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-3">
                    <div className="relative w-full md:w-80 group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                        <Input
                            placeholder="Search agents..."
                            className="pl-10 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                </div>
            </div>

            {loading ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {[1, 2, 3, 4, 5, 6].map(i => (
                        <div key={i} className="h-[400px] rounded-3xl bg-slate-900/50 border border-slate-800 animate-pulse" />
                    ))}
                </div>
            ) : filteredTechs.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-24 text-center border-2 border-dashed border-slate-800 rounded-3xl bg-slate-900/20">
                    <div className="w-16 h-16 bg-slate-800/50 rounded-2xl flex items-center justify-center mb-6 text-slate-600">
                        <Wrench size={32} />
                    </div>
                    <h3 className="text-xl font-bold text-slate-300">No technicians found</h3>
                    <p className="text-slate-500 max-w-xs mt-2">Try adjusting your search criteria.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {filteredTechs.map((tech) => (
                        <Card key={tech.id} className="overflow-hidden border-slate-800/50 bg-slate-900/40 backdrop-blur-sm group hover:border-slate-700 transition-all duration-300 flex flex-col">
                            <CardHeader className="p-6 pb-4">
                                <div className="flex justify-between items-start">
                                    <div className="relative group/avatar">
                                        <div className="h-20 w-20 rounded-2xl bg-slate-800 border border-slate-700 flex items-center justify-center overflow-hidden shadow-lg group-hover:border-indigo-500/30 transition-all duration-300">
                                            {tech.profileImage ? (
                                                <img src={tech.profileImage} alt={tech.name} className="h-full w-full object-cover" />
                                            ) : (
                                                <UserCircle className="h-10 w-10 text-slate-600" />
                                            )}
                                        </div>
                                        <div className={`absolute -bottom-1 -right-1 w-5 h-5 rounded-full border-4 border-[#0f172a] ${tech.isAvailable ? 'bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]' : 'bg-slate-600'}`} />
                                    </div>
                                    <div className="flex flex-col items-end gap-2">
                                        <StatusBadge status={tech.status || 'pending'} />
                                        <div className="flex items-center gap-1 px-2 py-1 bg-slate-800/50 rounded-lg border border-slate-700/50">
                                            <Star size={12} className="text-amber-400 fill-amber-400" />
                                            <span className="text-xs font-black text-white">{tech.rating?.toFixed(1) || '5.0'}</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="mt-4">
                                    <h3 className="text-xl font-black text-white hover:text-indigo-400 transition-colors truncate cursor-default">{tech.name || 'Anonymous Agent'}</h3>
                                    <div className="flex items-center gap-1.5 mt-0.5 text-[10px] font-bold text-slate-500 uppercase tracking-widest">
                                        <MapPin size={10} />
                                        {tech.city || 'National'}
                                    </div>
                                    <div className="flex flex-wrap gap-1.5 mt-3">
                                        {tech.skills?.slice(0, 2).map((s: string) => (
                                            <Badge key={s} className="bg-slate-800/80 text-slate-400 border-slate-700/50 font-bold px-2 py-0.5 text-[9px] uppercase tracking-wider">
                                                {s}
                                            </Badge>
                                        ))}
                                        {tech.skills?.length > 2 && (
                                            <Badge className="bg-indigo-500/10 text-indigo-400 border-indigo-500/20 font-bold px-2 py-0.5 text-[9px]">+ {tech.skills.length - 2}</Badge>
                                        )}
                                    </div>
                                </div>
                            </CardHeader>

                            <CardContent className="p-6 pt-0 flex-1 flex flex-col gap-4">
                                <div className="grid grid-cols-2 gap-3">
                                    <div className="p-4 bg-slate-900/50 rounded-2xl border border-slate-800/50 group-hover:border-slate-800 transition-colors">
                                        <div className="text-[9px] font-black text-slate-500 uppercase tracking-widest mb-1 flex items-center gap-1.5">
                                            <TrendingUp size={10} className="text-indigo-500" /> Accuracy
                                        </div>
                                        <div className="text-xl font-black text-white">98%</div>
                                    </div>
                                    <div className="p-4 bg-slate-900/50 rounded-2xl border border-slate-800/50 group-hover:border-slate-800 transition-colors">
                                        <div className="text-[9px] font-black text-slate-500 uppercase tracking-widest mb-1 flex items-center gap-1.5">
                                            <Briefcase size={10} className="text-emerald-500" /> Jobs
                                        </div>
                                        <div className="text-xl font-black text-white">{tech.jobsCompleted || 0}</div>
                                    </div>
                                </div>

                                <div className="space-y-2 mt-auto">
                                    <div className="flex items-center gap-3 text-xs text-slate-400 font-medium">
                                        <Mail size={14} className="text-slate-600" />
                                        {tech.email}
                                    </div>
                                    <div className="flex items-center gap-3 text-xs text-slate-400 font-medium">
                                        <Phone size={14} className="text-slate-600" />
                                        {tech.phone}
                                    </div>
                                </div>
                            </CardContent>

                            <div className="p-4 bg-slate-900/80 border-t border-slate-800/50 backdrop-blur-md flex items-center gap-2">
                                <Button
                                    variant="outline"
                                    size="sm"
                                    className="flex-1 bg-slate-800/50 border-slate-700 text-white font-black uppercase tracking-widest text-[9px] h-10 rounded-xl hover:bg-emerald-500/10 hover:text-emerald-400 hover:border-emerald-500/20 transition-all"
                                    disabled={processingId === tech.id}
                                    onClick={() => handleApprove(tech.id, true)}
                                >
                                    <CheckCircle2 size={14} className="mr-1.5 text-emerald-500" /> Restore
                                </Button>
                                <Button
                                    variant="outline"
                                    size="sm"
                                    className={`flex-1 bg-slate-800/50 border-slate-700 text-white font-black uppercase tracking-widest text-[9px] h-10 rounded-xl transition-all ${tech.isAvailable ? 'hover:bg-amber-500/10 hover:text-amber-400 hover:border-amber-500/20' : 'hover:bg-emerald-500/10 hover:text-emerald-400 hover:border-emerald-500/20'}`}
                                    disabled={processingId === tech.id}
                                    onClick={() => toggleAvailability(tech.id, tech.isAvailable)}
                                >
                                    <Activity size={14} className={`mr-1.5 ${tech.isAvailable ? 'text-amber-500' : 'text-emerald-500'}`} />
                                    {tech.isAvailable ? 'Pause' : 'Live'}
                                </Button>
                                <Button
                                    variant="outline"
                                    size="sm"
                                    className="flex-1 bg-slate-800/50 border-slate-700 text-white font-black uppercase tracking-widest text-[9px] h-10 rounded-xl hover:bg-red-500/10 hover:text-red-400 hover:border-red-500/20 transition-all group/suspend"
                                    disabled={processingId === tech.id}
                                    onClick={() => handleApprove(tech.id, false)}
                                >
                                    <XCircle size={14} className="mr-1.5 text-red-500" /> Suspend
                                </Button>
                            </div>
                        </Card>
                    ))}
                </div>
            )}
        </div>
    );
}
