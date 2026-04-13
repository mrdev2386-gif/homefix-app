'use client';

import { useState, useEffect } from 'react';
import { PageHeader, DataTable, StatusBadge, Column, ConfirmDialog, StatCard, Modal } from '@/components/ui';
import { Eye, CheckCircle, XCircle, Ban, Trash2, Package, Clock, AlertTriangle, Search, X, Check, Ban as BanIcon } from 'lucide-react';
import { db } from '@/lib/firebase';
import { functions } from '@/lib/firebaseClient';
import { collection, query, getDocs, orderBy, Timestamp } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';

type ModerationStatus = 'pending' | 'active' | 'rejected' | 'disabled';

interface TechnicianService {
  id: string;
  technicianId: string;
  technicianName?: string;
  technicianPhone?: string;
  technicianRating?: number;
  serviceId: string;
  serviceName?: string;
  subServiceId: string;
  subServiceName?: string;
  categoryId: string;
  categoryName?: string;
  title: string;
  description?: string;
  price: number;
  imageUrl?: string;
  city?: string;
  district?: string;
  status: ModerationStatus;
  createdAt: any;
}

export default function TechnicianServicesPage() {
  const [services, setServices] = useState<TechnicianService[]>([]);
  const [filteredServices, setFilteredServices] = useState<TechnicianService[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedService, setSelectedService] = useState<TechnicianService | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [toast, setToast] = useState<{ show: boolean; message: string; type: 'success' | 'error' }>({ show: false, message: '', type: 'success' });
  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    action: string;
    serviceId: string;
    onConfirm: () => void;
    variant?: 'default' | 'danger';
  }>({ isOpen: false, title: '', message: '', action: '', serviceId: '', onConfirm: () => {} });
  
  // Filters
  const [statusFilter, setStatusFilter] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [searchTitle, setSearchTitle] = useState('');
  const [searchTechnician, setSearchTechnician] = useState('');

  useEffect(() => {
    fetchServices();
  }, []);

  useEffect(() => {
    applyFilters();
  }, [services, statusFilter, categoryFilter, searchTitle, searchTechnician]);

  // Toast notification
  useEffect(() => {
    if (toast.show) {
      const timer = setTimeout(() => setToast({ ...toast, show: false }), 3000);
      return () => clearTimeout(timer);
    }
  }, [toast.show]);

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ show: true, message, type });
  };

  const fetchServices = async () => {
    try {
      setLoading(true);
      
      // 🔍 STEP 1: FIRESTORE DATA CHECK
      console.log('🔍 STEP 1: FIRESTORE DATA CHECK');
      console.log('Firebase project connected:', db ? 'YES' : 'NO');
      console.log('Database instance:', db);
      
      // 🔍 STEP 2: FIRESTORE QUERY VALIDATION
      console.log('🔍 STEP 2: FIRESTORE QUERY VALIDATION');
      console.log('Starting to fetch services from technician_services collection...');
      
      const servicesQuery = query(
        collection(db, "technician_services"),
        orderBy("createdAt", "desc")
      );
      
      console.log('Query created successfully:', servicesQuery);
      
      const snapshot = await getDocs(servicesQuery);
      console.log('Query snapshot:', snapshot.size);
      console.log('Raw snapshot docs:', snapshot.docs.length);
      
      if (snapshot.empty) {
        console.error('❌ CRITICAL: No documents found in technician_services collection!');
        console.log('Checking if collection exists by trying to read without orderBy...');
        
        // Try without orderBy to see if documents exist
        const basicQuery = collection(db, "technician_services");
        const basicSnapshot = await getDocs(basicQuery);
        console.log('Basic query (no orderBy) results:', basicSnapshot.size);
        
        if (basicSnapshot.empty) {
          console.error('❌ Collection is completely empty or does not exist');
          showToast('No technician services found in database', 'error');
          return;
        } else {
          console.error('❌ Documents exist but orderBy query failed - likely missing Firestore index');
          showToast('Database index required for sorting. Check console for details.', 'error');
          
          // Process documents without ordering
          const servicesData = basicSnapshot.docs.map(doc => {
            const data = doc.data();
            console.log('🔍 STEP 3: CREATEDAT FIELD TYPE CHECK');
            console.log('Document ID:', doc.id);
            console.log('Document data:', data);
            console.log('createdAt field:', data.createdAt);
            console.log('createdAt type:', typeof data.createdAt);
            console.log('Is Timestamp?', data.createdAt?.toDate ? 'YES' : 'NO');
            
            return {
              id: doc.id,
              technicianId: data.technicianId || 'MISSING',
              technicianName: data.technicianName || 'Unknown',
              title: data.title || 'Untitled Service',
              price: data.price || 0,
              status: data.status || 'pending',
              createdAt: data.createdAt ?? Timestamp.now(),
              // Include all other fields
              technicianPhone: data.technicianPhone,
              technicianRating: data.technicianRating,
              serviceId: data.serviceId,
              serviceName: data.serviceName,
              subServiceId: data.subServiceId,
              subServiceName: data.subServiceName,
              categoryId: data.categoryId,
              categoryName: data.categoryName,
              description: data.description,
              imageUrl: data.imageUrl,
              city: data.city,
              district: data.district,
            } as TechnicianService;
          });
          
          console.log("✅ Loaded services (without ordering):", servicesData);
          setServices(servicesData);
          return;
        }
      }
      
      // 🔍 STEP 3: CREATEDAT FIELD TYPE CHECK
      console.log('🔍 STEP 3: CREATEDAT FIELD TYPE CHECK');
      
      // Fetch related data for enrichment
      console.log('Fetching related collections...');
      const [techniciansSnap, categoriesSnap, servicesSnap] = await Promise.all([
        getDocs(collection(db, 'technicians')),
        getDocs(collection(db, 'categories')),
        getDocs(collection(db, 'services'))
      ]);
      
      console.log('Related collections loaded:');
      console.log('- Technicians:', techniciansSnap.size);
      console.log('- Categories:', categoriesSnap.size);
      console.log('- Services:', servicesSnap.size);
      
      const techniciansMap = new Map(techniciansSnap.docs.map(d => [d.id, d.data()]));
      const categoriesMap = new Map(categoriesSnap.docs.map(d => [d.id, d.data()]));
      const servicesMap = new Map(servicesSnap.docs.map(d => [d.id, d.data()]));
      
      const servicesData = snapshot.docs.map(doc => {
        const data = doc.data();
        console.log('Processing service document:');
        console.log('- ID:', doc.id);
        console.log('- Raw data:', data);
        console.log('- createdAt:', data.createdAt, typeof data.createdAt);
        console.log('- Required fields check:');
        console.log('  * title:', data.title ? '✅' : '❌');
        console.log('  * technicianId:', data.technicianId ? '✅' : '❌');
        console.log('  * price:', data.price !== undefined ? '✅' : '❌');
        console.log('  * status:', data.status ? '✅' : '❌');
        console.log('  * createdAt:', data.createdAt ? '✅' : '❌');
        
        const technician = techniciansMap.get(data.technicianId);
        const category = categoriesMap.get(data.categoryId);
        const service = servicesMap.get(data.serviceId);
        
        // Find sub-service from service's subServices array
        let subServiceName = data.subServiceId;
        if (service?.subServices) {
          const subService = service.subServices.find((s: any) => s.id === data.subServiceId);
          if (subService) subServiceName = subService.name;
        }
        
        const processedService = { 
          id: doc.id,
          technicianId: data.technicianId,
          technicianName: technician?.name || data.technicianName,
          technicianPhone: technician?.phone || data.technicianPhone,
          technicianRating: technician?.rating || data.technicianRating,
          serviceId: data.serviceId,
          serviceName: service?.name || data.serviceName,
          subServiceId: data.subServiceId,
          subServiceName: subServiceName || data.subServiceName,
          categoryId: data.categoryId,
          categoryName: category?.name || data.categoryName,
          title: data.title,
          description: data.description,
          price: data.price,
          imageUrl: data.imageUrl,
          city: data.city,
          district: data.district,
          status: data.status || 'pending',
          createdAt: data.createdAt ?? Timestamp.now()
        };
        
        console.log('- Processed service:', processedService);
        return processedService;
      }) as TechnicianService[];
      
      console.log("✅ FINAL LOADED SERVICES:", servicesData);
      console.log("Services by status:", {
        pending: servicesData.filter(s => s.status === 'pending').length,
        active: servicesData.filter(s => s.status === 'active').length,
        rejected: servicesData.filter(s => s.status === 'rejected').length,
        disabled: servicesData.filter(s => s.status === 'disabled').length,
        total: servicesData.length
      });
      
      setServices(servicesData);
      
    } catch (error: any) {
      console.error('❌ ERROR FETCHING SERVICES:', error);
      console.error('Error code:', error.code);
      console.error('Error message:', error.message);
      console.error('Full error:', error);
      
      // 🔍 STEP 6: FIRESTORE INDEX CHECK
      if (error.code === 'failed-precondition' && error.message.includes('index')) {
        console.error('🔍 STEP 6: FIRESTORE INDEX MISSING');
        console.error('Firestore index required for orderBy("createdAt")');
        console.error('Collection: technician_services');
        console.error('Fields: createdAt (Descending)');
        console.error('Create index at: https://console.firebase.google.com/project/homefix-aa42d/firestore/indexes');
        showToast('Database index required. Please check console for details.', 'error');
      } else if (error.code === 'permission-denied') {
        console.error('🔍 STEP 5: SECURITY RULES CHECK - PERMISSION DENIED');
        console.error('Admin panel cannot read technician_services collection');
        console.error('Check Firestore security rules');
        showToast('Permission denied. Check Firestore security rules.', 'error');
      } else {
        showToast('Failed to load services. Please try again.', 'error');
      }
    } finally {
      setLoading(false);
    }
  };

  // 🔍 STEP 7: FILTER LOGIC INSPECTION
  const applyFilters = () => {
    console.log('🔍 STEP 7: FILTER LOGIC INSPECTION');
    console.log('Starting with services count:', services.length);
    
    let filtered = [...services];

    if (statusFilter) {
      const beforeCount = filtered.length;
      filtered = filtered.filter(s => s.status === statusFilter);
      console.log(`Status filter '${statusFilter}': ${beforeCount} → ${filtered.length}`);
    }
    
    if (categoryFilter) {
      const beforeCount = filtered.length;
      filtered = filtered.filter(s => s.categoryId === categoryFilter);
      console.log(`Category filter '${categoryFilter}': ${beforeCount} → ${filtered.length}`);
    }
    
    if (searchTitle) {
      const beforeCount = filtered.length;
      filtered = filtered.filter(s => s.title?.toLowerCase().includes(searchTitle.toLowerCase()));
      console.log(`Title search '${searchTitle}': ${beforeCount} → ${filtered.length}`);
    }
    
    if (searchTechnician) {
      const beforeCount = filtered.length;
      filtered = filtered.filter(s => s.technicianName?.toLowerCase().includes(searchTechnician.toLowerCase()));
      console.log(`Technician search '${searchTechnician}': ${beforeCount} → ${filtered.length}`);
    }

    console.log('✅ FINAL FILTERED SERVICES:', filtered.length);
    console.log('Filtered services data:', filtered);
    setFilteredServices(filtered);
  };

  const handleAction = (action: string, serviceId: string, serviceTitle: string) => {
    const titles: Record<string, string> = {
      approve: 'Approve Service',
      reject: 'Reject Service',
      disable: 'Disable Service',
      delete: 'Delete Service'
    };
    const messages: Record<string, string> = {
      approve: `Are you sure you want to approve "${serviceTitle}"? It will become visible to customers.`,
      reject: `Are you sure you want to reject "${serviceTitle}"?`,
      disable: `Are you sure you want to disable "${serviceTitle}"? It will no longer be visible to customers.`,
      delete: `Are you sure you want to delete "${serviceTitle}"? This action cannot be undone.`
    };
    
    setConfirmDialog({
      isOpen: true,
      title: titles[action] || 'Confirm Action',
      message: messages[action] || 'Are you sure?',
      action,
      serviceId,
      onConfirm: () => executeAction(action, serviceId),
      variant: action === 'delete' || action === 'reject' ? 'danger' : 'default'
    });
  };

  const executeAction = async (action: string, serviceId: string) => {
    try {
      const service = services.find(s => s.id === serviceId);
      if (!service || !service.technicianId) {
        showToast('Service not found or missing technician ID', 'error');
        return;
      }

      console.log(`Executing action '${action}' on service:`, serviceId);

      // Use Cloud Functions instead of direct Firestore writes
      if (action === 'approve') {
        const approveService = httpsCallable(functions, 'approveService');
        await approveService({ serviceId });
        showToast('Service approved successfully! It is now visible in customer app.');
      } else if (action === 'reject') {
        const rejectService = httpsCallable(functions, 'rejectService');
        await rejectService({ serviceId });
        showToast('Service rejected');
      } else if (action === 'disable') {
        const disableService = httpsCallable(functions, 'disableService');
        await disableService({ serviceId });
        showToast('Service disabled successfully');
      } else if (action === 'delete') {
        showToast('Delete functionality requires Cloud Function implementation', 'error');
        return;
      }
      
      setConfirmDialog({ ...confirmDialog, isOpen: false });
      await fetchServices();
    } catch (error: any) {
      console.error('Error executing action:', error);
      showToast(error.message || 'Failed to execute action', 'error');
    }
  };

  const handleViewDetails = (service: TechnicianService) => {
    console.log('Viewing details for service:', service.id);
    setSelectedService(service);
    setShowDetailsModal(true);
  };

  const getStatusVariant = (status: ModerationStatus): 'success' | 'warning' | 'error' | 'info' | 'default' | 'purple' => {
    switch (status) {
      case 'active': return 'success';
      case 'rejected': return 'default';
      case 'disabled': return 'error';
      default: return 'warning';
    }
  };

  const stats = {
    total: services.length,
    pending: services.filter(s => s.status === 'pending').length,
    active: services.filter(s => s.status === 'active').length,
    rejected: services.filter(s => s.status === 'rejected').length,
    disabled: services.filter(s => s.status === 'disabled').length,
  };

  const uniqueCategories = Array.from(new Set(services.map(s => s.categoryId).filter(Boolean)));

  const formatDate = (timestamp: any) => {
    if (!timestamp) return '-';
    try {
      const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      return date.toLocaleDateString();
    } catch (error) {
      console.warn('Error formatting date:', timestamp, error);
      return '-';
    }
  };

  const columns: Column[] = [
    {
      key: 'title',
      label: 'Service Title',
      sortable: true,
      render: (item: TechnicianService) => (
        <div>
          <p className="text-sm font-medium text-[#E5E7EB]">{item.title}</p>
          <p className="text-xs text-[#6B7280]">{item.subServiceName}</p>
        </div>
      )
    },
    {
      key: 'technician',
      label: 'Technician',
      render: (item: TechnicianService) => (
        <div>
          <p className="text-sm font-medium text-[#E5E7EB]">{item.technicianName}</p>
          {item.technicianRating && (
            <p className="text-xs text-[#6B7280]">⭐ {item.technicianRating.toFixed(1)}</p>
          )}
        </div>
      )
    },
    {
      key: 'price',
      label: 'Price',
      render: (item: TechnicianService) => (
        <span className="text-sm font-medium text-[#E5E7EB]">₹{item.price}</span>
      )
    },
    {
      key: 'status',
      label: 'Status',
      render: (item: TechnicianService) => (
        <StatusBadge 
          status={item.status.charAt(0).toUpperCase() + item.status.slice(1)} 
          variant={getStatusVariant(item.status)}
        />
      )
    },
    {
      key: 'actions',
      label: 'Actions',
      align: 'right',
      render: (item: TechnicianService) => (
        <div className="flex items-center gap-2 justify-end">
          <button 
            onClick={() => handleViewDetails(item)}
            className="px-3 py-1 text-xs bg-[#1F2937] text-[#E5E7EB] rounded-lg hover:bg-[#374151] transition-colors"
          >
            <Eye size={14} className="inline mr-1" />
            View
          </button>
          {item.status === 'pending' && (
            <>
              <button 
                onClick={() => handleAction('approve', item.id, item.title)}
                className="px-3 py-1 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
              >
                <CheckCircle size={14} className="inline mr-1" />
                Approve
              </button>
              <button 
                onClick={() => handleAction('reject', item.id, item.title)}
                className="px-3 py-1 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
              >
                <XCircle size={14} className="inline mr-1" />
                Reject
              </button>
            </>
          )}
        </div>
      )
    },
  ];

  // 🔍 DEBUGGING DISPLAY
  console.log('🔍 CURRENT STATE:');
  console.log('- Loading:', loading);
  console.log('- Services count:', services.length);
  console.log('- Filtered services count:', filteredServices.length);
  console.log('- Status filter:', statusFilter);
  console.log('- Category filter:', categoryFilter);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Services Management (DEBUG MODE)"
        description="Review and moderate technician-created service listings"
      />

      {/* Debug Info */}
      <div className="admin-card p-4 bg-yellow-900/20 border-yellow-600">
        <h3 className="text-yellow-400 font-bold mb-2">🔍 DEBUG INFORMATION</h3>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <p><strong>Loading:</strong> {loading ? 'YES' : 'NO'}</p>
            <p><strong>Raw Services:</strong> {services.length}</p>
            <p><strong>Filtered Services:</strong> {filteredServices.length}</p>
          </div>
          <div>
            <p><strong>Status Filter:</strong> {statusFilter || 'None'}</p>
            <p><strong>Category Filter:</strong> {categoryFilter || 'None'}</p>
            <p><strong>Firebase Connected:</strong> {db ? 'YES' : 'NO'}</p>
          </div>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6">
        <StatCard title="Total Listings" value={stats.total} icon={Package} color="purple" />
        <StatCard title="Pending Approval" value={stats.pending} icon={Clock} color="orange" />
        <StatCard title="Active Listings" value={stats.active} icon={CheckCircle} color="green" />
        <StatCard title="Rejected" value={stats.rejected} icon={XCircle} color="gray" />
        <StatCard title="Disabled Listings" value={stats.disabled} icon={BanIcon} color="red" />
      </div>

      {/* Filters */}
      <div className="admin-card p-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="input-field"
          >
            <option value="">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="active">Active</option>
            <option value="rejected">Rejected</option>
            <option value="disabled">Disabled</option>
          </select>
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="input-field"
          >
            <option value="">All Categories</option>
            {uniqueCategories.map(cat => (
              <option key={cat} value={cat}>{cat}</option>
            ))}
          </select>
        </div>
        {(statusFilter || categoryFilter) && (
          <button
            onClick={() => {
              setStatusFilter('');
              setCategoryFilter('');
            }}
            className="mt-4 px-4 py-2 bg-[#1F2937] text-[#E5E7EB] rounded-lg hover:bg-[#374151] transition-colors"
          >
            Clear Filters
          </button>
        )}
      </div>

      {/* Services Table */}
      <div className="admin-card p-6">
        <DataTable
          columns={columns}
          data={filteredServices}
          loading={loading}
          emptyMessage="No service listings found"
        />
      </div>

      {/* Service Details Modal */}
      {showDetailsModal && selectedService && (
        <Modal
          isOpen={showDetailsModal}
          onClose={() => setShowDetailsModal(false)}
          title="Service Details"
          size="lg"
        >
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-[#6B7280]">Service Title</p>
                <p className="text-base font-medium text-[#E5E7EB]">{selectedService.title}</p>
              </div>
              <div>
                <p className="text-sm text-[#6B7280]">Price</p>
                <p className="text-base font-medium text-[#E5E7EB]">₹{selectedService.price}</p>
              </div>
              <div>
                <p className="text-sm text-[#6B7280]">Status</p>
                <StatusBadge 
                  status={selectedService.status.charAt(0).toUpperCase() + selectedService.status.slice(1)} 
                  variant={getStatusVariant(selectedService.status)}
                />
              </div>
              <div>
                <p className="text-sm text-[#6B7280]">Technician</p>
                <p className="text-base font-medium text-[#E5E7EB]">{selectedService.technicianName}</p>
              </div>
            </div>
          </div>
        </Modal>
      )}

      {/* Confirm Dialog */}
      <ConfirmDialog
        isOpen={confirmDialog.isOpen}
        title={confirmDialog.title}
        message={confirmDialog.message}
        onConfirm={confirmDialog.onConfirm}
        onCancel={() => setConfirmDialog({ ...confirmDialog, isOpen: false })}
        variant={confirmDialog.variant}
      />

      {/* Toast Notification */}
      {toast.show && (
        <div className={`fixed bottom-4 right-4 px-6 py-3 rounded-lg shadow-lg z-50 flex items-center gap-2 ${
          toast.type === 'success' ? 'bg-green-600' : 'bg-red-600'
        } text-white`}>
          {toast.type === 'success' ? <CheckCircle size={20} /> : <XCircle size={20} />}
          {toast.message}
        </div>
      )}
    </div>
  );
}