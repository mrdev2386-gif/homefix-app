'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, limit, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import {
    ClipboardList, Clock, Shield, Search, Filter, History,
    UserCheck, Terminal, MoreHorizontal, ChevronRight, Activity,
    Database, ShieldCheck, Key, Hash, Code
} from 'lucide-react';
import { Card, CardContent, CardHeader } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import Table from '@/components/ui/Table';
import { Badge } from '@/components/ui/Badge';

export default function LogsPage() {
    const [logs, setLogs] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        const fetchLogs = async () => {
            try {
                const q = query(collection(db, 'admin_logs'), orderBy('timestamp', 'desc'), limit(100));
                const snap = await getDocs(q);
                setLogs(snap.docs.map(d => ({ id: d.id, ...d.data() })));
            } catch (error) {
                console.error(error);
            } finally {
                setLoading(false);
            }
        };
        fetchLogs();
    }, []);

    const getActionTheme = (action: string) => {
        const a = action.toLowerCase();
        if (a.includes('delete') || a.includes('reject') || a.includes('cancel'))
            return 'bg-red-500/10 text-red-400 border-red-500/20';
        if (a.includes('create') || a.includes('approve') || a.includes('success'))
            return 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20';
        if (a.includes('update') || a.includes('edit') || a.includes('modify'))
            return 'bg-amber-500/10 text-amber-400 border-amber-500/20';
        return 'bg-indigo-500/10 text-indigo-400 border-indigo-500/20';
    };

    const filteredLogs = logs.filter(log =>
        log.action?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        log.adminUid?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        log.targetId?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const columns = [
        {
            key: 'timestamp',
            label: 'Temporal Marker',
            render: (l: any) => (
                <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-500">
                        <Clock size={16} strokeWidth={2.5} />
                    </div>
                    <div className="flex flex-col">
                        <span className="text-[11px] font-black text-white tracking-tight leading-tight uppercase">
                            {l.timestamp?.seconds ? new Date(l.timestamp.seconds * 1000).toLocaleDateString(undefined, { day: '2-digit', month: 'short' }) : 'RECENT'}
                        </span>
                        <span className="text-[10px] font-black text-indigo-500 uppercase tracking-widest font-mono mt-0.5">
                            {l.timestamp?.seconds ? new Date(l.timestamp.seconds * 1000).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit' }) : 'LOGGING'}
                        </span>
                    </div>
                </div>
            )
        },
        {
            key: 'operator',
            label: 'Operator Identity',
            render: (l: any) => (
                <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-indigo-500/5 border border-indigo-500/10 flex items-center justify-center">
                        <UserCheck size={14} className="text-indigo-400" />
                    </div>
                    <span className="text-[11px] font-bold font-mono text-slate-400 tracking-tighter uppercase">
                        OPER-{l.adminUid.substring(0, 8).toUpperCase()}
                    </span>
                </div>
            )
        },
        {
            key: 'action',
            label: 'Instruction Execution',
            render: (l: any) => (
                <Badge className={`${getActionTheme(l.action)} px-3 py-1 font-black text-[9px] uppercase tracking-[0.2em]`}>
                    {l.action.replace('admin_', '').replace('_', ' ')}
                </Badge>
            )
        },
        {
            key: 'target',
            label: 'Logic Target',
            render: (l: any) => (
                <div className="flex items-center gap-2">
                    <Shield size={12} className="text-slate-600" />
                    <span className="text-[10px] font-black font-mono text-slate-500 uppercase tracking-widest">
                        {l.targetId ? l.targetId.substring(0, 10).toUpperCase() : 'PLATFORM_KERNEL'}
                    </span>
                </div>
            )
        },
        {
            key: 'metadata',
            label: 'State Payload',
            render: (l: any) => (
                <div className="max-w-[180px] bg-slate-950/50 px-3 py-2 rounded-lg border border-slate-800/50 overflow-hidden text-ellipsis whitespace-nowrap font-mono text-[9px] font-bold text-slate-600 group-hover:text-indigo-400 transition-colors">
                    {l.metadata ? JSON.stringify(l.metadata) : 'N/A'}
                </div>
            )
        },
        {
            key: 'verification',
            label: 'Integrity',
            align: 'right' as const,
            render: () => (
                <div className="flex justify-end pr-4">
                    <div className="w-6 h-6 rounded-full bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-500">
                        <ShieldCheck size={12} strokeWidth={3} />
                    </div>
                </div>
            )
        }
    ];

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase tracking-tighter">Audit Infrastructure</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Immutable sequence of all administrative logic executions and system mutations.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            Live Telemetry Stream
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-3">
                    <div className="relative group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                        <Input
                            placeholder="Identify operator, target or logic..."
                            className="w-full md:w-80 pl-10 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                    <Button variant="outline" className="h-12 w-12 p-0 border-slate-800 bg-slate-900/50 rounded-xl hover:bg-slate-800">
                        <Terminal size={20} className="text-slate-500" />
                    </Button>
                </div>
            </div>

            <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-3xl">
                <CardContent className="p-0">
                    <Table
                        columns={columns}
                        data={filteredLogs}
                        loading={loading}
                        emptyMessage="No cryptographic traces found in the current viewport."
                        className="[&_tr]:border-slate-800/50 [&_th]:bg-transparent [&_th]:text-slate-500 [&_th]:text-[10px] [&_th]:font-black [&_th]:uppercase [&_th]:tracking-[0.2em] [&_th]:py-6"
                    />
                </CardContent>
            </Card>
        </div>
    );
}
