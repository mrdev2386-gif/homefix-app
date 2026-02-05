'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, limit, onSnapshot } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { adminApi, DashboardStats } from '@/lib/admin-api';
import {
    Users, Wrench, DollarSign, Activity, AlertCircle, ShoppingBag,
    ArrowUpRight, ArrowDownRight, RefreshCw, Layers
} from 'lucide-react';
import DashboardCharts from '@/components/DashboardCharts';
import StatusBadge from '@/components/ui/StatusBadge';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import Table from '@/components/ui/Table';

export default function Dashboard() {
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [recentBookings, setRecentBookings] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [refreshing, setRefreshing] = useState(false);

    const fetchStats = async (isManual = false) => {
        if (isManual) setRefreshing(true);
        try {
            const data = await adminApi.getDashboardStats();
            setStats(data);
        } catch (e) {
            console.error('Failed to fetch dashboard stats:', e);
        } finally {
            setLoading(false);
            setRefreshing(false);
        }
    };

    useEffect(() => {
        fetchStats();

        // Real-time bookings feed
        const q = query(collection(db, 'bookings'), orderBy('createdAt', 'desc'), limit(10));
        const unsubscribe = onSnapshot(q, (snap) => {
            setRecentBookings(snap.docs.map(d => ({ id: d.id, ...d.data() })));
        });

        // Poll stats every 2 minutes
        const interval = setInterval(fetchStats, 120000);

        return () => {
            unsubscribe();
            clearInterval(interval);
        };
    }, []);

    const StatCard = ({ title, value, icon: Icon, trend, trendValue, description, color }: any) => (
        <Card className="overflow-hidden border-slate-800/50 bg-slate-900/40 backdrop-blur-sm group hover:border-indigo-500/30 transition-all duration-300">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-xs font-bold uppercase tracking-wider text-slate-500">
                    {title}
                </CardTitle>
                <div className={`p-2 rounded-lg bg-slate-800 border border-slate-700 text-slate-400 group-hover:text-white group-hover:bg-indigo-600 transition-all duration-300 shadow-sm`}>
                    <Icon className="h-4 w-4" />
                </div>
            </CardHeader>
            <CardContent>
                <div className="text-3xl font-black text-white tracking-tight">{value}</div>
                <div className="flex items-center gap-2 mt-2">
                    {trend && (
                        <div className={`flex items-center gap-0.5 text-[10px] font-bold px-1.5 py-0.5 rounded-full ${trend === 'up' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-red-500/10 text-red-500 border border-red-500/20'
                            }`}>
                            {trend === 'up' ? <ArrowUpRight size={10} /> : <ArrowDownRight size={10} />}
                            {trendValue}
                        </div>
                    )}
                    {description && (
                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-widest leading-none">
                            {description}
                        </p>
                    )}
                </div>
            </CardContent>
            {/* Subtle bottom gradient */}
            <div className={`h-1 w-full absolute bottom-0 left-0 transition-opacity opacity-0 group-hover:opacity-100 duration-500 ${color || 'bg-indigo-500'}`} />
        </Card>
    );

    if (loading) {
        return (
            <div className="py-20 flex flex-col items-center justify-center gap-4">
                <div className="relative">
                    <div className="w-12 h-12 border-4 border-indigo-500/20 rounded-full"></div>
                    <div className="w-12 h-12 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin absolute top-0 left-0"></div>
                </div>
                <p className="text-slate-500 text-[10px] font-black uppercase tracking-[0.3em] animate-pulse">Loading Analytics...</p>
            </div>
        );
    }

    const columns = [
        {
            key: 'id',
            label: 'Order ID',
            render: (b: any) => <span className="font-mono text-[10px] text-slate-500 font-bold tracking-tighter">#{b.id.substring(0, 8).toUpperCase()}</span>
        },
        {
            key: 'serviceTitle',
            label: 'Service',
            render: (b: any) => (
                <div className="flex flex-col">
                    <span className="font-bold text-sm text-slate-200">{b.serviceTitle}</span>
                    <span className="text-[10px] text-slate-500 font-medium">{b.subServiceTitle || 'Standard'}</span>
                </div>
            )
        },
        {
            key: 'customerName',
            label: 'Customer',
            render: (b: any) => <span className="text-sm font-semibold text-slate-300">{b.customerName || 'Guest'}</span>
        },
        {
            key: 'amount',
            label: 'Amount',
            render: (b: any) => <span className="font-black text-white">₹{b.finalAmount || b.totalAmount || 0}</span>
        },
        {
            key: 'status',
            label: 'Status',
            align: 'right' as const,
            render: (b: any) => <div className="flex justify-end"><StatusBadge status={b.status} /></div>
        }
    ];

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto">
            <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-4xl font-black tracking-tight text-white mb-1">Command Center</h1>
                    <div className="flex items-center gap-2">
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-emerald-500/10 text-emerald-400 rounded-md border border-emerald-500/20 text-[10px] font-black uppercase tracking-widest">
                            <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
                            Live System
                        </div>
                        <p className="text-slate-500 text-sm font-medium italic">Your platform at a glance.</p>
                    </div>
                </div>
                <div className="flex items-center gap-3">
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={() => fetchStats(true)}
                        disabled={refreshing}
                        className="bg-slate-900/50 border-slate-800 text-slate-300 hover:text-white hover:bg-slate-800 flex items-center gap-2 rounded-xl h-10 px-4"
                    >
                        <RefreshCw size={14} className={refreshing ? 'animate-spin' : ''} />
                        <span className="text-xs font-bold uppercase tracking-widest">Refresh Data</span>
                    </Button>
                </div>
            </header>

            {/* Quick Metrics */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <StatCard
                    title="Gross Revenue"
                    value={`₹${stats?.counters?.totalRevenue?.toLocaleString() || 0}`}
                    icon={DollarSign}
                    trend="up"
                    trendValue="12.5%"
                    description="vs last period"
                    color="bg-emerald-500"
                />
                <StatCard
                    title="Active Bookings"
                    value={stats?.counters?.activeBookings || 0}
                    icon={ShoppingBag}
                    description="Current focus"
                    color="bg-indigo-500"
                />
                <StatCard
                    title="Verified Techs"
                    value={stats?.counters?.totalTechnicians || 0}
                    icon={Wrench}
                    description={`+${stats?.counters?.onlineTechnicians || 0} currently online`}
                    color="bg-amber-500"
                />
                <StatCard
                    title="KYC Pending"
                    value={stats?.counters?.pendingKYC || 0}
                    icon={Users}
                    description="Awaiting Approval"
                    color="bg-red-500"
                />
            </div>

            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-7">
                <div className="col-span-4 h-full">
                    <Card className="h-full border-slate-800 bg-slate-900/40 backdrop-blur-sm">
                        <CardHeader className="flex flex-row items-center justify-between">
                            <div className="space-y-1">
                                <CardTitle className="text-xl font-black text-white">Revenue Performance</CardTitle>
                                <CardDescription className="text-slate-500 text-xs uppercase font-bold tracking-widest">Growth metrics over time</CardDescription>
                            </div>
                            <div className="p-2 rounded-lg bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
                                <Activity size={18} />
                            </div>
                        </CardHeader>
                        <CardContent className="h-[350px]">
                            <DashboardCharts data={stats?.chartData || []} />
                        </CardContent>
                    </Card>
                </div>

                <div className="col-span-3 space-y-6">
                    <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-sm">
                        <CardHeader>
                            <CardTitle className="text-lg font-black text-white flex items-center gap-2">
                                <Layers className="h-4 w-4 text-indigo-400" />
                                Order Distribution
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            {[
                                { label: 'Pending Payment', value: stats?.counters?.pendingBookings || 0, color: 'bg-amber-500' },
                                { label: 'Confirmed', value: stats?.counters?.confirmedBookings || 0, color: 'bg-indigo-500' },
                                { label: 'Completed', value: stats?.counters?.completedBookings || 0, color: 'bg-emerald-500' },
                                { label: 'Cancelled', value: stats?.counters?.cancelledBookings || 0, color: 'bg-red-500' },
                            ].map((item) => (
                                <div key={item.label} className="group cursor-default">
                                    <div className="flex items-center justify-between mb-1.5">
                                        <div className="flex items-center gap-2.5">
                                            <div className={`w-2 h-2 rounded-full ${item.color} shadow-[0_0_8px_rgba(0,0,0,0.3)]`}></div>
                                            <span className="text-xs font-bold text-slate-400 group-hover:text-slate-200 transition-colors uppercase tracking-widest">{item.label}</span>
                                        </div>
                                        <span className="font-black text-white">{item.value}</span>
                                    </div>
                                    <div className="w-full bg-slate-800 h-1.5 rounded-full overflow-hidden">
                                        <div
                                            className={`${item.color} h-full transition-all duration-1000 ease-out`}
                                            style={{ width: `${stats ? (item.value / (stats.counters.pendingBookings + stats.counters.confirmedBookings + stats.counters.completedBookings + stats.counters.cancelledBookings || 1) * 100) : 0}%` }}
                                        />
                                    </div>
                                </div>
                            ))}
                        </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-br from-indigo-600 to-violet-700 text-white border-transparent shadow-xl shadow-indigo-500/10">
                        <CardHeader>
                            <CardTitle className="text-white flex items-center gap-2 font-black italic tracking-tighter text-xl">
                                <Activity className="h-5 w-5 animate-pulse" />
                                LIVE FEED
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="text-4xl font-black tracking-tighter">{stats?.counters?.onlineTechnicians || 0}</div>
                            <p className="text-indigo-100 text-[10px] font-black uppercase tracking-[0.2em] mt-1">Experts Active Now</p>

                            <div className="mt-6 p-3 bg-white/10 rounded-xl border border-white/10 backdrop-blur-sm">
                                <div className="flex items-center justify-between text-[10px] font-black uppercase tracking-widest">
                                    <span className="text-indigo-200">System Stability</span>
                                    <span className="text-white">99.9%</span>
                                </div>
                                <div className="w-full bg-white/20 h-1 rounded-full mt-2">
                                    <div className="bg-white h-full w-[99.9%] rounded-full"></div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>

            {/* Recent Activity Table */}
            <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-sm overflow-hidden">
                <CardHeader className="flex flex-row items-center justify-between border-b border-slate-800/50 pb-6">
                    <div>
                        <CardTitle className="text-xl font-black text-white">Recent Transactions</CardTitle>
                        <CardDescription className="text-slate-500 text-xs font-bold uppercase tracking-widest mt-1">Real-time booking audit</CardDescription>
                    </div>
                </CardHeader>
                <div className="overflow-x-auto">
                    <Table
                        columns={columns}
                        data={recentBookings}
                        loading={false}
                        emptyMessage="Awaiting fresh system activity..."
                    />
                </div>
            </Card>
        </div>
    );
}
