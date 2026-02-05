'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, onSnapshot, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { getFunctions, httpsCallable } from 'firebase/functions';
import {
    ShieldAlert, Search, Filter, AlertTriangle, User,
    Wrench, MoreHorizontal, RefreshCw, Lock, Unlock,
    History, Activity, ShieldCheck, Hash, ArrowUpRight,
    Zap, Ban, CheckCircle2, MoreVertical
} from 'lucide-react';
import { Card, CardContent, CardHeader } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';

export default function RiskManagementPage() {
    const [profiles, setProfiles] = useState<any[]>([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(true);
    const functions = getFunctions();

    useEffect(() => {
        const q = query(
            collection(db, 'risk_profiles'),
            where('riskScore', '>', 0),
            orderBy('riskScore', 'desc')
        );
        const unsubscribe = onSnapshot(q, (snap) => {
            setProfiles(snap.docs.map(d => ({ id: d.id, ...d.data() })));
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    const filteredProfiles = profiles.filter(p =>
        p.entityId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.flags?.some((f: string) => f.toLowerCase().includes(searchTerm.toLowerCase()))
    );

    const handleResetScore = async (id: string) => {
        const reason = prompt("Enter reason for resetting risk score:");
        if (!reason) return;

        try {
            const manageRisk = httpsCallable(functions, 'admin_manageRiskProfile');
            await manageRisk({ entityId: id, action: 'reset', reason });
        } catch (e: any) {
            console.error(e);
            alert(`Execution failed: ${e.message}`);
        }
    };

    const handleChangeStatus = async (id: string, newStatus: string) => {
        if (!confirm(`Change status to ${newStatus}?`)) return;

        try {
            const manageRisk = httpsCallable(functions, 'admin_manageRiskProfile');
            await manageRisk({ entityId: id, action: 'update_status', newStatus });
        } catch (e: any) {
            console.error(e);
            alert(`Execution failed: ${e.message}`);
        }
    };

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase tracking-tighter">Risk Control</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Monitor anomalous pattern detection and enforce platform-wide security protocols.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-rose-500/10 text-rose-400 rounded-md border border-rose-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            {profiles.filter(p => p.riskScore > 40).length} Critical Vulnerabilities
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-3">
                    <div className="relative group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                        <Input
                            placeholder="Identify ID or risk vectors..."
                            className="w-full md:w-80 pl-10 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 gap-6">
                {loading ? (
                    [1, 2].map(i => (
                        <div key={i} className="h-44 rounded-3xl bg-slate-900/50 border border-slate-800 animate-pulse" />
                    ))
                ) : filteredProfiles.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-40 text-center border-2 border-dashed border-slate-800 rounded-3xl bg-slate-900/20">
                        <div className="w-16 h-16 bg-emerald-500/10 rounded-2xl flex items-center justify-center mb-6 text-emerald-400 border border-emerald-500/20">
                            <ShieldCheck size={32} />
                        </div>
                        <h3 className="text-xl font-bold text-slate-300 uppercase tracking-tight">Perimeter Secure</h3>
                        <p className="text-slate-500 max-w-xs mt-2 font-medium">Zero anomalous entities detected within the current monitoring window.</p>
                    </div>
                ) : filteredProfiles.map((profile) => (
                    <Card key={profile.id} className={`overflow-hidden border-slate-800/50 bg-slate-900/40 backdrop-blur-sm group hover:border-slate-700/80 transition-all duration-500 relative ${profile.riskScore >= 70 ? 'after:absolute after:left-0 after:top-0 after:bottom-0 after:w-1 after:bg-rose-600' :
                            profile.riskScore >= 40 ? 'after:absolute after:left-0 after:top-0 after:bottom-0 after:w-1 after:bg-amber-500' :
                                'after:absolute after:left-0 after:top-0 after:bottom-0 after:w-1 after:bg-indigo-600'
                        }`}>
                        <CardContent className="p-0">
                            <div className="flex flex-col lg:flex-row divide-y lg:divide-y-0 lg:divide-x divide-slate-800/50">
                                <div className="p-8 lg:w-48 flex flex-col items-center justify-center bg-slate-950/20">
                                    <div className={`text-5xl font-black tracking-tighter ${profile.riskScore >= 70 ? 'text-rose-500' :
                                            profile.riskScore >= 40 ? 'text-amber-400' :
                                                'text-indigo-400'
                                        }`}>
                                        {profile.riskScore}
                                    </div>
                                    <div className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-600 mt-2">Criticality</div>
                                </div>

                                <div className="flex-1 p-8 space-y-6">
                                    <div className="flex flex-wrap items-center justify-between gap-4">
                                        <div className="flex items-center gap-4">
                                            <Badge className={`px-3 py-1 text-[9px] font-black uppercase tracking-widest ${profile.entityType === 'customer'
                                                    ? 'bg-blue-500/10 text-blue-400 border-blue-500/20'
                                                    : 'bg-purple-500/10 text-purple-400 border-purple-500/20'
                                                }`}>
                                                {profile.entityType === 'customer' ? <User size={10} className="mr-1.5" /> : <Wrench size={10} className="mr-1.5" />}
                                                {profile.entityType} Entity
                                            </Badge>
                                            <div className="flex items-center gap-1.5 px-3 py-1 bg-slate-950/50 border border-slate-800/50 rounded-lg">
                                                <Hash size={10} className="text-slate-600" />
                                                <span className="text-[9px] font-mono font-black text-slate-500 uppercase tracking-tighter">UID-{profile.entityId.substring(0, 12).toUpperCase()}</span>
                                            </div>
                                        </div>

                                        <Badge className={`px-3 py-1 text-[10px] font-black uppercase tracking-widest ${profile.status === 'suspended' ? 'bg-rose-500 text-white border-transparent' :
                                                profile.status === 'restricted' ? 'bg-amber-500/10 text-amber-400 border-amber-500/20' :
                                                    profile.status === 'monitored' ? 'bg-indigo-500/10 text-indigo-400 border-indigo-500/20' :
                                                        'bg-slate-800 text-slate-400'
                                            }`}>
                                            {profile.status}
                                        </Badge>
                                    </div>

                                    <div className="flex flex-wrap gap-2">
                                        {profile.flags?.map((flag: string) => (
                                            <div key={flag} className="flex items-center gap-2 px-3 py-1.5 bg-slate-800/40 border border-slate-700/50 rounded-lg group-hover:bg-slate-800/60 transition-colors">
                                                <Zap size={10} className="text-amber-500" />
                                                <span className="text-[10px] font-black text-slate-300 uppercase tracking-tight">{flag.replaceAll('_', ' ')}</span>
                                            </div>
                                        ))}
                                        {(!profile.flags || profile.flags.length === 0) && (
                                            <div className="text-xs text-slate-500 font-medium italic opacity-60">No specific cryptographic flags detected. Monitoring baseline behavioral shift.</div>
                                        )}
                                    </div>
                                </div>

                                <div className="p-8 lg:w-64 bg-slate-950/20 flex flex-col justify-center gap-3">
                                    {profile.status !== 'suspended' ? (
                                        <Button
                                            variant="outline"
                                            onClick={() => handleChangeStatus(profile.entityId, 'suspended')}
                                            className="w-full h-11 bg-rose-500/10 border-rose-500/20 text-rose-400 hover:bg-rose-600 hover:text-white font-black uppercase text-[10px] tracking-widest rounded-xl transition-all border-none"
                                        >
                                            <Ban size={14} className="mr-2" /> Quarantine
                                        </Button>
                                    ) : (
                                        <Button
                                            variant="outline"
                                            onClick={() => handleChangeStatus(profile.entityId, 'monitored')}
                                            className="w-full h-11 bg-emerald-500/10 border-emerald-500/20 text-emerald-400 hover:bg-emerald-600 hover:text-white font-black uppercase text-[10px] tracking-widest rounded-xl transition-all border-none"
                                        >
                                            <CheckCircle2 size={14} className="mr-2" /> Re-Authorize
                                        </Button>
                                    )}

                                    <Button
                                        variant="outline"
                                        onClick={() => handleResetScore(profile.entityId)}
                                        className="w-full h-11 bg-slate-900/50 border-slate-800 text-slate-500 hover:text-indigo-400 hover:border-indigo-500/30 font-black uppercase text-[10px] tracking-widest rounded-xl transition-all"
                                    >
                                        <RefreshCw size={14} className="mr-2" /> Reset Metrics
                                    </Button>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                ))}
            </div>
        </div>
    );
}
