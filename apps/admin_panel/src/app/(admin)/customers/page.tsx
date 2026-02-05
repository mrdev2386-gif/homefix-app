'use client';

import { useEffect, useState } from 'react';
import { collection, query, onSnapshot, orderBy } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '@/lib/firebase';
import {
    Users, Search, Filter, Mail, Phone, Calendar,
    Wallet, Ban, UserCheck, MoreHorizontal, Activity,
    ShieldAlert, ShieldCheck, Scale, Globe, Smartphone,
    Clock, Hash, ArrowUpRight
} from 'lucide-react';

import Table from '@/components/ui/Table';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Card, CardHeader, CardContent } from '@/components/ui/Card';

export default function UsersPage() {
    const [users, setUsers] = useState<any[]>([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(true);
    const [processingId, setProcessingId] = useState<string | null>(null);

    useEffect(() => {
        const q = query(collection(db, 'users'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snap) => {
            setUsers(snap.docs.map(d => ({ id: d.id, ...d.data() })));
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    const handleManageUser = async (userId: string, action: string) => {
        if (!confirm(`Are you sure you want to ${action} this user?`)) return;
        setProcessingId(userId);
        try {
            const fn = httpsCallable(functions, 'admin_manageUser');
            await fn({ userId, action, type: 'customer' });
        } catch (e: any) {
            console.error('Failed to manage user:', e);
            alert(`Operation failed: ${e.message || 'Unknown error'}`);
        } finally {
            setProcessingId(null);
        }
    };

    const filteredUsers = users.filter(u =>
        u.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.phone?.includes(searchTerm)
    );

    const columns = [
        {
            key: 'name',
            label: 'Identity',
            render: (u: any) => (
                <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-2xl bg-slate-800 border border-slate-700 flex items-center justify-center overflow-hidden">
                        {u.profileImage ? (
                            <img src={u.profileImage} alt={u.name} className="w-full h-full object-cover" />
                        ) : (
                            <span className="text-xs font-black text-slate-500">{u.name?.[0] || 'U'}</span>
                        )}
                    </div>
                    <div className="flex flex-col">
                        <span className="font-black text-white text-sm tracking-tight">{u.name || 'Anonymous User'}</span>
                        <div className="flex items-center gap-1 mt-0.5">
                            <Hash size={10} className="text-indigo-500" />
                            <span className="text-[10px] font-mono font-bold text-slate-500 uppercase tracking-tighter">{u.id.substring(0, 10)}</span>
                        </div>
                    </div>
                </div>
            )
        },
        {
            key: 'contact',
            label: 'Communication',
            render: (u: any) => (
                <div className="flex flex-col gap-1.5">
                    <div className="flex items-center gap-2 group/text">
                        <div className="w-5 h-5 rounded-md bg-indigo-500/5 border border-indigo-500/10 flex items-center justify-center">
                            <Mail size={10} className="text-indigo-400" />
                        </div>
                        <span className="text-[11px] font-bold text-slate-400 group-hover/text:text-indigo-400 transition-colors">{u.email || 'No email registered'}</span>
                    </div>
                    {u.phone && (
                        <div className="flex items-center gap-2 group/text">
                            <div className="w-5 h-5 rounded-md bg-emerald-500/5 border border-emerald-500/10 flex items-center justify-center">
                                <Smartphone size={10} className="text-emerald-400" />
                            </div>
                            <span className="text-[11px] font-bold text-slate-400 group-hover/text:text-emerald-400 transition-colors uppercase tracking-wider">{u.phone}</span>
                        </div>
                    )}
                </div>
            )
        },
        {
            key: 'wallet',
            label: 'Capital',
            render: (u: any) => (
                <div className="flex items-center gap-3 bg-slate-900/50 border border-slate-800 px-3 py-1.5 rounded-xl w-fit">
                    <Wallet size={12} className="text-amber-500" />
                    <span className="text-[11px] font-black text-white tracking-widest leading-none mt-0.5">₹{(u.walletBalance || 0).toLocaleString()}</span>
                </div>
            )
        },
        {
            key: 'status',
            label: 'Account State',
            render: (u: any) => (
                u.isBlocked ? (
                    <Badge className="bg-red-500/10 text-red-400 border-red-500/20 font-black text-[9px] uppercase tracking-widest px-2.5 py-1">
                        <ShieldAlert size={10} className="mr-1.5" /> Restricted
                    </Badge>
                ) : (
                    <Badge className="bg-emerald-500/10 text-emerald-400 border-emerald-500/20 font-black text-[9px] uppercase tracking-widest px-2.5 py-1">
                        <ShieldCheck size={10} className="mr-1.5" /> Operational
                    </Badge>
                )
            )
        },
        {
            key: 'joined',
            label: 'Retention',
            render: (u: any) => (
                <div className="flex items-center gap-2">
                    <Clock size={12} className="text-slate-600" />
                    <div className="flex flex-col">
                        <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Signed Up</span>
                        <span className="text-[11px] font-bold text-slate-300">
                            {u.createdAt?.seconds ? new Date(u.createdAt.seconds * 1000).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' }) : 'LEGACY'}
                        </span>
                    </div>
                </div>
            )
        },
        {
            key: 'actions',
            label: 'Governance',
            align: 'right' as const,
            render: (u: any) => (
                <Button
                    disabled={processingId === u.id}
                    variant="outline"
                    size="sm"
                    className={`h-9 border-slate-800 text-[10px] font-black uppercase tracking-widest rounded-xl transition-all ${u.isBlocked
                        ? "bg-indigo-500/10 border-indigo-500/20 text-indigo-400 hover:bg-indigo-500 hover:text-white"
                        : "bg-slate-900/50 border-slate-800 text-slate-500 hover:border-red-500/30 hover:bg-red-500/10 hover:text-red-400"
                        }`}
                    onClick={() => handleManageUser(u.id, u.isBlocked ? 'unblock' : 'block')}
                >
                    {u.isBlocked ? <UserCheck size={14} className="mr-2" /> : <Ban size={14} className="mr-2" />}
                    {u.isBlocked ? 'Restore Access' : 'Restrict'}
                </Button>
            )
        }
    ];

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase">Customer Directory</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Global authority for user account management and access governance.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            {users.length} Index Records
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-3">
                    <div className="relative group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                        <Input
                            placeholder="Identify by name, mail or phone..."
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
                        data={filteredUsers}
                        loading={loading}
                        emptyMessage="The customer directory is currently clear."
                        className="[&_tr]:border-slate-800/50 [&_th]:bg-transparent [&_th]:text-slate-500 [&_th]:text-[10px] [&_th]:font-black [&_th]:uppercase [&_th]:tracking-[0.2em] [&_th]:py-6"
                        pagination={{
                            currentPage: 1,
                            totalPages: Math.ceil(filteredUsers.length / 10),
                            onPageChange: () => { }
                        }}
                    />
                </CardContent>
            </Card>
        </div>
    );
}
