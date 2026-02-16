import { httpsCallable } from 'firebase/functions';
import { functions } from './firebase';

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
        const fn = httpsCallable(functions, 'admin_approveTechnician');
        return await fn({ techId, approve, reason });
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
     * Manage Professional Video Reels
     */
    manageProfessionalVideos: async (data: any) => {
        const fn = httpsCallable(functions, 'admin_manageProfessionalVideos');
        return await fn(data);
    },

    /**
     * Manage Cleaning Categories (Essentials)
     */
    manageCleaningEssentials: async (data: any) => {
        const fn = httpsCallable(functions, 'admin_manageCleaningEssentials');
        return await fn(data);
    },
    /**
     * Manage Service Banners
     */
    manageServiceBanners: async (data: any) => {
        const fn = httpsCallable(functions, 'admin_manageServiceBanners');
        return await fn(data);
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
    getTechnicians: async (params: { limit?: number; offset?: number; status?: string; search?: string; city?: string }) => {
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
     * Manage Reviews (hide, flag, delete)
     */
    manageReview: async (reviewId: string, action: string, reason?: string) => {
        const fn = httpsCallable(functions, 'admin_manageReview');
        return await fn({ reviewId, action, reason });
    },

    /**
     * Manage Disputes (resolve, reject, refund)
     */
    manageDispute: async (disputeId: string, action: string, payload: any = {}) => {
        const fn = httpsCallable(functions, 'admin_manageDispute');
        return await fn({ disputeId, action, ...payload });
    },

    /**
     * Get Finance Data
     */
    getFinanceData: async (params: { limit?: number; startDate?: string; endDate?: string }) => {
        const fn = httpsCallable(functions, 'admin_getFinanceData');
        const result = await fn(params);
        return result.data;
    },

    /**
     * Process Refund
     */
    processRefund: async (bookingId: string, amount?: number, reason?: string) => {
        const fn = httpsCallable(functions, 'admin_processRefund');
        return await fn({ bookingId, amount, reason });
    }
};
