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
    },

    // ============================================================================
    // HOME SECTIONS MANAGEMENT (Dynamic Home Screen)
    // ============================================================================

    /**
     * Manage Home Sections (add, update, delete, reorder)
     */
    manageHomeSections: async (data: {
        action: 'add' | 'update' | 'delete' | 'reorder';
        sectionId?: string;
        sectionData?: {
            title: string;
            type: 'horizontal' | 'grid' | 'banner';
            linkedCategoryId?: string;
            customServices?: string[];
            imageUrl?: string;
            isActive?: boolean;
            order?: number;
        };
        orders?: Array<{ id: string; order: number }>;
    }) => {
        const fn = httpsCallable(functions, 'admin_manageHomeSections');
        return await fn(data);
    },

    // ============================================================================
    // CATEGORY MANAGEMENT (categories collection)
    // ============================================================================

    /**
     * Manage Categories (add, update, delete, reorder)
     */
    manageCategory: async (data: {
        action: 'add' | 'update' | 'delete' | 'reorder';
        categoryId?: string;
        categoryData?: {
            name: string;
            imageUrl?: string;
            isActive?: boolean;
            order?: number;
        };
        orders?: Array<{ id: string; order: number }>;
        force?: boolean;
    }) => {
        const fn = httpsCallable(functions, 'admin_manageCategory');
        return await fn(data);
    },

    // ============================================================================
    // NESTED SERVICE MANAGEMENT (categories/{categoryId}/services)
    // ============================================================================

    /**
     * Manage Services under categories (add, update, delete, reorder)
     */
    manageNestedService: async (data: {
        action: 'add' | 'update' | 'delete' | 'reorder';
        categoryId: string;
        serviceId?: string;
        serviceData?: {
            name: string;
            imageUrl?: string;
            isActive?: boolean;
            order?: number;
        };
        orders?: Array<{ id: string; order: number }>;
        force?: boolean;
    }) => {
        const fn = httpsCallable(functions, 'admin_manageNestedService');
        return await fn(data);
    },

    // ============================================================================
    // NESTED SUBSERVICE MANAGEMENT (categories/{categoryId}/services/{serviceId}/subServices)
    // ============================================================================

    /**
     * Manage SubServices under services (add, update, delete, reorder)
     */
    manageNestedSubService: async (data: {
        action: 'add' | 'update' | 'delete' | 'reorder';
        categoryId: string;
        serviceId: string;
        subServiceId?: string;
        subServiceData?: {
            name: string;
            price: number;
            imageUrl?: string;
            isActive?: boolean;
            order?: number;
        };
        orders?: Array<{ id: string; order: number }>;
    }) => {
        const fn = httpsCallable(functions, 'admin_manageNestedSubService');
        return await fn(data);
    },

    // ============================================================================
    // SERVICE CATALOG MANAGEMENT (legacy flat services collection)
    // ============================================================================

    /**
     * Create a new service in the flat services collection
     */
    createService: async (serviceData: {
        name: string;
        slug: string;
        category: string;
        icon?: string;
        imageUrl?: string;
        description?: string;
        requiresInspection?: boolean;
        inspectionCharge?: number;
        inspectionDuration?: number;
        isFeatured?: boolean;
        order?: number;
    }) => {
        const fn = httpsCallable(functions, 'createService');
        return await fn(serviceData);
    },

    /**
     * Update an existing service
     */
    updateService: async (serviceId: string, updates: any) => {
        const fn = httpsCallable(functions, 'updateService');
        return await fn({ serviceId, updates });
    },

    /**
     * Delete (soft delete) a service
     */
    deleteService: async (serviceId: string) => {
        const fn = httpsCallable(functions, 'deleteService');
        return await fn({ serviceId });
    },

    /**
     * Create a new sub-service
     */
    createSubService: async (subServiceData: {
        serviceId: string;
        name: string;
        slug: string;
        description?: string;
        detailedDescription?: string;
        fixedPrice: number;
        estimatedDuration?: number;
        warrantyDays?: number;
        requiredTools?: string[];
        requiredCertifications?: string[];
        skillLevel?: string;
        requiresInspection?: boolean;
        canBeAddedAfterInspection?: boolean;
        order?: number;
        tags?: string[];
    }) => {
        const fn = httpsCallable(functions, 'createSubService');
        return await fn(subServiceData);
    },

    /**
     * Update a sub-service
     */
    updateSubService: async (subServiceId: string, updates: any) => {
        const fn = httpsCallable(functions, 'updateSubService');
        return await fn({ subServiceId, updates });
    },

    /**
     * Delete (soft delete) a sub-service
     */
    deleteSubService: async (subServiceId: string) => {
        const fn = httpsCallable(functions, 'deleteSubService');
        return await fn({ subServiceId });
    }
};
