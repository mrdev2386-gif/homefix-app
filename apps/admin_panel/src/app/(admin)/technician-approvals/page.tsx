'use client';

import { Users } from 'lucide-react';
import { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, doc, updateDoc, Timestamp } from 'firebase/firestore';
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
import { User, Phone, Mail, MapPin, Calendar, Award, CreditCard, Image as ImageIcon, Shield, Briefcase } from 'lucide-react';

interface TechnicianApproval {
  id: string;
  fullName: string;
  phone: string;
  email: string;
  district: string;
  state?: string;
  experienceYears: number;
  skills: string[];
  profilePhotoUrl?: string;
  aadhaarFrontUrl?: string;
  aadhaarBackUrl?: string;
  selfieWithAadhaarUrl?: string;
  portfolioImages?: string[];
  categoryId?: string;
  categoryName?: string;
  services?: string[];
  accountHolderName?: string;
  bankName?: string;
  accountNumber?: string;
  ifscCode?: string;
  profileCompletion: number;
  profileApprovalRequested: boolean;
  profileApproved: boolean;
  profileRejected: boolean;
  reviewRequestedAt: Timestamp;
  createdAt: Timestamp;
}

export default function TechnicianApprovalsPage() {
  const [technicians, setTechnicians] = useState<TechnicianApproval[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedTechnician, setSelectedTechnician] = useState<TechnicianApproval | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showApproveDialog, setShowApproveDialog] = useState(false);
  const [showRejectDialog, setShowRejectDialog] = useState(false);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [lightboxImage, setLightboxImage] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, 'technicians'),
      where('profileApprovalRequested', '==', true),
      where('profileApproved', '==', false),
      where('profileRejected', '==', false)
    );

    const unsubscribe = onSnapshot(q, 
      (snapshot) => {
        const technicianData = snapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        })) as TechnicianApproval[];
        
        setTechnicians(technicianData.sort((a, b) => 
          b.reviewRequestedAt.toMillis() - a.reviewRequestedAt.toMillis()
        ));
        setLoading(false);
        setError(null);
      },
      (err) => {
        console.error('Error fetching technician approvals:', err);
        setError('Failed to load technician approvals');
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  const handleApprove = async (technicianId: string) => {
    setProcessingId(technicianId);
    try {
      await updateDoc(doc(db, 'technicians', technicianId), {
        profileApproved: true,
        profileApprovalRequested: false,
        profileRejected: false,
        status: 'active',
        approvedAt: Timestamp.now(),
        updatedAt: Timestamp.now()
      });
      setShowApproveDialog(false);
      setSelectedTechnician(null);
    } catch (error) {
      console.error('Error approving technician:', error);
      alert('Failed to approve technician');
    } finally {
      setProcessingId(null);
    }
  };

  const handleReject = async (technicianId: string) => {
    setProcessingId(technicianId);
    try {
      await updateDoc(doc(db, 'technicians', technicianId), {
        profileApproved: false,
        profileApprovalRequested: false,
        profileRejected: true,
        rejectedAt: Timestamp.now(),
        updatedAt: Timestamp.now()
      });
      setShowRejectDialog(false);
      setSelectedTechnician(null);
    } catch (error) {
      console.error('Error rejecting technician:', error);
      alert('Failed to reject technician');
    } finally {
      setProcessingId(null);
    }
  };

  const openDetailsModal = (technician: TechnicianApproval) => {
    setSelectedTechnician(technician);
    setShowDetailsModal(true);
  };

  const openApproveDialog = (technician: TechnicianApproval) => {
    setSelectedTechnician(technician);
    setShowApproveDialog(true);
  };

  const openRejectDialog = (technician: TechnicianApproval) => {
    setSelectedTechnician(technician);
    setShowRejectDialog(true);
  };

  if (loading) return <LoadingState />;
  if (error) return <ErrorState message={error} />;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Technician Approvals"
        description="Review and approve technician profiles"
      />

      {technicians.length === 0 ? (
        <EmptyState
          icon={Users}
          title="No Pending Approvals"
          description="All technician profiles have been reviewed"
        />
      ) : (
        <div className="grid gap-6">
          {technicians.map((technician) => (
            <Card key={technician.id} className="p-6">
              <div className="flex items-start justify-between">
                <div className="flex items-start space-x-4">
                  {technician.profilePhotoUrl && (
                    <img
                      src={technician.profilePhotoUrl}
                      alt={technician.fullName}
                      className="w-16 h-16 rounded-full object-cover"
                    />
                  )}
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-gray-900">
                      {technician.fullName}
                    </h3>
                    <p className="text-sm text-gray-600">{technician.phone}</p>
                    <p className="text-sm text-gray-600">{technician.email}</p>
                    <p className="text-sm text-gray-600">
                      {technician.district} • {technician.experienceYears} years experience
                    </p>
                    <div className="flex flex-wrap gap-1 mt-2">
                      {technician.skills.slice(0, 3).map((skill) => (
                        <Badge key={skill} variant="secondary" size="sm">
                          {skill}
                        </Badge>
                      ))}
                      {technician.skills.length > 3 && (
                        <Badge variant="secondary" size="sm">
                          +{technician.skills.length - 3} more
                        </Badge>
                      )}
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center space-x-2">
                  <Badge 
                    variant={technician.profileCompletion === 100 ? 'success' : 'warning'}
                  >
                    {technician.profileCompletion}% Complete
                  </Badge>
                </div>
              </div>

              <div className="flex items-center justify-between mt-4 pt-4 border-t border-gray-200">
                <p className="text-sm text-gray-500">
                  Requested: {technician.reviewRequestedAt.toDate().toLocaleDateString()}
                </p>
                
                <div className="flex space-x-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => openDetailsModal(technician)}
                  >
                    View Details
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => openRejectDialog(technician)}
                    disabled={processingId === technician.id}
                    className="text-red-600 border-red-200 hover:bg-red-50"
                  >
                    Reject
                  </Button>
                  <Button
                    size="sm"
                    onClick={() => openApproveDialog(technician)}
                    disabled={processingId === technician.id}
                    className="bg-green-600 hover:bg-green-700"
                  >
                    {processingId === technician.id ? 'Processing...' : 'Approve'}
                  </Button>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Enhanced Details Modal */}
      {selectedTechnician && (
        <Modal
          isOpen={showDetailsModal}
          onClose={() => setShowDetailsModal(false)}
          title="Technician Details"
          size="xl"
        >
          <div className="max-h-[80vh] overflow-y-auto">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Left Column */}
              <div className="space-y-6">
                {/* Basic Information */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <User className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Basic Information</h3>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Full Name</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedTechnician.fullName || 'Not Provided'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Phone</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedTechnician.phone || 'Not Provided'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Email</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedTechnician.email || 'Not Provided'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">District</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedTechnician.district || 'Not Provided'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Experience</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedTechnician.experienceYears || 0} years</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Profile Completion</label>
                      <div className="mt-1 flex items-center gap-2">
                        <div className="flex-1 bg-[#374151] rounded-full h-2">
                          <div 
                            className="bg-[#6366F1] h-2 rounded-full transition-all" 
                            style={{ width: `${selectedTechnician.profileCompletion}%` }}
                          />
                        </div>
                        <span className="text-sm text-[#E5E7EB] font-medium">{selectedTechnician.profileCompletion}%</span>
                      </div>
                    </div>
                  </div>
                  <div className="mt-4">
                    <label className="block text-sm font-medium text-[#9CA3AF]">Skills</label>
                    <div className="flex flex-wrap gap-2 mt-2">
                      {selectedTechnician.skills?.length > 0 ? (
                        selectedTechnician.skills.map((skill) => (
                          <Badge key={skill} variant="secondary" className="text-xs">
                            {skill}
                          </Badge>
                        ))
                      ) : (
                        <span className="text-sm text-[#6B7280]">Not Provided</span>
                      )}
                    </div>
                  </div>
                </div>

                {/* Profile Section */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <ImageIcon className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Profile</h3>
                  </div>
                  <div className="flex items-center gap-4">
                    {selectedTechnician.profilePhotoUrl ? (
                      <img
                        src={selectedTechnician.profilePhotoUrl}
                        alt="Profile"
                        className="w-20 h-20 rounded-full object-cover cursor-pointer hover:opacity-80 transition-opacity"
                        onClick={() => setLightboxImage(selectedTechnician.profilePhotoUrl!)}
                      />
                    ) : (
                      <div className="w-20 h-20 rounded-full bg-[#374151] flex items-center justify-center">
                        <User className="w-8 h-8 text-[#6B7280]" />
                      </div>
                    )}
                    <div>
                      <div className="mb-2">
                        <label className="block text-sm font-medium text-[#9CA3AF]">Technician ID</label>
                        <p className="text-sm text-[#E5E7EB] font-mono">{selectedTechnician.id}</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[#9CA3AF]">Registration Date</label>
                        <p className="text-sm text-[#E5E7EB]">{selectedTechnician.createdAt.toDate().toLocaleDateString()}</p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Work Information */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <Briefcase className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Work Information</h3>
                  </div>
                  <div className="grid grid-cols-1 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Primary Service Category</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedTechnician.categoryName || 'Not Provided'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Services Offered</label>
                      <div className="flex flex-wrap gap-2 mt-2">
                        {selectedTechnician.services?.length > 0 ? (
                          selectedTechnician.services.map((service, index) => (
                            <Badge key={index} variant="outline" className="text-xs">
                              {service}
                            </Badge>
                          ))
                        ) : (
                          <span className="text-sm text-[#6B7280]">Not Provided</span>
                        )}
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF]">Service Area</label>
                      <p className="mt-1 text-sm text-[#E5E7EB] font-medium">
                        {selectedTechnician.district}{selectedTechnician.state ? `, ${selectedTechnician.state}` : ''}
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Right Column */}
              <div className="space-y-6">
                {/* Identity Verification */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <Shield className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Identity Verification</h3>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF] mb-2">Aadhaar Front</label>
                      {selectedTechnician.aadhaarFrontUrl ? (
                        <img
                          src={selectedTechnician.aadhaarFrontUrl}
                          alt="Aadhaar Front"
                          className="w-full h-24 rounded-lg object-cover cursor-pointer hover:opacity-80 transition-opacity"
                          onClick={() => setLightboxImage(selectedTechnician.aadhaarFrontUrl!)}
                        />
                      ) : (
                        <div className="w-full h-24 rounded-lg bg-[#374151] flex items-center justify-center">
                          <span className="text-sm text-[#6B7280]">Not Provided</span>
                        </div>
                      )}
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[#9CA3AF] mb-2">Aadhaar Back</label>
                      {selectedTechnician.aadhaarBackUrl ? (
                        <img
                          src={selectedTechnician.aadhaarBackUrl}
                          alt="Aadhaar Back"
                          className="w-full h-24 rounded-lg object-cover cursor-pointer hover:opacity-80 transition-opacity"
                          onClick={() => setLightboxImage(selectedTechnician.aadhaarBackUrl!)}
                        />
                      ) : (
                        <div className="w-full h-24 rounded-lg bg-[#374151] flex items-center justify-center">
                          <span className="text-sm text-[#6B7280]">Not Provided</span>
                        </div>
                      )}
                    </div>
                    {selectedTechnician.selfieWithAadhaarUrl && (
                      <div className="col-span-2">
                        <label className="block text-sm font-medium text-[#9CA3AF] mb-2">Selfie with Aadhaar</label>
                        <img
                          src={selectedTechnician.selfieWithAadhaarUrl}
                          alt="Selfie with Aadhaar"
                          className="w-full h-32 rounded-lg object-cover cursor-pointer hover:opacity-80 transition-opacity"
                          onClick={() => setLightboxImage(selectedTechnician.selfieWithAadhaarUrl!)}
                        />
                      </div>
                    )}
                  </div>
                </div>

                {/* Portfolio */}
                <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                  <div className="flex items-center gap-2 mb-4">
                    <ImageIcon className="w-5 h-5 text-[#6366F1]" />
                    <h3 className="text-lg font-semibold text-[#E5E7EB]">Portfolio</h3>
                  </div>
                  {selectedTechnician.portfolioImages?.length > 0 ? (
                    <div className="grid grid-cols-3 gap-3">
                      {selectedTechnician.portfolioImages.map((image, index) => (
                        <img
                          key={index}
                          src={image}
                          alt={`Portfolio ${index + 1}`}
                          className="w-full h-20 rounded-lg object-cover cursor-pointer hover:opacity-80 transition-opacity"
                          onClick={() => setLightboxImage(image)}
                        />
                      ))}
                    </div>
                  ) : (
                    <div className="text-center py-8">
                      <ImageIcon className="w-12 h-12 text-[#6B7280] mx-auto mb-2" />
                      <span className="text-sm text-[#6B7280]">No portfolio images provided</span>
                    </div>
                  )}
                </div>

                {/* Bank Details */}
                {(selectedTechnician.accountHolderName || selectedTechnician.bankName || selectedTechnician.accountNumber || selectedTechnician.ifscCode) && (
                  <div className="bg-[#1F2937] rounded-lg p-6 border border-[#374151]">
                    <div className="flex items-center gap-2 mb-4">
                      <CreditCard className="w-5 h-5 text-[#6366F1]" />
                      <h3 className="text-lg font-semibold text-[#E5E7EB]">Bank Details</h3>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[#9CA3AF]">Account Holder</label>
                        <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedTechnician.accountHolderName || 'Not Provided'}</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[#9CA3AF]">Bank Name</label>
                        <p className="mt-1 text-sm text-[#E5E7EB] font-medium">{selectedTechnician.bankName || 'Not Provided'}</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[#9CA3AF]">Account Number</label>
                        <p className="mt-1 text-sm text-[#E5E7EB] font-mono">
                          {selectedTechnician.accountNumber ? `****${selectedTechnician.accountNumber.slice(-4)}` : 'Not Provided'}
                        </p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[#9CA3AF]">IFSC Code</label>
                        <p className="mt-1 text-sm text-[#E5E7EB] font-mono">{selectedTechnician.ifscCode || 'Not Provided'}</p>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Sticky Action Footer */}
            <div className="sticky bottom-0 bg-[#111827] border-t border-[#374151] p-6 mt-6 -mx-6 -mb-6">
              <div className="flex items-center justify-between">
                <div>
                  <span className="text-sm text-[#9CA3AF]">Technician ID:</span>
                  <span className="ml-2 text-sm text-[#E5E7EB] font-mono">{selectedTechnician.id}</span>
                </div>
                <div className="flex space-x-3">
                  <Button
                    variant="outline"
                    onClick={() => {
                      setShowDetailsModal(false);
                      openRejectDialog(selectedTechnician);
                    }}
                    className="text-red-400 border-red-400 hover:bg-red-400/10"
                  >
                    Reject
                  </Button>
                  <Button
                    onClick={() => {
                      setShowDetailsModal(false);
                      openApproveDialog(selectedTechnician);
                    }}
                    className="bg-green-600 hover:bg-green-700 text-white"
                  >
                    Approve
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </Modal>
      )}

      {/* Image Lightbox */}
      {lightboxImage && (
        <div 
          className="fixed inset-0 z-[60] bg-black/90 flex items-center justify-center p-4"
          onClick={() => setLightboxImage(null)}
        >
          <div className="relative max-w-4xl max-h-[90vh]">
            <img
              src={lightboxImage}
              alt="Preview"
              className="max-w-full max-h-full object-contain rounded-lg"
            />
            <button
              onClick={() => setLightboxImage(null)}
              className="absolute top-4 right-4 bg-black/50 hover:bg-black/70 text-white rounded-full p-2 transition-colors"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      )}

      {/* Approve Confirmation Dialog */}
      <ConfirmDialog
        isOpen={showApproveDialog}
        onCancel={() => setShowApproveDialog(false)}
        onConfirm={() => selectedTechnician && handleApprove(selectedTechnician.id)}
        title="Approve Technician"
        message={`Are you sure you want to approve ${selectedTechnician?.fullName}? They will be able to create and list services.`}
        confirmText="Approve"
      />

      {/* Reject Confirmation Dialog */}
      <ConfirmDialog
        isOpen={showRejectDialog}
        onCancel={() => setShowRejectDialog(false)}
        onConfirm={() => selectedTechnician && handleReject(selectedTechnician.id)}
        title="Reject Technician"
        message={`Are you sure you want to reject ${selectedTechnician?.fullName}? They will need to update their profile and resubmit.`}
        confirmText="Reject"
        variant="danger"
      />
    </div>
  );
}