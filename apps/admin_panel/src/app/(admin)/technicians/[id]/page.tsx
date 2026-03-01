
'use client';

import { useCallback, useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { adminApi } from '@/lib/admin-api';
import {
    ArrowLeft, Mail, Smartphone, Wallet, ShieldAlert,
    ShieldCheck, Clock, Hash, Calendar, History,
    Wrench, Briefcase, Star, MapPin, CheckCircle2,
    XCircle, FileText, IndianRupee, TrendingUp, AlertCircle
} from 'lucide-react';

import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';

export default function TechnicianDetailPage() {
    const params = useParams();
    const router = useRouter();
    const techId = params.id as string;

    const [tech, setTech] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [updating, setUpdating] = useState(false);

    const [editMode, setEditMode] = useState(false);
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        phone: '',
        city: '',
    });

    const fetchTechDetails = useCallback(async () => {
        setLoading(true);
        try {
            const data = await adminApi.getTechnicianById(techId) as any;
            if (!data) {
                console.warn('Technician not found');
                setLoading(false);
                return;
            }
            setTech(data as any);
            setFormData({
                name: data?.name || '',
                email: data?.email || '',
                phone: data?.phone || '',
                city: data?.city || '',
            });
        } catch (e: any) {
            console.error('Failed to fetch technician:', e);
            alert(`Error: ${e.message}`);
        } finally {
            setLoading(false);
        }
    }, [techId]);

    useEffect(() => {
        fetchTechDetails();
    }, [fetchTechDetails]);

    const handleUpdateTech = async () => {
        setUpdating(true);
        try {
            await adminApi.updateTechnician(techId, formData);
            await fetchTechDetails();
            setEditMode(false);
        } catch (e: any) {
            alert(`Update failed: ${e.message}`);
        } finally {
            setUpdating(false);
        }
    };

    const handleStatusToggle = async (approve: boolean) => {
        const action = approve ? 'verify' : 'block';
        if (!confirm(`Are you sure you want to ${action} this technician?`)) return;

        setUpdating(true);
        try {
            await adminApi.approveTechnician(techId, approve);
            await fetchTechDetails();
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

    if (!tech) return <div className="p-8 text-white">Technician not found</div>;

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
                                {tech.name || 'Anonymous Agent'}
                            </h1>
                            <Badge className={`font-black text-[10px] uppercase tracking-widest px-3 py-1.5 ${tech.status === 'approved' ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20" :
                                tech.status === 'pending' ? "bg-amber-500/10 text-amber-400 border-amber-500/20" :
                                    "bg-red-500/10 text-red-400 border-red-500/20"
                                }`}>
                                {tech.status || 'Pending'}
                            </Badge>
                        </div>
                        <div className="flex items-center gap-3 mt-1">
                            <div className="flex items-center gap-1.5 text-xs font-bold text-slate-500 uppercase tracking-widest">
                                <MapPin size={12} className="text-indigo-500" />
                                {tech.city || 'Location Pending'}
                            </div>
                            <div className="w-1 h-1 rounded-full bg-slate-800" />
                            <div className="flex items-center gap-1.5 text-xs font-bold text-slate-500 uppercase tracking-widest">
                                <Star size={12} className="text-amber-500" />
                                {tech.rating?.toFixed(1) || '5.0'} Global Score
                            </div>
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-3">
                    {tech.status !== 'approved' ? (
                        <Button
                            className="h-12 rounded-2xl bg-emerald-500 border-none font-black uppercase tracking-widest text-[10px] px-8 text-white hover:bg-emerald-400 shadow-lg shadow-emerald-500/20 transition-all"
                            onClick={() => handleStatusToggle(true)}
                            disabled={updating}
                        >
                            <CheckCircle2 size={16} className="mr-2" /> Activate Asset
                        </Button>
                    ) : (
                        <Button
                            variant="outline"
                            className="h-12 rounded-2xl border-slate-800 bg-red-500/10 text-red-400 border-red-500/20 font-black uppercase tracking-widest text-[10px] px-8 hover:bg-red-500 hover:text-white transition-all"
                            onClick={() => handleStatusToggle(false)}
                            disabled={updating}
                        >
                            <XCircle size={16} className="mr-2" /> Deactivate
                        </Button>
                    )}
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Left Column: Details & Docs */}
                <div className="lg:col-span-2 space-y-8">
                    {/* Professional Profile */}
                    <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md rounded-3xl overflow-hidden">
                        <CardHeader className="p-8 border-b border-slate-800/50 flex flex-row items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400">
                                    <Wrench size={20} />
                                </div>
                                <CardTitle className="text-xl font-black text-white uppercase tracking-tight">Professional Dossier</CardTitle>
                            </div>
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setEditMode(!editMode)}
                                className="h-9 rounded-xl border-slate-800 bg-slate-900/50 text-[10px] font-black uppercase tracking-widest text-slate-400 hover:text-white"
                            >
                                {editMode ? 'Cancel' : 'Modify Data'}
                            </Button>
                        </CardHeader>
                        <CardContent className="p-8">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                                <div className="space-y-6">
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Name</label>
                                        {editMode ? <Input value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} className="bg-slate-900 border-slate-800 text-white rounded-xl" /> : <div className="text-lg font-bold text-slate-200">{tech.name}</div>}
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Contact</label>
                                        <div className="flex flex-col gap-2">
                                            <div className="flex items-center gap-3 text-slate-300 font-bold">
                                                <Mail size={16} className="text-slate-600" />
                                                {tech.email}
                                            </div>
                                            <div className="flex items-center gap-3 text-slate-300 font-bold uppercase tracking-widest">
                                                <Smartphone size={16} className="text-slate-600" />
                                                {tech.phone}
                                            </div>
                                        </div>
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Assigned Skills</label>
                                        <div className="flex flex-wrap gap-2">
                                            {tech.skills?.map((s: string) => (
                                                <Badge key={s} className="bg-slate-800 text-slate-400 border-slate-700 font-black text-[9px] uppercase tracking-widest px-2.5 py-1">
                                                    {s}
                                                </Badge>
                                            ))}
                                        </div>
                                    </div>
                                </div>
                                <div className="space-y-6">
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Deployment City</label>
                                        {editMode ? <Input value={formData.city} onChange={e => setFormData({ ...formData, city: e.target.value })} className="bg-slate-900 border-slate-800 text-white rounded-xl" /> : <div className="text-lg font-bold text-slate-200">{tech.city || 'Sector Pending'}</div>}
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Availability Matrix</label>
                                        <Badge className={`font-black text-[10px] uppercase tracking-widest px-3 py-1.5 ${tech.isAvailable ? 'bg-emerald-500/10 text-emerald-400' : 'bg-slate-800 text-slate-500'}`}>
                                            {tech.isAvailable ? 'Operative Ready' : 'Off-Duty'}
                                        </Badge>
                                    </div>
                                    {editMode && (
                                        <Button
                                            onClick={handleUpdateTech}
                                            disabled={updating}
                                            className="w-full h-11 bg-indigo-500 text-white font-black uppercase tracking-widest text-[10px] rounded-xl hover:bg-indigo-400 transition-all"
                                        >
                                            Save Modifications
                                        </Button>
                                    )}
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* KYC Documents */}
                    <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md rounded-3xl overflow-hidden">
                        <CardHeader className="p-8 border-b border-slate-800/50">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400">
                                    <FileText size={20} />
                                </div>
                                <CardTitle className="text-xl font-black text-white uppercase tracking-tight">KYC Assets</CardTitle>
                            </div>
                        </CardHeader>
                        <CardContent className="p-8">
                            {!tech.documents || Object.keys(tech.documents).length === 0 ? (
                                <div className="p-8 border-2 border-dashed border-slate-800 rounded-2xl flex flex-col items-center justify-center text-center">
                                    <AlertCircle size={24} className="text-slate-600 mb-2" />
                                    <div className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">No Digital Documents Uploaded</div>
                                </div>
                            ) : (
                                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                                    {Object.entries(tech.documents).map(([key, url]: [string, any]) => (
                                        <a key={key} href={url} target="_blank" rel="noopener noreferrer" className="group relative aspect-[4/3] rounded-2xl bg-slate-950/50 border border-slate-800/50 overflow-hidden hover:border-indigo-500/30 transition-all">
                                            <img src={url} alt={key} className="w-full h-full object-cover opacity-50 group-hover:opacity-80 transition-opacity" />
                                            <div className="absolute inset-0 p-4 flex flex-col justify-end bg-gradient-to-t from-slate-950 to-transparent">
                                                <span className="text-[9px] font-black text-white uppercase tracking-widest truncate">{key}</span>
                                            </div>
                                        </a>
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>

                    {/* Deployment History */}
                    <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md rounded-3xl overflow-hidden">
                        <CardHeader className="p-8 border-b border-slate-800/50">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400">
                                    <History size={20} />
                                </div>
                                <CardTitle className="text-xl font-black text-white uppercase tracking-tight">Operations Log</CardTitle>
                            </div>
                        </CardHeader>
                        <CardContent className="p-0">
                            {tech.jobHistory && tech.jobHistory.length > 0 ? (
                                <div className="divide-y divide-slate-800/50">
                                    {tech.jobHistory.map((job: any) => (
                                        <div key={job.id} className="p-6 flex items-center justify-between hover:bg-white/5 transition-colors group">
                                            <div className="flex items-center gap-4">
                                                <div className="text-sm font-black text-white uppercase tracking-tight">{job.serviceTitle || 'Service Operation'}</div>
                                            </div>
                                            <div className="text-right">
                                                <div className="text-sm font-black text-white tracking-widest">₹{(job.finalAmount || 0).toLocaleString()}</div>
                                                <Badge className={`text-[8px] uppercase tracking-widest mt-1 ${job.status === 'completed' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-slate-800 text-slate-500'}`}>
                                                    {job.status}
                                                </Badge>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <div className="p-12 text-center text-slate-600 font-black text-[10px] uppercase tracking-widest">No Past Assignments Recorded</div>
                            )}
                        </CardContent>
                    </Card>
                </div>

                {/* Right Column: Financials & Verification */}
                <div className="space-y-8">
                    {/* Financial Core */}
                    <Card className="border-slate-800 bg-indigo-500/5 backdrop-blur-md rounded-3xl border-indigo-500/20">
                        <CardContent className="p-8 space-y-8">
                            <div className="space-y-6">
                                <div className="space-y-2">
                                    <label className="text-[10px] font-black text-indigo-400 uppercase tracking-widest">Liquid Capital</label>
                                    <div className="flex items-center justify-between">
                                        <div className="text-4xl font-black text-white tracking-tighter">₹{(tech.wallet?.availableBalance || 0).toLocaleString()}</div>
                                        <div className="w-12 h-12 rounded-2xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center shadow-lg shadow-indigo-500/10 text-indigo-400">
                                            <IndianRupee size={24} />
                                        </div>
                                    </div>
                                </div>
                                <div className="h-px bg-indigo-500/10" />
                                <div className="space-y-2">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Pending Settlements</label>
                                    <div className="text-2xl font-black text-slate-300">₹{(tech.wallet?.pendingBalance || 0).toLocaleString()}</div>
                                </div>
                            </div>

                            <div className="grid grid-cols-1 gap-4">
                                <div className="p-4 rounded-2xl bg-slate-900 border border-slate-800">
                                    <div className="flex items-center gap-3">
                                        <TrendingUp size={16} className="text-emerald-500" />
                                        <div className="flex-1">
                                            <div className="text-[9px] font-black text-slate-500 uppercase tracking-widest">Efficiency</div>
                                            <div className="text-sm font-black text-white">99.4% Verified</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Operative Stats */}
                    <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md rounded-3xl">
                        <CardHeader className="p-8 pb-0">
                            <CardTitle className="text-xs font-black text-slate-500 uppercase tracking-widest">Performance Matrix</CardTitle>
                        </CardHeader>
                        <CardContent className="p-8 grid grid-cols-2 gap-4">
                            <div className="space-y-1">
                                <div className="text-[9px] font-black text-slate-600 uppercase tracking-widest">Deployments</div>
                                <div className="text-2xl font-black text-white tracking-tighter">{tech.jobsCompleted || 0}</div>
                            </div>
                            <div className="space-y-1">
                                <div className="text-[9px] font-black text-slate-600 uppercase tracking-widest">Reliability</div>
                                <div className="text-2xl font-black text-emerald-500 tracking-tighter">100%</div>
                            </div>
                            <div className="col-span-2 pt-4">
                                <div className="text-[9px] font-black text-slate-600 uppercase tracking-widest mb-2">Latest Intel (Reviews)</div>
                                {tech.reviews && tech.reviews.length > 0 ? (
                                    <div className="space-y-3">
                                        {tech.reviews.map((r: any) => (
                                            <div key={r.id} className="p-3 rounded-xl bg-slate-950/50 border border-slate-800/50">
                                                <div className="flex items-center justify-between mb-1">
                                                    <div className="flex items-center gap-1">
                                                        <Star size={10} className="text-amber-500 fill-amber-500" />
                                                        <span className="text-[10px] font-black text-white">{r.rating}</span>
                                                    </div>
                                                    <span className="text-[8px] font-bold text-slate-600">MISSION #{r.bookingId?.substring(0, 6)}</span>
                                                </div>
                                                <p className="text-[10px] text-slate-400 italic line-clamp-2">&quot;{r.comment || 'No report provided.'}&quot;</p>
                                            </div>
                                        ))}
                                    </div>
                                ) : (
                                    <div className="text-[10px] font-bold text-slate-500 uppercase tracking-widest italic">No operational feedback received yet.</div>
                                )}
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div >
    );
}
