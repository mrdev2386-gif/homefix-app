'use client';

import { useState, useEffect } from 'react';
import { PageHeader, StatCard, Table, StatusBadge, Column } from '@/components/ui';
import { 
  Calendar, 
  Users, 
  DollarSign, 
  Clock, 
  FileText, 
  UserCheck,
  TrendingUp,
  IndianRupee,
  CheckCircle,
  XCircle
} from 'lucide-react';
import { db } from '@/lib/firebase';
import { 
  collection, 
  query, 
  where, 
  orderBy, 
  limit, 
  getDocs, 
  getCountFromServer,
  Timestamp 
} from 'firebase/firestore';
import { adminApi } from '@/lib/admin-api';

export default function DashboardPage() {
  const [stats, setStats] = useState({
    totalBookings: 0,
    pendingBookings: 0,
    customRequests: 0,
    pendingCustomRequests: 0,
    techApplications: 0,
    activeTechnicians: 0,
    totalCustomers: 0,
    completedBookings: 0,
    todayRevenue: 0,
    monthlyRevenue: 0,
  });
  const [pendingBookings, setPendingBookings] = useState<any[]>([]);
  const [recentBookings, setRecentBookings] = useState<any[]>([]);
  const [recentTechnicians, setRecentTechnicians] = useState<any[]>([]);
  const [recentReviews, setRecentReviews] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);

      // Fetch counts using count queries for efficiency
      const [
        totalBookingsSnap,
        pendingBookingsSnap,
        customRequestsSnap,
        pendingCustomRequestsSnap,
        techApplicationsSnap,
        activeTechniciansSnap,
        totalCustomersSnap,
        completedBookingsSnap,
      ] = await Promise.all([
        getCountFromServer(collection(db, 'bookings')),
        getCountFromServer(query(collection(db, 'bookings'), where('status', '==', 'pending_admin'))),
        getCountFromServer(collection(db, 'custom_requests')),
        getCountFromServer(query(collection(db, 'custom_requests'), where('status', '==', 'pending'))),
        getCountFromServer(query(collection(db, 'technicianApplications'), where('status', '==', 'pending'))),
        getCountFromServer(query(collection(db, 'technicians'), where('status', '==', 'approved'))),
        getCountFromServer(collection(db, 'customers')),
        getCountFromServer(query(collection(db, 'bookings'), where('status', '==', 'completed'))),
      ]);

      // Fetch limited lists for display
      const [
        pendingBookingsListSnap,
        recentBookingsSnap,
        recentTechSnap,
        reviewsSnap
      ] = await Promise.all([
        // Pending bookings (limited to 5)
        getDocs(query(
          collection(db, 'bookings'),
          where('status', '==', 'pending_admin'),
          orderBy('createdAt', 'desc'),
          limit(5)
        )),
        // Recent bookings (limited to 5)
        getDocs(query(
          collection(db, 'bookings'),
          orderBy('createdAt', 'desc'),
          limit(5)
        )),
        // Recent technicians (limited to 5)
        getDocs(query(
          collection(db, 'technicians'),
          where('status', '==', 'approved'),
          orderBy('createdAt', 'desc'),
          limit(5)
        )),
        // Recent reviews (limited to 5)
        getDocs(query(
          collection(db, 'reviews'),
          orderBy('createdAt', 'desc'),
          limit(5)
        )),
      ]);

      setStats({
        totalBookings: totalBookingsSnap.data().count,
        pendingBookings: pendingBookingsSnap.data().count,
        customRequests: customRequestsSnap.data().count,
        pendingCustomRequests: pendingCustomRequestsSnap.data().count,
        techApplications: techApplicationsSnap.data().count,
        activeTechnicians: activeTechniciansSnap.data().count,
        totalCustomers: totalCustomersSnap.data().count,
        completedBookings: completedBookingsSnap.data().count,
        todayRevenue: 12450, // TODO: replace with actual revenue query
        monthlyRevenue: 245678, // TODO: replace with actual revenue query
      });

      setPendingBookings(pendingBookingsListSnap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setRecentBookings(recentBookingsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setRecentTechnicians(recentTechSnap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setRecentReviews(reviewsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() })));

    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleApproveBooking = async (bookingId: string) => {
    try {
      await adminApi.approveBookingRequest(bookingId);
      await fetchDashboardData();
    } catch (error) {
      console.error('Error approving booking:', error);
    }
  };

  const handleRejectBooking = async (bookingId: string) => {
    try {
      await adminApi.rejectBookingRequest(bookingId, 'Rejected by admin');
      await fetchDashboardData();
    } catch (error) {
      console.error('Error rejecting booking:', error);
    }
  };

  const handleApproveTechnician = async (techId: string) => {
    try {
      await adminApi.approveTechnicianApp(techId);
      await fetchDashboardData();
    } catch (error) {
      console.error('Error approving technician:', error);
    }
  };

  const handleRejectTechnician = async (techId: string) => {
    try {
      await adminApi.rejectTechnicianApp(techId, 'Application rejected');
      await fetchDashboardData();
    } catch (error) {
      console.error('Error rejecting technician:', error);
    }
  };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    if (timestamp instanceof Timestamp) {
      return timestamp.toDate().toLocaleDateString();
    }
    return 'N/A';
  };

  const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'info' | 'default' => {
    const statusMap: Record<string, 'success' | 'warning' | 'error' | 'info' | 'default'> = {
      'pending_admin': 'warning',
      'approved': 'info',
      'in_progress': 'info',
      'completed': 'success',
      'cancelled': 'error',
    };
    return statusMap[status] || 'default';
  };

  const bookingColumns: Column[] = [
    { key: 'id', label: 'Booking ID', sortable: true },
    { 
      key: 'customerName', 
      label: 'Customer',
      render: (item) => <span className="text-sm text-[#E5E7EB]">{item.customerName || 'N/A'}</span>
    },
    { 
      key: 'serviceType', 
      label: 'Service',
      render: (item) => <span className="text-sm text-[#E5E7EB]">{item.serviceType || 'N/A'}</span>
    },
    { 
      key: 'status', 
      label: 'Status',
      render: (item) => {
        const status = item.status?.replace(/_/g, ' ') || 'Unknown';
        return <StatusBadge status={status.charAt(0).toUpperCase() + status.slice(1)} variant={getStatusVariant(item.status)} />
      }
    },
    {
      key: 'actions',
      label: 'Action',
      align: 'right',
      render: (item) => (
        item.status === 'pending_admin' ? (
          <div className="flex items-center gap-2 justify-end">
            <button
              onClick={() => handleApproveBooking(item.id)}
              className="px-3 py-1 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
            >
              <CheckCircle size={14} className="inline mr-1" />
              Approve
            </button>
            <button
              onClick={() => handleRejectBooking(item.id)}
              className="px-3 py-1 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
            >
              <XCircle size={14} className="inline mr-1" />
              Reject
            </button>
          </div>
        ) : null
      )
    },
  ];

  const technicianColumns: Column[] = [
    { 
      key: 'name', 
      label: 'Name',
      render: (item) => <span className="text-sm font-medium text-[#E5E7EB]">{item.name || 'N/A'}</span>
    },
    { 
      key: 'phone', 
      label: 'Phone',
      render: (item) => <span className="text-sm text-[#9CA3AF]">{item.phone || 'N/A'}</span>
    },
    { 
      key: 'city', 
      label: 'City',
      render: (item) => <span className="text-sm text-[#9CA3AF]">{item.city || item.district || 'N/A'}</span>
    },
    {
      key: 'status',
      label: 'Status',
      render: (item) => {
        const status = item.status === 'approved' ? 'Active' : item.status === 'pending' ? 'Pending' : item.status;
        const variant = item.status === 'approved' ? 'success' : item.status === 'pending' ? 'warning' : 'default';
        return <StatusBadge status={status} variant={variant} />
      }
    },
  ];

  const reviewColumns: Column[] = [
    { 
      key: 'customerName', 
      label: 'Customer',
      render: (item) => <span className="text-sm text-[#E5E7EB]">{item.customerName || 'N/A'}</span>
    },
    { 
      key: 'technicianName', 
      label: 'Technician',
      render: (item) => <span className="text-sm text-[#9CA3AF]">{item.technicianName || 'N/A'}</span>
    },
    { 
      key: 'rating', 
      label: 'Rating',
      render: (item) => (
        <div className="flex items-center gap-1">
          <span className="text-yellow-400">★</span>
          <span className="text-sm text-[#E5E7EB]">{item.rating || 'N/A'}</span>
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
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        description="Platform overview and operational insights"
      />

      {/* Key Metrics - Row 1 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Bookings"
          value={stats.totalBookings}
          icon={Calendar}
          color="purple"
        />
        <StatCard
          title="Pending Bookings"
          value={stats.pendingBookings}
          icon={Clock}
          color="orange"
        />
        <StatCard
          title="Active Technicians"
          value={stats.activeTechnicians}
          icon={Users}
          color="green"
        />
        <StatCard
          title="Total Customers"
          value={stats.totalCustomers}
          icon={Users}
          color="blue"
        />
      </div>

      {/* Key Metrics - Row 2 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Pending Applications"
          value={stats.techApplications}
          icon={UserCheck}
          color="orange"
        />
        <StatCard
          title="Pending Custom Requests"
          value={stats.pendingCustomRequests}
          icon={FileText}
          color="purple"
        />
        <StatCard
          title="Completed Bookings"
          value={stats.completedBookings}
          icon={CheckCircle}
          color="green"
        />
        <StatCard
          title="Monthly Revenue"
          value={`₹${stats.monthlyRevenue.toLocaleString()}`}
          icon={IndianRupee}
          color="green"
        />
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Pending Booking Approvals */}
        <div className="admin-card p-6">
          <h3 className="text-lg font-semibold text-[#E5E7EB] mb-4">Pending Booking Approvals</h3>
          <Table
            columns={bookingColumns}
            data={pendingBookings}
            loading={loading}
            emptyMessage="No pending bookings"
          />
        </div>

        {/* Recent Technicians */}
        <div className="admin-card p-6">
          <h3 className="text-lg font-semibold text-[#E5E7EB] mb-4">Recent Technicians</h3>
          <Table
            columns={technicianColumns}
            data={recentTechnicians}
            loading={loading}
            emptyMessage="No technicians found"
          />
        </div>
      </div>

      {/* Recent Reviews */}
      <div className="admin-card p-6">
        <h3 className="text-lg font-semibold text-[#E5E7EB] mb-4">Recent Reviews</h3>
        <Table
          columns={reviewColumns}
          data={recentReviews}
          loading={loading}
          emptyMessage="No reviews found"
        />
      </div>
    </div>
  );
}
