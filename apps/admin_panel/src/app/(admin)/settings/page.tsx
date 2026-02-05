'use client';

import { useState } from 'react';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';
import {
    Bell, Shield, Send, RefreshCcw, AlertCircle, Info,
    Lock, Activity, Zap, Cpu, Loader2, Globe, ShieldCheck,
    Terminal, Database, Radio, LayoutGrid
} from 'lucide-react';

import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

export default function SettingsPage() {
    const [notifForm, setNotifForm] = useState({ target: 'all', title: '', body: '' });
    const [loading, setLoading] = useState(false);

    const handleSend = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        try {
            const fn = httpsCallable(functions, 'admin_sendPushNotification');
            await fn(notifForm);
            alert('Notification broadcasted successfully!');
            setNotifForm({ target: 'all', title: '', body: '' });
        } catch (e) {
            console.error(e);
            alert('Failed to send broadcast');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto pb-20">
            <header className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase">System Control</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Manage core infrastructure and communication relays.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            Engine Active
                        </div>
                    </div>
                </div>
                <div className="flex items-center gap-3">
                    <div className="hidden md:flex flex-col items-end mr-2">
                        <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Environment</span>
                        <span className="text-sm font-bold text-emerald-400 uppercase tracking-tighter">Production_Main</span>
                    </div>
                    <div className="w-12 h-12 rounded-2xl bg-slate-900 border border-slate-800 flex items-center justify-center text-indigo-400">
                        <Cpu size={20} />
                    </div>
                </div>
            </header>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                {/* Broadcast Hub */}
                <Card className="lg:col-span-7 border-none bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-[32px] shadow-2xl ring-1 ring-white/5">
                    <CardHeader className="p-8 pb-4">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-indigo-500/10 text-indigo-400 rounded-xl flex items-center justify-center border border-indigo-500/20 shadow-lg shadow-indigo-500/5">
                                <Radio size={20} />
                            </div>
                            <div>
                                <CardTitle className="text-xl font-black text-white uppercase tracking-tight">Signal Broadcast</CardTitle>
                                <CardDescription className="text-slate-500 font-bold uppercase text-[9px] tracking-[0.2em] mt-0.5">Push Notification Relay</CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="p-8 pt-4">
                        <form onSubmit={handleSend} className="space-y-6">
                            <div className="space-y-3">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Target Trajectory</label>
                                <div className="grid grid-cols-3 gap-3">
                                    {['all', 'customers', 'technicians'].map((t) => (
                                        <button
                                            key={t}
                                            type="button"
                                            onClick={() => setNotifForm({ ...notifForm, target: t })}
                                            className={`py-3 rounded-2xl text-[10px] font-black uppercase tracking-widest transition-all border ${notifForm.target === t
                                                ? 'bg-indigo-600 text-white border-indigo-500 shadow-xl shadow-indigo-600/20'
                                                : 'bg-slate-950/50 text-slate-500 border-slate-800 hover:border-slate-700'
                                                }`}
                                        >
                                            {t === 'all' ? 'Universal' : t}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Transmission Title</label>
                                <Input
                                    placeholder="e.g. Critical Update Payload"
                                    value={notifForm.title}
                                    onChange={e => setNotifForm({ ...notifForm, title: e.target.value })}
                                    required
                                    className="bg-slate-950/50 border-slate-800 text-white rounded-2xl h-12 focus:ring-indigo-500/30 transition-all font-medium"
                                />
                            </div>

                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Directive Content</label>
                                <textarea
                                    className="flex min-h-[120px] w-full rounded-2xl border border-slate-800 bg-slate-950/50 px-4 py-3 text-sm text-white placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-indigo-500/30 transition-all resize-none shadow-inner"
                                    placeholder="Execute transmission message payload here..."
                                    value={notifForm.body}
                                    onChange={e => setNotifForm({ ...notifForm, body: e.target.value })}
                                    required
                                />
                            </div>

                            <Button
                                type="submit"
                                disabled={loading}
                                className="w-full bg-indigo-600 hover:bg-indigo-500 text-white rounded-2xl h-14 font-black uppercase text-xs tracking-[0.2em] shadow-2xl shadow-indigo-600/20 border-none transition-all group"
                            >
                                {loading ? (
                                    <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                                ) : (
                                    <Send size={18} className="mr-2 group-hover:translate-x-1 group-hover:-translate-y-1 transition-transform" />
                                )}
                                Initialize Broadcast
                            </Button>
                        </form>
                    </CardContent>
                </Card>

                {/* Right Column */}
                <div className="lg:col-span-5 space-y-8">
                    {/* Security Node */}
                    <Card className="border-none bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-[32px] shadow-2xl ring-1 ring-white/5">
                        <CardHeader className="p-8 pb-4">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <div className="w-10 h-10 bg-emerald-500/10 text-emerald-400 rounded-xl flex items-center justify-center border border-emerald-500/20">
                                        <ShieldCheck size={20} />
                                    </div>
                                    <h3 className="text-xl font-black text-white uppercase tracking-tight">Security Matrix</h3>
                                </div>
                                <Badge className="bg-emerald-500/10 text-emerald-400 border-emerald-500/20 font-black text-[9px] uppercase tracking-widest px-2.5 py-1">Secure</Badge>
                            </div>
                        </CardHeader>
                        <CardContent className="p-8 pt-4 space-y-4">
                            <div className="flex items-center justify-between p-4 bg-slate-950/50 rounded-2xl border border-slate-800 group hover:border-slate-700 transition-colors">
                                <div className="flex items-center gap-3">
                                    <div className="w-8 h-8 bg-indigo-500/10 rounded-lg flex items-center justify-center text-indigo-400">
                                        <Lock size={14} />
                                    </div>
                                    <span className="text-xs font-black text-slate-500 uppercase tracking-widest">Authority Role</span>
                                </div>
                                <span className="text-sm font-black text-white uppercase tracking-tighter">SUPER_ADMIN</span>
                            </div>

                            <div className="flex items-center justify-between p-4 bg-slate-950/50 rounded-2xl border border-slate-800 group hover:border-slate-700 transition-colors">
                                <div className="flex items-center gap-3">
                                    <div className="w-8 h-8 bg-emerald-500/10 rounded-lg flex items-center justify-center text-emerald-400">
                                        <Activity size={14} />
                                    </div>
                                    <span className="text-xs font-black text-slate-500 uppercase tracking-widest">Runtime Status</span>
                                </div>
                                <span className="text-sm font-black text-emerald-400 uppercase tracking-tighter">LIVE_PRODUCTION</span>
                            </div>

                            <div className="flex items-center justify-between p-4 bg-slate-950/50 rounded-2xl border border-slate-800 group hover:border-slate-700 transition-colors">
                                <div className="flex items-center gap-3">
                                    <div className="w-8 h-8 bg-amber-500/10 rounded-lg flex items-center justify-center text-amber-400">
                                        <Globe size={14} />
                                    </div>
                                    <span className="text-xs font-black text-slate-500 uppercase tracking-widest">Regional Node</span>
                                </div>
                                <span className="text-sm font-black text-white uppercase tracking-tighter">SOUTH_ASIA_01</span>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Infrastructure Audit */}
                    <Card className="border-none bg-slate-900 overflow-hidden rounded-[32px] shadow-2xl ring-1 ring-white/5 bg-gradient-to-br from-slate-900 to-indigo-950/30">
                        <CardHeader className="p-8">
                            <div className="flex items-center gap-3 mb-2">
                                <div className="w-10 h-10 bg-white/10 text-white rounded-xl flex items-center justify-center backdrop-blur-md">
                                    <Terminal size={20} />
                                </div>
                                <h3 className="text-xl font-black text-white uppercase tracking-tight">Kernel Audit</h3>
                            </div>
                            <p className="text-slate-400 text-sm font-medium leading-relaxed">
                                Continuous integrity monitoring active. All administrative actions are recorded in the encrypted ledger.
                            </p>
                        </CardHeader>
                        <CardFooter className="p-8 pt-0">
                            <Button variant="outline" className="w-full border-white/10 bg-white/5 text-white hover:bg-white/10 hover:text-white rounded-2xl h-12 font-black uppercase text-[10px] tracking-widest">
                                <Database size={16} className="mr-2 text-indigo-400" /> Retrieve Audit Trails
                            </Button>
                        </CardFooter>
                    </Card>
                </div>
            </div>
        </div>
    );
}

