'use client';

import { useEffect, useState, useRef } from 'react';
import { collection, onSnapshot, query } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, functions, storage } from '@/lib/firebase';
import {
    Plus, Edit3, Trash2, Tag, X, Save,
    Search, Activity, Image as ImageIcon,
    Upload, Loader2, Sparkles, Layers, ArrowRight
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardFooter } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

// Define the Service interface matching customer app
interface Service {
    id: string;
    key?: string;
    name?: string;
    title?: string; // Legacy
    price?: number;
    basePrice?: number; // Legacy
    description?: string;
    categoryId?: string;
    category?: string; // Legacy
    image?: string;
    imageUrl?: string; // Legacy
    imageAssetPath?: string; // Legacy
    order?: number;
    priority?: number; // Legacy
    isActive?: boolean;
    rating?: number;
}

export default function ServicesPage() {
    const [services, setServices] = useState<Service[]>([]);
    const [isModalOpen, setModalOpen] = useState(false);
    const [editingService, setEditingService] = useState<Service | null>(null);

    // Form state uses the "preferred" fields
    const [form, setForm] = useState({
        name: '',
        price: 0,
        description: '',
        categoryId: 'cleaning',
        image: '',
        order: 0,
        isActive: true
    });

    const [imageFile, setImageFile] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const [isSaving, setIsSaving] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const fileInputRef = useRef<HTMLInputElement>(null);

    useEffect(() => {
        const q = query(collection(db, 'services'));
        const unsub = onSnapshot(q, (snap) => {
            const data = snap.docs.map(d => ({ id: d.id, ...d.data() } as Service));
            data.sort((a, b) => {
                const orderA = a.order ?? 999;
                const orderB = b.order ?? 999;
                if (orderA !== orderB) return orderA - orderB;
                return (a.name || a.title || '').localeCompare(b.name || b.title || '');
            });
            setServices(data);
        });
        return () => unsub();
    }, []);

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
            let finalImageUrl = form.image;

            if (imageFile) {
                const storageRef = ref(storage, `services/${Date.now()}_${imageFile.name}`);
                const uploadResult = await uploadBytes(storageRef, imageFile);
                finalImageUrl = await getDownloadURL(uploadResult.ref);
            }

            const fn = httpsCallable(functions, 'admin_manageService');
            const payload = {
                name: form.name,
                price: Number(form.price),
                description: form.description,
                categoryId: form.categoryId,
                imageUrl: finalImageUrl,
                image: finalImageUrl, // Compatibility
                order: Number(form.order),
                isActive: form.isActive,
                title: form.name,
                basePrice: Number(form.price),
                category: form.categoryId
            };

            await fn({
                action: editingService ? 'update' : 'create',
                serviceId: editingService?.id,
                payload
            });

            setModalOpen(false);
            resetForm();
        } catch (e: any) {
            console.error('Operation failed', e);
            alert(`Operation failed: ${e.message}`);
        } finally {
            setIsSaving(false);
        }
    };

    const resetForm = () => {
        setEditingService(null);
        setForm({
            name: '',
            price: 0,
            description: '',
            categoryId: 'cleaning',
            image: '',
            order: 0,
            isActive: true
        });
        setImageFile(null);
        setImagePreview(null);
    };

    const handleDelete = async (id: string) => {
        if (!confirm('Are you sure you want to permanently delete this service?')) return;
        try {
            const fn = httpsCallable(functions, 'admin_manageService');
            await fn({ action: 'delete', serviceId: id });
        } catch (e: any) {
            alert(`Delete failed: ${e.message}`);
        }
    };

    const toggleVisibility = async (service: Service) => {
        try {
            const fn = httpsCallable(functions, 'admin_manageService');
            await fn({
                action: 'update',
                serviceId: service.id,
                payload: { isActive: !service.isActive }
            });
        } catch (e: any) {
            alert(`Failed to toggle visibility: ${e.message}`);
        }
    };

    const openEdit = (service: Service) => {
        setEditingService(service);
        const name = service.name || service.title || '';
        const price = service.price || service.basePrice || 0;
        const cat = service.categoryId || service.category || 'cleaning';
        const img = service.image || service.imageUrl || service.imageAssetPath || '';
        const order = service.order !== undefined ? service.order : (service.priority || 0);

        setForm({
            name,
            price,
            description: service.description || '',
            categoryId: cat,
            image: img,
            order,
            isActive: service.isActive !== false
        });
        setImagePreview(img || null);
        setModalOpen(true);
    };

    const filteredServices = services.filter(s => {
        const n = s.name || s.title || '';
        const c = s.categoryId || s.category || '';
        return n.toLowerCase().includes(searchTerm.toLowerCase()) ||
            c.toLowerCase().includes(searchTerm.toLowerCase());
    });

    return (
        <div className="space-y-8 max-w-[1400px] mx-auto">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight">Service Catalog</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <p className="text-slate-500 text-sm font-medium">Configure and organize the platform inventory.</p>
                        <div className="flex items-center gap-1.5 px-2 py-0.5 bg-indigo-500/10 text-indigo-400 rounded-md border border-indigo-500/20 text-[10px] font-black uppercase tracking-widest">
                            <Layers size={10} />
                            {services.length} Total Units
                        </div>
                    </div>
                </div>

                <div className="flex items-center gap-4">
                    <div className="relative w-full md:w-64 group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                        <Input
                            placeholder="Search catalog..."
                            className="pl-10 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                    <Button
                        onClick={() => { resetForm(); setModalOpen(true); }}
                        className="bg-white text-black hover:bg-slate-200 font-black uppercase tracking-widest text-[10px] h-12 px-6 rounded-xl shadow-xl shadow-white/5 transition-all hover:scale-105 active:scale-95 flex items-center gap-2"
                    >
                        <Plus size={18} strokeWidth={3} />
                        Add Unit
                    </Button>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {filteredServices.map((service) => {
                    const displayName = service.name || service.title || 'Untitled Service';
                    const displayPrice = service.price || service.basePrice || 0;
                    const displayImage = service.image || service.imageUrl || service.imageAssetPath;
                    const displayCat = service.categoryId || service.category || 'general';
                    const displayOrder = service.order !== undefined ? service.order : service.priority;

                    return (
                        <Card key={service.id} className={`overflow-hidden border-slate-800/50 bg-slate-900/40 backdrop-blur-sm group hover:border-slate-700 transition-all duration-500 flex flex-col ${!service.isActive ? 'opacity-50' : ''}`}>
                            <div className="relative h-56 w-full bg-slate-800 overflow-hidden">
                                {displayImage ? (
                                    <img
                                        src={displayImage}
                                        alt={displayName}
                                        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-1000 ease-out"
                                    />
                                ) : (
                                    <div className="w-full h-full flex items-center justify-center text-slate-700">
                                        <ImageIcon size={48} />
                                    </div>
                                )}

                                <div className="absolute inset-0 bg-gradient-to-t from-[#0f172a] via-transparent to-transparent opacity-60" />

                                <div className="absolute top-3 right-3 flex gap-2 translate-y-2 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-300">
                                    <Button
                                        size="icon"
                                        variant="secondary"
                                        className="h-9 w-9 bg-slate-900/80 border border-slate-700 backdrop-blur-md text-white hover:bg-indigo-500 hover:border-indigo-400 rounded-xl transition-all"
                                        onClick={() => openEdit(service)}
                                    >
                                        <Edit3 size={16} />
                                    </Button>
                                    <Button
                                        size="icon"
                                        variant="secondary"
                                        className="h-9 w-9 bg-slate-900/80 border border-slate-700 backdrop-blur-md text-red-400 hover:bg-red-500 hover:text-white hover:border-red-400 rounded-xl transition-all"
                                        onClick={() => handleDelete(service.id)}
                                    >
                                        <Trash2 size={16} />
                                    </Button>
                                </div>

                                <div className="absolute bottom-3 left-3 flex flex-col gap-1.5">
                                    <Badge className="bg-white/10 text-white border-white/20 backdrop-blur-md font-black text-[9px] uppercase tracking-[0.1em] px-2 w-fit">
                                        Unit No. {displayOrder ?? 0}
                                    </Badge>
                                </div>
                            </div>

                            <CardContent className="p-6 pt-5 flex-1 flex flex-col">
                                <div className="flex items-center justify-between mb-3 text-[10px] font-black uppercase tracking-widest">
                                    <Badge variant="outline" className="text-indigo-400 border-indigo-500/20 bg-indigo-500/5">
                                        {displayCat.replace('_', ' ')}
                                    </Badge>
                                    <span className="text-white text-lg">₹{displayPrice.toLocaleString()}</span>
                                </div>
                                <h3 className="text-xl font-black text-white mb-2 leading-tight group-hover:text-indigo-400 transition-colors">{displayName}</h3>
                                <p className="text-sm text-slate-500 line-clamp-2 leading-relaxed font-medium">
                                    {service.description || 'System documentation missing for this resource.'}
                                </p>
                            </CardContent>

                            <div className="px-6 py-4 bg-slate-900/50 border-t border-slate-800/50 flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <div className={`w-1.5 h-1.5 rounded-full ${service.isActive ? 'bg-emerald-500 animate-pulse' : 'bg-slate-600'}`} />
                                    <span className={`text-[10px] font-black uppercase tracking-widest ${service.isActive ? 'text-emerald-500' : 'text-slate-500'}`}>
                                        {service.isActive ? 'Live' : 'Hidden'}
                                    </span>
                                </div>
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    className="h-8 text-xs font-bold text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg px-2"
                                    onClick={() => toggleVisibility(service)}
                                >
                                    <Activity size={14} className="mr-1.5" /> Toggle
                                </Button>
                            </div>
                        </Card>
                    );
                })}
            </div>

            {/* Modal - Redesigned */}
            {isModalOpen && (
                <div className="fixed inset-0 bg-[#0f172a]/95 backdrop-blur-xl flex items-center justify-center z-[100] p-4 animate-in fade-in duration-300">
                    <Card className="w-full max-w-3xl bg-slate-900 border-slate-800 shadow-2xl shadow-black/50 overflow-hidden">
                        <div className="p-8 border-b border-slate-800 flex items-center justify-between bg-gradient-to-r from-slate-900 via-slate-900 to-indigo-950/20">
                            <div>
                                <h2 className="text-2xl font-black text-white tracking-tight flex items-center gap-3">
                                    {editingService ? <Edit3 className="text-indigo-500" /> : <Plus className="text-indigo-500" />}
                                    {editingService ? 'Refine Catalog Unit' : 'Initialize New Unit'}
                                </h2>
                                <p className="text-slate-500 text-sm font-medium mt-1">Configure structural parameters for the service inventory.</p>
                            </div>
                            <Button
                                variant="ghost"
                                size="icon"
                                className="text-slate-500 hover:text-white hover:bg-slate-800 rounded-xl"
                                onClick={() => setModalOpen(false)}
                            >
                                <X size={24} />
                            </Button>
                        </div>

                        <CardContent className="p-8">
                            <form onSubmit={handleSubmit} className="space-y-8">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
                                    <div className="space-y-6">
                                        <div className="space-y-2">
                                            <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1">Universal Designation</label>
                                            <Input
                                                value={form.name}
                                                onChange={e => setForm({ ...form, name: e.target.value })}
                                                placeholder="e.g. Deep Home Sanitation"
                                                className="bg-slate-800/50 border-slate-700 text-white h-12 rounded-xl focus:ring-indigo-500/50"
                                                required
                                            />
                                        </div>

                                        <div className="grid grid-cols-2 gap-4">
                                            <div className="space-y-2">
                                                <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1">Sector</label>
                                                <select
                                                    className="flex h-12 w-full rounded-xl border border-slate-700 bg-slate-800/50 px-3 py-2 text-sm text-white focus:ring-2 focus:ring-indigo-500/50 focus:outline-none appearance-none"
                                                    value={form.categoryId}
                                                    onChange={e => setForm({ ...form, categoryId: e.target.value })}
                                                >
                                                    <option value="cleaning">Cleaning</option>
                                                    <option value="plumbing">Plumbing</option>
                                                    <option value="electrician">Electrician</option>
                                                    <option value="ac_repair">AC Repair</option>
                                                    <option value="carpenter">Carpenter</option>
                                                    <option value="painting">Painting</option>
                                                </select>
                                            </div>
                                            <div className="space-y-2">
                                                <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1">Base Price (₹)</label>
                                                <Input
                                                    type="number"
                                                    value={form.price}
                                                    onChange={e => setForm({ ...form, price: Number(e.target.value) })}
                                                    className="bg-slate-800/50 border-slate-700 text-white h-12 rounded-xl"
                                                    required
                                                />
                                            </div>
                                        </div>

                                        <div className="space-y-2">
                                            <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1">Documentation</label>
                                            <textarea
                                                className="flex min-h-[100px] w-full rounded-xl border border-slate-700 bg-slate-800/50 px-4 py-3 text-sm text-white placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 resize-none transition-all font-medium"
                                                value={form.description}
                                                onChange={e => setForm({ ...form, description: e.target.value })}
                                                placeholder="Describe the unit's capabilities and scope..."
                                                rows={4}
                                            />
                                        </div>

                                        <div className="flex items-center justify-between p-5 bg-slate-950/50 rounded-2xl border border-slate-800">
                                            <div className="space-y-1">
                                                <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500">Inventory Priority</label>
                                                <Input
                                                    type="number"
                                                    className="w-24 bg-slate-800/50 border-slate-700 text-white h-10 rounded-lg text-lg font-black"
                                                    value={form.order}
                                                    onChange={e => setForm({ ...form, order: Number(e.target.value) })}
                                                />
                                            </div>
                                            <div className="flex flex-col items-end gap-1.5">
                                                <span className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 text-right">Visibility State</span>
                                                <label className="relative inline-flex items-center cursor-pointer">
                                                    <input
                                                        type="checkbox"
                                                        className="sr-only peer"
                                                        checked={form.isActive}
                                                        onChange={e => setForm({ ...form, isActive: e.target.checked })}
                                                    />
                                                    <div className="w-11 h-6 bg-slate-800 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600"></div>
                                                </label>
                                            </div>
                                        </div>
                                    </div>

                                    <div className="space-y-6 flex flex-col">
                                        <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1">Visual Asset</label>
                                        <div
                                            onClick={() => fileInputRef.current?.click()}
                                            className="relative flex-1 group aspect-square rounded-3xl border-2 border-dashed border-slate-800 flex flex-col items-center justify-center cursor-pointer hover:bg-slate-800/30 hover:border-indigo-500/50 transition-all overflow-hidden bg-slate-950/30 shadow-inner"
                                        >
                                            {imagePreview ? (
                                                <>
                                                    <img src={imagePreview} className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110" alt="Preview" />
                                                    <div className="absolute inset-0 bg-indigo-600/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white">
                                                        <div className="bg-slate-900/80 backdrop-blur-md p-4 rounded-2xl border border-white/20 scale-90 group-hover:scale-100 transition-transform duration-500">
                                                            <Upload size={32} />
                                                        </div>
                                                    </div>
                                                </>
                                            ) : (
                                                <div className="text-center p-8 space-y-4 animate-in zoom-in duration-500">
                                                    <div className="w-20 h-20 bg-slate-800/50 rounded-3xl flex items-center justify-center mx-auto mb-2 text-slate-500 border border-slate-700/50 group-hover:bg-indigo-500/10 group-hover:text-indigo-400 group-hover:border-indigo-500/20 transition-all duration-300">
                                                        <ImageIcon size={40} />
                                                    </div>
                                                    <div>
                                                        <span className="text-xs font-black text-slate-400 uppercase tracking-widest block mb-1">Select Asset</span>
                                                        <span className="text-[10px] font-bold text-slate-600 uppercase tracking-widest block">PNG, JPG up to 10MB</span>
                                                    </div>
                                                </div>
                                            )}
                                            <input
                                                type="file"
                                                ref={fileInputRef}
                                                onChange={handleImageChange}
                                                className="hidden"
                                                accept="image/*"
                                            />
                                        </div>
                                        <div className="p-4 bg-indigo-500/5 rounded-2xl border border-indigo-500/10 flex items-start gap-3">
                                            <Sparkles size={16} className="text-indigo-400 mt-0.5 flex-shrink-0" />
                                            <p className="text-[10px] font-medium text-slate-500 leading-relaxed italic">
                                                For best visual impact, use high-resolution photography with a centered subject.
                                            </p>
                                        </div>
                                    </div>
                                </div>

                                <div className="flex gap-4 pt-4">
                                    <Button
                                        type="button"
                                        variant="outline"
                                        onClick={() => setModalOpen(false)}
                                        className="flex-1 bg-transparent border-slate-800 text-slate-400 hover:text-white hover:bg-slate-800 h-14 rounded-2xl font-black uppercase tracking-widest text-[11px]"
                                    >
                                        Cancel
                                    </Button>
                                    <Button
                                        type="submit"
                                        disabled={isSaving}
                                        className="flex-[2] bg-white text-black hover:bg-slate-200 h-14 rounded-2xl font-black uppercase tracking-widest text-[11px] shadow-2xl shadow-white/10 relative overflow-hidden group"
                                    >
                                        {isSaving ? (
                                            <Loader2 className="animate-spin" size={20} />
                                        ) : (
                                            <>
                                                <Save size={18} className="mr-2" />
                                                Publish Changes
                                                <ArrowRight size={16} className="ml-2 opacity-0 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />
                                            </>
                                        )}
                                    </Button>
                                </div>
                            </form>
                        </CardContent>
                    </Card>
                </div>
            )}
        </div>
    );
}
