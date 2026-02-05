'use client';

import { useState, useEffect } from 'react';
import { db } from '@/lib/firebase';
import {
    collection,
    onSnapshot,
    addDoc,
    updateDoc,
    deleteDoc,
    doc,
    query,
    orderBy
} from 'firebase/firestore';
import {
    Plus,
    Trash2,
    Edit2,
    Sparkles,
    Save,
    ChevronUp,
    ChevronDown,
    Eye,
    EyeOff,
    Image as ImageIcon,
    Activity,
    Layers,
    X,
    Check
} from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import Table from '@/components/ui/Table';
import { Badge } from '@/components/ui/Badge';

interface CleaningCategory {
    id: string;
    name: string;
    iconUrl: string;
    isActive: boolean;
    order: number;
}

export default function CleaningCategoriesPage() {
    const [categories, setCategories] = useState<CleaningCategory[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isAdding, setIsAdding] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);

    // Form states
    const [formData, setFormData] = useState<Partial<CleaningCategory>>({
        name: '',
        iconUrl: '',
        isActive: true,
        order: 0
    });

    useEffect(() => {
        const q = query(collection(db, 'cleaning_categories'), orderBy('order', 'asc'));
        const unsubscribe = onSnapshot(q, (snapshot) => {
            const data = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            } as CleaningCategory));
            setCategories(data);
            setIsLoading(false);
        });

        return () => unsubscribe();
    }, []);

    const handleSave = async () => {
        if (!formData.name || !formData.iconUrl) {
            alert('Name and Icon URL are required');
            return;
        }

        try {
            if (editingId) {
                await updateDoc(doc(db, 'cleaning_categories', editingId), formData);
                setEditingId(null);
            } else {
                await addDoc(collection(db, 'cleaning_categories'), {
                    ...formData,
                    order: categories.length
                });
                setIsAdding(false);
            }
            setFormData({ name: '', iconUrl: '', isActive: true, order: 0 });
        } catch (error) {
            console.error('Error saving category:', error);
            alert('Error saving category');
        }
    };

    const handleDelete = async (id: string) => {
        if (confirm('Are you sure you want to delete this category?')) {
            try {
                await deleteDoc(doc(db, 'cleaning_categories', id));
            } catch (error) {
                console.error('Error deleting category:', error);
            }
        }
    };

    const toggleStatus = async (cat: CleaningCategory) => {
        try {
            await updateDoc(doc(db, 'cleaning_categories', cat.id), {
                isActive: !cat.isActive
            });
        } catch (error) {
            console.error('Error toggling status:', error);
        }
    };

    const moveCategory = async (index: number, direction: 'up' | 'down') => {
        const newCats = [...categories];
        const targetIndex = direction === 'up' ? index - 1 : index + 1;

        if (targetIndex < 0 || targetIndex >= categories.length) return;

        const temp = newCats[index];
        newCats[index] = newCats[targetIndex];
        newCats[targetIndex] = temp;

        try {
            for (let i = 0; i < newCats.length; i++) {
                if (newCats[i].order !== i) {
                    await updateDoc(doc(db, 'cleaning_categories', newCats[i].id), {
                        order: i
                    });
                }
            }
        } catch (error) {
            console.error('Error reordering:', error);
        }
    };

    const columns = [
        {
            key: 'preview',
            label: 'Asset',
            render: (cat: CleaningCategory) => (
                <div className="w-14 h-14 bg-slate-800 border-2 border-slate-700/50 rounded-[18px] flex items-center justify-center overflow-hidden shadow-2xl relative group/asset">
                    {cat.iconUrl ? (
                        <img src={cat.iconUrl} alt={cat.name} className="w-full h-full object-cover group-hover/asset:scale-110 transition-transform duration-500" />
                    ) : (
                        <Sparkles size={20} className="text-slate-600" />
                    )}
                    <div className="absolute inset-0 bg-indigo-600/20 opacity-0 group-hover/asset:opacity-100 transition-opacity" />
                </div>
            )
        },
        {
            key: 'name',
            label: 'Category Taxonomy',
            render: (cat: CleaningCategory) => (
                <div className="flex flex-col">
                    <span className="font-black text-white text-base tracking-tight uppercase leading-tight">{cat.name}</span>
                    <span className="text-[10px] font-mono font-bold text-slate-500 mt-1 tracking-tighter uppercase">UID: {cat.id.substring(0, 16).toUpperCase()}</span>
                </div>
            )
        },
        {
            key: 'order',
            label: 'Rank',
            render: (cat: CleaningCategory, index: number) => (
                <div className="flex items-center gap-4">
                    <div className="w-8 h-8 rounded-lg bg-slate-950/50 border border-slate-800 flex items-center justify-center text-xs font-black text-indigo-400">
                        {cat.order}
                    </div>
                    <div className="flex flex-col gap-1">
                        <button
                            onClick={() => moveCategory(index, 'up')}
                            disabled={index === 0}
                            className="p-1 hover:bg-slate-800 rounded-md disabled:opacity-20 text-slate-500 hover:text-white transition-colors"
                        >
                            <ChevronUp size={14} />
                        </button>
                        <button
                            onClick={() => moveCategory(index, 'down')}
                            disabled={index === categories.length - 1}
                            className="p-1 hover:bg-slate-800 rounded-md disabled:opacity-20 text-slate-500 hover:text-white transition-colors"
                        >
                            <ChevronDown size={14} />
                        </button>
                    </div>
                </div>
            )
        },
        {
            key: 'status',
            label: 'Deployment',
            render: (cat: CleaningCategory) => (
                <button
                    onClick={() => toggleStatus(cat)}
                    className={`flex items-center gap-2 px-4 py-1.5 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all border ${cat.isActive
                            ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 shadow-lg shadow-emerald-500/5'
                            : 'bg-slate-800/50 text-slate-500 border-slate-700'
                        }`}
                >
                    {cat.isActive ? <Eye size={12} className="fill-emerald-400/20" /> : <EyeOff size={12} />}
                    {cat.isActive ? 'Active Node' : 'Suspended'}
                </button>
            )
        },
        {
            key: 'actions',
            label: '',
            align: 'right' as const,
            render: (cat: CleaningCategory) => (
                <div className="flex justify-end gap-2 pr-4">
                    <Button
                        size="icon"
                        variant="ghost"
                        className="h-9 w-9 text-slate-500 hover:text-indigo-400 hover:bg-indigo-400/10 rounded-xl"
                        onClick={() => {
                            setEditingId(cat.id);
                            setFormData({
                                name: cat.name,
                                iconUrl: cat.iconUrl,
                                isActive: cat.isActive,
                                order: cat.order
                            });
                            setIsAdding(false);
                        }}
                    >
                        <Edit2 size={16} />
                    </Button>
                    <Button
                        size="icon"
                        variant="ghost"
                        className="h-9 w-9 text-slate-500 hover:text-rose-400 hover:bg-rose-400/10 rounded-xl"
                        onClick={() => handleDelete(cat.id)}
                    >
                        <Trash2 size={16} />
                    </Button>
                </div>
            )
        }
    ];

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto pb-20">
            <header className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight uppercase tracking-tighter">Cluster Taxonomy</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Manage specialized cleaning service categories and hierarchical ranking.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-emerald-500/10 text-emerald-400 rounded-md border border-emerald-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Layers size={10} />
                            {categories.length} Nodes Active
                        </div>
                    </div>
                </div>
                {!isAdding && !editingId && (
                    <Button
                        onClick={() => setIsAdding(true)}
                        className="bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl h-12 px-6 font-black uppercase text-[10px] tracking-widest shadow-xl shadow-indigo-600/20 border-none"
                    >
                        <Plus size={16} className="mr-2" /> Inject Category
                    </Button>
                )}
            </header>

            {(isAdding || editingId) && (
                <Card className="border-none bg-slate-900 overflow-hidden rounded-[32px] shadow-2xl shadow-indigo-900/10 ring-1 ring-white/5 animate-in fade-in slide-in-from-top-4 duration-500">
                    <CardHeader className="p-8 pb-4">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 bg-indigo-500/10 text-indigo-400 rounded-xl flex items-center justify-center border border-indigo-500/20">
                                    <Edit2 size={20} />
                                </div>
                                <h2 className="text-xl font-black text-white uppercase tracking-tight">
                                    {editingId ? 'Modify Strategy' : 'Bootstrap Category'}
                                </h2>
                            </div>
                            <Button
                                variant="ghost"
                                size="icon"
                                className="text-slate-500 hover:text-white rounded-full h-8 w-8"
                                onClick={() => {
                                    setIsAdding(false);
                                    setEditingId(null);
                                    setFormData({ name: '', iconUrl: '', isActive: true, order: 0 });
                                }}
                            >
                                <X size={20} />
                            </Button>
                        </div>
                    </CardHeader>
                    <CardContent className="p-8 pt-6">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Taxonomy Identity</label>
                                <Input
                                    value={formData.name}
                                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                    placeholder="e.g. PREMIUM_CARPET_CARE"
                                    className="bg-slate-950/50 border-slate-800 text-white rounded-2xl h-12 focus:ring-indigo-500/30 transition-all shadow-inner"
                                />
                            </div>
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Visual Asset (Icon Source)</label>
                                <Input
                                    value={formData.iconUrl}
                                    onChange={(e) => setFormData({ ...formData, iconUrl: e.target.value })}
                                    placeholder="https://cdn.platform.net/assets/icon_cluster_01.png"
                                    className="bg-slate-950/50 border-slate-800 text-white rounded-2xl h-12 focus:ring-indigo-500/30 transition-all shadow-inner"
                                />
                            </div>
                            <div className="md:col-span-2 flex justify-end gap-3 mt-4">
                                <Button
                                    variant="ghost"
                                    onClick={() => {
                                        setIsAdding(false);
                                        setEditingId(null);
                                        setFormData({ name: '', iconUrl: '', isActive: true, order: 0 });
                                    }}
                                    className="text-slate-500 font-black uppercase text-[10px] tracking-widest rounded-xl px-6"
                                >
                                    Abort
                                </Button>
                                <Button
                                    onClick={handleSave}
                                    className="bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl h-12 px-8 font-black uppercase text-[10px] tracking-widest shadow-xl shadow-indigo-600/20 border-none px-6"
                                >
                                    <Save size={16} className="mr-2" />
                                    {editingId ? 'Push Updates' : 'Commit Strategy'}
                                </Button>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            )}

            <Card className="border-slate-800/50 bg-slate-900/40 backdrop-blur-sm overflow-hidden rounded-[32px]">
                <Table
                    columns={columns}
                    data={categories}
                    loading={isLoading}
                    emptyMessage="No cluster nodes identified in database."
                />
            </Card>
        </div>
    );
}
