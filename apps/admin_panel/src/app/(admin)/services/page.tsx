'use client';

import { useState, useEffect } from 'react';
import { PageHeader, DataTable, StatusBadge, Column, ConfirmDialog, StatCard, Modal } from '@/components/ui';
import { Eye, CheckCircle, XCircle, Ban, Trash2, Package, Clock, AlertTriangle, Search, X, Check, Ban as BanIcon } from 'lucide-react';
import { db } from '@/lib/firebase';
import { collection, query, getDocs, doc, updateDoc, deleteDoc, collectionGroup, orderBy } from 'firebase/firestore';

type ModerationStatus = 'pending' | 'approved' | 'rejected' | 'disabled';

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
      
      // Fetch from technician_services collection
      const servicesQuery = query(
        collection(db, 'technician_services'),
        orderBy('createdAt', 'desc')
      );
      const snapshot = await getDocs(servicesQuery);
      
      console.log('Fetched services count:', snapshot.docs.length);
      
      // Fetch related data
      const techniciansSnap = await getDocs(collection(db, 'technicians'));
      const categoriesSnap = await getDocs(collection(db, 'categories'));
      const servicesSnap = await getDocs(collection(db, 'services'));
      
      const techniciansMap = new Map(techniciansSnap.docs.map(d => [d.id, d.data()]));
      const categoriesMap = new Map(categoriesSnap.docs.map(d => [d.id, d.data()]));
      const servicesMap = new Map(servicesSnap.docs.map(d => [d.id, d.data()]));
      
      const servicesData = snapshot.docs.map(doc => {
        const data = doc.data();
        console.log('Service data:', data);
        
        const technician = techniciansMap.get(data.technicianId);
        const category = categoriesMap.get(data.categoryId);
        const service = servicesMap.get(data.serviceId);
        
        // Find sub-service from service's subServices array
        let subServiceName = data.subServiceId;
        if (service?.subServices) {
          const subService = service.subServices.find((s: any) => s.id === data.subServiceId);
          if (subService) subServiceName = subService.name;
        }
        
        return { 
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
          createdAt: data.createdAt
        };
      }) as TechnicianService[];
      
      console.log('Processed services:', servicesData);
      setServices(servicesData);
    } catch (error: any) {
      console.error('Error fetching technician services:', error);
      showToast('Failed to load services. Please try again.', 'error');
    } finally {
      setLoading(false);
    }
  };

  const applyFilters = () => {
    let filtered = [...services];

    if (statusFilter) {
      filtered = filtered.filter(s => s.status === statusFilter);
    }
    if (categoryFilter) {
      filtered = filtered.filter(s => s.categoryId === categoryFilter);
    }
    if (searchTitle) {
      filtered = filtered.filter(s => s.title?.toLowerCase().includes(searchTitle.toLowerCase()));
    }
    if (searchTechnician) {
      filtered = filtered.filter(s => s.technicianName?.toLowerCase().includes(searchTechnician.toLowerCase()));
    }

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

      const serviceRef = doc(db, 'technician_services', serviceId);

      if (action === 'delete') {
        await deleteDoc(serviceRef);
        showToast('Service deleted successfully');
      } else {
        const newStatus: ModerationStatus = 
          action === 'approve' ? 'approved' :
          action === 'reject' ? 'rejected' :
          action === 'disable' ? 'disabled' : 'pending';
        
        await updateDoc(serviceRef, { status: newStatus });
        
        if (action === 'approve') {
          showToast('Service approved successfully! It is now visible in customer app.');
        } else if (action === 'disable') {
          showToast('Service disabled successfully');
        } else if (action === 'reject') {
          showToast('Service rejected');
        }
      }
      
      setConfirmDialog({ ...confirmDialog, isOpen: false });
      await fetchServices();
    } catch (error) {
      console.error('Error executing action:', error);
      showToast('Failed to execute action', 'error');
    }
  };

  const handleViewDetails = (service: TechnicianService) => {
    setSelectedService(service);
    setShowDetailsModal(true);
  };

  const getStatusVariant = (status: ModerationStatus): 'success' | 'warning' | 'error' | 'info' | 'default' | 'purple' => {
    switch (status) {
      case 'approved': return 'success';
      case 'rejected': return 'default';
      case 'disabled': return 'error';
      default: return 'warning';
    }
  };

  const stats = {
    total: services.length,
    pending: services.filter(s => s.status === 'pending').length,
    approved: services.filter(s => s.status === 'approved').length,
    disabled: services.filter(s => s.status === 'disabled').length,
  };

  const uniqueCategories = Array.from(new Set(services.map(s => s.categoryId).filter(Boolean)));

  const formatDate = (timestamp: any) => {
    if (!timestamp) return '-';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString();
  };

  const columns: Column[] = [
    {
      key: 'image',
      label: 'Image',
      render: (item: TechnicianService) => (
        <div className="w-12 h-12 rounded-lg overflow-hidden bg-[#1F2937]">
          {item.imageUrl ? (
            <img src={item.imageUrl} alt={item.title} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full flex items-center justify-center text-[#6B7280]">
              <Package size={20} />
            </div>
          )}
        </div>
      )
    },
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
      key: 'category',
      label: 'Category',
      render: (item: TechnicianService) => (
        <span className="text-sm text-[#9CA3AF]">{item.categoryName}</span>
      )
    },
    {
      key: 'service',
      label: 'Sub Service',
      render: (item: TechnicianService) => (
        <span className="text-sm text-[#9CA3AF]">{item.serviceName}</span>
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
      key: 'location',
      label: 'City / District',
      render: (item: TechnicianService) => (
        <span className="text-sm text-[#9CA3AF]">
          {item.city || item.district || '-'}
        </span>
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
      key: 'createdAt',
      label: 'Created',
      render: (item: TechnicianService) => (
        <span className="text-sm text-[#9CA3AF]">{formatDate(item.createdAt)}</span>
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
          {item.status === 'approved' && (
            <button 
              onClick={() => handleAction('disable', item.id, item.title)}
              className="px-3 py-1 text-xs bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors"
            >
              <Ban size={14} className="inline mr-1" />
              Disable
            </button>
          )}
          {item.status === 'disabled' && (
            <button 
              onClick={() => handleAction('approve', item.id, item.title)}
              className="px-3 py-1 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
            >
              <Check size={14} className="inline mr-1" />
              Enable
            </button>
          )}
          <button 
            onClick={() => handleAction('delete', item.id, item.title)}
            className="px-3 py-1 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
          >
            <Trash2 size={14} className="inline mr-1" />
          </button>
        </div>
      )
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Services Management"
        description="Review and moderate technician-created service listings"
      />

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <StatCard title="Total Listings" value={stats.total} icon={Package} color="purple" />
        <StatCard title="Pending Approval" value={stats.pending} icon={Clock} color="orange" />
        <StatCard title="Approved Listings" value={stats.approved} icon={CheckCircle} color="green" />
        <StatCard title="Disabled Listings" value={stats.disabled} icon={BanIcon} color="red" />
      </div>

      {/* Filters */}
      <div className="admin-card p-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-[#6B7280]" size={18} />
            <input
              type="text"
              placeholder="Search by service title..."
              value={searchTitle}
              onChange={(e) => setSearchTitle(e.target.value)}
              className="input-field w-full pl-10 pr-4"
            />
            {searchTitle && (
              <button
                onClick={() => setSearchTitle('')}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-[#6B7280] hover:text-[#E5E7EB]"
              >
                <X size={18} />
              </button>
            )}
          </div>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-[#6B7280]" size={18} />
            <input
              type="text"
              placeholder="Search by technician name..."
              value={searchTechnician}
              onChange={(e) => setSearchTechnician(e.target.value)}
              className="input-field w-full pl-10 pr-4"
            />
            {searchTechnician && (
              <button
                onClick={() => setSearchTechnician('')}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-[#6B7280] hover:text-[#E5E7EB]"
              >
                <X size={18} />
              </button>
            )}
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="input-field"
          >
            <option value="">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
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
        {(statusFilter || categoryFilter || searchTitle || searchTechnician) && (
          <button
            onClick={() => {
              setStatusFilter('');
              setCategoryFilter('');
              setSearchTitle('');
              setSearchTechnician('');
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
            {/* Service Image */}
            {selectedService.imageUrl && (
              <div className="w-full h-48 rounded-lg overflow-hidden bg-[#1F2937]">
                <img src={selectedService.imageUrl} alt={selectedService.title} className="w-full h-full object-cover" />
              </div>
            )}

            {/* Service Info */}
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
                <p className="text-sm text-[#6B7280]">Category</p>
                <p className="text-base font-medium text-[#E5E7EB]">{selectedService.categoryName}</p>
              </div>
              <div>
                <p className="text-sm text-[#6B7280]">Service</p>
                <p className="text-base font-medium text-[#E5E7EB]">{selectedService.serviceName}</p>
              </div>
              <div>
                <p className="text-sm text-[#6B7280]">Sub Service</p>
                <p className="text-base font-medium text-[#E5E7EB]">{selectedService.subServiceName}</p>
              </div>
              <div>
                <p className="text-sm text-[#6B7280]">Status</p>
                <StatusBadge 
                  status={selectedService.status.charAt(0).toUpperCase() + selectedService.status.slice(1)} 
                  variant={getStatusVariant(selectedService.status)}
                />
              </div>
            </div>

            {/* Description */}
            {selectedService.description && (
              <div>
                <p className="text-sm text-[#6B7280] mb-2">Description</p>
                <p className="text-base text-[#E5E7EB] bg-[#1F2937] p-4 rounded-lg">{selectedService.description}</p>
              </div>
            )}

            {/* Technician Info */}
            <div className="border-t border-[#1F2937] pt-4">
              <h4 className="text-sm font-semibold text-[#E5E7EB] mb-3">Technician Information</h4>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-[#6B7280]">Name</p>
                  <p className="text-base font-medium text-[#E5E7EB]">{selectedService.technicianName}</p>
                </div>
                <div>
                  <p className="text-sm text-[#6B7280]">Phone</p>
                  <p className="text-base font-medium text-[#E5E7EB]">{selectedService.technicianPhone || '-'}</p>
                </div>
                <div>
                  <p className="text-sm text-[#6B7280]">Rating</p>
                  <p className="text-base font-medium text-[#E5E7EB]">
                    {selectedService.technicianRating ? `⭐ ${selectedService.technicianRating.toFixed(1)}` : '-'}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-[#6B7280]">Location</p>
                  <p className="text-base font-medium text-[#E5E7EB]">{selectedService.city || selectedService.district || '-'}</p>
                </div>
              </div>
            </div>

            {/* Created Date */}
            <div className="border-t border-[#1F2937] pt-4">
              <p className="text-sm text-[#6B7280]">Created Date</p>
              <p className="text-base font-medium text-[#E5E7EB]">
                {formatDate(selectedService.createdAt)}
              </p>
            </div>

            {/* Action Buttons */}
            <div className="flex gap-3 border-t border-[#1F2937] pt-4">
              {selectedService.status === 'pending' && (
                <>
                  <button
                    onClick={() => {
                      setShowDetailsModal(false);
                      handleAction('approve', selectedService.id, selectedService.title);
                    }}
                    className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                  >
                    <CheckCircle size={16} className="inline mr-2" />
                    Approve Listing
                  </button>
                  <button
                    onClick={() => {
                      setShowDetailsModal(false);
                      handleAction('reject', selectedService.id, selectedService.title);
                    }}
                    className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                  >
                    <XCircle size={16} className="inline mr-2" />
                    Reject Listing
                  </button>
                </>
              )}
              {selectedService.status === 'approved' && (
                <button
                  onClick={() => {
                    setShowDetailsModal(false);
                    handleAction('disable', selectedService.id, selectedService.title);
                  }}
                  className="flex-1 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors"
                >
                  <Ban size={16} className="inline mr-2" />
                  Disable Listing
                </button>
              )}
              {selectedService.status === 'disabled' && (
                <button
                  onClick={() => {
                    setShowDetailsModal(false);
                    handleAction('approve', selectedService.id, selectedService.title);
                  }}
                  className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                >
                  <Check size={16} className="inline mr-2" />
                  Enable Listing
                </button>
              )}
              <button
                onClick={() => {
                  setShowDetailsModal(false);
                  handleAction('delete', selectedService.id, selectedService.title);
                }}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
              >
                <Trash2 size={16} className="inline mr-2" />
                Delete
              </button>
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
