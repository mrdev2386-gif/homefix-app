
'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { adminApi } from '@/lib/admin-api';
import {
    ArrowLeft, Mail, Smartphone, Wallet, ShieldAlert,
    ShieldCheck, Clock, Hash, Calendar, History,
    User, HardDrive, Key, AlertTriangle, CheckCircle2
} from 'lucide-react';

import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';

export default function UserDetailPage() {
    const params = useParams();
    const router = useRouter();
    const userId = params.id as string;

    const [user, setUser] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [updating, setUpdating] = useState(false);

    const [editMode, setEditMode] = useState(false);
    const [formData, setFormData] = useState({
        name: '',
        role: '',
    });

    useEffect(() => {
        fetchUserDetails();
    }, [userId]);

    const fetchUserDetails = async () => {
        setLoading(true);
        try {
            const data = await adminApi.getUserById(userId);
            setUser(data);
            setFormData({
                name: data.name || '',
                role: data.role || 'customer',
            });
        } catch (e: any) {
            console.error('Failed to fetch user:', e);
            alert(`Error: ${e.message}`);
        } finally {
            setLoading(false);
        }
    };

    const handleUpdateUser = async () => {
        setUpdating(true);
        try {
            await adminApi.updateUser(userId, formData);
            await fetchUserDetails();
            setEditMode(false);
        } catch (e: any) {
            alert(`Update failed: ${e.message}`);
        } finally {
            setUpdating(false);
        }
    };

    const handleBlockToggle = async () => {
        const action = user.isBlocked ? 'unblock' : 'block';
        if (!confirm(`Are you sure you want to ${action} this user?`)) return;

        setUpdating(true);
        try {
            await adminApi.blockUser(userId, !user.isBlocked);
            await fetchUserDetails();
        } catch (e: any) {
            alert(`Action failed: ${e.message}`);
        } finally {
            setUpdating(false);
        }
    };

    if (loading) return (
        <div className="flex flex-col gap-6 animate-pulse p-8">
            <div className="h-10 w-48 bg-slate-800 rounded-lg" />
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-2 space-y-8">
                    <div className="h-64 bg-slate-800 rounded-3xl" />
                    <div className="h-96 bg-slate-800 rounded-3xl" />
                </div>
                <div className="h-[600px] bg-slate-800 rounded-3xl" />
            </div>
        </div>
    );

    if (!user) return <div className="p-8 text-white">User not found</div>;

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto pb-20">
            {/* Header */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div className="flex items-center gap-4">
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={() => router.back()}
                        className="h-12 w-12 p-0 rounded-2xl border-slate-800 bg-slate-900/50 text-slate-400 hover:text-white"
                    >
                        <ArrowLeft size={20} />
                    </Button>
                    <div>
                        <div className="flex items-center gap-3">
                            <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase">
                                {user.name || 'Anonymous Entity'}
                            </h1>
                            {user.isBlocked ? (
                                <Badge className="bg-red-500/10 text-red-400 border-red-500/20 font-black text-[10px] uppercase tracking-widest px-3 py-1.5">
                                    Restricted
                                </Badge>
                            ) : (
                                <Badge className="bg-emerald-500/10 text-emerald-400 border-emerald-500/20 font-black text-[10px] uppercase tracking-widest px-3 py-1.5">
                                    Verified
                                </Badge>
                            )}
                        </div>
                        <div className="flex items-center gap-2 mt-1">
                            <Hash size={12} className="text-indigo-500" />
                            <span className="text-xs font-mono font-bold text-slate-500 uppercase tracking-tighter">{user.id}</span>
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-3">
                    <Button
                        variant="outline"
                        className={`h-12 rounded-2xl border-slate-800 font-black uppercase tracking-widest text-[10px] px-6 transition-all ${user.isBlocked
                                ? "bg-indigo-500/10 text-indigo-400 border-indigo-500/20 hover:bg-indigo-500 hover:text-white"
                                : "bg-red-500/10 text-red-400 border-red-500/20 hover:bg-red-500 hover:text-white"
                            }`}
                        onClick={handleBlockToggle}
                        disabled={updating}
                    >
                        {user.isBlocked ? <ShieldCheck size={16} className="mr-2" /> : <ShieldAlert size={16} className="mr-2" />}
                        {user.isBlocked ? 'Restore Privileges' : 'Revoke Access'}
                    </Button>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Profile Information */}
                <div className="lg:col-span-2 space-y-8">
                    <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md rounded-3xl overflow-hidden">
                        <CardHeader className="p-8 border-b border-slate-800/50">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <div className="w-10 h-10 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center">
                                        <User size={20} className="text-indigo-400" />
                                    </div>
                                    <CardTitle className="text-xl font-black text-white uppercase tracking-tight">Personnel Profile</CardTitle>
                                </div>
                                {!editMode ? (
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={() => setEditMode(true)}
                                        className="h-9 rounded-xl border-slate-800 bg-slate-900/50 text-[10px] font-black uppercase tracking-widest text-slate-400 hover:text-white"
                                    >
                                        Edit Credentials
                                    </Button>
                                ) : (
                                    <div className="flex items-center gap-2">
                                        <Button
                                            variant="outline"
                                            size="sm"
                                            onClick={() => setEditMode(false)}
                                            className="h-9 rounded-xl border-slate-800 bg-slate-900/50 text-[10px] font-black uppercase tracking-widest text-slate-500"
                                        >
                                            Cancel
                                        </Button>
                                        <Button
                                            variant="outline"
                                            size="sm"
                                            onClick={handleUpdateUser}
                                            disabled={updating}
                                            className="h-9 rounded-xl border-indigo-500/30 bg-indigo-500/10 text-[10px] font-black uppercase tracking-widest text-indigo-400 hover:bg-indigo-500 hover:text-white"
                                        >
                                            {updating ? 'Processing...' : 'Apply Changes'}
                                        </Button>
                                    </div>
                                )}
                            </div>
                        </CardHeader>
                        <CardContent className="p-8">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                                <div className="space-y-6">
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Legal Name</label>
                                        {editMode ? (
                                            <Input
                                                value={formData.name}
                                                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                                className="bg-slate-900 border-slate-800 rounded-xl text-white"
                                            />
                                        ) : (
                                            <div className="text-lg font-bold text-slate-200">{user.name || 'Not Provided'}</div>
                                        )}
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Authority Level</label>
                                        {editMode ? (
                                            <select
                                                className="w-full h-10 px-3 rounded-xl bg-slate-900 border border-slate-800 text-sm font-bold text-white focus:outline-none focus:ring-1 focus:ring-indigo-500"
                                                value={formData.role}
                                                onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                                            >
                                                <option value="customer">Customer</option>
                                                <option value="technician">Technician</option>
                                                <option value="admin">Administrator</option>
                                            </select>
                                        ) : (
                                            <Badge className="bg-slate-800 text-slate-400 border-slate-700 font-black text-[10px] uppercase tracking-widest">
                                                {user.role || 'customer'}
                                            </Badge>
                                        )}
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Authentication Provider</label>
                                        <div className="flex gap-2">
                                            {user.authProvider?.map((p: string) => (
                                                <Badge key={p} className="bg-indigo-500/10 text-indigo-400 border-indigo-500/20 font-bold">
                                                    {p === 'password' ? <Key size={10} className="mr-1.5" /> : <Smartphone size={10} className="mr-1.5" />}
                                                    {p}
                                                </Badge>
                                            ))}
                                        </div>
                                    </div>
                                </div>
                                <div className="space-y-6 text-xl">
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Primary Contact (Email)</label>
                                        <div className="flex items-center gap-3 text-slate-300 font-bold">
                                            <Mail size={16} className="text-slate-600" />
                                            {user.email || 'N/A'}
                                        </div>
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Contact Number</label>
                                        <div className="flex items-center gap-3 text-slate-300 font-bold uppercase tracking-wider">
                                            <Smartphone size={16} className="text-slate-600" />
                                            {user.phoneNumber || user.phone || 'N/A'}
                                        </div>
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Registered Date</label>
                                        <div className="flex items-center gap-3 text-slate-300 font-bold">
                                            <Calendar size={16} className="text-slate-600" />
                                            {user.createdAt ? new Date(user.createdAt.seconds * 1000).toLocaleString() : 'Legacy'}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Booking History */}
                    <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md rounded-3xl overflow-hidden">
                        <CardHeader className="p-8 border-b border-slate-800/50">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center">
                                    <History size={20} className="text-amber-400" />
                                </div>
                                <CardTitle className="text-xl font-black text-white uppercase tracking-tight">Recent Deployments</CardTitle>
                            </div>
                        </CardHeader>
                        <CardContent className="p-0">
                            {!user.bookingHistory || user.bookingHistory.length === 0 ? (
                                <div className="p-12 text-center">
                                    <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-slate-800 text-slate-600 mb-4">
                                        <AlertTriangle size={32} />
                                    </div>
                                    <h3 className="text-slate-400 font-bold uppercase tracking-widest text-xs">No Deployment Records Found</h3>
                                </div>
                            ) : (
                                <div className="divide-y divide-slate-800/50">
                                    {user.bookingHistory.map((job: any) => (
                                        <div key={job.id} className="p-6 flex items-center justify-between hover:bg-white/5 transition-colors group">
                                            <div className="flex items-center gap-4">
                                                <div className="w-12 h-12 rounded-xl bg-slate-800 flex items-center justify-center border border-slate-700">
                                                    <CheckCircle2 size={24} className={job.status === 'completed' ? 'text-emerald-500' : 'text-slate-600'} />
                                                </div>
                                                <div>
                                                    <div className="text-sm font-black text-white leading-tight uppercase tracking-tight">{job.serviceTitle}</div>
                                                    <div className="text-[10px] font-bold text-slate-500 mt-1 uppercase tracking-widest">
                                                        {new Date(job.createdAt.seconds * 1000).toLocaleDateString()} • {job.id.substring(0, 8)}
                                                    </div>
                                                </div>
                                            </div>
                                            <div className="text-right">
                                                <div className="text-sm font-black text-white tracking-widest">₹{(job.finalAmount || job.price).toLocaleString()}</div>
                                                <Badge className={`text-[9px] uppercase tracking-widest mt-1 ${job.status === 'completed' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-amber-500/10 text-amber-400'
                                                    }`}>
                                                    {job.status}
                                                </Badge>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </div>

                {/* Account Metadata & Stats */}
                <div className="space-y-8">
                    <Card className="border-slate-800 bg-indigo-500/5 backdrop-blur-md rounded-3xl border-indigo-500/20">
                        <CardContent className="p-8 space-y-6">
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-indigo-400 uppercase tracking-widest">Wallet Capital</label>
                                <div className="flex items-center justify-between">
                                    <div className="text-4xl font-black text-white tracking-tighter">₹{(user.walletBalance || 0).toLocaleString()}</div>
                                    <div className="w-12 h-12 rounded-2xl bg-indigo-500/10 flex items-center justify-center border border-indigo-500/20 shadow-lg shadow-indigo-500/10 text-indigo-400">
                                        <Wallet size={24} />
                                    </div>
                                </div>
                            </div>
                            <div className="h-px bg-indigo-500/10" />
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <div className="text-[9px] font-black text-slate-500 uppercase tracking-widest mb-1">Last Login</div>
                                    <div className="text-xs font-bold text-slate-300">
                                        {user.lastLogin ? new Date(user.lastLogin).toLocaleDateString() : 'N/A'}
                                    </div>
                                </div>
                                <div>
                                    <div className="text-[9px] font-black text-slate-500 uppercase tracking-widest mb-1">Reliability</div>
                                    <div className="text-xs font-bold text-emerald-400 uppercase tracking-widest">Tier 1 Elite</div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md rounded-3xl">
                        <CardHeader className="p-8 pb-4">
                            <CardTitle className="text-xs font-black text-slate-500 uppercase tracking-widest flex items-center gap-2">
                                <HardDrive size={12} className="text-slate-600" />
                                Identity Metadata
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="p-8 pt-0 space-y-4">
                            <div className="p-4 rounded-2xl bg-slate-950/50 border border-slate-800/50 space-y-3">
                                <div className="flex justify-between items-center">
                                    <span className="text-[10px] font-bold text-slate-600 uppercase">Disabled (Auth)</span>
                                    <Badge className={user.disabled ? 'bg-red-500/10 text-red-500 border-red-500/20' : 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20'}>
                                        {user.disabled ? 'TRUE' : 'FALSE'}
                                    </Badge>
                                </div>
                                <div className="flex justify-between items-center">
                                    <span className="text-[10px] font-bold text-slate-600 uppercase">Provider ID</span>
                                    <span className="text-[10px] font-mono text-slate-400 uppercase">{user.authProvider?.[0] || 'Unknown'}</span>
                                </div>
                                <div className="flex justify-between items-center">
                                    <span className="text-[10px] font-bold text-slate-600 uppercase">Global Verified</span>
                                    <Badge className={user.isVerified ? 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20' : 'bg-slate-800 text-slate-500 border-slate-700'}>
                                        {user.isVerified ? 'SECURED' : 'PENDING'}
                                    </Badge>
                                </div>
                            </div>
                            <div className="p-4 rounded-2xl bg-amber-500/5 border border-amber-500/10">
                                <div className="flex gap-3">
                                    <AlertTriangle size={16} className="text-amber-500 shrink-0" />
                                    <p className="text-[10px] font-bold text-amber-500/80 uppercase leading-relaxed tracking-wide">
                                        All modifications to identity metadata are logged and audited in the global registry.
                                    </p>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    );
}
