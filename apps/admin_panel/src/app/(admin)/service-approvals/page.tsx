'use client';

import { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, doc, updateDoc, getDoc, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import Modal from '@/components/ui/Modal';
import PageHeader from '@/components/ui/PageHeader';
import LoadingState from '@/components/ui/LoadingState';
import EmptyState from '@/components/ui/EmptyState';
import ErrorState from '@/components/ui/ErrorState';
import ConfirmDialog from '@/components/ui/ConfirmDialog';
import { Briefcase, Search, Filter, Eye, Clock, MapPin, User, Phone, DollarSign, Calendar, Image as ImageIcon } from 'lucide-react';

interface TechnicianService {
  id: string;
  serviceName: string;
  category: string;
  subService?: string;
  description: string;
  price: number;
  estimatedDuration?: string;
  district: string;
  city?: string;
  imageUrl?: string;
  technicianId: string;
  technicianName?: string;
  technicianPhone?: string;
  technicianExperience?: number;
  status: 'pending' | 'approved' | 'rejected';
  createdAt: Timestamp;
}

export default function ServiceApprovalsPage() {
  const [services, setServices] = useState<TechnicianService[]>([]);
  const [filteredServices, setFilteredServices] = useState<TechnicianService[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedService, setSelectedService] = useState<TechnicianService | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showApproveDialog, setShowApproveDialog] = useState(false);
  const [showRejectDialog, setShowRejectDialog] = useState(false);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [rejectionReason, setRejectionReason] = useState('');

  const itemsPerPage = 20;
  const categories = [...new Set(services.map(service => service.category))];

  // Helper for development-only logging
  const debugLog = (...args: any[]) => {
    if (process.env.NODE_ENV === 'development') {
      console.log(...args);
    }
  };

  useEffect(() => {
    debugLog('[ADMIN PANEL] Setting up service approvals listener...');
    
    const q = query(
      collection(db, 'technician_services'),
      where('status', '==', 'pending')
    );

    debugLog('[ADMIN PANEL] Query configured for collection: technician_services, status: pending');

    const unsubscribe = onSnapshot(q, 
      async (snapshot) => {
        debugLog('[ADMIN PANEL] Snapshot received');
        debugLog('[ADMIN PANEL] Total documents:', snapshot.docs.length);
        debugLog('[ADMIN PANEL] Empty:', snapshot.empty);
        
        // Log each document
        snapshot.docs.forEach((doc, index) => {
          debugLog(`[ADMIN PANEL] Doc ${index + 1}:`, doc.id, doc.data());
        });
        
        const serviceData = await Promise.all(
          snapshot.docs.map(async (serviceDoc) => {
            const data = serviceDoc.data();
            
            debugLog(`[ADMIN PANEL] Processing service ${serviceDoc.id}:`, {
              name: data.name || data.serviceName,
              status: data.status,
              technicianId: data.technicianId
            });
            
            // Fetch technician details
            let technicianName = 'Not Available';
            let technicianPhone = '';
            let technicianExperience = 0;
            
            if (data.technicianId) {
              try {
                const techRef = doc(db, 'technicians', data.technicianId);
                const techSnap = await getDoc(techRef);
                
                if (techSnap.exists()) {
                  const techData = techSnap.data();
                  technicianName = techData.fullName || techData.name || 'Not Available';
                  technicianPhone = techData.phone || '';
                  technicianExperience = techData.experience || 0;
                }
              } catch (err) {
                console.error('Error fetching technician:', err);
              }
            }
            
            return {
              id: serviceDoc.id,
              serviceName: data.serviceName || data.name || 'Not Available',
              category: data.category || 'Not Available',
              subService: data.subService,
              description: data.description || '',
              price: data.price || 0,
              estimatedDuration: data.estimatedDuration,
              district: data.district || 'Not Available',
              city: data.city,
              imageUrl: data.imageUrl,
              technicianId: data.technicianId || '',
              technicianName,
              technicianPhone,
              technicianExperience,
              status: data.status,
              createdAt: data.createdAt || Timestamp.now(),
            } as TechnicianService;
          })
        );
        
        setServices(serviceData.sort((a, b) => {
          const aTime = a.createdAt?.toMillis?.() || 0;
          const bTime = b.createdAt?.toMillis?.() || 0;
          return bTime - aTime;
        }));
        
        debugLog('[ADMIN PANEL] Services set:', serviceData.length);
        debugLog('[ADMIN PANEL] Service IDs:', serviceData.map(s => s.id));
        
        setLoading(false);
        setError(null);
      },
      (err) => {
        if (process.env.NODE_ENV === 'development') {
          console.error('[ADMIN PANEL] Error fetching service approvals:', err);
          console.error('[ADMIN PANEL] Error code:', err.code);
          console.error('[ADMIN PANEL] Error message:', err.message);
        }
        setError(`Failed to load service approvals: ${err.message}`);
        setLoading(false);
      }
    );

    debugLog('[ADMIN PANEL] Listener attached');
    return () => {
      debugLog('[ADMIN PANEL] Cleaning up listener');
      unsubscribe();
    };
  }, []);

  useEffect(() => {
    let filtered = services;

    if (searchTerm) {
      filtered = filtered.filter(service =>
        service.serviceName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        service.technicianName?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (selectedCategory) {
      filtered = filtered.filter(service => service.category === selectedCategory);
    }

    setFilteredServices(filtered);
    setCurrentPage(1);
  }, [services, searchTerm, selectedCategory]);

  const paginatedServices = filteredServices.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const totalPages = Math.ceil(filteredServices.length / itemsPerPage);

  const handleApprove = async (serviceId: string) => {
    setProcessingId(serviceId);
    try {
      await updateDoc(doc(db, 'technician_services', serviceId), {
        status: 'approved',
        isActive: true, // CRITICAL: Activate service on approval
        approvedAt: Timestamp.now(),
        approvedBy: 'admin',
        updatedAt: Timestamp.now()
      });
      setShowApproveDialog(false);
      setSelectedService(null);
    } catch (error) {
      console.error('Error approving service:', error);
      alert('Failed to approve service');
    } finally {
      setProcessingId(null);
    }
  };

  const handleReject = async (serviceId: string) => {
    setProcessingId(serviceId);
    try {
      const updateData: any = {
        status: 'rejected',
        isActive: false, // CRITICAL: Keep inactive on rejection
        rejectedAt: Timestamp.now(),
        rejectedBy: 'admin',
        updatedAt: Timestamp.now()
      };

      if (rejectionReason && rejectionReason.trim()) {
        updateData.rejectionReason = rejectionReason.trim();
      }

      await updateDoc(doc(db, 'technician_services', serviceId), updateData);
      setShowRejectDialog(false);
      setSelectedService(null);
      setRejectionReason('');
    } catch (error) {
      console.error('Error rejecting service:', error);
      alert('Failed to reject service');
    } finally {
      setProcessingId(null);
    }
  };

  const openDetailsModal = (service: TechnicianService) => {
    setSelectedService(service);
    setShowDetailsModal(true);
  };

  const openApproveDialog = (service: TechnicianService) => {
    setSelectedService(service);
    setShowApproveDialog(true);
  };

  const openRejectDialog = (service: TechnicianService) => {
    setSelectedService(service);
    setShowRejectDialog(true);
  };

  if (loading) return <LoadingState />;
  if (error) return <ErrorState message={error} />;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Service Approvals"
        description="Review and approve services submitted by technicians"
      />

      {/* Search and Filters */}
      <Card className="p-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-[#6B7280] w-4 h-4" />
            <input
              type="text"
              placeholder="Search services or technicians..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-[#1F2937] border border-[#374151] rounded-lg text-[#E5E7EB] placeholder-[#6B7280] focus:outline-none focus:ring-2 focus:ring-[#6366F1] focus:border-transparent"
            />
          </div>
          <div className="relative">
            <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 text-[#6B7280] w-4 h-4" />
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="pl-10 pr-8 py-2 bg-[#1F2937] border border-[#374151] rounded-lg text-[#E5E7EB] focus:outline-none focus:ring-2 focus:ring-[#6366F1] focus:border-transparent"
            >
              <option value="">All Categories</option>
              {categories.map(category => (
                <option key={category} value={category}>{category}</option>
              ))}
            </select>
          </div>
        </div>
      </Card>

      {filteredServices.length === 0 ? (
        <EmptyState
          icon={Briefcase}
          title="No Services Pending Approval"
          description="All submitted services have been reviewed"
        />
      ) : (
        <>
          {/* Services Table */}
          <Card className="overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-[#1F2937] border-b border-[#374151]">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Service</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Category</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Technician</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Price</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Location</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Submitted</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-[#9CA3AF] uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#374151]">
                  {paginatedServices.map((service) => (
                    <tr key={service.id} className="hover:bg-[#1F2937] transition-colors">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          {service.imageUrl ? (
                            <img
                              src={service.imageUrl}
                              alt={service.serviceName}
                              className="w-12 h-12 rounded-lg object-cover mr-4"
                            />
                          ) : (
                            <div className="w-12 h-12 rounded-lg bg-[#374151] flex items-center justify-center mr-4">
                              <ImageIcon className="w-6 h-6 text-[#6B7280]" />
                            </div>
                          )}
                          <div>
                            <div className="text-sm font-medium text-[#E5E7EB]">{service.serviceName}</div>
                            {service.subService && (
                              <div className="text-sm text-[#9CA3AF]">{service.subService}</div>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <Badge variant="secondary" className="text-xs">
                          {service.category}
                        </Badge>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-[#E5E7EB]">{service.technicianName}</div>
                        {service.technicianPhone && (
                          <div className="text-sm text-[#9CA3AF]">{service.technicianPhone}</div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-[#E5E7EB]">₹{service.price}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-[#E5E7EB]">{service.district}</div>
                        {service.city && (
                          <div className="text-sm text-[#9CA3AF]">{service.city}</div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-[#E5E7EB]">
                          {service.createdAt?.toDate?.()?.toLocaleDateString() || 'N/A'}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => openDetailsModal(service)}
                          className="mr-2"
                        >
                          <Eye className="w-4 h-4 mr-1" />
                          View
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between">
              <div className="text-sm text-[#9CA3AF]">
                Showing {((currentPage - 1) * itemsPerPage) + 1} to {Math.min(currentPage * itemsPerPage, filteredServices.length)} of {filteredServices.length} services
              </div>
              <div className="flex space-x-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                  disabled={currentPage === 1}
                >
                  Previous
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                  disabled={currentPage === totalPages}
                >
                  Next
                </Button>
              </div>
            </div>
          )}
        </>
      )}

      {/* Service Details Modal */}
      {selectedService && (
        <Modal
          isOpen={showDetailsModal}
          onClose={() => setShowDetailsModal(false)}
          title="Service Details"
          size="xl"
        >
          <div className="max-h-[80vh] overflow-y-auto">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Left Column */}
              <div className="space-y-6">
                {/* Basic Information */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <Briefcase className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Basic Information</h3>
                  </div>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Service Name</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedService.serviceName}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Category</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedService.category}</p>
                    </div>
                    {selectedService.subService && (
                      <div>
                        <label className="block text-sm font-medium text-[#9CA3AF]">Sub-Service</label>
                        <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedService.subService}</p>
                      </div>
                    )}
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Description</label>
                      <p className="mt-1 text-sm text-[#E5E7EB]">{selectedService.description || 'No description provided'}</p>
                    </div>
                  </div>
                </div>

                {/* Service Details */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <DollarSign className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Service Details</h3>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Price</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">₹{selectedService.price}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Duration</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedService.estimatedDuration || 'Not specified'}</p>
                    </div>
                    <div className="col-span-2">
                      <label className="block text-sm font-medium text-[#9CA3AF]">Service Area</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">
                        {selectedService.district}{selectedService.city ? `, ${selectedService.city}` : ''}
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Right Column */}
              <div className="space-y-6">
                {/* Technician Information */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <User className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Technician Information</h3>
                  </div>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Name</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedService.technicianName || 'Not provided'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Technician ID</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-mono">{selectedService.technicianId}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Phone</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedService.technicianPhone || 'Not provided'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Experience</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">
                        {selectedService.technicianExperience ? `${selectedService.technicianExperience} years` : 'Not provided'}
                      </p>
                    </div>
                  </div>
                </div>

                {/* Media */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <ImageIcon className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Service Image</h3>
                  </div>
                  {selectedService.imageUrl ? (
                    <img
                      src={selectedService.imageUrl}
                      alt={selectedService.serviceName}
                      className="w-full h-48 rounded-lg object-cover"
                    />
                  ) : (
                    <div className="w-full h-48 rounded-lg bg-[#374151] flex items-center justify-center">
                      <div className="text-center">
                        <ImageIcon className="w-12 h-12 text-[#6B7280] mx-auto mb-2" />
                        <span className="text-sm text-[#6B7280]">No image provided</span>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Sticky Action Footer */}
            <div className="sticky bottom-0 bg-[#111827] border-t border-[#374151] p-6 mt-6 -mx-6 -mb-6">
              <div className="flex items-center justify-between">
                <div>
                  <span className="text-sm text-[#9CA3AF]">Service ID:</span>
                  <span className="ml-2 text-sm text-[#E5E7EB] font-mono">{selectedService.id}</span>
                </div>
                <div className="flex space-x-3">
                  <Button
                    variant="outline"
                    onClick={() => {
                      setShowDetailsModal(false);
                      openRejectDialog(selectedService);
                    }}
                    className="text-red-400 border-red-400 hover:bg-red-400/10"
                    disabled={processingId === selectedService.id}
                  >
                    Reject
                  </Button>
                  <Button
                    onClick={() => {
                      setShowDetailsModal(false);
                      openApproveDialog(selectedService);
                    }}
                    className="bg-green-600 hover:bg-green-700 text-white"
                    disabled={processingId === selectedService.id}
                  >
                    Approve
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </Modal>
      )}

      {/* Approve Confirmation Dialog */}
      <ConfirmDialog
        isOpen={showApproveDialog}
        onCancel={() => setShowApproveDialog(false)}
        onConfirm={() => selectedService && handleApprove(selectedService.id)}
        title="Approve Service"
        message={`Are you sure you want to approve "${selectedService?.serviceName}"? This service will be available for customers to book.`}
        confirmText="Approve"
      />

      {/* Reject Confirmation Dialog */}
      <ConfirmDialog
        isOpen={showRejectDialog}
        onCancel={() => {
          setShowRejectDialog(false);
          setRejectionReason('');
        }}
        onConfirm={(inputValue) => {
          if (inputValue) setRejectionReason(inputValue);
          selectedService && handleReject(selectedService.id);
        }}
        title="Reject Service"
        message={`Are you sure you want to reject "${selectedService?.serviceName}"?`}
        confirmText="Reject"
        variant="danger"
        requireInput={true}
        inputLabel="Rejection Reason (Optional)"
        inputPlaceholder="Provide a reason for rejection..."
      />
    </div>
  );
}