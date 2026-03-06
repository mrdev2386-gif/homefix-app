'use client';

import { useState, useEffect } from 'react';
import { PageHeader, Table, StatusBadge, Column, ConfirmDialog } from '@/components/ui';
import { Search, Filter, X, Star, Trash2, Eye, EyeOff } from 'lucide-react';
import { db } from '@/lib/firebase';
import { collection, query, orderBy, limit as firestoreLimit, getDocs, doc, deleteDoc, updateDoc, Timestamp } from 'firebase/firestore';

interface Review {
  id: string;
  customerId: string;
  customerName: string;
  technicianId: string;
  technicianName: string;
  bookingId?: string;
  rating: number;
  comment?: string;
  reviewText?: string;
  isHidden?: boolean;
  createdAt: any;
}

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [filteredReviews, setFilteredReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [ratingFilter, setRatingFilter] = useState('all');
  const [selectedReview, setSelectedReview] = useState<Review | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    onConfirm: () => void;
    variant?: 'default' | 'danger';
  }>({ isOpen: false, title: '', message: '', onConfirm: () => {} });

  useEffect(() => {
    fetchReviews();
  }, []);

  useEffect(() => {
    filterReviews();
  }, [reviews, searchTerm, ratingFilter]);

  const fetchReviews = async () => {
    try {
      setLoading(true);
      const reviewsQuery = query(
        collection(db, 'reviews'),
        orderBy('createdAt', 'desc'),
        firestoreLimit(100)
      );
      const snapshot = await getDocs(reviewsQuery);
      const reviewsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as Review[];
      setReviews(reviewsData);
    } catch (error) {
      console.error('Error fetching reviews:', error);
    } finally {
      setLoading(false);
    }
  };

  const filterReviews = () => {
    let filtered = [...reviews];

    if (ratingFilter !== 'all') {
      filtered = filtered.filter(r => r.rating === parseInt(ratingFilter));
    }

    if (searchTerm) {
      filtered = filtered.filter(r => 
        r.customerName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.technicianName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.comment?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.reviewText?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredReviews(filtered);
  };

  const handleViewDetails = (review: Review) => {
    setSelectedReview(review);
    setShowDetailsModal(true);
  };

  const handleDelete = (reviewId: string) => {
    setConfirmDialog({
      isOpen: true,
      title: 'Delete Review',
      message: 'Are you sure you want to delete this review? This action cannot be undone.',
      variant: 'danger',
      onConfirm: async () => {
        try {
          await deleteDoc(doc(db, 'reviews', reviewId));
          await fetchReviews();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error deleting review:', error);
        }
      },
    });
  };

  const handleToggleHide = (review: Review) => {
    setConfirmDialog({
      isOpen: true,
      title: review.isHidden ? 'Show Review' : 'Hide Review',
      message: review.isHidden 
        ? 'Are you sure you want to show this review again?' 
        : 'Are you sure you want to hide this review? It will not be visible to customers.',
      onConfirm: async () => {
        try {
          await updateDoc(doc(db, 'reviews', review.id), {
            isHidden: !review.isHidden
          });
          await fetchReviews();
          setConfirmDialog({ ...confirmDialog, isOpen: false });
        } catch (error) {
          console.error('Error updating review:', error);
        }
      },
    });
  };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    if (timestamp instanceof Timestamp) {
      return timestamp.toDate().toLocaleDateString();
    }
    return 'N/A';
  };

  const getRatingStars = (rating: number) => {
    return '★'.repeat(rating) + '☆'.repeat(5 - rating);
  };

  const columns: Column[] = [
    { 
      key: 'customerName', 
      label: 'Customer',
      render: (item) => (
        <span className="text-sm text-[#E5E7EB]">{item.customerName || 'N/A'}</span>
      )
    },
    { 
      key: 'technicianName', 
      label: 'Technician',
      render: (item) => (
        <span className="text-sm text-[#E5E7EB]">{item.technicianName || 'N/A'}</span>
      )
    },
    { 
      key: 'rating', 
      label: 'Rating',
      render: (item) => (
        <div className="flex items-center gap-1">
          <span className="text-yellow-400">{getRatingStars(item.rating || 0)}</span>
          <span className="text-sm text-[#9CA3AF] ml-1">({item.rating || 0})</span>
        </div>
      )
    },
    { 
      key: 'comment', 
      label: 'Review',
      render: (item) => (
        <span className="text-sm text-[#9CA3AF] truncate max-w-xs block">
          {item.comment || item.reviewText || 'No comment'}
        </span>
      )
    },
    { 
      key: 'createdAt', 
      label: 'Date',
      render: (item) => (
        <span className="text-sm text-[#9CA3AF]">{formatDate(item.createdAt)}</span>
      )
    },
    {
      key: 'isHidden',
      label: 'Status',
      render: (item) => (
        <StatusBadge 
          status={item.isHidden ? 'Hidden' : 'Visible'} 
          variant={item.isHidden ? 'warning' : 'success'}
        />
      )
    },
    {
      key: 'actions',
      label: 'Actions',
      align: 'right',
      render: (item) => (
        <div className="flex items-center gap-2 justify-end">
          <button
            onClick={() => handleViewDetails(item)}
            className="p-2 text-[#9CA3AF] hover:text-[#E5E7EB] hover:bg-[#1F2937] rounded-lg transition-colors"
            title="View Details"
          >
            <Eye size={16} />
          </button>
          <button
            onClick={() => handleToggleHide(item)}
            className={`p-2 rounded-lg transition-colors ${item.isHidden ? 'text-green-400 hover:bg-green-500/10' : 'text-yellow-400 hover:bg-yellow-500/10'}`}
            title={item.isHidden ? 'Show Review' : 'Hide Review'}
          >
            {item.isHidden ? <Eye size={16} /> : <EyeOff size={16} />}
          </button>
          <button
            onClick={() => handleDelete(item.id)}
            className="p-2 text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
            title="Delete Review"
          >
            <Trash2 size={16} />
          </button>
        </div>
      )
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reviews"
        description="Manage and moderate customer reviews"
      />

      {/* Filters */}
      <div className="admin-card p-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-[#6B7280]" size={18} />
            <input
              type="text"
              placeholder="Search by customer, technician, or review..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input-field w-full pl-10 pr-4"
            />
            {searchTerm && (
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-[#6B7280] hover:text-[#E5E7EB]"
              >
                <X size={18} />
              </button>
            )}
          </div>

          {/* Rating Filter */}
          <div className="relative">
            <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 text-[#6B7280]" size={18} />
            <select
              value={ratingFilter}
              onChange={(e) => setRatingFilter(e.target.value)}
              className="input-field w-full pl-10 pr-4 appearance-none"
            >
              <option value="all">All Ratings</option>
              <option value="5">5 Stars</option>
              <option value="4">4 Stars</option>
              <option value="3">3 Stars</option>
              <option value="2">2 Stars</option>
              <option value="1">1 Star</option>
            </select>
          </div>

          {/* Results Count */}
          <div className="flex items-center justify-end">
            <span className="text-sm text-[#9CA3AF]">
              Showing {filteredReviews.length} of {reviews.length} reviews
            </span>
          </div>
        </div>
      </div>

      {/* Reviews Table */}
      <div className="admin-card p-6">
        <Table
          columns={columns}
          data={filteredReviews}
          loading={loading}
          emptyMessage="No reviews found"
        />
      </div>

      {/* Review Details Modal */}
      {showDetailsModal && selectedReview && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="sticky top-0 bg-[#111827] border-b border-[#1F2937] p-6 flex items-center justify-between">
              <h2 className="text-xl font-bold text-[#E5E7EB]">Review Details</h2>
              <button
                onClick={() => setShowDetailsModal(false)}
                className="text-[#6B7280] hover:text-[#E5E7EB]"
              >
                <X size={24} />
              </button>
            </div>
            <div className="p-6 space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-[#6B7280]">Customer</p>
                  <p className="text-sm font-medium text-[#E5E7EB]">{selectedReview.customerName || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-sm text-[#6B7280]">Technician</p>
                  <p className="text-sm font-medium text-[#E5E7EB]">{selectedReview.technicianName || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-sm text-[#6B7280]">Rating</p>
                  <div className="flex items-center gap-1">
                    <span className="text-yellow-400">{getRatingStars(selectedReview.rating || 0)}</span>
                    <span className="text-sm text-[#E5E7EB] ml-1">({selectedReview.rating || 0}/5)</span>
                  </div>
                </div>
                <div>
                  <p className="text-sm text-[#6B7280]">Date</p>
                  <p className="text-sm font-medium text-[#E5E7EB]">{formatDate(selectedReview.createdAt)}</p>
                </div>
                {selectedReview.bookingId && (
                  <div>
                    <p className="text-sm text-[#6B7280]">Booking ID</p>
                    <p className="text-sm font-medium text-[#6366F1]">{selectedReview.bookingId}</p>
                  </div>
                )}
                <div>
                  <p className="text-sm text-[#6B7280]">Status</p>
                  <StatusBadge 
                    status={selectedReview.isHidden ? 'Hidden' : 'Visible'} 
                    variant={selectedReview.isHidden ? 'warning' : 'success'}
                  />
                </div>
              </div>
              <div>
                <p className="text-sm text-[#6B7280] mb-2">Review</p>
                <p className="text-sm text-[#E5E7EB] bg-[#1F2937] p-4 rounded-lg">
                  {selectedReview.comment || selectedReview.reviewText || 'No comment provided'}
                </p>
              </div>
            </div>
          </div>
        </div>
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
    </div>
  );
}
