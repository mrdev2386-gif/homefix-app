'use client';

import { useState, useEffect } from 'react';
import { PageHeader, DataTable, StatusBadge, Column, ConfirmDialog, StatCard, Modal } from '@/components/ui';
import { Eye, CheckCircle, XCircle, Ban, Trash2, Package, Clock, Search, X, Check, Ban as BanIcon, ChevronDown } from 'lucide-react';
import { db, functions, app } from '@/lib/firebase';
import { collection, query, getDocs, orderBy, where, Timestamp, limit, startAfter, DocumentSnapshot, doc, getDoc } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';

// FIXED: Use standard status values for production-ready moderation
type ModerationStatus = 'pending' | 'approved' | 'rejected' | 'disabled';

interface TechnicianService {
  id: string;
  technicianId: string;
  technicianName?: string;
  technicianPhone?: string;
  title: string;
  price: number;
  status: ModerationStatus;
  createdAt: any;
  description?: string;
  categoryName?: string;
  serviceName?: string;
  subServiceName?: string;
  imageUrl?: string;
  duration?: number;
  categoryId?: string;
  serviceId?: string;
  subServiceId?: string;
}

export default function TechnicianServicesPage() {
  const [services, setServices] = useState<TechnicianService[]>([]);
  const [filteredServices, setFilteredServices] = useState<TechnicianService[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [lastVisible, setLastVisible] = useState<DocumentSnapshot | null>(null);
  const [hasMore, setHasMore] = useState(true);
  const PAGE_SIZE = 50;
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
  
  const [statusFilter, setStatusFilter] = useState('');

  useEffect(() => {
    fetchServices();
  }, []);

  useEffect(() => {
    // Refetch when status filter changes (reset pagination)
    if (statusFilter) {
      fetchServices(statusFilter, false);
    } else {
      fetchServices(undefined, false);
    }
  }, [statusFilter]);

  useEffect(() => {
    if (toast.show) {
      const timer = setTimeout(() => setToast({ ...toast, show: false }), 3000);
      return () => clearTimeout(timer);
    }
  }, [toast.show]);

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ show: true, message, type });
  };

  const fetchServices = async (statusFilter?: string, loadMore = false) => {
    try {
      if (loadMore) {
        setLoadingMore(true);
      } else {
        setLoading(true);
        setServices([]);
        setLastVisible(null);
        setHasMore(true);
      }
      
      console.log("Fetching services from technician_services collection...");
      console.log("Status filter:", statusFilter || 'all');
      console.log("Load more:", loadMore);
      
      // PRODUCTION-READY: Paginated query with cursor-based pagination
      let servicesQuery;
      
      if (statusFilter) {
        servicesQuery = query(
          collection(db, "technician_services"),
          where("status", "==", statusFilter),
          orderBy("createdAt", "desc"),
          limit(PAGE_SIZE),
          ...(loadMore && lastVisible ? [startAfter(lastVisible)] : [])
        );
      } else {
        servicesQuery = query(
          collection(db, "technician_services"),
          orderBy("createdAt", "desc"),
          limit(PAGE_SIZE),
          ...(loadMore && lastVisible ? [startAfter(lastVisible)] : [])
        );
      }
      
      const snapshot = await getDocs(servicesQuery);
      console.log("Fetched services:", snapshot.size);
      
      // Update pagination state
      if (snapshot.docs.length > 0) {
        setLastVisible(snapshot.docs[snapshot.docs.length - 1]);
        setHasMore(snapshot.docs.length === PAGE_SIZE);
      } else {
        setHasMore(false);
      }
      
      if (snapshot.empty) {
        console.warn("No services found in technician_services collection");
        showToast('No technician services found', 'error');
        setServices([]);
        return;
      }

      // Resolve related documents for each service
      const servicesData: TechnicianService[] = [];
      
      for (const serviceDoc of snapshot.docs) {
        const serviceData = serviceDoc.data();
        
        console.log(`Resolving service ${serviceDoc.id}:`, {
          technicianId: serviceData.technicianId || 'missing',
          categoryId: serviceData.categoryId || 'missing',
          serviceId: serviceData.serviceId || 'missing'
        });

        // Resolve technician document
        let technicianName = 'Unknown Technician';
        let technicianPhone = 'N/A';
        if (serviceData.technicianId) {
          try {
            const technicianDoc = await getDoc(doc(db, 'technicians', serviceData.technicianId));
            if (technicianDoc.exists()) {
              const techData = technicianDoc.data();
              technicianName = techData.name || 'Unknown Technician';
              technicianPhone = techData.phone || 'N/A';
            }
          } catch (error) {
            console.warn(`Failed to resolve technician ${serviceData.technicianId}:`, error);
          }
        }

        // Resolve category document
        let categoryName = 'Unknown Category';
        if (serviceData.categoryId) {
          try {
            const categoryDoc = await getDoc(doc(db, 'categories', serviceData.categoryId));
            if (categoryDoc.exists()) {
              const catData = categoryDoc.data();
              categoryName = catData.name || 'Unknown Category';
            }
          } catch (error) {
            console.warn(`Failed to resolve category ${serviceData.categoryId}:`, error);
          }
        }

        // Resolve service document
        let serviceName = 'Unknown Service';
        if (serviceData.serviceId) {
          try {
            const masterServiceDoc = await getDoc(doc(db, 'services', serviceData.serviceId));
            if (masterServiceDoc.exists()) {
              const svcData = masterServiceDoc.data();
              serviceName = svcData.name || 'Unknown Service';
            }
          } catch (error) {
            console.warn(`Failed to resolve service ${serviceData.serviceId}:`, error);
          }
        }

        // Construct resolved service object
        const resolvedService: TechnicianService = {
          id: serviceDoc.id,
          title: serviceData.title || 'Untitled Service',
          description: serviceData.description || null,
          price: serviceData.price || 0,
          status: serviceData.status || 'pending',
          createdAt: serviceData.createdAt || Timestamp.now(),
          
          technicianId: serviceData.technicianId || 'unknown',
          technicianName,
          technicianPhone,
          
          categoryId: serviceData.categoryId || null,
          categoryName,
          
          serviceId: serviceData.serviceId || null,
          serviceName,
          
          subServiceId: serviceData.subServiceId || null,
          subServiceName: serviceData.subServiceName || null,
          
          imageUrl: serviceData.imageUrl || null,
          duration: serviceData.durationMinutes || serviceData.duration || null
        };
        
        servicesData.push(resolvedService);
      }
      
      console.log("Services loaded:", servicesData.length);
      console.log("Services by status:", {
        pending: servicesData.filter(s => s.status === 'pending').length,
        approved: servicesData.filter(s => s.status === 'approved').length,
        rejected: servicesData.filter(s => s.status === 'rejected').length,
        disabled: servicesData.filter(s => s.status === 'disabled').length,
        total: servicesData.length
      });
      
      if (loadMore) {
        setServices(prev => [...prev, ...servicesData]);
      } else {
        setServices(servicesData);
      }
      
    } catch (error: any) {
      console.error('Error fetching services:', error);
      
      if (error.code === 'failed-precondition' && error.message.includes('index')) {
        console.error("❌ FIRESTORE INDEX REQUIRED:");
        console.error("Collection: technician_services");
        console.error("Fields: status (ASC), createdAt (DESC)");
        console.error("Create index at: https://console.firebase.google.com/project/homefix-aa42d/firestore/indexes");
        showToast('Database index required for technician_services collection', 'error');
      } else if (error.code === 'permission-denied') {
        console.error("❌ PERMISSION DENIED - Check Firestore Security Rules:");
        console.error("Required rule: match /technician_services/{serviceId} { allow read: if true; }");
        showToast('Permission denied. Check Firestore security rules.', 'error');
      } else {
        showToast('Failed to load services: ' + error.message, 'error');
      }
    } finally {
      if (loadMore) {
        setLoadingMore(false);
      } else {
        setLoading(false);
      }
    }
  };

  const loadMoreServices = () => {
    if (!loadingMore && hasMore) {
      fetchServices(statusFilter, true);
    }
  };

  const applyFilters = () => {
    let filtered = [...services];
    
    if (statusFilter) {
      filtered = filtered.filter(s => s.status === statusFilter);
    }
    
    console.log(`Filtered services: ${filtered.length} (from ${services.length})`);
    setFilteredServices(filtered);
  };

  const handleAction = (action: string, serviceId: string, serviceTitle: string) => {
    const titles: Record<string, string> = {
      approve: 'Approve Service',
      reject: 'Reject Service',
      disable: 'Disable Service',
      delete: 'Delete Service'
    };
    
    setConfirmDialog({
      isOpen: true,
      title: titles[action] || 'Confirm Action',
      message: `Are you sure you want to ${action} "${serviceTitle}"?`,
      action,
      serviceId,
      onConfirm: () => executeAction(action, serviceId),
      variant: action === 'delete' || action === 'reject' ? 'danger' : 'default'
    });
  };

  const executeAction = async (action: string, serviceId: string) => {
    try {
      console.log(`Executing action '${action}' on service:`, serviceId);

      if (action === 'approve') {
        const approveService = httpsCallable(functions, 'admin_approveService');
        await approveService({ serviceId, status: 'approved' });
        showToast('Service approved successfully!');
      } else if (action === 'reject') {
        const rejectService = httpsCallable(functions, 'admin_rejectService');
        await rejectService({ serviceId, status: 'rejected' });
        showToast('Service rejected');
      } else if (action === 'disable') {
        const disableService = httpsCallable(functions, 'admin_disableService');
        await disableService({ serviceId, status: 'disabled' });
        showToast('Service disabled');
      }
      
      setConfirmDialog({ ...confirmDialog, isOpen: false });
      await fetchServices(statusFilter, false);
    } catch (error: any) {
      console.error('Error executing action:', error);
      showToast(error.message || 'Failed to execute action', 'error');
    }
  };

  const handleViewDetails = async (service: TechnicianService) => {
    // Service is already fully resolved, just set it
    setSelectedService(service);
    setShowDetailsModal(true);
  };

  const getStatusVariant = (status: ModerationStatus): 'success' | 'warning' | 'error' | 'default' => {
    switch (status) {
      case 'approved': return 'success';
      case 'rejected': return 'default';
      case 'disabled': return 'error';
      default: return 'warning';
    }
  };

  const getStatusLabel = (status: ModerationStatus): string => {
    switch (status) {
      case 'pending': return 'Pending';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'disabled': return 'Disabled';
      default: return status;
    }
  };

  const stats = {
    total: services.length,
    pending: services.filter(s => s.status === 'pending').length,
    approved: services.filter(s => s.status === 'approved').length,
    rejected: services.filter(s => s.status === 'rejected').length,
    disabled: services.filter(s => s.status === 'disabled').length,
  };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return '-';
    try {
      const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      return date.toLocaleDateString();
    } catch (error) {
      return '-';
    }
  };

  const columns: Column[] = [
    {
      key: 'title',
      label: 'Service Title',
      render: (item: TechnicianService) => (
        <div>
          <p className="text-sm font-medium text-[#E5E7EB]">{item.title}</p>
          <p className="text-xs text-[#6B7280]">{item.serviceName}</p>
        </div>
      )
    },
    {
      key: 'technician',
      label: 'Technician',
      render: (item: TechnicianService) => (
        <p className="text-sm font-medium text-[#E5E7EB]">{item.technicianName}</p>
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
          status={getStatusLabel(item.status)} 
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
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6">
        <StatCard title="Total Listings" value={stats.total} icon={Package} color="purple" />
        <StatCard title="Pending Approval" value={stats.pending} icon={Clock} color="orange" />
        <StatCard title="Approved Listings" value={stats.approved} icon={CheckCircle} color="green" />
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
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
            <option value="disabled">Disabled</option>
          </select>
          {statusFilter && (
            <button
              onClick={() => setStatusFilter('')}
              className="px-4 py-2 bg-[#1F2937] text-[#E5E7EB] rounded-lg hover:bg-[#374151] transition-colors"
            >
              Clear Filter
            </button>
          )}
        </div>
      </div>

      {/* Services Table */}
      <div className="admin-card p-6">
        <DataTable
          columns={columns}
          data={services}
          loading={loading}
          emptyMessage="No service listings found"
        />
        
        {/* Load More Button */}
        {hasMore && services.length > 0 && (
          <div className="flex justify-center mt-6">
            <button
              onClick={loadMoreServices}
              disabled={loadingMore}
              className="px-6 py-3 bg-[#1F2937] text-[#E5E7EB] rounded-lg hover:bg-[#374151] transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {loadingMore ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-[#E5E7EB]"></div>
                  Loading...
                </>
              ) : (
                <>
                  <ChevronDown size={16} />
                  Load More Services
                </>
              )}
            </button>
          </div>
        )}
        
        {/* Pagination Info */}
        {services.length > 0 && (
          <div className="text-center mt-4 text-sm text-[#6B7280]">
            Showing {services.length} services{hasMore ? ' (more available)' : ' (all loaded)'}
          </div>
        )}
      </div>

      {/* Service Details Modal */}
      {showDetailsModal && selectedService && (
        <Modal
          isOpen={showDetailsModal}
          onClose={() => setShowDetailsModal(false)}
          title="Service Details"
          size="xl"
        >
          <div className="space-y-6">
            {/* Service Image */}
            {selectedService.imageUrl && (
              <div className="flex justify-center">
                <img 
                  src={selectedService.imageUrl} 
                  alt={selectedService.title}
                  className="w-32 h-32 object-cover rounded-lg border border-[#374151]"
                  onError={(e) => {
                    (e.target as HTMLImageElement).style.display = 'none';
                  }}
                />
              </div>
            )}
            
            {/* Service Information Grid */}
            <div className="grid grid-cols-2 gap-6">
              <div>
                <p className="text-sm text-[#6B7280] mb-1">Service Title</p>
                <p className="text-base font-medium text-[#E5E7EB]">{selectedService.title}</p>
              </div>
              <div>
                <p className="text-sm text-[#6B7280] mb-1">Price</p>
                <p className="text-base font-medium text-[#E5E7EB]">₹{selectedService.price}</p>
              </div>
              
              <div>
                <p className="text-sm text-[#6B7280] mb-1">Category</p>
                <p className="text-base font-medium text-[#E5E7EB]">{selectedService.categoryName}</p>
              </div>
              <div>
                <p className="text-sm text-[#6B7280] mb-1">Service</p>
                <p className="text-base font-medium text-[#E5E7EB]">{selectedService.serviceName}</p>
              </div>
              
              {selectedService.subServiceName && (
                <div>
                  <p className="text-sm text-[#6B7280] mb-1">Sub Service</p>
                  <p className="text-base font-medium text-[#E5E7EB]">{selectedService.subServiceName}</p>
                </div>
              )}
              
              {selectedService.duration && (
                <div>
                  <p className="text-sm text-[#6B7280] mb-1">Duration</p>
                  <p className="text-base font-medium text-[#E5E7EB]">{selectedService.duration} minutes</p>
                </div>
              )}
              
              <div>
                <p className="text-sm text-[#6B7280] mb-1">Status</p>
                <StatusBadge 
                  status={getStatusLabel(selectedService.status)} 
                  variant={getStatusVariant(selectedService.status)}
                />
              </div>
              <div>
                <p className="text-sm text-[#6B7280] mb-1">Created Date</p>
                <p className="text-base font-medium text-[#E5E7EB]">{formatDate(selectedService.createdAt)}</p>
              </div>
            </div>
            
            {/* Technician Information */}
            <div className="border-t border-[#374151] pt-4">
              <h4 className="text-lg font-medium text-[#E5E7EB] mb-3">Technician Information</h4>
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <p className="text-sm text-[#6B7280] mb-1">Technician Name</p>
                  <p className="text-base font-medium text-[#E5E7EB]">{selectedService.technicianName}</p>
                </div>
                <div>
                  <p className="text-sm text-[#6B7280] mb-1">Technician Phone</p>
                  <p className="text-base font-medium text-[#E5E7EB]">{selectedService.technicianPhone}</p>
                </div>
              </div>
            </div>

            {/* Description */}
            {selectedService.description && (
              <div className="border-t border-[#374151] pt-4">
                <p className="text-sm text-[#6B7280] mb-2">Description</p>
                <p className="text-base text-[#E5E7EB] bg-[#1F2937] p-4 rounded-lg leading-relaxed">{selectedService.description}</p>
              </div>
            )}

            {/* Action Buttons */}
            <div className="flex gap-3 border-t border-[#374151] pt-4">
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
                    Approve
                  </button>
                  <button
                    onClick={() => {
                      setShowDetailsModal(false);
                      handleAction('reject', selectedService.id, selectedService.title);
                    }}
                    className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                  >
                    <XCircle size={16} className="inline mr-2" />
                    Reject
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
                  Disable
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
                  Enable
                </button>
              )}
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