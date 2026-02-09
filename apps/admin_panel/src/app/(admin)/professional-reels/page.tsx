'use client';

import { useState, useEffect } from 'react';
import { db } from '@/lib/firebase';
import {
    collection, onSnapshot, addDoc, updateDoc,
    deleteDoc, doc, query, orderBy
} from 'firebase/firestore';
import {
    Plus, Trash2, Edit2, Video as VideoIcon, Check,
    X, Save, ChevronUp, ChevronDown, Eye, EyeOff,
    PlayCircle, Activity, Layout, Hash, ArrowUpRight,
    Search, Filter, MoreHorizontal
} from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Card, CardHeader, CardContent } from '@/components/ui/Card';
import Table, { Column } from '@/components/ui/Table';
import { Badge } from '@/components/ui/Badge';
import { adminApi } from '@/lib/admin-api';

interface ProfessionalReel {
    id: string;
    videoUrl: string;
    thumbnailUrl: string;
    title: string;
    isActive: boolean;
    order: number;
}

export default function ProfessionalReelsPage() {
    const [reels, setReels] = useState<ProfessionalReel[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);
    const [isAdding, setIsAdding] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);

    const [formData, setFormData] = useState<Partial<ProfessionalReel>>({
        videoUrl: '',
        thumbnailUrl: '',
        title: '',
        isActive: true,
        order: 0
    });

    useEffect(() => {
        const q = query(collection(db, 'celebrating_professionals'), orderBy('order', 'asc'));
        const unsubscribe = onSnapshot(q, (snapshot) => {
            const data = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            } as ProfessionalReel));
            setReels(data.slice(0, 5)); // Client-side enforcement as well
            setIsLoading(false);
        });

        return () => unsubscribe();
    }, []);

    const handleSave = async () => {
        setIsSaving(true);
        try {
            if (editingId) {
                await adminApi.manageProfessionalVideos({
                    action: 'update',
                    videoId: editingId,
                    videoData: formData
                });
                setEditingId(null);
            } else {
                if (reels.length >= 5) {
                    alert('Maximum 5 videos allowed. Delete one before adding more.');
                    return;
                }
                await adminApi.manageProfessionalVideos({
                    action: 'add',
                    videoData: formData
                });
                setIsAdding(false);
            }
            setFormData({ videoUrl: '', thumbnailUrl: '', title: '', isActive: true, order: 0 });
        } catch (error: any) {
            console.error('Error saving reel:', error);
            alert(`Error saving reel: ${error.message}`);
        } finally {
            setIsSaving(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (confirm('Are you sure you want to delete this reel?')) {
            try {
                await adminApi.manageProfessionalVideos({
                    action: 'delete',
                    videoId: id
                });
            } catch (error) {
                console.error('Error deleting reel:', error);
            }
        }
    };

    const toggleStatus = async (reel: ProfessionalReel) => {
        try {
            await adminApi.manageProfessionalVideos({
                action: 'update',
                videoId: reel.id,
                videoData: { isActive: !reel.isActive }
            });
        } catch (error) {
            console.error('Error toggling status:', error);
        }
    };

    const moveReel = async (index: number, direction: 'up' | 'down') => {
        const newReels = [...reels];
        const targetIndex = direction === 'up' ? index - 1 : index + 1;

        if (targetIndex < 0 || targetIndex >= reels.length) return;

        const temp = newReels[index];
        newReels[index] = newReels[targetIndex];
        newReels[targetIndex] = temp;

        try {
            const orders = newReels.map((r, i) => ({ id: r.id, order: i }));
            await adminApi.manageProfessionalVideos({
                action: 'reorder',
                orders
            });
        } catch (error: any) {
            console.error('Error reordering:', error);
            alert(`Error reordering: ${error.message}`);
        }
    };

    const columns: Column[] = [
        {
            key: 'title',
            label: 'Asset Intelligence',
            render: (r: ProfessionalReel, index: number) => (
                <div className="flex items-center gap-4">
                    <div className="w-12 h-16 rounded-xl bg-slate-800 border border-slate-700 overflow-hidden relative group/asset">
                        {r.thumbnailUrl ? (
                            <img src={r.thumbnailUrl} alt={r.title} className="w-full h-full object-cover group-hover/asset:scale-110 transition-transform duration-500" />
                        ) : (
                            <div className="w-full h-full flex items-center justify-center text-slate-600">
                                <VideoIcon size={20} />
                            </div>
                        )}
                        <div className="absolute inset-0 bg-indigo-600/20 opacity-0 group-hover/asset:opacity-100 transition-opacity flex items-center justify-center">
                            <PlayCircle size={20} className="text-white shadow-xl" />
                        </div>
                    </div>
                    <div className="flex flex-col">
                        <span className="font-black text-white text-sm tracking-tight uppercase leading-tight">{r.title || 'Untitled Operation'}</span>
                        <span className="text-[10px] font-mono font-bold text-slate-500 truncate max-w-[150px] mt-1 tracking-tighter">{r.videoUrl}</span>
                    </div>
                </div>
            )
        },
        {
            key: 'order',
            label: 'Sequence',
            render: (r: ProfessionalReel, index: number) => (
                <div className="flex items-center gap-4 bg-slate-900/50 border border-slate-800 px-3 py-1.5 rounded-xl w-fit">
                    <span className="text-[11px] font-black text-indigo-400 font-mono tracking-widest">{String(r.order).padStart(2, '0')}</span>
                    <div className="flex gap-1">
                        <button
                            onClick={() => moveReel(index, 'up')}
                            disabled={index === 0}
                            className="w-6 h-6 rounded-md hover:bg-slate-800 disabled:opacity-20 transition-all flex items-center justify-center border border-transparent hover:border-slate-700"
                        >
                            <ChevronUp size={14} className="text-slate-400" />
                        </button>
                        <button
                            onClick={() => moveReel(index, 'down')}
                            disabled={index === reels.length - 1}
                            className="w-6 h-6 rounded-md hover:bg-slate-800 disabled:opacity-20 transition-all flex items-center justify-center border border-transparent hover:border-slate-700"
                        >
                            <ChevronDown size={14} className="text-slate-400" />
                        </button>
                    </div>
                </div>
            )
        },
        {
            key: 'status',
            label: 'State',
            render: (r: ProfessionalReel, index: number) => (
                <button
                    onClick={() => toggleStatus(r)}
                    className={`flex items-center gap-2.5 px-3 py-1.5 rounded-xl border transition-all ${r.isActive
                        ? 'bg-emerald-500/5 border-emerald-500/10 text-emerald-400'
                        : 'bg-slate-800/50 border-slate-700 text-slate-500'
                        }`}
                >
                    {r.isActive ? <Eye size={12} className="stroke-[3]" /> : <EyeOff size={12} className="stroke-[3]" />}
                    <span className="text-[10px] font-black uppercase tracking-widest leading-none mt-0.5">{r.isActive ? 'Visible' : 'Inactive'}</span>
                </button>
            )
        },
        {
            key: 'actions',
            label: 'Control',
            align: 'right' as const,
            render: (r: ProfessionalReel, index: number) => (
                <div className="flex justify-end gap-2 pr-2">
                    <Button
                        size="sm"
                        variant="outline"
                        className="h-9 w-9 p-0 bg-slate-900/50 border-slate-800 text-slate-400 hover:text-indigo-400 hover:border-indigo-500/30 rounded-xl"
                        onClick={() => {
                            setEditingId(r.id);
                            setFormData({
                                videoUrl: r.videoUrl,
                                thumbnailUrl: r.thumbnailUrl,
                                title: r.title,
                                isActive: r.isActive,
                                order: r.order
                            });
                            setIsAdding(false);
                        }}
                    >
                        <Edit2 size={16} />
                    </Button>
                    <Button
                        size="sm"
                        variant="outline"
                        className="h-9 w-9 p-0 bg-slate-900/50 border-slate-800 text-slate-400 hover:text-red-400 hover:border-red-500/30 rounded-xl"
                        onClick={() => handleDelete(r.id)}
                    >
                        <Trash2 size={16} />
                    </Button>
                </div>
            )
        }
    ];

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase tracking-tighter">Content Studio</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Curate premium video reels showcasing our professional force.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Activity size={10} className="animate-pulse" />
                            {reels.filter(r => r.isActive).length} Live Assets
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-3">
                    {!isAdding && !editingId && (
                        <Button
                            onClick={() => setIsAdding(true)}
                            className="bg-indigo-600 hover:bg-indigo-500 text-white h-12 px-6 rounded-2xl font-black uppercase text-[11px] tracking-widest shadow-xl shadow-indigo-600/20"
                        >
                            <Plus size={18} className="mr-2 stroke-[3]" /> Sync New Reel
                        </Button>
                    )}
                </div>
            </div>

            {(isAdding || editingId) && (
                <Card className="border-indigo-600/20 bg-indigo-600/[0.03] backdrop-blur-md rounded-3xl overflow-hidden shadow-2xl shadow-indigo-950">
                    <CardHeader className="p-8 pb-0 flex flex-row items-center justify-between">
                        <div>
                            <h2 className="text-xl font-black text-white uppercase tracking-tight">{editingId ? 'Modify Intelligence' : 'Register New Asset'}</h2>
                            <p className="text-slate-500 text-xs font-bold mt-1">Configure asset parameters for consumer distribution.</p>
                        </div>
                        <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                                setIsAdding(false);
                                setEditingId(null);
                                setFormData({ videoUrl: '', thumbnailUrl: '', title: '', isActive: true, order: 0 });
                            }}
                            className="text-slate-500 hover:bg-slate-800"
                        >
                            <X size={20} />
                        </Button>
                    </CardHeader>
                    <CardContent className="p-8 space-y-8">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Asset Reference (MP4)</label>
                                <Input
                                    value={formData.videoUrl}
                                    onChange={(e) => setFormData({ ...formData, videoUrl: e.target.value })}
                                    className="bg-slate-900/50 border-slate-800 text-white h-12 rounded-xl focus:ring-indigo-500/50"
                                    placeholder="https://content.homefix.com/v/..."
                                />
                            </div>
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Visual Preview Thumbnail</label>
                                <Input
                                    value={formData.thumbnailUrl}
                                    onChange={(e) => setFormData({ ...formData, thumbnailUrl: e.target.value })}
                                    className="bg-slate-900/50 border-slate-800 text-white h-12 rounded-xl focus:ring-indigo-500/50"
                                    placeholder="https://content.homefix.com/t/..."
                                />
                            </div>
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Operational Label</label>
                                <Input
                                    value={formData.title}
                                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                    className="bg-slate-900/50 border-slate-800 text-white h-12 rounded-xl focus:ring-indigo-500/50"
                                    placeholder="Celebrating Expertise..."
                                />
                            </div>
                        </div>
                        <div className="flex justify-end gap-3 pt-4 border-t border-slate-800/50">
                            <Button
                                onClick={handleSave}
                                className="bg-indigo-600 hover:bg-indigo-500 text-white font-black uppercase text-[11px] tracking-[0.2em] px-10 h-12 rounded-xl shadow-lg shadow-indigo-600/20"
                            >
                                <Save size={18} className="mr-2" /> {editingId ? 'COMMIT CHANGES' : 'DEPLOY ASSET'}
                            </Button>
                        </div>
                    </CardContent>
                </Card>
            )}

            <Card className="border-slate-800 bg-slate-900/40 backdrop-blur-md overflow-hidden rounded-3xl">
                <CardContent className="p-0">
                    <Table
                        columns={columns}
                        data={reels}
                        loading={isLoading}
                        emptyMessage="Studio vault is currently empty. Initialize assets to begin curation."
                        className="[&_tr]:border-slate-800/50 [&_th]:bg-transparent [&_th]:text-slate-500 [&_th]:text-[10px] [&_th]:font-black [&_th]:uppercase [&_th]:tracking-[0.2em] [&_th]:py-6"
                    />
                </CardContent>
            </Card>
        </div>
    );
}
