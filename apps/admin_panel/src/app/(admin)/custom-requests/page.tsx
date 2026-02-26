'use client';

import { useEffect, useState, useCallback } from 'react';
import { 
    collection, 
    query, 
    orderBy, 
    onSnapshot, 
    where,
    limit,
    startAfter,
    getDocs
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { adminApi } from '@/lib/admin-api';
import StatusBadge from '@/components/ui/StatusBadge';
import Table from '@/components/ui/Table';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import {
    Search,
    Calendar,
    Filter,
    XCircle,
    CheckCircle2,
    RefreshCw,
    ArrowRightCircle,
    Eye,
    Clock,
    MapPin,
    User,
    Phone,
    FileText,
    ImageIcon,
    ChevronLeft,
    ChevronRight,
    Loader2,
    AlertCircle,
    X
} from 'lucide-react';

interface CustomRequest {
    id: string;
    customerId: string;
    customerName: string;
    phone: string;
    serviceTitle: string;
    description: string;
    location: string;
    images: string[];
    status: 'pending' | 'reviewed' | 'rejected' | 'converted';
    createdAt: { seconds: number; nanoseconds: number };
    adminNotes?: string;
}

const ITEMS_PER_PAGE = 10;

const statusFilters = [
    { value: 'all', label: 'All Status' },
    { value: 'pending', label: 'Pending' },
    { value: 'reviewed', label: 'Reviewed' },
    { value: 'rejected', label: 'Rejected' },
    { value: 'converted', label: 'Converted' }
];

export default function CustomRequestsPage() {
    const [requests, setRequests] = useState<CustomRequest[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('all');
    const [dateFilter, setDateFilter] = useState('');
    const [processingId, setProcessingId] = useState<string | null>(null);
    const [selectedRequest, setSelectedRequest] = useState<CustomRequest | null>(null);
    const [isDetailsOpen, setIsDetailsOpen] = useState(false);
    const [isRejectModalOpen, setIsRejectModalOpen] = useState(false);
    const [rejectNotes, setRejectNotes] = useState('');
    const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
    
    // Pagination
    const [lastDoc, setLastDoc] = useState<any>(null);
    const [hasMore, setHasMore] = useState(true);
    const [currentPage, setCurrentPage] = useState(1);

    // Show toast notification
    const showToast = (type: 'success' | 'error', message: string) => {
        setToast({ type, message });
        setTimeout(() => setToast(null), 4000);
    };

    // Build query based on filters
    const buildQuery = useCallback((page: number = 1, lastDocument: any = null) => {
        if (!db) return null;
        
        let constraints: any[] = [];
        
        // Add status filter
        if (statusFilter !== 'all') {
            constraints.push(where('status', '==', statusFilter));
        }
        
        // Add order
        constraints.push(orderBy('createdAt', 'desc'));
        
        // Add pagination
        if (page === 1) {
            constraints.push(limit(ITEMS_PER_PAGE));
        } else if (lastDocument) {
            constraints.push(startAfter(lastDocument));
            constraints.push(limit(ITEMS_PER_PAGE));
        }
        
        return query(collection(db, 'customRequests'), ...constraints);
    }, [statusFilter]);

    // Fetch requests
    const fetchRequests = useCallback(async (page: number = 1, reset: boolean = false) => {
        if (!db) return;
        
        setLoading(true);
        try {
            let q;
            
            if (statusFilter === 'all') {
                // No status filter - simple query
                if (page === 1) {
                    q = query(
                        collection(db, 'customRequests'),
                        orderBy('createdAt', 'desc'),
                        limit(ITEMS_PER_PAGE)
                    );
                } else {
                    q = query(
                        collection(db, 'customRequests'),
                        orderBy('createdAt', 'desc'),
                        startAfter(lastDoc),
                        limit(ITEMS_PER_PAGE)
                    );
                }
            } else {
                // With status filter - need composite index
                if (page === 1) {
                    q = query(
                        collection(db, 'customRequests'),
                        where('status', '==', statusFilter),
                        orderBy('createdAt', 'desc'),
                        limit(ITEMS_PER_PAGE)
                    );
                } else {
                    q = query(
                        collection(db, 'customRequests'),
                        where('status', '==', statusFilter),
                        orderBy('createdAt', 'desc'),
                        startAfter(lastDoc),
                        limit(ITEMS_PER_PAGE)
                    );
                }
            }
            
            const snapshot = await getDocs(q);
            const newRequests: CustomRequest[] = [];
            snapshot.docs.forEach((d) => {
                const docData = d.data() as Record<string, unknown>;
                const item: CustomRequest = {
                    id: d.id,
                    customerId: docData.customerId as string || '',
                    customerName: docData.customerName as string || '',
                    phone: docData.phone as string || '',
                    serviceTitle: docData.serviceTitle as string || '',
                    description: docData.description as string || '',
                    location: docData.location as string || '',
                    images: (docData.images as string[]) || [],
                    status: (docData.status as CustomRequest['status']) || 'pending',
                    createdAt: docData.createdAt as CustomRequest['createdAt'] || { seconds: 0, nanoseconds: 0 },
                    adminNotes: docData.adminNotes as string | undefined,
                };
                newRequests.push(item);
            });
            
            if (page === 1 || reset) {
                setRequests(newRequests);
            } else {
                setRequests(prev => [...prev, ...newRequests]);
            }
            
            setLastDoc(snapshot.docs[snapshot.docs.length - 1]);
            setHasMore(snapshot.docs.length === ITEMS_PER_PAGE);
            setCurrentPage(page);
        } catch (error: any) {
            console.error('Error fetching requests:', error);
            showToast('error', `Failed to load requests: ${error.message}`);
        } finally {
            setLoading(false);
        }
    }, [statusFilter, lastDoc]);

    // Initial load and filter changes
    useEffect(() => {
        fetchRequests(1, true);
    }, [statusFilter]);

    // Real-time listener for updates
    useEffect(() => {
        if (!db) return;
        
        const q = query(collection(db, 'customRequests'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snap) => {
            // Only update if on first page and no filters
            if (currentPage === 1 && statusFilter === 'all' && !searchTerm) {
                setRequests(snap.docs.map(d => ({ id: d.id, ...d.data() })) as CustomRequest[]);
                setLoading(false);
            }
        });
        
        return () => unsubscribe();
    }, [currentPage, statusFilter, searchTerm]);

    // Filter requests locally for search
    const filteredRequests = requests.filter(r => {
        const matchesSearch = !searchTerm || 
            r.customerName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            r.phone?.includes(searchTerm) ||
            r.serviceTitle?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            r.id.toLowerCase().includes(searchTerm.toLowerCase());
        
        const matchesDate = !dateFilter || 
            new Date(r.createdAt?.seconds * 1000).toISOString().split('T')[0] === dateFilter;
        
        return matchesSearch && matchesDate;
    });

    // Handle actions
    const handleMarkAsReviewed = async (requestId: string) => {
        setProcessingId(requestId);
        try {
            await adminApi.markCustomRequestAsReviewed(requestId);
            showToast('success', 'Request marked as reviewed');
            fetchRequests(currentPage, true);
        } catch (error: any) {
            console.error('Error marking as reviewed:', error);
            showToast('error', `Failed: ${error.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const handleConvertToBooking = async (requestId: string) => {
        setProcessingId(requestId);
        try {
            const result = await adminApi.convertCustomRequest(requestId);
            showToast('success', 'Request converted to booking successfully');
            fetchRequests(currentPage, true);
        } catch (error: any) {
            console.error('Error converting to booking:', error);
            showToast('error', `Failed: ${error.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const handleReject = () => {
        if (!selectedRequest || !rejectNotes.trim()) return;
        
        setProcessingId(selectedRequest.id);
        adminApi.rejectCustomRequest(selectedRequest.id, rejectNotes)
            .then(() => {
                showToast('success', 'Request rejected');
                setIsRejectModalOpen(false);
                setRejectNotes('');
                fetchRequests(currentPage, true);
            })
            .catch((error: any) => {
                console.error('Error rejecting request:', error);
                showToast('error', `Failed: ${error.message}`);
            })
            .finally(() => {
                setProcessingId(null);
            });
    };

    const openRejectModal = (request: CustomRequest) => {
        setSelectedRequest(request);
        setIsRejectModalOpen(true);
    };

    const openDetails = (request: CustomRequest) => {
        setSelectedRequest(request);
        setIsDetailsOpen(true);
    };

    const columns = [
        {
            key: 'id',
            label: 'Reference',
            render: (r: CustomRequest) => (
                <div className="flex flex-col">
                    <span className="font-mono text-[10px] font-black text-indigo-400 tracking-wider">#{r.id.substring(0, 8).toUpperCase()}</span>
                    <span className="text-[9px] text-slate-500 font-bold uppercase tracking-widest mt-0.5">
                        {r.createdAt ? new Date(r.createdAt.seconds * 1000).toLocaleDateString() : 'N/A'}
                    </span>
                </div>
            )
        },
        {
            key: 'serviceTitle',
            label: 'Service',
            render: (r: CustomRequest) => (
                <div className="flex flex-col max-w-xs">
                    <span className="font-black text-white text-sm tracking-tight truncate">{r.serviceTitle || 'Custom Service'}</span>
                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest mt-1 truncate">{r.description?.substring(0, 50)}</span>
                </div>
            )
        },
        {
            key: 'customer',
            label: 'Customer',
            render: (r: CustomRequest) => (
                <div className="flex items-center gap-3">
                    <div className="flex flex-col">
                        <span className="text-sm font-bold text-slate-200">{r.customerName || 'Unknown'}</span>
                        <span className="text-[10px] font-medium text-slate-500">{r.phone || 'No phone'}</span>
                    </div>
                </div>
            )
        },
        {
            key: 'location',
            label: 'Location',
            render: (r: CustomRequest) => (
                <span className="text-xs text-slate-400 max-w-[120px] truncate block">{r.location || 'N/A'}</span>
            )
        },
        {
            key: 'status',
            label: 'Status',
            render: (r: CustomRequest) => <StatusBadge status={r.status || 'pending'} />
        },
        {
            key: 'actions',
            label: 'Actions',
            align: 'right' as const,
            render: (r: CustomRequest) => (
                <div className="flex justify-end gap-2 pr-2">
                    <Button
                        size="sm"
                        variant="ghost"
                        className="text-slate-500 hover:text-white hover:bg-slate-800 font-black text-[9px] uppercase tracking-widest px-3 h-9 rounded-xl"
                        onClick={() => openDetails(r)}
                    >
                        <Eye size={14} className="mr-1" /> View
                    </Button>
                    {r.status === 'pending' && (
                        <>
                            <Button
                                size="sm"
                                className="bg-blue-600 hover:bg-blue-500 text-white font-black text-[9px] uppercase tracking-widest px-3 h-9 rounded-xl"
                                onClick={() => handleMarkAsReviewed(r.id)}
                                disabled={processingId === r.id}
                            >
                                {processingId === r.id ? <Loader2 size={12} className="animate-spin" /> : <RefreshCw size={12} className="mr-1" />}
                                Review
                            </Button>
                            <Button
                                size="sm"
                                className="bg-emerald-600 hover:bg-emerald-500 text-white font-black text-[9px] uppercase tracking-widest px-3 h-9 rounded-xl"
                                onClick={() => handleConvertToBooking(r.id)}
                                disabled={processingId === r.id}
                            >
                                {processingId === r.id ? <Loader2 size={12} className="animate-spin" /> : <ArrowRightCircle size={12} className="mr-1" />}
                                Convert
                            </Button>
                            <Button
                                size="sm"
                                variant="ghost"
                                className="text-slate-500 hover:text-red-400 hover:bg-red-500/10 font-black text-[9px] uppercase tracking-widest px-3 h-9 rounded-xl"
                                onClick={() => openRejectModal(r)}
                                disabled={processingId === r.id}
                            >
                                <XCircle size={12} className="mr-1" />
                                Reject
                            </Button>
                        </>
                    )}
                </div>
            )
        }
    ];

    return (
        <div className="space-y-8 max-w-[1600px] mx-auto p-4 md:p-8">
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
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase">Custom Requests</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Review and manage custom service requests from customers.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            {requests.filter(r => r.status === 'pending').length} Pending
                        </div>
                    </div>
                </div>
            </div>

            {/* Filters */}
            <div className="flex flex-wrap gap-4 items-center">
                <div className="relative flex-1 min-w-[200px] max-w-md">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4" />
                    <Input
                        placeholder="Search by name, phone, service..."
                        className="pl-12 bg-slate-900/50 border-slate-800 text-white h-12 rounded-2xl"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
                
                <div className="flex items-center gap-3">
                    <Filter className="text-slate-500 h-4 w-4" />
                    <select
                        value={statusFilter}
                        onChange={(e) => setStatusFilter(e.target.value)}
                        className="bg-slate-900/50 border border-slate-800 text-white h-12 px-4 rounded-2xl text-sm font-medium focus:ring-2 focus:ring-indigo-500/50 focus:outline-none"
                    >
                        {statusFilters.map(filter => (
                            <option key={filter.value} value={filter.value}>{filter.label}</option>
                        ))}
                    </select>
                </div>

                <div className="flex items-center gap-3">
                    <Calendar className="text-slate-500 h-4 w-4" />
                    <input
                        type="date"
                        value={dateFilter}
                        onChange={(e) => setDateFilter(e.target.value)}
                        className="bg-slate-900/50 border border-slate-800 text-white h-12 px-4 rounded-2xl text-sm font-medium focus:ring-2 focus:ring-indigo-500/50 focus:outline-none"
                    />
                </div>

                {(statusFilter !== 'all' || dateFilter || searchTerm) && (
                    <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                            setStatusFilter('all');
                            setDateFilter('');
                            setSearchTerm('');
                        }}
                        className="text-slate-400 hover:text-white"
                    >
                        Clear Filters
                    </Button>
                )}
            </div>

            {/* Table */}
            <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-3xl">
                <CardContent className="p-0">
                    <Table
                        columns={columns}
                        data={filteredRequests}
                        loading={loading}
                        emptyMessage="No custom requests found."
                        className="[&_tr]:border-slate-800/50 [&_th]:text-slate-500 [&_th]:text-[10px] [&_th]:font-black [&_th]:uppercase [&_th]:tracking-widest [&_th]:py-6"
                    />
                </CardContent>
            </Card>

            {/* Pagination */}
            {!loading && requests.length > 0 && (
                <div className="flex items-center justify-between">
                    <div className="text-sm text-slate-500">
                        Page {currentPage} {hasMore && '- Showing top results'}
                    </div>
                    <div className="flex gap-2">
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={() => fetchRequests(currentPage - 1)}
                            disabled={currentPage === 1}
                            className="border-slate-700 text-slate-300 hover:bg-slate-800"
                        >
                            <ChevronLeft size={16} />
                        </Button>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={() => fetchRequests(currentPage + 1)}
                            disabled={!hasMore}
                            className="border-slate-700 text-slate-300 hover:bg-slate-800"
                        >
                            <ChevronRight size={16} />
                        </Button>
                    </div>
                </div>
            )}

            {/* Details Drawer */}
            {isDetailsOpen && selectedRequest && (
                <div className="fixed inset-0 bg-[#0f172a]/95 backdrop-blur-xl flex items-center justify-center z-50 p-4">
                    <Card className="w-full max-w-2xl bg-slate-900 border-slate-800 rounded-3xl overflow-hidden shadow-2xl max-h-[90vh] overflow-y-auto">
                        <div className="p-6 border-b border-slate-800 flex justify-between items-center sticky top-0 bg-slate-900 z-10">
                            <div>
                                <h2 className="text-xl font-black text-white uppercase tracking-tight">Request Details</h2>
                                <p className="text-slate-500 text-xs font-bold mt-0.5 tracking-wider uppercase">
                                    Ref: #{selectedRequest.id.substring(0, 8).toUpperCase()}
                                </p>
                            </div>
                            <div className="flex items-center gap-3">
                                <StatusBadge status={selectedRequest.status} />
                                <Button variant="ghost" onClick={() => setIsDetailsOpen(false)} className="text-slate-500 hover:text-white rounded-full h-10 w-10 p-0">
                                    <X size={24} />
                                </Button>
                            </div>
                        </div>
                        
                        <div className="p-6 space-y-6">
                            {/* Customer Info */}
                            <div className="space-y-4">
                                <h3 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] flex items-center gap-2">
                                    <User size={14} /> Customer Information
                                </h3>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Name</p>
                                        <p className="text-white font-medium">{selectedRequest.customerName || 'N/A'}</p>
                                    </div>
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Phone</p>
                                        <p className="text-white font-medium">{selectedRequest.phone || 'N/A'}</p>
                                    </div>
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800 col-span-2">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Location</p>
                                        <p className="text-white font-medium flex items-center gap-2">
                                            <MapPin size={14} className="text-slate-500" />
                                            {selectedRequest.location || 'N/A'}
                                        </p>
                                    </div>
                                </div>
                            </div>

                            {/* Request Info */}
                            <div className="space-y-4">
                                <h3 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] flex items-center gap-2">
                                    <FileText size={14} /> Request Information
                                </h3>
                                <div className="space-y-4">
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Service Title</p>
                                        <p className="text-white font-medium text-lg">{selectedRequest.serviceTitle || 'Custom Service'}</p>
                                    </div>
                                    <div className="p-4 bg-slate-800/50 rounded-2xl border border-slate-800">
                                        <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Description</p>
                                        <p className="text-white font-medium leading-relaxed">{selectedRequest.description || 'No description provided'}</p>
                                    </div>
                                    <div className="flex items-center gap-2 text-sm text-slate-400">
                                        <Clock size={14} />
                                        <span>Created: {selectedRequest.createdAt ? new Date(selectedRequest.createdAt.seconds * 1000).toLocaleString() : 'N/A'}</span>
                                    </div>
                                </div>
                            </div>

                            {/* Images */}
                            {selectedRequest.images && selectedRequest.images.length > 0 && (
                                <div className="space-y-4">
                                    <h3 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] flex items-center gap-2">
                                        <ImageIcon size={14} /> Images ({selectedRequest.images.length})
                                    </h3>
                                    <div className="grid grid-cols-3 gap-3">
                                        {selectedRequest.images.map((img, idx) => (
                                            <div key={idx} className="aspect-square bg-slate-800 rounded-xl overflow-hidden border border-slate-700">
                                                <img 
                                                    src={img} 
                                                    alt={`Image ${idx + 1}`}
                                                    className="w-full h-full object-cover hover:scale-110 transition-transform duration-300"
                                                />
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}

                            {/* Admin Notes */}
                            {selectedRequest.adminNotes && (
                                <div className="space-y-4">
                                    <h3 className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Admin Notes</h3>
                                    <div className="p-4 bg-amber-500/10 rounded-2xl border border-amber-500/20">
                                        <p className="text-amber-400 font-medium">{selectedRequest.adminNotes}</p>
                                    </div>
                                </div>
                            )}

                            {/* Actions */}
                            {selectedRequest.status === 'pending' && (
                                <div className="flex gap-3 pt-4 border-t border-slate-800">
                                    <Button 
                                        className="flex-1 bg-blue-600 hover:bg-blue-500 text-white h-12 rounded-2xl font-black text-[10px] uppercase tracking-widest"
                                        onClick={() => {
                                            setIsDetailsOpen(false);
                                            handleMarkAsReviewed(selectedRequest.id);
                                        }}
                                        disabled={processingId === selectedRequest.id}
                                    >
                                        <RefreshCw size={16} className="mr-2" />
                                        Mark as Reviewed
                                    </Button>
                                    <Button 
                                        className="flex-1 bg-emerald-600 hover:bg-emerald-500 text-white h-12 rounded-2xl font-black text-[10px] uppercase tracking-widest"
                                        onClick={() => {
                                            setIsDetailsOpen(false);
                                            handleConvertToBooking(selectedRequest.id);
                                        }}
                                        disabled={processingId === selectedRequest.id}
                                    >
                                        <ArrowRightCircle size={16} className="mr-2" />
                                        Convert to Booking
                                    </Button>
                                    <Button 
                                        variant="destructive"
                                        className="flex-1 bg-red-600 hover:bg-red-500 text-white h-12 rounded-2xl font-black text-[10px] uppercase tracking-widest"
                                        onClick={() => {
                                            setIsDetailsOpen(false);
                                            openRejectModal(selectedRequest);
                                        }}
                                        disabled={processingId === selectedRequest.id}
                                    >
                                        <XCircle size={16} className="mr-2" />
                                        Reject
                                    </Button>
                                </div>
                            )}
                        </div>
                    </Card>
                </div>
            )}

            {/* Reject Modal */}
            {isRejectModalOpen && selectedRequest && (
                <div className="fixed inset-0 bg-[#0f172a]/95 backdrop-blur-xl flex items-center justify-center z-50 p-4">
                    <Card className="w-full max-w-md bg-slate-900 border-slate-800 rounded-3xl overflow-hidden shadow-2xl">
                        <div className="p-6 border-b border-slate-800 flex justify-between items-center">
                            <div>
                                <h2 className="text-xl font-black text-white uppercase tracking-tight">Reject Request</h2>
                                <p className="text-slate-500 text-xs font-bold mt-0.5 tracking-wider uppercase">
                                    Ref: #{selectedRequest.id.substring(0, 8).toUpperCase()}
                                </p>
                            </div>
                            <Button variant="ghost" onClick={() => setIsRejectModalOpen(false)} className="text-slate-500 hover:text-white rounded-full h-10 w-10 p-0">
                                <X size={24} />
                            </Button>
                        </div>
                        <div className="p-6 space-y-4">
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">
                                    Rejection Reason (Admin Notes)
                                </label>
                                <textarea
                                    value={rejectNotes}
                                    onChange={(e) => setRejectNotes(e.target.value)}
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
                                    disabled={!rejectNotes.trim() || processingId === selectedRequest.id}
                                >
                                    {processingId === selectedRequest.id ? (
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
