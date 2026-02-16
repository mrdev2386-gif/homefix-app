'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, onSnapshot } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { adminApi } from '@/lib/admin-api';
import StatusBadge from '@/components/ui/StatusBadge';
import Table from '@/components/ui/Table';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import {
    Search, Calendar, Filter, MoreHorizontal, IndianRupee,
    User, Wrench, Clock, MapPin, ChevronRight, CheckCircle2,
    XCircle, Send, Activity, Eye, Layers, ArrowRight, Hash,
    ArrowUpRight
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';

export default function BookingsPage() {
    const [bookings, setBookings] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [activeTab, setActiveTab] = useState('all');
    const [processingId, setProcessingId] = useState<string | null>(null);
    const [selectedBooking, setSelectedBooking] = useState<any>(null);
    const [isActionModalOpen, setActionModalOpen] = useState(false);
    const [actionType, setActionType] = useState<string>('');
    const [actionPayload, setActionPayload] = useState<any>({});

    useEffect(() => {
        const q = query(collection(db, 'bookings'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snap) => {
            setBookings(snap.docs.map(d => ({ id: d.id, ...d.data() })));
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    const filteredBookings = bookings.filter(b => {
        const matchesSearch = b.id?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            b.customerName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            b.serviceTitle?.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesTab = activeTab === 'all' || b.status === activeTab;
        return matchesSearch && matchesTab;
    });

    const handleAction = async (bookingId: string, action: string) => {
        // Open modal instead of using prompt
        setSelectedBooking(bookings.find(b => b.id === bookingId));
        setActionType(action);
        setActionPayload({});
        setActionModalOpen(true);
    };

    const executeAction = async () => {
        if (!selectedBooking) return;
        
        setProcessingId(selectedBooking.id);
        try {
            await adminApi.manageBooking(selectedBooking.id, actionType, actionPayload);
            alert('Action completed successfully!');
            setActionModalOpen(false);
        } catch (e: any) {
            console.error('Action failed:', e);
            alert(`Action failed: ${e.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const columns = [
        {
            key: 'id',
            label: 'Reference',
            render: (b: any) => (
                <div className="flex flex-col">
                    <span className="font-mono text-[10px] font-black text-indigo-400 tracking-wider">#{b.id.substring(0, 8).toUpperCase()}</span>
                    <span className="text-[9px] text-slate-500 font-bold uppercase tracking-widest mt-0.5">
                        {b.paymentMode === 'online' ? 'Digital' : 'Cash'} - {b.paymentStatus || 'Pending'}
                    </span>
                </div>
            )
        },
        {
            key: 'serviceTitle',
            label: 'Service Details',
            render: (b: any) => (
                <div className="flex flex-col">
                    <span className="font-black text-white text-sm tracking-tight">{b.serviceTitle || 'General Service'}</span>
                    <div className="flex items-center gap-1.5 mt-1">
                        <Calendar size={10} className="text-slate-500" />
                        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">
                            {b.createdAt?.seconds ? new Date(b.createdAt.seconds * 1000).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : 'Recently'}
                        </span>
                    </div>
                </div>
            )
        },
        {
            key: 'customerName',
            label: 'Customer Info',
            render: (b: any) => (
                <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center text-[10px] font-black text-slate-400">
                        {b.customerName?.[0] || 'U'}
                    </div>
                    <div className="flex flex-col">
                        <span className="text-sm font-bold text-slate-200">{b.customerName || 'Anonymous'}</span>
                        <span className="text-[10px] font-medium text-slate-500 truncate max-w-[120px]">{b.customerEmail}</span>
                    </div>
                </div>
            )
        },
        {
            key: 'technician',
            label: 'Execution Force',
            render: (b: any) => (
                b.assignedTechnicianName ? (
                    <div className="flex items-center gap-2.5 px-3 py-1.5 bg-emerald-500/5 border border-emerald-500/10 rounded-xl w-fit">
                        <Wrench size={12} className="text-emerald-500" />
                        <span className="text-[11px] font-black text-emerald-400 uppercase tracking-wider">{b.assignedTechnicianName}</span>
                    </div>
                ) : (
                    <Badge className="bg-slate-800/50 text-slate-500 border-slate-700/50 font-bold text-[9px] uppercase tracking-wider">Unassigned</Badge>
                )
            )
        },
        {
            key: 'amount',
            label: 'Value',
            render: (b: any) => (
                <div className="flex flex-col items-end mr-4">
                    <span className="text-sm font-black text-white">₹{(b.finalAmount || b.totalAmount || 0).toLocaleString()}</span>
                    <span className="text-[9px] font-bold text-slate-500 uppercase tracking-widest">{b.isPaid ? 'Settled' : 'Unpaid'}</span>
                </div>
            )
        },
        {
            key: 'status',
            label: 'Lifecycle',
            render: (b: any) => <StatusBadge status={b.status} />
        },
        {
            key: 'actions',
            label: 'Control',
            align: 'right' as const,
            render: (b: any) => (
                <div className="flex justify-end gap-2 pr-2">
                    {(b.status === 'confirmed' || b.status === 'requested') && (
                        <Button
                            size="sm"
                            variant="outline"
                            className="h-8 bg-indigo-500/10 border-indigo-500/20 text-indigo-400 hover:bg-indigo-500 hover:text-white rounded-lg font-black text-[9px] uppercase tracking-widest px-3"
                            disabled={processingId === b.id}
                            onClick={() => handleAction(b.id, 'assign')}
                        >
                            Assign Force
                        </Button>
                    )}
                    {!['completed', 'cancelled'].includes(b.status) && (
                        <Button
                            size="sm"
                            variant="ghost"
                            className="h-8 text-slate-500 hover:text-red-400 hover:bg-red-500/10 rounded-lg font-black text-[9px] uppercase tracking-widest px-3"
                            disabled={processingId === b.id}
                            onClick={() => handleAction(b.id, 'cancel')}
                        >
                            Terminate
                        </Button>
                    )}
                </div>
            )
        }
    ];

    const tabs = [
        { id: 'all', label: 'All Operations' },
        { id: 'requested', label: 'Requested' },
        { id: 'assigned', label: 'Assigned' },
        { id: 'completed', label: 'Completed' },
        { id: 'cancelled', label: 'Cancelled' }
    ];

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase">Operational Stream</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Real-time status of all platform service transactions.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            {bookings.filter(b => b.status === 'assigned').length} active
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-4">
                    <div className="relative w-full md:w-80 group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                        <Input
                            placeholder="Enter reference or customer name..."
                            className="pl-10 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                </div>
            </div>

            <div className="space-y-6">
                <div className="flex items-center gap-2 p-1 bg-slate-900/50 border border-slate-800 rounded-2xl w-fit overflow-x-auto no-scrollbar">
                    {tabs.map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id)}
                            className={`px-5 py-2.5 rounded-xl text-[10px] font-black uppercase tracking-[0.15em] transition-all whitespace-nowrap ${activeTab === tab.id
                                    ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/20'
                                    : 'text-slate-500 hover:text-slate-300 hover:bg-slate-800/50'
                                }`}
                        >
                            {tab.label}
                        </button>
                    ))}
                </div>

                <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-3xl">
                    <CardContent className="p-0">
                        <Table
                            columns={columns}
                            data={filteredBookings}
                            loading={loading}
                            emptyMessage="The operational stream is currently clear."
                            className="[&_tr]:border-slate-800/50 [&_th]:bg-transparent [&_th]:text-slate-500 [&_th]:text-[10px] [&_th]:font-black [&_th]:uppercase [&_th]:tracking-[0.2em] [&_th]:py-6"
                        />
                    </CardContent>
                </Card>
            </div>

            {/* Action Modal */}
            {isActionModalOpen && selectedBooking && (
                <div className="fixed inset-0 bg-[#0f172a]/95 backdrop-blur-xl flex items-center justify-center z-[100] p-4 animate-in fade-in duration-300">
                    <Card className="w-full max-w-lg bg-slate-900 border-slate-800 shadow-2xl shadow-black/50 overflow-hidden rounded-3xl">
                        <div className="p-6 border-b border-slate-800 flex items-center justify-between">
                            <div>
                                <h2 className="text-xl font-black text-white uppercase">
                                    {actionType === 'assign' ? 'Assign Technician' : 
                                     actionType === 'reassign' ? 'Reassign Technician' :
                                     actionType === 'cancel' ? 'Cancel Booking' :
                                     'Complete Booking'}
                                </h2>
                                <p className="text-slate-500 text-xs mt-1">Booking: #{selectedBooking.id.substring(0, 8).toUpperCase()}</p>
                            </div>
                            <Button variant="ghost" onClick={() => setActionModalOpen(false)} className="text-slate-500 hover:text-white">
                                <XCircle size={20} />
                            </Button>
                        </div>
                        <CardContent className="p-6 space-y-4">
                            {(actionType === 'assign' || actionType === 'reassign') && (
                                <div className="space-y-2">
                                    <label className="text-xs font-black text-slate-500 uppercase tracking-widest">Technician UID</label>
                                    <Input
                                        placeholder="Enter technician UID"
                                        value={actionPayload.technicianId || ''}
                                        onChange={(e) => setActionPayload({ ...actionPayload, technicianId: e.target.value })}
                                        className="bg-slate-800/50 border-slate-700 text-white"
                                    />
                                </div>
                            )}
                            {(actionType === 'cancel' || actionType === 'complete') && (
                                <div className="space-y-2">
                                    <label className="text-xs font-black text-slate-500 uppercase tracking-widest">Reason / Notes</label>
                                    <textarea
                                        className="flex min-h-[80px] w-full rounded-xl border border-slate-700 bg-slate-800/50 px-4 py-3 text-sm text-white placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 resize-none"
                                        placeholder="Enter reason or notes..."
                                        value={actionPayload.reason || ''}
                                        onChange={(e) => setActionPayload({ ...actionPayload, reason: e.target.value })}
                                    />
                                </div>
                            )}
                            <div className="flex gap-3 pt-2">
                                <Button
                                    variant="outline"
                                    onClick={() => setActionModalOpen(false)}
                                    className="flex-1 border-slate-700 text-slate-400 hover:text-white"
                                >
                                    Cancel
                                </Button>
                                <Button
                                    onClick={executeAction}
                                    disabled={processingId === selectedBooking.id}
                                    className="flex-1 bg-indigo-600 hover:bg-indigo-500 text-white"
                                >
                                    {processingId === selectedBooking.id ? 'Processing...' : 'Confirm'}
                                </Button>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            )}
        </div>
    );
}
