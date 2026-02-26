'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, limit, startAfter, where, getDocs, QueryDocumentSnapshot, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';
import { Star, Search, Eye, EyeOff, Flag, XCircle, User, Wrench, Calendar, AlertTriangle } from 'lucide-react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

const LIMIT = 20;

export default function ReviewsPage() {
    const [reviews, setReviews] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [ratingFilter, setRatingFilter] = useState<number | null>(null);
    const [statusFilter, setStatusFilter] = useState<string>('all');
    const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot | null>(null);
    const [hasMore, setHasMore] = useState(true);
    const [processingId, setProcessingId] = useState<string | null>(null);
    const [selectedReview, setSelectedReview] = useState<any>(null);

    const fetchReviews = async (isLoadMore = false) => {
        try {
            setLoading(true);
            let q = query(collection(db, 'reviews'), orderBy('createdAt', 'desc'), limit(LIMIT));

            if (ratingFilter) q = query(q, where('rating', '==', ratingFilter));
            if (statusFilter === 'hidden') q = query(q, where('isHidden', '==', true));
            if (statusFilter === 'flagged') q = query(q, where('isFlagged', '==', true));
            if (statusFilter === 'visible') q = query(q, where('isHidden', '==', false));
            if (isLoadMore && lastDoc) q = query(q, startAfter(lastDoc));

            const snap = await getDocs(q);
            const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));

            setReviews(isLoadMore ? [...reviews, ...data] : data);
            setLastDoc(snap.docs[snap.docs.length - 1] || null);
            setHasMore(snap.docs.length === LIMIT);
        } catch (e) {
            console.error('Fetch reviews error:', e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchReviews();
    }, [ratingFilter, statusFilter]);

    const handleAction = async (reviewId: string, action: string) => {
        if (!confirm(`Confirm ${action} action?`)) return;
        setProcessingId(reviewId);
        try {
            const fn = httpsCallable(functions, 'admin_manageReview');
            await fn({ reviewId, action });
            await fetchReviews();
        } catch (e: any) {
            alert(`Failed: ${e.message}`);
        } finally {
            setProcessingId(null);
        }
    };

    const filteredReviews = reviews.filter(r =>
        r.customerName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.technicianName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.reviewText?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="space-y-6 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black text-white uppercase">Reviews</h1>
                    <p className="text-slate-500 text-sm">Moderate customer feedback</p>
                </div>
                <div className="relative w-full md:w-80">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4" />
                    <Input
                        placeholder="Search reviews..."
                        className="pl-10 bg-slate-900/50 border-slate-800"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            <div className="flex gap-2 flex-wrap">
                <Button
                    variant={statusFilter === 'all' ? 'default' : 'outline'}
                    onClick={() => setStatusFilter('all')}
                    className="text-xs"
                >
                    All
                </Button>
                <Button
                    variant={statusFilter === 'visible' ? 'default' : 'outline'}
                    onClick={() => setStatusFilter('visible')}
                    className="text-xs"
                >
                    Visible
                </Button>
                <Button
                    variant={statusFilter === 'hidden' ? 'default' : 'outline'}
                    onClick={() => setStatusFilter('hidden')}
                    className="text-xs"
                >
                    Hidden
                </Button>
                <Button
                    variant={statusFilter === 'flagged' ? 'default' : 'outline'}
                    onClick={() => setStatusFilter('flagged')}
                    className="text-xs"
                >
                    Flagged
                </Button>
                <div className="h-6 w-px bg-slate-800 mx-2" />
                {[5, 4, 3, 2, 1].map(star => (
                    <Button
                        key={star}
                        variant={ratingFilter === star ? 'default' : 'outline'}
                        onClick={() => setRatingFilter(ratingFilter === star ? null : star)}
                        className="text-xs"
                    >
                        {star} <Star size={12} className="ml-1" />
                    </Button>
                ))}
            </div>

            <div className="space-y-4">
                {loading && reviews.length === 0 ? (
                    [1, 2, 3].map(i => <div key={i} className="h-40 rounded-2xl bg-slate-900/50 animate-pulse" />)
                ) : filteredReviews.length === 0 ? (
                    <div className="text-center py-20 border-2 border-dashed border-slate-800 rounded-2xl">
                        <p className="text-slate-500">No reviews found</p>
                    </div>
                ) : (
                    filteredReviews.map((review) => (
                        <Card key={review.id} className="border-slate-800 bg-slate-900/40">
                            <div className="flex flex-col lg:flex-row divide-y lg:divide-y-0 lg:divide-x divide-slate-800">
                                <div className="flex-1 p-6 space-y-4">
                                    <div className="flex items-center justify-between">
                                        <div className="flex items-center gap-1">
                                            {[1, 2, 3, 4, 5].map(s => (
                                                <Star
                                                    key={s}
                                                    size={16}
                                                    className={s <= review.rating ? 'text-amber-400 fill-amber-400' : 'text-slate-700'}
                                                />
                                            ))}
                                        </div>
                                        <div className="flex items-center gap-2">
                                            {review.isHidden && <Badge className="bg-red-500/10 text-red-500 text-xs">Hidden</Badge>}
                                            {review.isFlagged && <Badge className="bg-amber-500/10 text-amber-500 text-xs">Flagged</Badge>}
                                            {review.rating <= 2 && <Badge className="bg-rose-500/10 text-rose-500 text-xs"><AlertTriangle size={10} className="mr-1" />Critical</Badge>}
                                        </div>
                                    </div>

                                    <p className="text-slate-300 italic">"{review.reviewText || 'No text provided'}"</p>

                                    <div className="grid grid-cols-2 gap-4 pt-4 border-t border-slate-800">
                                        <div className="flex items-center gap-3">
                                            <div className="w-10 h-10 rounded-xl bg-slate-800 flex items-center justify-center">
                                                <User size={18} className="text-indigo-400" />
                                            </div>
                                            <div>
                                                <p className="text-xs text-slate-500">Customer</p>
                                                <p className="text-sm font-bold text-slate-200">{review.customerName || 'Anonymous'}</p>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-3">
                                            <div className="w-10 h-10 rounded-xl bg-slate-800 flex items-center justify-center">
                                                <Wrench size={18} className="text-emerald-400" />
                                            </div>
                                            <div>
                                                <p className="text-xs text-slate-500">Technician</p>
                                                <p className="text-sm font-bold text-slate-200">{review.technicianName || 'N/A'}</p>
                                            </div>
                                        </div>
                                    </div>

                                    <div className="flex items-center gap-2 text-xs text-slate-500">
                                        <Calendar size={12} />
                                        {review.createdAt?.seconds ? new Date(review.createdAt.seconds * 1000).toLocaleDateString() : 'N/A'}
                                    </div>
                                </div>

                                <div className="p-6 lg:w-56 flex flex-col gap-2">
                                    <Button
                                        size="sm"
                                        variant="outline"
                                        onClick={() => setSelectedReview(review)}
                                        className="w-full"
                                    >
                                        View Details
                                    </Button>
                                    {!review.isHidden ? (
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            disabled={processingId === review.id}
                                            onClick={() => handleAction(review.id, 'hide')}
                                            className="w-full"
                                        >
                                            <EyeOff size={14} className="mr-2" /> Hide
                                        </Button>
                                    ) : (
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            disabled={processingId === review.id}
                                            onClick={() => handleAction(review.id, 'unhide')}
                                            className="w-full"
                                        >
                                            <Eye size={14} className="mr-2" /> Unhide
                                        </Button>
                                    )}
                                    {!review.isFlagged ? (
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            disabled={processingId === review.id}
                                            onClick={() => handleAction(review.id, 'flag')}
                                            className="w-full text-amber-500 hover:text-amber-400"
                                        >
                                            <Flag size={14} className="mr-2" /> Flag
                                        </Button>
                                    ) : (
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            disabled={processingId === review.id}
                                            onClick={() => handleAction(review.id, 'unflag')}
                                            className="w-full"
                                        >
                                            <Flag size={14} className="mr-2" /> Unflag
                                        </Button>
                                    )}
                                </div>
                            </div>
                        </Card>
                    ))
                )}
            </div>

            {hasMore && !loading && (
                <Button onClick={() => fetchReviews(true)} className="w-full">
                    Load More
                </Button>
            )}

            {selectedReview && (
                <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4" onClick={() => setSelectedReview(null)}>
                    <Card className="w-full max-w-2xl bg-slate-900 border-slate-800" onClick={(e) => e.stopPropagation()}>
                        <div className="p-6 border-b border-slate-800 flex items-center justify-between">
                            <h2 className="text-xl font-bold text-white">Review Details</h2>
                            <Button variant="ghost" size="sm" onClick={() => setSelectedReview(null)}>
                                <XCircle size={20} />
                            </Button>
                        </div>
                        <div className="p-6 space-y-4">
                            <div className="flex items-center gap-1">
                                {[1, 2, 3, 4, 5].map(s => (
                                    <Star key={s} size={24} className={s <= selectedReview.rating ? 'text-amber-400 fill-amber-400' : 'text-slate-700'} />
                                ))}
                            </div>
                            <p className="text-slate-300 text-lg italic">"{selectedReview.reviewText}"</p>
                            <div className="grid grid-cols-2 gap-4 pt-4 border-t border-slate-800">
                                <div>
                                    <p className="text-xs text-slate-500 mb-1">Customer</p>
                                    <p className="text-sm font-bold">{selectedReview.customerName}</p>
                                </div>
                                <div>
                                    <p className="text-xs text-slate-500 mb-1">Technician</p>
                                    <p className="text-sm font-bold">{selectedReview.technicianName}</p>
                                </div>
                                <div>
                                    <p className="text-xs text-slate-500 mb-1">Booking ID</p>
                                    <p className="text-sm font-mono">{selectedReview.bookingId}</p>
                                </div>
                                <div>
                                    <p className="text-xs text-slate-500 mb-1">Date</p>
                                    <p className="text-sm">{selectedReview.createdAt?.seconds ? new Date(selectedReview.createdAt.seconds * 1000).toLocaleString() : 'N/A'}</p>
                                </div>
                            </div>
                        </div>
                    </Card>
                </div>
            )}
        </div>
    );
}
