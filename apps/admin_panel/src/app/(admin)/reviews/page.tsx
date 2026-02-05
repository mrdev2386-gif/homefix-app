'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, onSnapshot, updateDoc, doc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import {
    Star, MessageSquare, User, Wrench, Calendar, Search,
    Trash2, Flag, AlertTriangle, Tag, MoreHorizontal,
    Activity, ShieldCheck, Filter, ArrowUpRight
} from 'lucide-react';
import { Card, CardHeader, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

export default function ReviewsPage() {
    const [reviews, setReviews] = useState<any[]>([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(true);
    const [ratingFilter, setRatingFilter] = useState<number | null>(null);

    useEffect(() => {
        const q = query(collection(db, 'reviews'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snap) => {
            setReviews(snap.docs.map(d => ({ id: d.id, ...d.data() })));
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    const filteredReviews = reviews.filter(r => {
        const matchesSearch =
            r.customerName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            r.technicianId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            r.reviewText?.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesRating = ratingFilter ? r.rating === ratingFilter : true;
        return matchesSearch && matchesRating;
    });

    const handleDeleteReview = async (id: string) => {
        if (!confirm('Are you sure you want to soft-delete this review?')) return;
        try {
            await updateDoc(doc(db, 'reviews', id), {
                status: 'deleted',
                updatedAt: new Date(),
            });
        } catch (e: any) {
            console.error(e);
            alert(`Failed: ${e.message}`);
        }
    };

    const handleFlagReview = async (id: string) => {
        try {
            await updateDoc(doc(db, 'reviews', id), {
                flagged: true,
                updatedAt: new Date(),
            });
        } catch (e: any) {
            console.error(e);
        }
    };

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase">Feedback Ledger</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Moderate and monitor platform service quality standards.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-amber-500/10 text-amber-400 rounded-md border border-amber-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Star size={10} className="fill-amber-400" />
                            {reviews.length} Total Logs
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-4">
                    <div className="relative w-full md:w-80 group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                        <Input
                            placeholder="Identify customer or agent..."
                            className="pl-10 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                </div>
            </div>

            <div className="space-y-6">
                <div className="flex items-center gap-2 p-1 bg-slate-900/50 border border-slate-800 rounded-2xl w-fit">
                    <button
                        onClick={() => setRatingFilter(null)}
                        className={`px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${ratingFilter === null ? 'bg-indigo-600 text-white shadow-lg' : 'text-slate-500 hover:text-slate-300'
                            }`}
                    >
                        All Grades
                    </button>
                    {[5, 4, 3, 2, 1].map(star => (
                        <button
                            key={star}
                            onClick={() => setRatingFilter(ratingFilter === star ? null : star)}
                            className={`px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all flex items-center gap-2 ${ratingFilter === star ? 'bg-indigo-600 text-white shadow-lg' : 'text-slate-500 hover:text-slate-300 hover:bg-slate-800/50'
                                }`}
                        >
                            {star} <Star size={10} className={ratingFilter === star ? 'fill-white' : 'fill-currentColor'} />
                        </button>
                    ))}
                </div>

                <div className="grid grid-cols-1 gap-4">
                    {loading ? (
                        [1, 2, 3].map(i => (
                            <div key={i} className="h-48 rounded-3xl bg-slate-900/50 border border-slate-800 animate-pulse" />
                        ))
                    ) : filteredReviews.length === 0 ? (
                        <div className="flex flex-col items-center justify-center py-32 text-center border-2 border-dashed border-slate-800 rounded-3xl bg-slate-900/20">
                            <div className="w-16 h-16 bg-slate-800/50 rounded-2xl flex items-center justify-center mb-6 text-slate-600">
                                <MessageSquare size={32} />
                            </div>
                            <h3 className="text-xl font-bold text-slate-300">No matching logs</h3>
                            <p className="text-slate-500 max-w-xs mt-2">Adjust your moderation criteria.</p>
                        </div>
                    ) : filteredReviews.map((review) => (
                        <Card key={review.id} className="overflow-hidden border-slate-800/50 bg-slate-900/40 backdrop-blur-sm group hover:border-slate-700 transition-all duration-300">
                            <div className="flex flex-col md:flex-row divide-y md:divide-y-0 md:divide-x divide-slate-800/50">
                                <div className="flex-1 p-6 md:p-8">
                                    <div className="flex flex-wrap items-center justify-between gap-4 mb-6">
                                        <div className="flex items-center gap-1">
                                            {[1, 2, 3, 4, 5].map(s => (
                                                <Star
                                                    key={s}
                                                    size={16}
                                                    className={`${s <= review.rating ? 'text-amber-400 fill-amber-400' : 'text-slate-800'} transition-all`}
                                                />
                                            ))}
                                            <div className="ml-3 h-4 w-px bg-slate-800 mx-1" />
                                            <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">
                                                {review.createdAt?.seconds ? new Date(review.createdAt.seconds * 1000).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' }) : 'LOG_RECENT'}
                                            </span>
                                        </div>
                                        <div className="flex items-center gap-2">
                                            {review.rating <= 2 && (
                                                <Badge className="bg-red-500/10 text-red-500 border-red-500/20 font-black text-[9px] uppercase tracking-widest">
                                                    <AlertTriangle size={10} className="mr-1" /> Critical
                                                </Badge>
                                            )}
                                            <span className="text-[9px] font-mono text-slate-600 bg-slate-950/50 px-2 py-1 rounded-md border border-slate-800/50 uppercase tracking-tighter">
                                                REF_{review.id.substring(0, 8)}
                                            </span>
                                        </div>
                                    </div>

                                    <div className="space-y-4">
                                        <p className="text-slate-300 font-medium text-lg leading-relaxed italic group-hover:text-white transition-colors">
                                            "{review.reviewText || 'No verbal feedback provided.'}"
                                        </p>

                                        <div className="flex flex-wrap gap-2">
                                            {review.tags?.map((tag: string) => (
                                                <Badge key={tag} className="bg-slate-800/80 text-slate-500 border-slate-700/50 font-bold px-2 py-0.5 text-[9px] uppercase tracking-wider">
                                                    <Tag size={10} className="mr-1.5 text-indigo-500" /> {tag}
                                                </Badge>
                                            ))}
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mt-8 pt-8 border-t border-slate-800/50">
                                        <div className="flex items-center gap-4 group/entity">
                                            <div className="w-12 h-12 rounded-2xl bg-slate-800 border border-slate-700 flex items-center justify-center text-indigo-400 transition-all group-hover/entity:border-indigo-500/30 group-hover/entity:bg-slate-700">
                                                <User size={20} strokeWidth={2.5} />
                                            </div>
                                            <div>
                                                <p className="text-[9px] font-black text-slate-500 uppercase tracking-[0.2em] mb-0.5">Originator</p>
                                                <p className="text-sm font-black text-slate-200 group-hover/entity:text-white transition-colors">{review.customerName || 'Anonymous User'}</p>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-4 group/entity">
                                            <div className="w-12 h-12 rounded-2xl bg-slate-800 border border-slate-700 flex items-center justify-center text-emerald-400 transition-all group-hover/entity:border-emerald-500/30 group-hover/entity:bg-slate-700">
                                                <Wrench size={20} strokeWidth={2.5} />
                                            </div>
                                            <div>
                                                <p className="text-[9px] font-black text-slate-500 uppercase tracking-[0.2em] mb-0.5">Service Agent</p>
                                                <p className="text-sm font-black text-slate-200 group-hover/entity:text-white transition-colors">{review.serviceTitle || 'General Service'}</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div className="p-6 bg-slate-950/20 md:w-64 flex flex-col justify-center items-center gap-3">
                                    <Button
                                        onClick={() => handleFlagReview(review.id)}
                                        className="w-full bg-slate-800/50 border-slate-700 text-slate-400 h-10 rounded-xl font-black uppercase text-[10px] tracking-widest hover:bg-amber-500/10 hover:text-amber-500 hover:border-amber-500/20 transition-all"
                                    >
                                        <Flag size={14} className="mr-2" /> Mark Flag
                                    </Button>
                                    <Button
                                        onClick={() => handleDeleteReview(review.id)}
                                        className="w-full bg-slate-800/50 border-slate-700 text-slate-400 h-10 rounded-xl font-black uppercase text-[10px] tracking-widest hover:bg-red-500/10 hover:text-red-500 hover:border-red-500/20 transition-all"
                                    >
                                        <Trash2 size={14} className="mr-2" /> Rescind
                                    </Button>
                                    <div className="mt-2 w-full pt-4 border-t border-slate-800/50">
                                        <div className="flex items-center justify-between text-[9px] font-black text-slate-500 uppercase tracking-widest px-1">
                                            <span>Integrity Status</span>
                                            <ShieldCheck size={12} className="text-emerald-500" />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </Card>
                    ))}
                </div>
            </div>
        </div>
    );
}
