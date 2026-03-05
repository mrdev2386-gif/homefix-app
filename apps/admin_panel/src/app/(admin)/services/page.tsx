'use client';

import { useEffect, useState, useRef } from 'react';
import { collection, onSnapshot, query, orderBy, limit, startAfter, getDocs, QueryConstraint } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, functions, storage } from '@/lib/firebase';
import {
    Plus, Edit3, Trash2, X, Save,
    Search, Image as ImageIcon, Eye, EyeOff,
    Upload, Loader2, Sparkles, ArrowRight, ChevronLeft, ChevronRight, AlertCircle, Check
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';

// Define the Service interface with master catalog fields
interface Service {
    id: string;
    name: string;
    categoryId: string;
    price: number;
    pricingType?: 'fixed' | 'starting_from' | 'per_hour';
    durationMinutes?: number;
    description?: string;
    imageUrl?: string;
    isActive: boolean;
    isPopular?: boolean;
    createdAt?: any;
    updatedAt?: any;
    // Legacy fields for backward compatibility
    key?: string;
    title?: string;
    basePrice?: number;
    image?: string;
    category?: string;
    imageAssetPath?: string;
    order?: number;
    priority?: number;
    rating?: number;
}

// Toast notification type
interface Toast {
    id: string;
    message: string;
    type: 'success' | 'error' | 'info';
    duration?: number;
}


export default function ServicesPage() {
    const [services, setServices] = useState<Service[]>([]);
    const [filteredServices, setFilteredServices] = useState<Service[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isModalOpen, setModalOpen] = useState(false);
    const [editingService, setEditingService] = useState<Service | null>(null);
    const [searchTerm, setSearchTerm] = useState('');
    const [toasts, setToasts] = useState<Toast[]>([]);
    const [confirmDialog, setConfirmDialog] = useState<{ serviceId: string; action: string } | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    // Form state with validation
    const [form, setForm] = useState({
        name: '',
        categoryId: '',
        description: '',
        price: 0,
        pricingType: 'fixed' as const,
        durationMinutes: 0,
        imageUrl: '',
        isActive: true,
        isPopular: false
    });

    const [imageFile, setImageFile] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const [isSaving, setIsSaving] = useState(false);
    const [formErrors, setFormErrors] = useState<Record<string, string>>({});

    // Load services from Firestore with pagination and sorting
    useEffect(() => {
        setIsLoading(true);
        try {
            const constraints: QueryConstraint[] = [
                orderBy('createdAt', 'desc'),
                limit(20)
            ];
            const q = query(collection(db, 'services'), ...constraints);
            const unsub = onSnapshot(
                q,
                (snap) => {
                    const data = snap.docs.map(d => ({ id: d.id, ...d.data() } as Service));
                    setServices(data);
                    filterServices(data, searchTerm);
                    setIsLoading(false);
                },
                (error) => {
                    console.error('Failed to load services:', error);
                    showToast('Failed to load services', 'error');
                    setIsLoading(false);
                }
            );
            return () => unsub();
        } catch (error) {
            console.error('Error setting up listener:', error);
            showToast('Error loading services', 'error');
            setIsLoading(false);
        }
    }, []);

    // Filter services based on search term
    const filterServices = (serviceList: Service[], term: string) => {
        const filtered = serviceList.filter(s => {
            const name = s.name.toLowerCase();
            const category = s.categoryId.toLowerCase();
            const search = term.toLowerCase();
            return name.includes(search) || category.includes(search);
        });
        setFilteredServices(filtered);
    };

    const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const term = e.target.value;
        setSearchTerm(term);
        filterServices(services, term);
    };

    // Toast notification system
    const showToast = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
        const id = Date.now().toString();
        setToasts(prev => [...prev, { id, message, type }]);
        setTimeout(() => {
            setToasts(prev => prev.filter(t => t.id !== id));
        }, 4000);
    };

    // Validation
    const validateForm = (): boolean => {
        const errors: Record<string, string> = {};

        if (!form.name.trim()) {
            errors.name = 'Service name is required';
        }
        if (!form.categoryId) {
            errors.categoryId = 'Category is required';
        }
        if (form.price < 0) {
            errors.price = 'Price cannot be negative';
        }
        if (form.durationMinutes && form.durationMinutes <= 0) {
            errors.durationMinutes = 'Duration must be greater than 0';
        }

        setFormErrors(errors);
        return Object.keys(errors).length === 0;
    };

    // Image handling
    const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            if (file.size > 10 * 1024 * 1024) {
                showToast('Image size must be less than 10MB', 'error');
                return;
            }
            setImageFile(file);
            const reader = new FileReader();
            reader.onloadend = () => {
                setImagePreview(reader.result as string);
            };
            reader.readAsDataURL(file);
        }
    };

    // Form submission
    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!validateForm()) {
            showToast('Please fix the errors in the form', 'error');
            return;
        }

        setIsSaving(true);
        try {
            let finalImageUrl = form.imageUrl;

            // Upload image if new file selected
            if (imageFile) {
                const storageRef = ref(storage, `services/${Date.now()}_${imageFile.name}`);
                const uploadResult = await uploadBytes(storageRef, imageFile);
                finalImageUrl = await getDownloadURL(uploadResult.ref);
            }

            const fn = httpsCallable(functions, 'admin_manageService');
            const payload = {
                name: form.name.trim(),
                categoryId: form.categoryId,
                price: Number(form.price),
                pricingType: form.pricingType,
                durationMinutes: form.durationMinutes ? Number(form.durationMinutes) : undefined,
                description: form.description.trim(),
                imageUrl: finalImageUrl,
                isActive: form.isActive,
                isPopular: form.isPopular
            };

            const result = await fn({
                action: editingService ? 'update' : 'create',
                serviceId: editingService?.id,
                payload
            });

            showToast(
                editingService ? 'Service updated successfully' : 'Service created successfully',
                'success'
            );

            setModalOpen(false);
            resetForm();
        } catch (error: any) {
            console.error('Operation failed:', error);
            showToast(`Operation failed: ${error.message}`, 'error');
        } finally {
            setIsSaving(false);
        }
    };

    // Soft delete (disable service)
    const handleDisable = async (serviceId: string) => {
        try {
            const fn = httpsCallable(functions, 'admin_manageService');
            await fn({
                action: 'update',
                serviceId,
                payload: { isActive: false }
            });
            showToast('Service disabled successfully', 'success');
            setConfirmDialog(null);
        } catch (error: any) {
            showToast(`Failed to disable service: ${error.message}`, 'error');
        }
    };

    // Enable service
    const handleEnable = async (serviceId: string) => {
        try {
            const fn = httpsCallable(functions, 'admin_manageService');
            await fn({
                action: 'update',
                serviceId,
                payload: { isActive: true }
            });
            showToast('Service enabled successfully', 'success');
        } catch (error: any) {
            showToast(`Failed to enable service: ${error.message}`, 'error');
        }
    };

    // Open edit modal
    const openEdit = (service: Service) => {
        setEditingService(service);
        setForm({
            name: service.name,
            categoryId: service.categoryId,
            description: service.description || '',
            price: service.price || 0,
            pricingType: service.pricingType || 'fixed',
            durationMinutes: service.durationMinutes || 0,
            imageUrl: service.imageUrl || '',
            isActive: service.isActive !== false,
            isPopular: service.isPopular || false
        });
        setImagePreview(service.imageUrl || null);
        setFormErrors({});
        setModalOpen(true);
    };

    // Reset form
    const resetForm = () => {
        setEditingService(null);
        setForm({
            name: '',
            categoryId: '',
            description: '',
            price: 0,
            pricingType: 'fixed',
            durationMinutes: 0,
            imageUrl: '',
            isActive: true,
            isPopular: false
        });
        setImageFile(null);
        setImagePreview(null);
        setFormErrors({});
    };

    // Category options
    const categories = [
        { value: 'cleaning', label: 'Cleaning' },
        { value: 'plumbing', label: 'Plumbing' },
        { value: 'electrician', label: 'Electrician' },
        { value: 'ac_repair', label: 'AC Repair' },
        { value: 'carpenter', label: 'Carpenter' },
        { value: 'painting', label: 'Painting' }
    ];

    const getCategoryLabel = (categoryId: string) => {
        return categories.find(c => c.value === categoryId)?.label || categoryId;
    };

    return (
        <div className="space-y-8 max-w-full">
            {/* Header */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-black text-white tracking-tight leading-tight">Services Master Catalog</h1>
                    <p className="text-slate-500 text-sm font-medium mt-2">Manage the complete service inventory across all categories.</p>
                </div>

                <Button
                    onClick={() => { resetForm(); setModalOpen(true); }}
                    className="bg-white text-black hover:bg-slate-200 font-black uppercase tracking-widest text-[10px] h-12 px-6 rounded-xl shadow-xl shadow-white/5 transition-all hover:scale-105 active:scale-95 flex items-center gap-2 w-fit"
                >
                    <Plus size={18} strokeWidth={3} />
                    Add Service
                </Button>
            </div>

            {/* Search Bar */}
            <div className="relative w-full group">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 h-4 w-4 group-focus-within:text-indigo-400 transition-colors" />
                <Input
                    placeholder="Search by service name or category..."
                    className="pl-12 bg-slate-900/50 border-slate-800 text-slate-200 placeholder:text-slate-600 rounded-xl h-12 focus:ring-indigo-500/50 w-full"
                    value={searchTerm}
                    onChange={handleSearchChange}
                />
            </div>

            {/* Services Table */}
            <Card className="border-slate-800/50 bg-slate-900/40 backdrop-blur-sm overflow-hidden">
                <div className="overflow-x-auto">
                    {isLoading ? (
                        <div className="p-12 flex items-center justify-center">
                            <Loader2 className="animate-spin text-indigo-400" size={32} />
                        </div>
                    ) : filteredServices.length === 0 ? (
                        <div className="p-12 flex flex-col items-center justify-center text-center">
                            <AlertCircle className="text-slate-600 mb-4" size={48} />
                            <h3 className="text-xl font-bold text-slate-300 mb-2">No Services Found</h3>
                            <p className="text-slate-500 mb-6">
                                {services.length === 0 ? 'Create your first service to get started.' : 'No services match your search.'}
                            </p>
                        </div>
                    ) : (
                        <table className="w-full">
                            <thead>
                                <tr className="border-b border-slate-800/50 bg-slate-950/50">
                                    <th className="px-6 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-[0.2em]">Service</th>
                                    <th className="px-6 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-[0.2em]">Category</th>
                                    <th className="px-6 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-[0.2em]">Pricing</th>
                                    <th className="px-6 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-[0.2em]">Duration</th>
                                    <th className="px-6 py-4 text-center text-[10px] font-bold text-slate-500 uppercase tracking-[0.2em]">Status</th>
                                    <th className="px-6 py-4 text-right text-[10px] font-bold text-slate-500 uppercase tracking-[0.2em]">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredServices.map((service, idx) => (
                                    <tr
                                        key={service.id}
                                        className={`border-b border-slate-800/30 hover:bg-slate-800/30 transition-colors ${!service.isActive ? 'opacity-60' : ''}`}
                                    >
                                        {/* Service Column */}
                                        <td className="px-6 py-4">
                                            <div className="flex items-center gap-4">
                                                <div className="w-12 h-12 bg-slate-800 rounded-lg overflow-hidden flex-shrink-0">
                                                    {service.imageUrl ? (
                                                        <img
                                                            src={service.imageUrl}
                                                            alt={service.name}
                                                            className="w-full h-full object-cover"
                                                        />
                                                    ) : (
                                                        <div className="w-full h-full flex items-center justify-center text-slate-600">
                                                            <ImageIcon size={20} />
                                                        </div>
                                                    )}
                                                </div>
                                                <div>
                                                    <p className="font-bold text-white">{service.name}</p>
                                                    <p className="text-xs text-slate-500 mt-1">{service.id}</p>
                                                </div>
                                            </div>
                                        </td>

                                        {/* Category Column */}
                                        <td className="px-6 py-4">
                                            <Badge variant="outline" className="text-indigo-400 border-indigo-500/20 bg-indigo-500/5">
                                                {getCategoryLabel(service.categoryId)}
                                            </Badge>
                                        </td>

                                        {/* Pricing Column */}
                                        <td className="px-6 py-4">
                                            <div className="flex items-center gap-2">
                                                <span className="font-bold text-white">₹{service.price.toLocaleString()}</span>
                                                {service.pricingType && (
                                                    <Badge className="text-[8px] bg-slate-800 text-slate-300 border-0">
                                                        {service.pricingType.replace('_', ' ')}
                                                    </Badge>
                                                )}
                                            </div>
                                        </td>

                                        {/* Duration Column */}
                                        <td className="px-6 py-4">
                                            <span className="text-slate-300">
                                                {service.durationMinutes ? `${service.durationMinutes} mins` : '—'}
                                            </span>
                                        </td>

                                        {/* Status Column */}
                                        <td className="px-6 py-4 text-center">
                                            {service.isActive ? (
                                                <Badge className="bg-emerald-500/10 text-emerald-400 border-emerald-500/20 flex items-center gap-1.5 w-fit mx-auto">
                                                    <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                                                    Active
                                                </Badge>
                                            ) : (
                                                <Badge className="bg-red-500/10 text-red-400 border-red-500/20 flex items-center gap-1.5 w-fit mx-auto">
                                                    <div className="w-1.5 h-1.5 rounded-full bg-red-400" />
                                                    Inactive
                                                </Badge>
                                            )}
                                        </td>

                                        {/* Actions Column */}
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex items-center justify-end gap-2">
                                                <Button
                                                    size="icon"
                                                    variant="ghost"
                                                    className="h-9 w-9 text-slate-400 hover:text-indigo-400 hover:bg-indigo-500/10 rounded-lg"
                                                    onClick={() => openEdit(service)}
                                                    title="Edit"
                                                >
                                                    <Edit3 size={16} />
                                                </Button>

                                                {service.isActive ? (
                                                    <Button
                                                        size="icon"
                                                        variant="ghost"
                                                        className="h-9 w-9 text-slate-400 hover:text-red-400 hover:bg-red-500/10 rounded-lg"
                                                        onClick={() => setConfirmDialog({ serviceId: service.id, action: 'disable' })}
                                                        title="Disable"
                                                    >
                                                        <EyeOff size={16} />
                                                    </Button>
                                                ) : (
                                                    <Button
                                                        size="icon"
                                                        variant="ghost"
                                                        className="h-9 w-9 text-slate-400 hover:text-emerald-400 hover:bg-emerald-500/10 rounded-lg"
                                                        onClick={() => handleEnable(service.id)}
                                                        title="Enable"
                                                    >
                                                        <Eye size={16} />
                                                    </Button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    )}
                </div>

                {/* Pagination info */}
                {filteredServices.length > 0 && (
                    <div className="px-6 py-4 border-t border-slate-800/50 bg-slate-950/30 flex items-center justify-between text-xs text-slate-500">
                        <span>Showing {filteredServices.length} of {services.length} services</span>
                        <span>Sorted by newest first</span>
                    </div>
                )}
            </Card>

            {/* Create/Edit Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 bg-[#0f172a]/95 backdrop-blur-xl flex items-center justify-center z-[100] p-4 animate-in fade-in duration-300 overflow-y-auto">
                    <Card className="w-full max-w-3xl bg-slate-900 border-slate-800 shadow-2xl shadow-black/50 overflow-hidden my-8">
                        <div className="p-8 border-b border-slate-800 flex items-center justify-between bg-gradient-to-r from-slate-900 via-slate-900 to-indigo-950/20">
                            <div>
                                <h2 className="text-2xl font-black text-white tracking-tight flex items-center gap-3">
                                    {editingService ? <Edit3 className="text-indigo-500" size={24} /> : <Plus className="text-indigo-500" size={24} />}
                                    {editingService ? 'Edit Service' : 'Create New Service'}
                                </h2>
                                <p className="text-slate-500 text-sm font-medium mt-1">
                                    {editingService ? 'Update service details in the master catalog.' : 'Add a new service to the master catalog.'}
                                </p>
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
                                    {/* Left Column - Form Fields */}
                                    <div className="space-y-6">
                                        {/* Service Name */}
                                        <div className="space-y-2">
                                            <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1 flex items-center gap-1">
                                                Service Name
                                                <span className="text-red-400">*</span>
                                            </label>
                                            <Input
                                                value={form.name}
                                                onChange={e => {
                                                    setForm({ ...form, name: e.target.value });
                                                    if (formErrors.name) {
                                                        setFormErrors(prev => {
                                                            const { name, ...rest } = prev;
                                                            return rest;
                                                        });
                                                    }
                                                }}
                                                placeholder="e.g., Deep Home Cleaning"
                                                className={`bg-slate-800/50 border-slate-700 text-white h-12 rounded-xl focus:ring-indigo-500/50 ${formErrors.name ? 'border-red-500/50' : ''}`}
                                            />
                                            {formErrors.name && <p className="text-xs text-red-400 ml-1">{formErrors.name}</p>}
                                        </div>

                                        {/* Category */}
                                        <div className="space-y-2">
                                            <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1 flex items-center gap-1">
                                                Category
                                                <span className="text-red-400">*</span>
                                            </label>
                                            <select
                                                className={`flex h-12 w-full rounded-xl border bg-slate-800/50 px-4 py-2 text-sm text-white focus:ring-2 focus:ring-indigo-500/50 focus:outline-none appearance-none ${formErrors.categoryId ? 'border-red-500/50' : 'border-slate-700'}`}
                                                value={form.categoryId}
                                                onChange={e => {
                                                    setForm({ ...form, categoryId: e.target.value });
                                                    if (formErrors.categoryId) {
                                                        setFormErrors(prev => {
                                                            const { categoryId, ...rest } = prev;
                                                            return rest;
                                                        });
                                                    }
                                                }}
                                            >
                                                <option value="">Select a category</option>
                                                {categories.map(cat => (
                                                    <option key={cat.value} value={cat.value}>{cat.label}</option>
                                                ))}
                                            </select>
                                            {formErrors.categoryId && <p className="text-xs text-red-400 ml-1">{formErrors.categoryId}</p>}
                                        </div>

                                        {/* Price */}
                                        <div className="grid grid-cols-3 gap-3">
                                            <div className="col-span-2 space-y-2">
                                                <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1">Price (₹)</label>
                                                <Input
                                                    type="number"
                                                    value={form.price}
                                                    onChange={e => {
                                                        setForm({ ...form, price: Number(e.target.value) });
                                                        if (formErrors.price) {
                                                            setFormErrors(prev => {
                                                                const { price, ...rest } = prev;
                                                                return rest;
                                                            });
                                                        }
                                                    }}
                                                    step="0.01"
                                                    min="0"
                                                    className={`bg-slate-800/50 border-slate-700 text-white h-12 rounded-xl ${formErrors.price ? 'border-red-500/50' : ''}`}
                                                />
                                                {formErrors.price && <p className="text-xs text-red-400 ml-1">{formErrors.price}</p>}
                                            </div>
                                            <div className="space-y-2">
                                                <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1">Type</label>
                                                <select
                                                    className="flex h-12 w-full rounded-xl border border-slate-700 bg-slate-800/50 px-2 py-2 text-xs text-white focus:ring-2 focus:ring-indigo-500/50 focus:outline-none appearance-none"
                                                    value={form.pricingType}
                                                    onChange={e => setForm({ ...form, pricingType: e.target.value as any })}
                                                >
                                                    <option value="fixed">Fixed</option>
                                                    <option value="starting_from">Starting From</option>
                                                    <option value="per_hour">Per Hour</option>
                                                </select>
                                            </div>
                                        </div>

                                        {/* Duration */}
                                        <div className="space-y-2">
                                            <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1">Duration (minutes)</label>
                                            <Input
                                                type="number"
                                                value={form.durationMinutes || ''}
                                                onChange={e => {
                                                    setForm({ ...form, durationMinutes: e.target.value ? Number(e.target.value) : 0 });
                                                    if (formErrors.durationMinutes) {
                                                        setFormErrors(prev => {
                                                            const { durationMinutes, ...rest } = prev;
                                                            return rest;
                                                        });
                                                    }
                                                }}
                                                placeholder="Optional"
                                                min="0"
                                                className={`bg-slate-800/50 border-slate-700 text-white h-12 rounded-xl ${formErrors.durationMinutes ? 'border-red-500/50' : ''}`}
                                            />
                                            {formErrors.durationMinutes && <p className="text-xs text-red-400 ml-1">{formErrors.durationMinutes}</p>}
                                        </div>

                                        {/* Description */}
                                        <div className="space-y-2">
                                            <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1">Description</label>
                                            <textarea
                                                className="flex min-h-[80px] w-full rounded-xl border border-slate-700 bg-slate-800/50 px-4 py-3 text-sm text-white placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 resize-none transition-all font-medium"
                                                value={form.description}
                                                onChange={e => setForm({ ...form, description: e.target.value })}
                                                placeholder="Describe this service..."
                                                rows={3}
                                            />
                                        </div>

                                        {/* Toggles */}
                                        <div className="space-y-3 p-4 bg-slate-950/50 rounded-2xl border border-slate-800">
                                            <div className="flex items-center justify-between">
                                                <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500">Active</label>
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
                                            <div className="flex items-center justify-between">
                                                <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500">Popular</label>
                                                <label className="relative inline-flex items-center cursor-pointer">
                                                    <input
                                                        type="checkbox"
                                                        className="sr-only peer"
                                                        checked={form.isPopular}
                                                        onChange={e => setForm({ ...form, isPopular: e.target.checked })}
                                                    />
                                                    <div className="w-11 h-6 bg-slate-800 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600"></div>
                                                </label>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Right Column - Image Upload */}
                                    <div className="space-y-6 flex flex-col">
                                        <label className="text-[10px] uppercase tracking-[0.2em] font-black text-slate-500 ml-1">Service Image</label>
                                        <div
                                            onClick={() => fileInputRef.current?.click()}
                                            className="relative flex-1 group rounded-3xl border-2 border-dashed border-slate-800 flex flex-col items-center justify-center cursor-pointer hover:bg-slate-800/30 hover:border-indigo-500/50 transition-all overflow-hidden bg-slate-950/30 shadow-inner min-h-[250px]"
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
                                                    <div className="w-20 h-20 bg-slate-800/50 rounded-3xl flex items-center justify-center mx-auto text-slate-500 border border-slate-700/50 group-hover:bg-indigo-500/10 group-hover:text-indigo-400 group-hover:border-indigo-500/20 transition-all duration-300">
                                                        <ImageIcon size={40} />
                                                    </div>
                                                    <div>
                                                        <span className="text-xs font-black text-slate-400 uppercase tracking-widest block mb-1">Upload Image</span>
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
                                    </div>
                                </div>

                                {/* Action Buttons */}
                                <div className="flex gap-4 pt-4 border-t border-slate-800">
                                    <Button
                                        type="button"
                                        variant="outline"
                                        onClick={() => setModalOpen(false)}
                                        className="flex-1 bg-transparent border-slate-800 text-slate-400 hover:text-white hover:bg-slate-800 h-12 rounded-xl font-black uppercase tracking-widest text-[10px]"
                                    >
                                        Cancel
                                    </Button>
                                    <Button
                                        type="submit"
                                        disabled={isSaving}
                                        className="flex-[2] bg-white text-black hover:bg-slate-200 h-12 rounded-xl font-black uppercase tracking-widest text-[10px] shadow-2xl shadow-white/10 relative overflow-hidden group"
                                    >
                                        {isSaving ? (
                                            <Loader2 className="animate-spin" size={18} />
                                        ) : (
                                            <>
                                                <Save size={16} className="mr-2" />
                                                {editingService ? 'Update Service' : 'Create Service'}
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

            {/* Confirm Dialog */}
            {confirmDialog && (
                <div className="fixed inset-0 bg-[#0f172a]/95 backdrop-blur-xl flex items-center justify-center z-[110] p-4 animate-in fade-in duration-300">
                    <Card className="w-full max-w-md bg-slate-900 border-slate-800 shadow-2xl shadow-black/50">
                        <CardContent className="p-8">
                            <div className="space-y-6">
                                <div className="flex items-center justify-center w-12 h-12 rounded-full bg-red-500/10 border border-red-500/20 mx-auto">
                                    <AlertCircle className="text-red-400" size={24} />
                                </div>
                                <div className="text-center space-y-2">
                                    <h3 className="text-xl font-black text-white">Disable Service?</h3>
                                    <p className="text-slate-500 text-sm">
                                        This service will be hidden from customers but can be re-enabled later.
                                    </p>
                                </div>
                                <div className="flex gap-3 pt-2">
                                    <Button
                                        variant="outline"
                                        onClick={() => setConfirmDialog(null)}
                                        className="flex-1 bg-transparent border-slate-800 text-slate-400 hover:text-white hover:bg-slate-800 h-11 rounded-xl font-bold text-sm"
                                    >
                                        Cancel
                                    </Button>
                                    <Button
                                        onClick={() => handleDisable(confirmDialog.serviceId)}
                                        className="flex-1 bg-red-600 text-white hover:bg-red-700 h-11 rounded-xl font-bold text-sm"
                                    >
                                        Disable
                                    </Button>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            )}

            {/* Toast Notifications */}
            <div className="fixed bottom-6 right-6 z-[1000] space-y-3 pointer-events-none">
                {toasts.map(toast => {
                    const bgColor = toast.type === 'success' ? 'bg-emerald-600' :
                        toast.type === 'error' ? 'bg-red-600' : 'bg-blue-600';
                    const Icon = toast.type === 'success' ? Check : AlertCircle;

                    return (
                        <div
                            key={toast.id}
                            className={`${bgColor} text-white px-6 py-4 rounded-xl shadow-2xl flex items-center gap-3 animate-in slide-in-from-right duration-300 pointer-events-auto`}
                        >
                            <Icon size={18} />
                            <span className="font-bold text-sm">{toast.message}</span>
                        </div>
                    );
                })}
            </div>
        </div>
    );
}
