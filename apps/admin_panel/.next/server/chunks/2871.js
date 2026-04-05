"use strict";
exports.id = 2871;
exports.ids = [2871];
exports.modules = {

/***/ 2871:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   N: () => (/* binding */ adminApi)
/* harmony export */ });
/* harmony import */ var firebase_functions__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(3997);
/* harmony import */ var _firebase__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(4961);


/**
 * Centralized API for Admin Callable Functions
 */ const adminApi = {
    /**
     * Fetch Dashboard Statistics
     */ getDashboardStats: async ()=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_getDashboardStats");
        const result = await fn();
        return result.data;
    },
    /**
     * Approve a Technician Application
     */ approveTechnicianApplication: async (appId, approve, reason)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_approveTechnicianApplication");
        return await fn({
            appId,
            approve,
            reason
        });
    },
    /**
     * Approve/Verify an existing Technician
     */ approveTechnician: async (techId, approve, reason)=>{
        try {
            console.log("[ADMIN API] Calling admin_approveTechnician with:", {
                techId,
                approve,
                reason
            });
            const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_approveTechnician");
            const result = await fn({
                techId,
                approve,
                reason
            });
            console.log("[ADMIN API] Success:", result.data);
            return result.data;
        } catch (error) {
            console.error("[ADMIN API ❌] approveTechnician failed:", error);
            throw error;
        }
    },
    /**
     * Suspend a Technician
     */ suspendTechnician: async (technicianId, reason)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_manageUser");
        return await fn({
            uid: technicianId,
            action: "block",
            reason
        });
    },
    /**
     * Reactivate a Technician
     */ reactivateTechnician: async (technicianId)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_manageUser");
        return await fn({
            uid: technicianId,
            action: "unblock"
        });
    },
    /**
     * Toggle Technician Availability
     */ toggleTechAvailability: async (uid, isAvailable)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_toggleTechAvailability");
        return await fn({
            uid,
            isAvailable
        });
    },
    /**
     * Get Audit Logs
     */ getAuditLogs: async (limitCount = 50)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_getAuditLogs");
        const result = await fn({
            limit: limitCount
        });
        return result.data;
    },
    /**
     * Get paginated users
     */ getUsers: async (params)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_getUsers");
        const result = await fn(params);
        return result.data;
    },
    /**
     * Get user details
     */ getUserById: async (userId)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_getUserById");
        const result = await fn({
            userId
        });
        return result.data;
    },
    /**
     * Update user details
     */ updateUser: async (userId, updates)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_updateUser");
        return await fn({
            userId,
            updates
        });
    },
    /**
     * Block/Unblock user
     */ blockUser: async (userId, block)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_blockUser");
        return await fn({
            userId,
            block
        });
    },
    /**
     * Get paginated technicians
     */ getTechnicians: async (params)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_getTechnicians");
        const result = await fn(params);
        return result.data;
    },
    /**
     * Get technician details
     */ getTechnicianById: async (techId)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_getTechnicianById");
        const result = await fn({
            techId
        });
        return result.data;
    },
    /**
     * Update technician details
     */ updateTechnician: async (techId, updates)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_updateTechnician");
        return await fn({
            techId,
            updates
        });
    },
    /**
     * Manage Service Catalog
     */ manageService: async (data)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_manageService");
        return await fn(data);
    },
    /**
     * Manage Bookings (assign, cancel, complete)
     */ manageBooking: async (bookingId, action, payload = {})=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_manageBooking");
        return await fn({
            bookingId,
            action,
            ...payload
        });
    },
    /**
     * NEW FLOW: Approve a booking request
     * Moves booking from pending_admin to technician_pending
     */ approveBookingRequest: async (bookingId)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "adminApproveBooking");
        return await fn({
            bookingId,
            action: "approve"
        });
    },
    /**
     * NEW FLOW: Reject a booking request
     * Moves booking from pending_admin to admin_rejected
     */ rejectBookingRequest: async (bookingId, reason)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "adminApproveBooking");
        return await fn({
            bookingId,
            action: "reject",
            rejectionReason: reason
        });
    },
    /**
     * Approve a custom service request
     */ approveServiceRequest: async (requestId, technicianId)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "adminApproveServiceRequest");
        return await fn({
            requestId,
            action: "approve",
            technicianId
        });
    },
    /**
     * Reject a custom service request
     */ rejectServiceRequest: async (requestId, reason)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "adminApproveServiceRequest");
        return await fn({
            requestId,
            action: "reject",
            rejectionReason: reason
        });
    },
    // ============================================================================
    // CUSTOM REQUESTS MANAGEMENT (new Firebase-first architecture)
    // ============================================================================
    /**
     * Mark a custom request as reviewed
     */ markCustomRequestAsReviewed: async (requestId)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "markCustomRequestAsReviewed");
        return await fn({
            requestId
        });
    },
    /**
     * Convert a custom request to a booking
     */ convertCustomRequest: async (requestId)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "convertCustomRequest");
        return await fn({
            requestId
        });
    },
    /**
     * Reject a custom request
     */ rejectCustomRequest: async (requestId, adminNotes)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "rejectCustomRequest");
        return await fn({
            requestId,
            adminNotes
        });
    },
    // ============================================================================
    // TECHNICIAN APPLICATIONS (new Firebase-first architecture)
    // ============================================================================
    /**
     * Approve a technician application (new)
     */ approveTechnicianApp: async (uid)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "approveTechnician");
        return await fn({
            uid
        });
    },
    /**
     * Reject a technician application (new)
     */ rejectTechnicianApp: async (uid, reason)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "rejectTechnician");
        return await fn({
            uid,
            reason
        });
    },
    /**
     * Manage Reviews (hide, flag, delete)
     */ manageReview: async (reviewId, action, reason)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_manageReview");
        return await fn({
            reviewId,
            action,
            reason
        });
    },
    /**
     * Manage Disputes (resolve, escalate)
     */ manageDispute: async (disputeId, action, resolution)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_manageDispute");
        return await fn({
            disputeId,
            action,
            resolution
        });
    },
    /**
     * Generate
     */ generateReport: async (type, params = {})=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_generateReport");
        const result = await fn({
            type,
            params
        });
        return result.data;
    },
    // ============================================================================
    // TECHNICIAN SERVICE MANAGEMENT (Production Hardened)
    // ============================================================================
    /**
     * Approve a technician service
     * STEP 7: Production-ready service moderation
     */ approveService: async (serviceId)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_approveService");
        return await fn({
            serviceId,
            status: "approved"
        });
    },
    /**
     * Reject a technician service
     * STEP 7: Production-ready service moderation
     */ rejectService: async (serviceId, reason)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_rejectService");
        return await fn({
            serviceId,
            status: "rejected",
            reason
        });
    },
    /**
     * Disable a technician service (soft delete)
     * STEP 7: Production-ready service moderation
     */ disableService: async (serviceId)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_disableService");
        return await fn({
            serviceId,
            status: "disabled"
        });
    },
    /**
     * Get admin audit logs
     * STEP 5: Admin audit trail
     */ getAdminLogs: async (limit = 100)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_getAdminLogs");
        const result = await fn({
            limit
        });
        return result.data;
    },
    /**
     * Manage Coupons
     */ manageCoupon: async (action, couponData)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_manageCoupon");
        return await fn({
            action,
            ...couponData
        });
    },
    /**
     * Send Push Notification
     */ sendNotification: async (targetType, targetId, title, body)=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_sendNotification");
        return await fn({
            targetType,
            targetId,
            title,
            body
        });
    },
    /**
     * Get System Health
     */ getSystemHealth: async ()=>{
        const fn = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_0__/* .httpsCallable */ .V1)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .functions */ .wk, "admin_getSystemHealth");
        const result = await fn();
        return result.data;
    }
};


/***/ })

};
;