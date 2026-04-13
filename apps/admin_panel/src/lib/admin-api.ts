import { httpsCallable } from 'firebase/functions';
import { functions } from './firebaseClient';

/**
 * Interface for Dashboard Stats
 */
export interface DashboardStats {
    counters: {
        totalRevenue: number;
        revenueToday: number;
        bookingsToday: number;
        activeBookings: number;
        pendingKYC: number;
        pendingBookings: number;
        confirmedBookings: number;
        completedBookings: number;
        cancelledBookings: number;
        onlineTechnicians: number;
        totalTechnicians: number;
        totalCustomers: number;
    };
    chartData: Array<{
        name: string;
        revenue: number;
        bookings: number;
    }>;
}

/**
 * Centralized API for Admin Callable Functions
 */
export const adminApi = {
    /**
     * Fetch Dashboard Statistics
     */
    getDashboardStats: async (): Promise<DashboardStats> => {
        const fn = httpsCallable(functions, 'admin_getDashboardStats');
        const result = await fn();
        return result.data as DashboardStats;
    },

    /**
     * Approve a Technician Application
     */
    approveTechnicianApplication: async (appId: string, approve: boolean, reason?: string) => {
        const fn = httpsCallable(functions, 'admin_approveTechnicianApplication');
        return await fn({ appId, approve, reason });
    },

    /**
     * Approve/Verify an existing Technician
     */
    approveTechnician: async (techId: string, approve: boolean, reason?: string) => {
        try {
            console.log('[ADMIN API] Calling admin_approveTechnician with:', { techId, approve, reason });
            const fn = httpsCallable(functions, 'admin_approveTechnician');
            const result = await fn({ techId, approve, reason });
            console.log('[ADMIN API] Success:', result.data);
            return result.data;
        } catch (error: any) {
            console.error('[ADMIN API ❌] approveTechnician failed:', error);
            throw error;
        }
    },

    /**
     * Suspend a Technician
     */
    suspendTechnician: async (technicianId: string, reason: string) => {
        const fn = httpsCallable(functions, 'admin_manageUser');
        return await fn({
            uid: technicianId,
            action: 'block',
            reason
        });
    },

    /**
     * Reactivate a Technician
     */
    reactivateTechnician: async (technicianId: string) => {
        const fn = httpsCallable(functions, 'admin_manageUser');
        return await fn({
            uid: technicianId,
            action: 'unblock'
        });
    },

    /**
     * Toggle Technician Availability
     */
    toggleTechAvailability: async (uid: string, isAvailable: boolean) => {
        const fn = httpsCallable(functions, 'admin_toggleTechAvailability');
        return await fn({ uid, isAvailable });
    },

    /**
     * Get Audit Logs
     */
    getAuditLogs: async (limitCount: number = 50) => {
        const fn = httpsCallable(functions, 'admin_getAuditLogs');
        const result = await fn({ limit: limitCount });
        return result.data;
    },

    /**
     * Get paginated users
     */
    getUsers: async (params: { limit?: number; offset?: number; role?: string; status?: string; search?: string }) => {
        const fn = httpsCallable(functions, 'admin_getUsers');
        const result = await fn(params);
        return result.data as { users: any[]; total: number; limit: number; offset: number };
    },

    /**
     * Get user details
     */
    getUserById: async (userId: string) => {
        const fn = httpsCallable(functions, 'admin_getUserById');
        const result = await fn({ userId });
        return result.data;
    },

    /**
     * Update user details
     */
    updateUser: async (userId: string, updates: any) => {
        const fn = httpsCallable(functions, 'admin_updateUser');
        return await fn({ userId, updates });
    },

    /**
     * Block/Unblock user
     */
    blockUser: async (userId: string, block: boolean) => {
        const fn = httpsCallable(functions, 'admin_blockUser');
        return await fn({ userId, block });
    },

    /**
     * Get paginated technicians
     */
    getTechnicians: async (params: { limit?: number; offset?: number; status?: string; search?: string; city?: string; kycPending?: boolean }) => {
        const fn = httpsCallable(functions, 'admin_getTechnicians');
        const result = await fn(params);
        return result.data as { techs: any[]; total: number; limit: number; offset: number };
    },

    /**
     * Get technician details
     */
    getTechnicianById: async (techId: string) => {
        const fn = httpsCallable(functions, 'admin_getTechnicianById');
        const result = await fn({ techId });
        return result.data;
    },

    /**
     * Update technician details
     */
    updateTechnician: async (techId: string, updates: any) => {
        const fn = httpsCallable(functions, 'admin_updateTechnician');
        return await fn({ techId, updates });
    },

    /**
     * Manage Service Catalog
     */
    manageService: async (data: any) => {
        const fn = httpsCallable(functions, 'admin_manageService');
        return await fn(data);
    },

    /**
     * Manage Bookings (assign, cancel, complete)
     */
    manageBooking: async (bookingId: string, action: string, payload: any = {}) => {
        const fn = httpsCallable(functions, 'admin_manageBooking');
        return await fn({ bookingId, action, ...payload });
    },

    /**
     * NEW FLOW: Approve a booking request
     * Moves booking from pending_admin to technician_pending
     */
    approveBookingRequest: async (bookingId: string) => {
        const fn = httpsCallable(functions, 'adminApproveBooking');
        return await fn({ bookingId, action: 'approve' });
    },

    /**
     * NEW FLOW: Reject a booking request
     * Moves booking from pending_admin to admin_rejected
     */
    rejectBookingRequest: async (bookingId: string, reason?: string) => {
        const fn = httpsCallable(functions, 'adminApproveBooking');
        return await fn({ bookingId, action: 'reject', rejectionReason: reason });
    },

    /**
     * Approve a custom service request
     */
    approveServiceRequest: async (requestId: string, technicianId: string) => {
        const fn = httpsCallable(functions, 'adminApproveServiceRequest');
        return await fn({ requestId, action: 'approve', technicianId });
    },

    /**
     * Reject a custom service request
     */
    rejectServiceRequest: async (requestId: string, reason?: string) => {
        const fn = httpsCallable(functions, 'adminApproveServiceRequest');
        return await fn({ requestId, action: 'reject', rejectionReason: reason });
    },

    // ============================================================================
    // CUSTOM REQUESTS MANAGEMENT (new Firebase-first architecture)
    // ============================================================================

    /**
     * Mark a custom request as reviewed
     */
    markCustomRequestAsReviewed: async (requestId: string) => {
        const fn = httpsCallable(functions, 'markCustomRequestAsReviewed');
        return await fn({ requestId });
    },

    /**
     * Convert a custom request to a booking
     */
    convertCustomRequest: async (requestId: string) => {
        const fn = httpsCallable(functions, 'convertCustomRequest');
        return await fn({ requestId });
    },

    /**
     * Reject a custom request
     */
    rejectCustomRequest: async (requestId: string, adminNotes: string) => {
        const fn = httpsCallable(functions, 'rejectCustomRequest');
        return await fn({ requestId, adminNotes });
    },

    // ============================================================================
    // TECHNICIAN APPLICATIONS (new Firebase-first architecture)
    // ============================================================================

    /**
     * Approve a technician application (new)
     */
    approveTechnicianApp: async (uid: string) => {
        const fn = httpsCallable(functions, 'approveTechnician');
        return await fn({ uid });
    },

    /**
     * Reject a technician application (new)
     */
    rejectTechnicianApp: async (uid: string, reason: string) => {
        const fn = httpsCallable(functions, 'rejectTechnician');
        return await fn({ uid, reason });
    },

    /**
     * Manage Reviews (hide, flag, delete)
     */
    manageReview: async (reviewId: string, action: string, reason?: string) => {
        const fn = httpsCallable(functions, 'admin_manageReview');
        return await fn({ reviewId, action, reason });
    },

    /**
     * Manage Disputes (resolve, escalate)
     */
    manageDispute: async (disputeId: string, action: string, resolution?: string) => {
        const fn = httpsCallable(functions, 'admin_manageDispute');
        return await fn({ disputeId, action, resolution });
    },

    /**
     * Generate
     */
    generateReport: async (type: string, params: any = {}) => {
        const fn = httpsCallable(functions, 'admin_generateReport');
        const result = await fn({ type, params });
        return result.data;
    },

    // ============================================================================
    // TECHNICIAN SERVICE MANAGEMENT (Production Hardened)
    // ============================================================================

    /**
     * Approve a technician service
     * STEP 7: Production-ready service moderation
     */
    approveService: async (serviceId: string) => {
        const fn = httpsCallable(functions, 'admin_approveService');
        return await fn({ serviceId, status: 'approved' });
    },

    /**
     * Reject a technician service
     * STEP 7: Production-ready service moderation
     */
    rejectService: async (serviceId: string, reason?: string) => {
        const fn = httpsCallable(functions, 'admin_rejectService');
        return await fn({ serviceId, status: 'rejected', reason });
    },

    /**
     * Disable a technician service (soft delete)
     * STEP 7: Production-ready service moderation
     */
    disableService: async (serviceId: string) => {
        const fn = httpsCallable(functions, 'admin_disableService');
        return await fn({ serviceId, status: 'disabled' });
    },

    /**
     * Get admin audit logs
     * STEP 5: Admin audit trail
     */
    getAdminLogs: async (limit: number = 100) => {
        const fn = httpsCallable(functions, 'admin_getAdminLogs');
        const result = await fn({ limit });
        return result.data;
    },

    /**
     * Manage Coupons
     */
    manageCoupon: async (action: string, couponData?: any) => {
        const fn = httpsCallable(functions, 'admin_manageCoupon');
        return await fn({ action, ...couponData });
    },

    /**
     * Send Push Notification
     */
    sendNotification: async (targetType: string, targetId: string, title: string, body: string) => {
        const fn = httpsCallable(functions, 'admin_sendNotification');
        return await fn({ targetType, targetId, title, body });
    },

    /**
     * Get System Health
     */
    getSystemHealth: async () => {
        const fn = httpsCallable(functions, 'admin_getSystemHealth');
        const result = await fn();
        return result.data;
    }
};