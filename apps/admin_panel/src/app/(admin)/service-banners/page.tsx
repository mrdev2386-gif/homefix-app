'use client';

import { useEffect, useState, useRef } from 'react';
import { collection, onSnapshot, query, orderBy } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, storage } from '@/lib/firebase';
import {
    Plus, Edit3, Trash2, X, Save,
    Upload, Loader2, ImageIcon, GripVertical,
    Eye, EyeOff, Sparkles, Send
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { adminApi } from '@/lib/admin-api';

interface ServiceBanner {
    id: string;
    imageUrl: string;
    isActive: boolean;
    order: number;
    title: string;
    description: string;
}

export default function ServiceBannersPage() {
    const [banners, setBanners] = useState<ServiceBanner[]>([]);
    const [isModalOpen, setModalOpen] = useState(false);
    const [editingBanner, setEditingBanner] = useState<ServiceBanner | null>(null);
    const [isSaving, setIsSaving] = useState(false);
    const [imageFile, setImageFile] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const [form, setForm] = useState({
        title: '',
        description: '',
        isActive: true,
        order: 0
    });

    useEffect(() => {
        const q = query(collection(db, 'service_bottom_banners'), orderBy('order', 'asc'));
        const unsub = onSnapshot(q, (snap) => {
            const data = snap.docs.map(d => ({ id: d.id, ...d.data() } as ServiceBanner));
            setBanners(data);
        });
        return () => unsub();
    }, []);

    const resetForm = () => {
        setEditingBanner(null);
        setForm({
            title: '',
            description: '',
            isActive: true,
            order: banners.length
        });
        setImageFile(null);
        setImagePreview(null);
    };

    const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            setImageFile(file);
            const reader = new FileReader();
            reader.onloadend = () => {
                setImagePreview(reader.result as string);
            };
            reader.readAsDataURL(file);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsSaving(true);
        try {
            let imageUrl = editingBanner?.imageUrl || '';

            if (imageFile) {
                const storageRef = ref(storage, `banners/${Date.now()}_${imageFile.name}`);
                const uploadResult = await uploadBytes(storageRef, imageFile);
                imageUrl = await getDownloadURL(uploadResult.ref);
            }

            if (!imageUrl) {
                alert('Please upload an image first');
                return;
            }

            await adminApi.manageServiceBanners({
                action: editingBanner ? 'update' : 'add',
                bannerId: editingBanner?.id,
                bannerData: { ...form, imageUrl }
            });

            setModalOpen(false);
            resetForm();
        } catch (error: any) {
            alert(`Error: ${error.message}`);
        } finally {
            setIsSaving(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('Delete this banner?')) return;
        try {
            await adminApi.manageServiceBanners({ action: 'delete', bannerId: id });
        } catch (error: any) {
            alert(`Error: ${error.message}`);
        }
    };

    const toggleStatus = async (banner: ServiceBanner) => {
        try {
            await adminApi.manageServiceBanners({ action: 'update', bannerId: banner.id, bannerData: { isActive: !banner.isActive } });
        } catch (error: any) {
            alert(`Error: ${error.message}`);
        }
    };

    const moveBanner = async (index: number, direction: 'up' | 'down') => {
        const newBanners = [...banners];
        const targetIndex = direction === 'up' ? index - 1 : index + 1;
        if (targetIndex < 0 || targetIndex >= banners.length) return;

        [newBanners[index], newBanners[targetIndex]] = [newBanners[targetIndex], newBanners[index]];

        const orders = newBanners.map((b, i) => ({ id: b.id, order: i }));
        try {
            await adminApi.manageServiceBanners({ action: 'reorder', orders });
        } catch (error: any) {
            alert(`Reorder failed: ${error.message}`);
        }
    };

    return (
        <div className="space-y-8 max-w-6xl mx-auto">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight">Bottom Banners</h1>
                    <p className="text-slate-500 font-medium mt-1 uppercase tracking-widest text-[10px]">Promotional Real Estate Management</p>
                </div>
                <Button
                    onClick={() => { resetForm(); setModalOpen(true); }}
                    className="bg-white text-black hover:bg-slate-200 font-black px-8 h-12 rounded-xl flex items-center gap-2"
                >
                    <Plus size={20} /> Add Banner
                </Button>
            </div>

            <div className="grid grid-cols-1 gap-6">
                {banners.map((banner, index) => (
                    <Card key={banner.id} className={`bg-slate-900/40 border-slate-800 backdrop-blur-sm overflow-hidden group ${!banner.isActive ? 'opacity-50' : ''}`}>
                        <div className="flex flex-col md:flex-row gap-6 p-6">
                            <div className="w-full md:w-72 h-40 rounded-2xl overflow-hidden bg-slate-800 flex-shrink-0 relative">
                                <img src={banner.imageUrl} alt={banner.title} className="w-full h-full object-cover" />
                                <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                                    <Button size="sm" variant="secondary" onClick={() => {
                                        setEditingBanner(banner);
                                        setForm({
                                            title: banner.title,
                                            description: banner.description,
                                            isActive: banner.isActive,
                                            order: banner.order
                                        });
                                        setImagePreview(banner.imageUrl);
                                        setModalOpen(true);
                                    }}>Change Asset</Button>
                                </div>
                            </div>

                            <div className="flex-1 space-y-3">
                                <div className="flex items-center gap-3">
                                    <h3 className="text-2xl font-black text-white">{banner.title}</h3>
                                    <span className="px-2 py-0.5 bg-slate-800 text-slate-500 rounded text-[10px] font-bold uppercase tracking-widest">ORDER: {banner.order + 1}</span>
                                </div>
                                <p className="text-slate-400 font-medium line-clamp-2">{banner.description}</p>

                                <div className="flex items-center gap-4 pt-4">
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={() => toggleStatus(banner)}
                                        className={`rounded-lg border-slate-700 h-9 flex items-center gap-2 font-bold text-[10px] uppercase tracking-widest ${banner.isActive ? 'text-emerald-400' : 'text-slate-500'}`}
                                    >
                                        {banner.isActive ? <Eye size={14} /> : <EyeOff size={14} />}
                                        {banner.isActive ? 'Live' : 'Disabled'}
                                    </Button>
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={() => handleDelete(banner.id)}
                                        className="rounded-lg border-slate-700 h-9 flex items-center gap-2 text-red-400 hover:text-red-300 font-bold text-[10px] uppercase tracking-widest"
                                    >
                                        <Trash2 size={14} /> Delete
                                    </Button>
                                    <div className="flex gap-1 ml-auto">
                                        <Button variant="outline" size="icon" disabled={index === 0} onClick={() => moveBanner(index, 'up')} className="h-9 w-9 border-slate-700 rounded-lg"><GripVertical size={16} className="rotate-0 text-slate-500" /></Button>
                                        <Button variant="outline" size="icon" disabled={index === banners.length - 1} onClick={() => moveBanner(index, 'down')} className="h-9 w-9 border-slate-700 rounded-lg"><GripVertical size={16} className="rotate-0 text-slate-500" /></Button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </Card>
                ))}
            </div>

            {isModalOpen && (
                <div className="fixed inset-0 bg-black/90 backdrop-blur-md z-[100] flex items-center justify-center p-4">
                    <Card className="w-full max-w-xl bg-slate-900 border-slate-800">
                        <CardHeader className="flex flex-row items-center justify-between">
                            <CardTitle className="text-2xl font-black text-white uppercase tracking-tight">
                                {editingBanner ? 'Update Banner' : 'Configure New Banner'}
                            </CardTitle>
                            <Button variant="ghost" size="icon" onClick={() => setModalOpen(false)} className="text-slate-500"><X size={24} /></Button>
                        </CardHeader>
                        <CardContent className="space-y-6 pt-0">
                            <div
                                onClick={() => fileInputRef.current?.click()}
                                className="aspect-[21/9] rounded-2xl border-2 border-dashed border-slate-800 bg-slate-950/50 flex flex-col items-center justify-center cursor-pointer hover:border-indigo-500/50 transition-all overflow-hidden relative"
                            >
                                {imagePreview ? (
                                    <img src={imagePreview} alt="Preview" className="h-full w-full object-cover" />
                                ) : (
                                    <div className="text-center text-slate-600">
                                        <Upload size={40} className="mx-auto mb-2" />
                                        <span className="text-[10px] font-black uppercase tracking-widest">Select Visual Asset</span>
                                    </div>
                                )}
                                <input type="file" ref={fileInputRef} onChange={handleImageChange} className="hidden" accept="image/*" />
                            </div>

                            <div className="space-y-4">
                                <div className="space-y-1">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Banner Title</label>
                                    <Input
                                        value={form.title}
                                        onChange={e => setForm({ ...form, title: e.target.value })}
                                        className="bg-slate-800 border-slate-700 text-white h-12"
                                        placeholder="e.g. Festival Mega Sale"
                                    />
                                </div>
                                <div className="space-y-1">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Description / Subtitle</label>
                                    <Input
                                        value={form.description}
                                        onChange={e => setForm({ ...form, description: e.target.value })}
                                        className="bg-slate-800 border-slate-700 text-white h-12"
                                        placeholder="Flat 50% Off on all Deep Cleaning services"
                                    />
                                </div>
                            </div>

                            <div className="flex gap-4 pt-4">
                                <Button
                                    className="flex-1 bg-white text-black hover:bg-slate-200 h-14 font-black uppercase tracking-widest text-xs"
                                    onClick={handleSubmit}
                                    disabled={isSaving}
                                >
                                    {isSaving ? <Loader2 className="animate-spin" /> : editingBanner ? 'Apply Changes' : 'Initialize Banner'}
                                </Button>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            )}
        </div>
    );
}
