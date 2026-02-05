'use client';

import { useState } from 'react';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';
import {
    Beaker, User, Wrench, Calendar, CreditCard, Trash2,
    CheckCircle2, AlertTriangle, Terminal, Loader2,
    FlaskConical, ChevronRight, Activity, Zap,
    Cpu, Globe, Shield, Database, Send, Play, RefreshCw,
    X, Code, Info
} from 'lucide-react';
import { Card, CardContent, CardHeader } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';

export default function TestingPage() {
    const [loading, setLoading] = useState<string | null>(null);
    const [result, setResult] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);

    // Forms
    const [customerForm, setCustomerForm] = useState({ name: 'Test Customer', email: '', phone: '' });
    const [techForm, setTechForm] = useState({ name: 'Test Tech', email: '', serviceId: 'plumbing' });
    const [bookingForm, setBookingForm] = useState({ customerId: '', technicianId: '', serviceId: 'plumbing' });
    const [simPaymentId, setSimPaymentId] = useState('');

    const handleCall = async (action: string, fnName: string, data: any) => {
        setLoading(action);
        setResult(null);
        setError(null);
        try {
            const fn = httpsCallable(functions, fnName);
            const res = await fn(data);
            setResult(JSON.stringify(res.data, null, 2));
        } catch (e: any) {
            setError(e.message);
        } finally {
            setLoading(null);
        }
    };

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto pb-20">
            <header className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase tracking-tighter">Testing Laboratory</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Coordinate synthetic operations and validate platform behavioral responses.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            Sandbox Active
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-3">
                    <Badge variant="outline" className="h-10 px-4 bg-amber-500/10 text-amber-500 border-amber-500/20 font-black uppercase tracking-widest text-[10px]">
                        <Zap size={14} className="mr-2 fill-amber-500 animate-pulse" />
                        Infrastructure Synchronized
                    </Badge>
                </div>
            </header>

            {(result || error) && (
                <Card className={`border-none overflow-hidden animate-in fade-in slide-in-from-top-4 duration-500 ${result ? 'bg-emerald-500/5 ring-1 ring-emerald-500/20' : 'bg-rose-500/5 ring-1 ring-rose-500/20'
                    }`}>
                    <CardContent className="p-8">
                        <div className="flex items-start justify-between">
                            <div className="flex gap-4">
                                <div className={`p-3 rounded-2xl ${result ? 'bg-emerald-500/10 text-emerald-400' : 'bg-rose-500/10 text-rose-400'}`}>
                                    {result ? <CheckCircle2 size={24} /> : <AlertTriangle size={24} />}
                                </div>
                                <div>
                                    <h3 className={`text-sm font-black uppercase tracking-[0.2em] ${result ? 'text-emerald-400' : 'text-rose-400'}`}>
                                        Execution Pulse: {result ? 'SUCCESS' : 'FAILURE'}
                                    </h3>
                                    <p className="text-slate-500 text-xs mt-1 font-medium italic">
                                        {result ? 'Synthetic operation committed to the ledger.' : 'Internal logic rejected the proposed mutation.'}
                                    </p>
                                </div>
                            </div>
                            <Button variant="ghost" size="sm" onClick={() => { setResult(null); setError(null); }} className="text-slate-500 hover:text-white">
                                <X size={20} />
                            </Button>
                        </div>
                        <div className="mt-6 bg-slate-950/80 rounded-2xl p-6 border border-slate-800/50 backdrop-blur-sm">
                            <pre className={`text-[11px] font-mono leading-relaxed overflow-auto max-h-[300px] scrollbar-thin scrollbar-thumb-slate-800 ${result ? 'text-emerald-500/80' : 'text-rose-500/80'
                                }`}>
                                {result || error}
                            </pre>
                        </div>
                    </CardContent>
                </Card>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Synthetic User */}
                <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-3xl group hover:border-indigo-500/30 transition-all duration-500">
                    <CardHeader className="p-8 pb-0">
                        <div className="flex items-center gap-5">
                            <div className="w-14 h-14 bg-indigo-500/10 text-indigo-400 rounded-2xl flex items-center justify-center border border-indigo-500/20 group-hover:bg-indigo-600 group-hover:text-white transition-all duration-500">
                                <User size={24} />
                            </div>
                            <div>
                                <h2 className="text-xl font-black text-white uppercase tracking-tight">Instantiate Customer</h2>
                                <p className="text-[10px] font-black text-indigo-500 uppercase tracking-widest mt-1 opacity-60">Phase 01: Entity Generation</p>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="p-8 space-y-6">
                        <div className="space-y-4">
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Designation Label</label>
                                <Input
                                    className="bg-slate-950/50 border-slate-800 text-white rounded-xl h-12"
                                    value={customerForm.name}
                                    onChange={e => setCustomerForm({ ...customerForm, name: e.target.value })}
                                />
                            </div>
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Auth Persistence ID (Email)</label>
                                <Input
                                    className="bg-slate-950/50 border-slate-800 text-white rounded-xl h-12"
                                    value={customerForm.email}
                                    onChange={e => setCustomerForm({ ...customerForm, email: e.target.value })}
                                    placeholder="AUTO-GENERATED IF BLANK"
                                />
                            </div>
                        </div>
                        <Button
                            className="w-full h-14 bg-indigo-600 hover:bg-indigo-500 text-white font-black uppercase text-[11px] tracking-widest rounded-2xl shadow-xl shadow-indigo-600/10"
                            onClick={() => handleCall('customer', 'test_createCustomer', {
                                ...customerForm,
                                email: customerForm.email || `customer_${Date.now()}@test.com`
                            })}
                            disabled={loading !== null}
                        >
                            {loading === 'customer' ? <Loader2 className="animate-spin mr-2" /> : <Play className="mr-2 h-4 w-4" />}
                            Deploy User Node
                        </Button>
                    </CardContent>
                </Card>

                {/* Synthetic Technician */}
                <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-3xl group hover:border-violet-500/30 transition-all duration-500">
                    <CardHeader className="p-8 pb-0">
                        <div className="flex items-center gap-5">
                            <div className="w-14 h-14 bg-violet-500/10 text-violet-400 rounded-2xl flex items-center justify-center border border-violet-500/20 group-hover:bg-violet-600 group-hover:text-white transition-all duration-500">
                                <Wrench size={24} />
                            </div>
                            <div>
                                <h2 className="text-xl font-black text-white uppercase tracking-tight">Instantiate Agent</h2>
                                <p className="text-[10px] font-black text-violet-500 uppercase tracking-widest mt-1 opacity-60">Phase 02: Resource Allocation</p>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="p-8 space-y-6">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Specialization</label>
                                <select
                                    className="w-full bg-slate-950/50 border border-slate-800 text-white rounded-xl h-12 px-4 text-xs font-black uppercase tracking-widest appearance-none outline-none focus:ring-1 focus:ring-violet-500/50"
                                    value={techForm.serviceId}
                                    onChange={e => setTechForm({ ...techForm, serviceId: e.target.value })}
                                >
                                    <option value="plumbing">Plumbing</option>
                                    <option value="cleaning">Cleaning</option>
                                    <option value="electrician">Electrician</option>
                                </select>
                            </div>
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Asset Label</label>
                                <Input
                                    className="bg-slate-950/50 border-slate-800 text-white rounded-xl h-12"
                                    value={techForm.name}
                                    onChange={e => setTechForm({ ...techForm, name: e.target.value })}
                                />
                            </div>
                        </div>
                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Agent Auth ID</label>
                            <Input
                                className="bg-slate-950/50 border-slate-800 text-white rounded-xl h-12"
                                value={techForm.email}
                                onChange={e => setTechForm({ ...techForm, email: e.target.value })}
                                placeholder="AUTO-GENERATED IF BLANK"
                            />
                        </div>
                        <Button
                            className="w-full h-14 bg-violet-600 hover:bg-violet-500 text-white font-black uppercase text-[11px] tracking-widest rounded-2xl shadow-xl shadow-violet-600/10"
                            onClick={() => handleCall('tech', 'test_createTechnician', {
                                ...techForm,
                                email: techForm.email || `tech_${Date.now()}@test.com`
                            })}
                            disabled={loading !== null}
                        >
                            {loading === 'tech' ? <Loader2 className="animate-spin mr-2" /> : <Play className="mr-2 h-4 w-4" />}
                            Deploy Agent Node
                        </Button>
                    </CardContent>
                </Card>

                {/* Booking Trigger */}
                <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-3xl group hover:border-amber-500/30 transition-all duration-500">
                    <CardHeader className="p-8 pb-0">
                        <div className="flex items-center gap-5">
                            <div className="w-14 h-14 bg-amber-500/10 text-amber-400 rounded-2xl flex items-center justify-center border border-amber-500/20 group-hover:bg-amber-600 group-hover:text-white transition-all duration-500">
                                <Calendar size={24} />
                            </div>
                            <div>
                                <h2 className="text-xl font-black text-white uppercase tracking-tight">Sync Transaction</h2>
                                <p className="text-[10px] font-black text-amber-500 uppercase tracking-widest mt-1 opacity-60">Phase 03: Logic Simulation</p>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="p-8 space-y-6">
                        <div className="space-y-4">
                            <Input
                                placeholder="TARGET CUSTOMER UID"
                                className="bg-slate-950/50 border-slate-800 text-indigo-400 font-mono text-[10px] font-black uppercase tracking-widest h-12"
                                value={bookingForm.customerId}
                                onChange={e => setBookingForm({ ...bookingForm, customerId: e.target.value })}
                            />
                            <Input
                                placeholder="TARGET AGENT UID"
                                className="bg-slate-950/50 border-slate-800 text-violet-400 font-mono text-[10px] font-black uppercase tracking-widest h-12"
                                value={bookingForm.technicianId}
                                onChange={e => setBookingForm({ ...bookingForm, technicianId: e.target.value })}
                            />
                        </div>
                        <Button
                            className="w-full h-14 bg-amber-600 hover:bg-amber-500 text-white font-black uppercase text-[11px] tracking-widest rounded-2xl shadow-xl shadow-amber-600/10"
                            onClick={() => handleCall('booking', 'test_generateBooking', bookingForm)}
                            disabled={loading !== null}
                        >
                            {loading === 'booking' ? <Loader2 className="animate-spin mr-2" /> : <Send className="mr-2 h-4 w-4" />}
                            Execute Logic Link
                        </Button>
                    </CardContent>
                </Card>

                {/* Payment Simulation */}
                <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-3xl group hover:border-emerald-500/30 transition-all duration-500">
                    <CardHeader className="p-8 pb-0">
                        <div className="flex items-center gap-5">
                            <div className="w-14 h-14 bg-emerald-500/10 text-emerald-400 rounded-2xl flex items-center justify-center border border-emerald-500/20 group-hover:bg-emerald-600 group-hover:text-white transition-all duration-500">
                                <CreditCard size={24} />
                            </div>
                            <div>
                                <h2 className="text-xl font-black text-white uppercase tracking-tight">Mock Settlement</h2>
                                <p className="text-[10px] font-black text-emerald-500 uppercase tracking-widest mt-1 opacity-60">Phase 04: Capital Flow Sim</p>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="p-8 space-y-6">
                        <div className="space-y-4">
                            <Input
                                placeholder="BOOKING TRANSACTION HASH"
                                className="bg-slate-950/50 border-slate-800 text-emerald-400 font-mono text-[10px] font-black uppercase tracking-widest h-12"
                                value={simPaymentId}
                                onChange={e => setSimPaymentId(e.target.value)}
                            />
                            <div className="p-4 bg-emerald-500/5 rounded-xl border border-emerald-500/10 flex items-center gap-3">
                                <Info size={14} className="text-emerald-500 shrink-0" />
                                <p className="text-[9px] text-emerald-500/80 font-medium leading-relaxed italic">Synchronizes the ledger state to simulate successful clearing of funds.</p>
                            </div>
                        </div>
                        <Button
                            className="w-full h-14 bg-emerald-600 hover:bg-emerald-500 text-white font-black uppercase text-[11px] tracking-widest rounded-2xl shadow-xl shadow-emerald-600/10"
                            onClick={() => handleCall('pay', 'test_simulatePayment', { bookingId: simPaymentId })}
                            disabled={loading !== null}
                        >
                            {loading === 'pay' ? <Loader2 className="animate-spin mr-2" /> : <RefreshCw className="mr-2 h-4 w-4" />}
                            Clear Funds Flow
                        </Button>
                    </CardContent>
                </Card>
            </div>

            {/* Danger Zone */}
            <Card className="border-rose-500/20 bg-rose-500/5 backdrop-blur-md overflow-hidden rounded-[32px] group relative">
                <div className="absolute top-0 right-0 p-10 opacity-[0.02] group-hover:opacity-[0.05] group-hover:rotate-12 transition-all duration-1000 pointer-events-none">
                    <Trash2 size={240} />
                </div>
                <CardContent className="p-12 relative z-10">
                    <div className="flex flex-col lg:flex-row items-start lg:items-center justify-between gap-10">
                        <div className="space-y-4">
                            <div className="flex items-center gap-6">
                                <div className="w-16 h-16 bg-rose-500/10 text-rose-500 rounded-[24px] flex items-center justify-center border border-rose-500/20 shadow-xl shadow-rose-500/10">
                                    <Trash2 size={32} />
                                </div>
                                <h2 className="text-3xl font-black text-white uppercase tracking-tight">System Data Purge</h2>
                            </div>
                            <p className="max-w-xl text-slate-400 font-medium text-sm leading-relaxed">
                                Irrevocable destruction of all synthetic entities. Purges all nodes where <code className="bg-rose-500/10 text-rose-400 px-2 py-0.5 rounded-lg text-[10px] font-black mx-1">EXPERIMENTAL_FLAG=TRUE</code>. Production clusters remain architecturally isolated from this command.
                            </p>
                        </div>
                        <Button
                            variant="destructive"
                            onClick={() => {
                                if (confirm('⚠️ CRITICAL: Execute full synthetic dataset destruction? This action is immutable.')) {
                                    handleCall('reset', 'test_resetData', { confirm: true });
                                }
                            }}
                            disabled={loading !== null}
                            className="h-16 px-12 bg-rose-600 hover:bg-rose-700 text-white font-black uppercase text-xs tracking-[0.2em] rounded-[24px] shadow-2xl shadow-rose-500/20 border-none shrink-0"
                        >
                            {loading === 'reset' ? <Loader2 className="animate-spin mr-2" /> : 'Execute Reset Protocol'}
                        </Button>
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}
