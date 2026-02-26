'use client';

import { useEffect, useState, useCallback } from 'react';
import { 
    collection, 
    query, 
    onSnapshot, 
    orderBy,
    where 
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { adminApi } from '@/lib/admin-api';
import {
    ClipboardList,
    Search,
    Mail,
    Phone,
    UserCircle,
    CheckCircle,
    XCircle,
    Clock,
    MapPin,
    Fingerprint,
    Calendar,
    Shield,
    Briefcase,
    Image as ImageIcon,
    Loader2,
    AlertCircle,
    X,
    ExternalLink,
    CheckCircle2
} from 'lucide-react';
import StatusBadge from '@/components/ui/StatusBadge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

interface TechnicianApplication {
    id: string;
    uid: string;
    fullName: string;
    phone: string;
    email: string;
    city: string;
    category: string;
    experienceYears?: number;
    aadhaarNumber?: string;
    aadhaarFrontUrl?: string;
    aadhaarBackUrl?: string;
    selfieUrl?: string;
    status: 'pending' | 'approved' | 'rejected';
    rejectionReason?: string;
    createdAt: { seconds: number; nanoseconds: number };
    reviewedAt?: { seconds: number; nanoseconds: number };
}

type TabType = 'pending' | 'approved' | 'rejected';

export default function ApplicationsPage() {
    const [applications, setApplications] = useState<TechnicianApplication[]>([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(true);
    const [processingId, setProcessingId] = useState<string | null>(null);
    const [activeTab, setActiveTab] = useState<TabType>('pending');
    const [selectedApp, setSelectedApp] = useState<TechnicianApplication | null>(null);
    const [isDetailsOpen, setIsDetailsOpen] = useState(false);
    const [isRejectModalOpen, setIsRejectModalOpen] = useState(false);
    const [rejectReason, setRejectReason] = useState('');
    const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

    // Show toast notification
    const showToast = (type: 'success' | 'error', message: string) => {
        setToast({ type, message });
        setTimeout(() => setToast(null), 4000);
    };

    // Fetch applications with real-time listener
    useEffect(() => {
        if (!db) return;

        setLoading(true);
        const q = query(collection(db, 'technicianApplications'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snap) => {
            setApplications(snap.docs.map(d => {
                const data = d.data();
                return { id: d.id, ...data } as TechnicianApplication;
            }));
            setLoading(false);
        }, (error) => {
            console.error('Error fetching applications:', error);
            showToast('error', 'Failed to load applications');
            setLoading(false);
        });

        return () => unsubscribe();
    }, []);

    // Filter applications by tab and search
    const filteredApps = applications.filter(a => {
        // Tab filter
        const matchesTab = a.status === activeTab;
        
        // Search filter
        const matchesSearch = !searchTerm || 
            a.fullName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            a.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            a.phone?.includes(searchTerm) ||
            a.id.toLowerCase().includes(searchTerm.toLowerCase());
        
        return matchesTab && matchesSearch;
    });

    // Count badges
    const pendingCount = applications.filter(a => a.status === 'pending').length;
    const approvedCount = applications.filter(a => a.status === 'approved').length;
    const rejectedCount = applications.filter(a => a.status === 'rejected').length;

    // Handle approve
    const handleApprove = async (uid: string) => {
        if (!uid) return;
        
        setProcessingId(uid);
        try {
            await adminApi.approveTechnicianApp(uid);
            showToast('success', 'Technician application approved successfully!');
            setIsDetailsOpen(false);
        } catch (error: any) {
            console.error('Error approving technician:', error);
            showToast('error', `Failed to approve: ${error.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    // Handle reject
    const handleReject = async () => {
        if (!selectedApp?.uid || !rejectReason.trim()) return;

        setProcessingId(selectedApp.uid);
        try {
            await adminApi.rejectTechnicianApp(selectedApp.uid, rejectReason);
            showToast('success', 'Technician application rejected');
            setIsRejectModalOpen(false);
            setRejectReason('');
            setIsDetailsOpen(false);
        } catch (error: any) {
            console.error('Error rejecting technician:', error);
            showToast('error', `Failed to reject: ${error.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const openDetails = (app: TechnicianApplication) => {
        setSelectedApp(app);
        setIsDetailsOpen(true);
    };

    const openRejectModal = (app: TechnicianApplication) => {
        setSelectedApp(app);
        setIsRejectModalOpen(true);
    };

    const tabs = [
        { id: 'pending' as TabType, label: 'Pending', count: pendingCount },
        { id: 'approved' as TabType, label: 'Approved', count: approvedCount },
        { id: 'rejected' as TabType, label: 'Rejected', count: rejectedCount }
    ];

    return (
        <div className="space-y-8 max-w-[1600px] mx-auto">
            {/* Toast Notification */}
            {toast && (
                <div className={`fixed top-4 right-4 z-50 flex items-center gap-3 px-4 py-3 rounded-xl shadow-lg border ${
                    toast.type === 'success' 
                        ? 'bg-emerald-500/10 border-emerald-500/20 text-emerald-400' 
                        : 'bg-red-500/10 border-red-500/20 text-red-400'
                }`}>
                    {toast.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
                    <span className="text-sm font-medium">{toast.message}</span>
                </div>
            )}

            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight">Technician Applications</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Review and approve technician applications with KYC verification.</p>
                        {pendingCount > 0 && (
                            <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                                <Clock size={10} className="animate-pulse" />
                                {pendingCount} Pending
                            </div>
                        )}
                    </div>
                </div>

                <div className="relative w-full md:w-80 group">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                    <Input
                        placeholder="Search by name, email or phone..."
                        className="pl-10 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            {/* Tabs */}
            <div className="flex gap-2 border-b border-slate-800 pb-1">
                {tabs.map(tab => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id)}
                        className={`relative px-4 py-3 text-sm font-black uppercase tracking-widest transition-all ${
                            activeTab === tab.id
                                ? 'text-indigo-400'
                                : 'text-slate-500 hover:text-slate-300'
                        }`}
                    >
                        <div className="flex items-center gap-2">
                            {tab.label}
                            <span className={`px-2 py-0.5 rounded-full text-[10px] ${
                                activeTab === tab.id
                                    ? 'bg-indigo-500/20 text-indigo-400'
                                    : 'bg-slate-800 text-slate-500'
                            }`}>
                                {tab.count}
                            </span>
                        </div>
                        {activeTab === tab.id && (
                            <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-indigo-500 shadow-[0_0_10px_rgba(99,102,241,0.5)]" />
                        )}
                    </button>
                ))}
            </div>

            {/* Loading State */}
            {loading ? (
                <div className="py-20 flex flex-col items-center justify-center gap-4">
                    <div className="w-10 h-10 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin"></div>
                    <p className="text-slate-500 text-[10px] font-black uppercase tracking-widest animate-pulse">Loading Pipeline...</p>
                </div>
            ) : filteredApps.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-24 text-center border-2 border-dashed border-slate-800 rounded-3xl bg-slate-900/20">
                    <div className="w-16 h-16 bg-slate-800/50 rounded-2xl flex items-center justify-center mb-6 text-slate-600">
                        <ClipboardList size={32} />
                    </div>
                    <h3 className="text-xl font-bold text-slate-300">No applications found</h3>
                    <p className="text-slate-500 max-w-xs mt-2">
                        {activeTab === 'pending' 
                            ? 'No pending applications. Check back later for new submissions.'
                            : activeTab === 'approved'
                            ? 'No approved applications yet.'
                            : 'No rejected applications.'}
                    </p>
                </div>
            ) : (
                <div className="grid gap-6">
                    {filteredApps.map((app) => (
                        <Card 
                            key={app.id} 
                            className="overflow-hidden border-slate-800/50 bg-slate-900/40 backdrop-blur-sm group hover:border-slate-700 transition-all duration-300 cursor-pointer"
                            onClick={() => openDetails(app)}
                        >
                            <div className="flex flex-col md:flex-row">
                                <div className="p-8 flex-1">
                                    <div className="flex items-start gap-6">
                                        <div className="h-24 w-24 rounded-2xl bg-slate-800 border border-slate-700 flex items-center justify-center flex-shrink-0 overflow-hidden shadow-lg group-hover:border-indigo-500/30 transition-all duration-300">
                                            {app.selfieUrl ? (
                                                <img src={app.selfieUrl} alt={app.fullName} className="h-full w-full object-cover" />
                                            ) : (
                                                <UserCircle className="h-12 w-12 text-slate-600" />
                                            )}
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-center justify-between mb-2">
                                                <div>
                                                    <h3 className="text-2xl font-black text-white hover:text-indigo-400 transition-colors truncate cursor-default">
                                                        {app.fullName || 'Unknown'}
                                                    </h3>
                                                    <div className="flex items-center gap-2 mt-0.5">
                                                        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest flex items-center gap-1">
                                                            <Fingerprint size={12} />
                                                            ID: {app.uid?.substring(0, 8).toUpperCase() || app.id.substring(0, 8).toUpperCase()}
                                                        </span>
                                                        <span className="w-1 h-1 rounded-full bg-slate-800"></span>
                                                        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest flex items-center gap-1">
                                                            <Calendar size={12} />
                                                            {app.createdAt ? new Date(app.createdAt.seconds * 1000).toLocaleDateString() : 'N/A'}
                                                        </span>
                                                    </div>
                                                </div>
                                                <StatusBadge status={app.status || 'pending'} />
                                            </div>

                                            <div className="flex flex-wrap gap-x-6 gap-y-2 text-sm text-slate-400 font-medium mb-6">
                                                <div className="flex items-center gap-2">
                                                    <div className="p-1.5 bg-slate-800 rounded-lg text-slate-500"><Mail size={14} /></div>
                                                    {app.email || 'No email'}
                                                </div>
                                                <div className="flex items-center gap-2">
                                                    <div className="p-1.5 bg-slate-800 rounded-lg text-slate-500"><Phone size={14} /></div>
                                                    {app.phone || 'No phone'}
                                                </div>
                                                <div className="flex items-center gap-2">
                                                    <div className="p-1.5 bg-slate-800 rounded-lg text-slate-500"><MapPin size={14} /></div>
                                                    {app.city || 'No city'}
                                                </div>
                                                <div className="flex items-center gap-2">
                                                    <div className="p-1.5 bg-slate-800 rounded-lg text-slate-500"><Briefcase size={14} /></div>
                                                    {app.category || 'General'}
                                                </div>
                                            </div>

                                            {app.experienceYears && (
                                                <div className="text-xs text-slate-500">
                                                    <span className="font-medium text-emerald-400">{app.experienceYears} years</span> of experience
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                                <div 
                                    className="bg-slate-900/50 border-t md:border-t-0 md:border-l border-slate-800/50 p-8 flex flex-row md:flex-col items-center justify-center gap-3 md:w-56 flex-shrink-0"
                                    onClick={(e) => e.stopPropagation()}
                                >
                                    {app.status === 'pending' ? (
                                        <>
                                            <Button
                                                className="w-full bg-emerald-600 hover:bg-emerald-500 text-white font-black uppercase tracking-widest text-[10px] h-12 rounded-xl shadow-lg shadow-emerald-600/10 transition-all hover:scale-[1.02] active:scale-[0.98]"
                                                disabled={processingId === app.uid}
                                                onClick={() => handleApprove(app.uid)}
                                            >
                                                {processingId === app.uid ? (
                                                    <div className="w-5 h-5 border-2 border-white/20 border-t-white rounded-full animate-spin"></div>
                                                ) : (
                                                    <><CheckCircle className="mr-2 h-4 w-4" /> Approve</>
                                                )}
                                            </Button>
                                            <Button
                                                variant="destructive"
                                                className="w-full bg-red-600 hover:bg-red-500 text-white font-black uppercase tracking-widest text-[10px] h-12 rounded-xl shadow-lg shadow-red-600/10 transition-all hover:scale-[1.02] active:scale-[0.98]"
                                                disabled={processingId === app.uid}
                                                onClick={() => openRejectModal(app)}
                                            >
                                                <XCircle className="mr-2 h-4 w-4" /> Reject
                                            </Button>
                                        </>
                                    ) : (
                                        <div className="text-center p-6 bg-slate-800/30 rounded-2xl border border-slate-800/50 w-full animate-in fade-in zoom-in duration-500">
                                            <div className={`mx-auto h-12 w-12 rounded-full flex items-center justify-center mb-3 ${app.status === 'approved' ? 'bg-emerald-500/10 text-emerald-500' : 'bg-red-500/10 text-red-500'}`}>
                                                {app.status === 'approved' ? <CheckCircle size={24} /> : <XCircle size={24} />}
                                            </div>
                                            <span className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-500">Decision Recorded</span>
                                            {app.reviewedAt && (
                                                <p className="text-[9px] text-slate-600 mt-2">
                                                    {new Date(app.reviewedAt.seconds * 1000).toLocaleDateString()}
                                                </p>
                                            )}
                                        </div>
                                    )}
                                </div>
                            </div>
                        </Card>
                    ))}
                </div>
            )}

            {/* Details Drawer */}
            {isDetailsOpen && selectedApp && (
                <div className="fixed inset-0 bg-[#0f172a]/95 backdrop-blur-xl flex items-center justify-center z-50 p-4">
                    <Card className="w-full max-w-3xl bg-slate-900 border-slate-800 rounded-3xl overflow-hidden shadow-2xl max-h-[90vh] overflow-y-auto">
                        <div className="p-6 border-b border-slate-800 flex justify-between items-center sticky top-0 bg-slate-900 z-10">
                            <div>
                                <h2 className="text-xl font-black text-white uppercase tracking-tight">Application Details</h2>
                                <p className="text-slate-500 text-xs font-bold mt-0.5 tracking-wider uppercase">
                                    ID: {selectedApp.uid?.substring(0, 8).toUpperCase() || selectedApp.id.substring(0, 8).toUpperCase()}
                                </p>
                            </div>
                            <div className="flex items-center gap-3">
                                <StatusBadge status={selectedApp.status} />
                                <Button variant="ghost" onClick={() => setIsDetailsOpen(false)} className="text-slate-500 hover:text-white rounded-full h-10 w-10 p-0">
                                    <X size={24} />
                                </Button>
                            </div>
                        </div>
                        
                        <div className="p-6 space-y-6">
                            {/* Personal Info */}
                            <div className="space-y-4">
                                <h3 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] flex items-center gap-2">
                                    <UserCircle size={14} /> Personal Information
                                </h3>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Full Name</p>
                                        <p className="text-white font-medium">{selectedApp.fullName || 'N/A'}</p>
                                    </div>
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Phone</p>
                                        <p className="text-white font-medium">{selectedApp.phone || 'N/A'}</p>
                                    </div>
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Email</p>
                                        <p className="text-white font-medium">{selectedApp.email || 'N/A'}</p>
                                    </div>
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">City</p>
                                        <p className="text-white font-medium">{selectedApp.city || 'N/A'}</p>
                                    </div>
                                </div>
                            </div>

                            {/* Professional Info */}
                            <div className="space-y-4">
                                <h3 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] flex items-center gap-2">
                                    <Briefcase size={14} /> Professional Information
                                </h3>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Category</p>
                                        <p className="text-white font-medium">{selectedApp.category || 'General'}</p>
                                    </div>
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Experience</p>
                                        <p className="text-white font-medium">{selectedApp.experienceYears || 0} years</p>
                                    </div>
                                </div>
                            </div>

                            {/* KYC Documents */}
                            <div className="space-y-4">
                                <h3 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] flex items-center gap-2">
                                    <Shield size={14} /> KYC Documents
                                </h3>
                                <div className="grid grid-cols-3 gap-4">
                                    {/* Aadhaar Front */}
                                    <div className="space-y-2">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Aadhaar Front</p>
                                        <div className="aspect-video bg-slate-800 rounded-xl border border-slate-700 overflow-hidden">
                                            {selectedApp.aadhaarFrontUrl ? (
                                                <img 
                                                    src={selectedApp.aadhaarFrontUrl} 
                                                    alt="Aadhaar Front"
                                                    className="w-full h-full object-cover hover:scale-105 transition-transform cursor-pointer"
                                                />
                                            ) : (
                                                <div className="w-full h-full flex items-center justify-center text-slate-600">
                                                    <ImageIcon size={24} />
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                    {/* Aadhaar Back */}
                                    <div className="space-y-2">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Aadhaar Back</p>
                                        <div className="aspect-video bg-slate-800 rounded-xl border border-slate-700 overflow-hidden">
                                            {selectedApp.aadhaarBackUrl ? (
                                                <img 
                                                    src={selectedApp.aadhaarBackUrl} 
                                                    alt="Aadhaar Back"
                                                    className="w-full h-full object-cover hover:scale-105 transition-transform cursor-pointer"
                                                />
                                            ) : (
                                                <div className="w-full h-full flex items-center justify-center text-slate-600">
                                                    <ImageIcon size={24} />
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                    {/* Selfie */}
                                    <div className="space-y-2">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Selfie</p>
                                        <div className="aspect-video bg-slate-800 rounded-xl border border-slate-700 overflow-hidden">
                                            {selectedApp.selfieUrl ? (
                                                <img 
                                                    src={selectedApp.selfieUrl} 
                                                    alt="Selfie"
                                                    className="w-full h-full object-cover hover:scale-105 transition-transform cursor-pointer"
                                                />
                                            ) : (
                                                <div className="w-full h-full flex items-center justify-center text-slate-600">
                                                    <ImageIcon size={24} />
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                                {selectedApp.aadhaarNumber && (
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Aadhaar Number</p>
                                        <p className="text-white font-mono font-medium">XXXX-XXXX-{selectedApp.aadhaarNumber.slice(-4)}</p>
                                    </div>
                                )}
                            </div>

                            {/* Status Timeline */}
                            <div className="space-y-4">
                                <h3 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] flex items-center gap-2">
                                    <Clock size={14} /> Status Timeline
                                </h3>
                                <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                    <div className="flex items-center gap-4">
                                        <div className="flex flex-col items-center">
                                            <div className={`w-4 h-4 rounded-full ${selectedApp.status === 'pending' ? 'bg-amber-500 animate-pulse' : 'bg-emerald-500'}`}></div>
                                            <div className="h-8 w-0.5 bg-slate-700"></div>
                                            <div className={`w-4 h-4 rounded-full ${selectedApp.status === 'approved' ? 'bg-emerald-500' : selectedApp.status === 'rejected' ? 'bg-red-500' : 'bg-slate-700'}`}></div>
                                        </div>
                                        <div className="flex-1 space-y-2">
                                            <div>
                                                <p className="text-sm font-medium text-white">Submitted</p>
                                                <p className="text-xs text-slate-500">
                                                    {selectedApp.createdAt ? new Date(selectedApp.createdAt.seconds * 1000).toLocaleString() : 'N/A'}
                                                </p>
                                            </div>
                                            <div>
                                                <p className="text-sm font-medium text-white">
                                                    {selectedApp.status === 'approved' ? 'Approved' : selectedApp.status === 'rejected' ? 'Rejected' : 'Under Review'}
                                                </p>
                                                <p className="text-xs text-slate-500">
                                                    {selectedApp.reviewedAt ? new Date(selectedApp.reviewedAt.seconds * 1000).toLocaleString() : 'Pending'}
                                                </p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Rejection Reason (if rejected) */}
                            {selectedApp.status === 'rejected' && selectedApp.rejectionReason && (
                                <div className="space-y-4">
                                    <h3 className="text-[10px] font-black text-red-500 uppercase tracking-[0.2em]">Rejection Reason</h3>
                                    <div className="p-4 bg-red-500/10 rounded-2xl border border-red-500/20">
                                        <p className="text-red-400 font-medium">{selectedApp.rejectionReason}</p>
                                    </div>
                                </div>
                            )}

                            {/* Actions */}
                            {selectedApp.status === 'pending' && (
                                <div className="flex gap-3 pt-4 border-t border-slate-800">
                                    <Button 
                                        className="flex-1 bg-emerald-600 hover:bg-emerald-500 text-white h-14 rounded-2xl font-black text-[10px] uppercase tracking-widest"
                                        onClick={() => handleApprove(selectedApp.uid)}
                                        disabled={processingId === selectedApp.uid}
                                    >
                                        {processingId === selectedApp.uid ? (
                                            <Loader2 size={20} className="animate-spin" />
                                        ) : (
                                            <>
                                                <CheckCircle size={20} className="mr-2" />
                                                Approve & Create Technician
                                            </>
                                        )}
                                    </Button>
                                    <Button 
                                        variant="destructive"
                                        className="flex-1 bg-red-600 hover:bg-red-500 text-white h-14 rounded-2xl font-black text-[10px] uppercase tracking-widest"
                                        onClick={() => openRejectModal(selectedApp)}
                                        disabled={processingId === selectedApp.uid}
                                    >
                                        <XCircle size={20} className="mr-2" />
                                        Reject Application
                                    </Button>
                                </div>
                            )}
                        </div>
                    </Card>
                </div>
            )}

            {/* Reject Modal */}
            {isRejectModalOpen && selectedApp && (
                <div className="fixed inset-0 bg-[#0f172a]/95 backdrop-blur-xl flex items-center justify-center z-50 p-4">
                    <Card className="w-full max-w-md bg-slate-900 border-slate-800 rounded-3xl overflow-hidden shadow-2xl">
                        <div className="p-6 border-b border-slate-800 flex justify-between items-center">
                            <div>
                                <h2 className="text-xl font-black text-white uppercase tracking-tight">Reject Application</h2>
                                <p className="text-slate-500 text-xs font-bold mt-0.5 tracking-wider uppercase">
                                    {selectedApp.fullName}
                                </p>
                            </div>
                            <Button variant="ghost" onClick={() => setIsRejectModalOpen(false)} className="text-slate-500 hover:text-white rounded-full h-10 w-10 p-0">
                                <X size={24} />
                            </Button>
                        </div>
                        <div className="p-6 space-y-4">
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">
                                    Rejection Reason (Required)
                                </label>
                                <textarea
                                    value={rejectReason}
                                    onChange={(e) => setRejectReason(e.target.value)}
                                    placeholder="Enter reason for rejection..."
                                    className="w-full h-32 bg-slate-800/50 border border-slate-700 text-white p-4 rounded-2xl text-sm font-medium focus:ring-2 focus:ring-red-500/50 focus:outline-none resize-none"
                                />
                            </div>
                            <div className="flex gap-3 pt-4">
                                <Button 
                                    variant="outline" 
                                    className="flex-1 h-12 rounded-2xl font-black text-[10px] uppercase tracking-widest border-slate-700 text-slate-300"
                                    onClick={() => setIsRejectModalOpen(false)}
                                >
                                    Cancel
                                </Button>
                                <Button 
                                    className="flex-1 bg-red-600 hover:bg-red-500 text-white h-12 rounded-2xl font-black text-[10px] uppercase tracking-widest"
                                    onClick={handleReject}
                                    disabled={!rejectReason.trim() || processingId === selectedApp.uid}
                                >
                                    {processingId === selectedApp.uid ? (
                                        <Loader2 size={16} className="animate-spin" />
                                    ) : (
                                        'Confirm Rejection'
                                    )}
                                </Button>
                            </div>
                        </div>
                    </Card>
                </div>
            )}
        </div>
    );
}
