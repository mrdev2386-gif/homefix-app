
'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import { adminApi } from '@/lib/admin-api';
import {
    Search, Mail, Smartphone, Wallet, Ban, UserCheck,
    Activity, ShieldAlert, ShieldCheck, Clock, Hash,
    Eye, Filter, ChevronLeft, ChevronRight
} from 'lucide-react';

import Table from '@/components/ui/Table';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Card, CardContent } from '@/components/ui/Card';

export default function UsersPage() {
    const [users, setUsers] = useState<any[]>([]);
    const [total, setTotal] = useState(0);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(true);
    const [processingId, setProcessingId] = useState<string | null>(null);
    const [page, setPage] = useState(1);
    const [limit] = useState(10);
    const [roleFilter, setRoleFilter] = useState('');
    const [statusFilter, setStatusFilter] = useState('');

    const fetchUsers = useCallback(async () => {
        setLoading(true);
        try {
            const data = await adminApi.getUsers({
                limit,
                offset: (page - 1) * limit,
                search: searchTerm,
                role: roleFilter || undefined,
                status: statusFilter || undefined
            });
            setUsers(data.users);
            setTotal(data.total);
        } catch (e) {
            console.error('Failed to fetch users:', e);
        } finally {
            setLoading(false);
        }
    }, [page, limit, searchTerm, roleFilter, statusFilter]);

    useEffect(() => {
        const timeout = setTimeout(fetchUsers, 500);
        return () => clearTimeout(timeout);
    }, [fetchUsers]);

    const handleBlockUser = async (userId: string, currentlyBlocked: boolean) => {
        if (!confirm(`Are you sure you want to ${currentlyBlocked ? 'unblock' : 'block'} this user?`)) return;

        setProcessingId(userId);
        const previousUsers = [...users];

        // Optimistic update
        setUsers(users.map(u => u.id === userId ? { ...u, isBlocked: !currentlyBlocked } : u));

        try {
            await adminApi.blockUser(userId, !currentlyBlocked);
        } catch (e: any) {
            console.error('Failed to update user status:', e);
            setUsers(previousUsers); // Rollback
            alert(`Operation failed: ${e.message || 'Unknown error'}`);
        } finally {
            setProcessingId(null);
        }
    };

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
                        <span className="text-[11px] font-bold text-slate-400 group-hover/text:text-indigo-400 transition-colors">{u.email || 'No email'}</span>
                    </div>
                    {u.phoneNumber && (
                        <div className="flex items-center gap-2 group/text">
                            <div className="w-5 h-5 rounded-md bg-emerald-500/5 border border-emerald-500/10 flex items-center justify-center">
                                <Smartphone size={10} className="text-emerald-400" />
                            </div>
                            <span className="text-[11px] font-bold text-slate-400 group-hover/text:text-emerald-400 transition-colors uppercase tracking-wider">{u.phoneNumber}</span>
                        </div>
                    )}
                </div>
            )
        },
        {
            key: 'role',
            label: 'Authority',
            render: (u: any) => (
                <Badge className={`font-black text-[9px] uppercase tracking-widest px-2.5 py-1 ${u.role === 'admin' ? "bg-amber-500/10 text-amber-400 border-amber-500/20" :
                        u.role === 'technician' ? "bg-blue-500/10 text-blue-400 border-blue-500/20" :
                            "bg-slate-500/10 text-slate-400 border-slate-500/20"
                    }`}>
                    {u.role || 'customer'}
                </Badge>
            )
        },
        {
            key: 'status',
            label: 'State',
            render: (u: any) => (
                u.isBlocked ? (
                    <Badge className="bg-red-500/10 text-red-400 border-red-500/20 font-black text-[9px] uppercase tracking-widest px-2.5 py-1">
                        <ShieldAlert size={10} className="mr-1.5" /> Restricted
                    </Badge>
                ) : (
                    <Badge className="bg-emerald-500/10 text-emerald-400 border-emerald-500/20 font-black text-[9px] uppercase tracking-widest px-2.5 py-1">
                        <ShieldCheck size={10} className="mr-1.5" /> Active
                    </Badge>
                )
            )
        },
        {
            key: 'joined',
            label: 'Timeline',
            render: (u: any) => (
                <div className="flex items-center gap-2">
                    <Clock size={12} className="text-slate-600" />
                    <div className="flex flex-col">
                        <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Joined</span>
                        <span className="text-[11px] font-bold text-slate-300">
                            {u.createdAt?.seconds ? new Date(u.createdAt.seconds * 1000).toLocaleDateString() : 'Unknown'}
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
                <div className="flex items-center justify-end gap-2">
                    <Link href={`/customers/${u.id}`}>
                        <Button variant="outline" size="sm" className="h-9 border-slate-800 text-[10px] font-black uppercase tracking-widest rounded-xl bg-slate-900/50 text-slate-400 hover:text-white hover:border-indigo-500/30">
                            <Eye size={14} className="mr-2" /> Details
                        </Button>
                    </Link>
                    <Button
                        disabled={processingId === u.id}
                        variant="outline"
                        size="sm"
                        className={`h-9 border-slate-800 text-[10px] font-black uppercase tracking-widest rounded-xl transition-all ${u.isBlocked
                            ? "bg-indigo-500/10 border-indigo-500/20 text-indigo-400 hover:bg-indigo-500 hover:text-white"
                            : "bg-slate-900/50 border-slate-800 text-slate-500 hover:border-red-500/30 hover:bg-red-500/10 hover:text-red-400"
                            }`}
                        onClick={() => handleBlockUser(u.id, u.isBlocked)}
                    >
                        {u.isBlocked ? <UserCheck size={14} /> : <Ban size={14} />}
                    </Button>
                </div>
            )
        }
    ];

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto pb-20">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase">User Registry</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Unified command center for security and identity management.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            {total} Indexed Entities
                        </div>
                    </div>
                </div>

                <div className="flex flex-wrap items-center gap-3">
                    <div className="flex items-center gap-2 bg-slate-900/50 border border-slate-800 rounded-xl px-3 h-12">
                        <Filter size={14} className="text-slate-500" />
                        <select
                            className="bg-transparent text-xs font-black text-slate-400 uppercase tracking-widest focus:outline-none"
                            value={roleFilter}
                            onChange={(e) => setRoleFilter(e.target.value)}
                        >
                            <option value="">All Roles</option>
                            <option value="customer">Customer</option>
                            <option value="technician">Technician</option>
                            <option value="admin">Admin</option>
                        </select>
                        <div className="w-px h-4 bg-slate-800 mx-2" />
                        <select
                            className="bg-transparent text-xs font-black text-slate-400 uppercase tracking-widest focus:outline-none"
                            value={statusFilter}
                            onChange={(e) => setStatusFilter(e.target.value)}
                        >
                            <option value="">All States</option>
                            <option value="active">Active</option>
                            <option value="blocked">Blocked</option>
                        </select>
                    </div>

                    <div className="relative group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                        <Input
                            placeholder="Identify by identity or contact..."
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
                        data={users}
                        loading={loading}
                        emptyMessage="The registry is currently clear."
                        className="[&_tr]:border-slate-800/50 [&_th]:bg-transparent [&_th]:text-slate-500 [&_th]:text-[10px] [&_th]:font-black [&_th]:uppercase [&_th]:tracking-[0.2em] [&_th]:py-6"
                    />

                    <div className="flex items-center justify-between p-6 border-t border-slate-800/50">
                        <span className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">
                            Showing {(page - 1) * limit + 1} to {Math.min(page * limit, total)} of {total} records
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
                            <div className="h-8 px-3 flex items-center bg-indigo-500/10 border border-indigo-500/20 rounded-lg">
                                <span className="text-xs font-black text-indigo-400">{page}</span>
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
