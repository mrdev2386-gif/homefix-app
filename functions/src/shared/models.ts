
import { firestore } from 'firebase-admin';

// --- SERVICE CATALOG ---

/**
 * Main Service Category (e.g., AC, Fridge, Fan)
 * Platform-controlled, admin-only editable
 */
export interface Service {
    id: string;
    name: string; // e.g., "Air Conditioner", "Refrigerator"
    slug: string; // e.g., "ac", "fridge"
    category: string; // e.g., "Appliances", "Electronics"
    icon: string; // Icon URL or name
    imageUrl?: string; // Service image
    description: string;
    isActive: boolean;
    isFeatured: boolean; // Show on homepage
    order: number; // Display order

    // Inspection configuration
    requiresInspection: boolean; // Does this service category require inspection?
    inspectionCharge: number; // Fixed inspection charge (0 if no inspection)
    inspectionDuration: number; // Estimated inspection time in minutes

    // Metadata (auto-calculated)
    metadata: {
        totalSubServices: number;
        activeSubServices: number;
        activeTechnicians: number;
        avgRating: number;
        totalBookings: number;
    };

    // Admin tracking
    createdAt: firestore.Timestamp;
    updatedAt: firestore.Timestamp;
    createdBy?: string; // Admin UID
    updatedBy?: string; // Admin UID
}

/**
 * Sub-Service (specific repair/task under a service)
 * Example: "Gas Refill" under "AC"
 * Pricing is FIXED and ADMIN-CONTROLLED ONLY
 */
export interface SubService {
    id: string;
    serviceId: string; // Parent service ID
    serviceName: string; // Denormalized for quick access

    name: string; // e.g., "Gas Refill", "Capacitor Replacement"
    slug: string; // e.g., "gas-refill", "capacitor-replacement"
    description: string;
    detailedDescription?: string; // Longer description for detail page

    isActive: boolean;

    // PRICING - Platform controlled, immutable by technicians/customers
    fixedPrice: number; // The ONLY price for this sub-service
    currency: string; // Default: "INR"

    // Service details
    estimatedDuration: number; // In minutes
    warrantyDays?: number; // Warranty period if applicable

    // Requirements
    requiredTools: string[]; // Tools needed
    requiredCertifications: string[]; // Certifications needed
    skillLevel: 'basic' | 'intermediate' | 'advanced'; // Skill level required

    // Inspection
    requiresInspection: boolean; // Override service-level inspection requirement
    canBeAddedAfterInspection: boolean; // Can tech add this during inspection?

    // Display
    order: number; // Display order within service
    imageUrl?: string; // Sub-service image
    tags?: string[]; // Searchable tags

    // Metadata (auto-calculated)
    metadata: {
        totalBookings: number;
        avgRating: number;
        completionRate: number;
    };

    // Admin tracking
    createdAt: firestore.Timestamp;
    updatedAt: firestore.Timestamp;
    createdBy?: string; // Admin UID
    updatedBy?: string; // Admin UID
    priceHistory?: PriceHistoryEntry[]; // Track price changes
}

/**
 * Price History Entry
 * Tracks all price changes for audit and transparency
 */
export interface PriceHistoryEntry {
    oldPrice: number;
    newPrice: number;
    changedAt: firestore.Timestamp;
    changedBy: string; // Admin UID
    reason?: string; // Optional reason for price change
}

/**
 * Global Pricing Configuration
 * Stored in app_config/pricing
 */
export interface PricingConfig {
    // Global inspection settings
    defaultInspectionCharge: number;
    inspectionChargeRefundable: boolean; // If customer proceeds with repair

    // Platform fees
    platformFeePercentage: number; // % of booking value
    gstPercentage: number; // GST %

    // Payment settings
    currency: string; // Default: "INR"
    minBookingAmount: number;
    maxBookingAmount: number;

    // Pricing rules
    allowDynamicPricing: boolean; // Future: surge pricing
    allowDiscounts: boolean; // Can admins create discount codes?

    updatedAt: firestore.Timestamp;
    updatedBy: string; // Admin UID
}

// --- TECHNICIAN APPLICATION ---

export interface TechnicianApplication {
    id: string; // Same as auth UID
    phone: string;
    status: 'draft' | 'phone_verified' | 'kyc_submitted' | 'kyc_verified' | 'skills_verified' | 'submitted' | 'approved' | 'rejected';
    currentStep: number;

    personalDetails?: {
        name: string;
        dob: firestore.Timestamp;
        gender: string;
        photoUrl: string;
        address: string;
        coordinates: firestore.GeoPoint;
        city: string;
        serviceRadius: number;
    };

    kyc?: {
        idType: 'aadhaar' | 'pan' | 'driving_license';
        frontUrl: string;
        backUrl: string;
        selfieUrl: string;
        status: 'pending' | 'approved' | 'rejected';
        submittedAt: firestore.Timestamp;
        approvedAt?: firestore.Timestamp;
        approvedBy?: string;
        rejectionReason?: string;
        extractedData?: any;
    };

    skills?: {
        [serviceId: string]: {
            serviceId: string;
            serviceName: string;
            subServiceIds: string[];
            addedAt: firestore.Timestamp;
        };
    };

    experience?: {
        [serviceId: string]: {
            years: number;
            tools: string[];
            brands: string[];
            certifications: string[];
        };
    };

    availability?: {
        workingDays: number[]; // 1=Mon, 7=Sun
        startTime: string; // HH:mm
        endTime: string; // HH:mm
        emergencyAvailable: boolean;
        nightShift: boolean;
    };

    serviceArea?: {
        pinCodes: string[];
        radius: number;
        coordinates?: firestore.GeoPoint; // Center point
    };

    bankDetails?: {
        accountNumber: string; // Encrypted
        ifsc: string;
        holderName: string;
        upiId?: string;
        verified: boolean;
    };

    training?: {
        videoWatched: boolean;
        rulesAccepted: boolean;
        completedAt: firestore.Timestamp;
    };

    deviceInfo?: {
        deviceId: string;
        platform: string;
        appVersion: string;
    };

    createdAt: firestore.Timestamp;
    updatedAt: firestore.Timestamp;
    submittedAt?: firestore.Timestamp;
}

// --- TECHNICIAN PROFILE ---

export interface Technician extends Omit<TechnicianApplication, 'id' | 'currentStep' | 'bankDetails' | 'training' | 'status'> {
    // Fields from application are copied here upon approval

    isActive: boolean; // Technician toggle
    isOnline: boolean; // Real-time toggle
    status: 'active' | 'suspended' | 'pending_verification' | 'approved';

    rating: number;
    totalJobs: number;
    completedJobs: number;
    cancelledJobs: number;

    lastLocation?: firestore.GeoPoint;
    lastSeen?: firestore.Timestamp;
    geohash?: string; // For geo-queries

    fcmToken?: string;
}

// --- BOOKING ---

/**
 * Booking with Urban Company-style inspection and approval flow
 * Pricing is IMMUTABLE once customer approves
 */
export interface Booking {
    id: string;
    bookingNumber: string; // Human-readable booking number (e.g., "BK-2026-0001")

    // Parties
    customerId: string;
    customerName: string; // Denormalized
    customerPhone: string; // Denormalized

    technicianId?: string; // Assigned technician
    technicianName?: string; // Denormalized
    technicianPhone?: string; // Denormalized

    // Service
    serviceId: string;
    serviceName: string; // Denormalized

    // Location
    location: {
        address: string;
        coordinates: firestore.GeoPoint;
        pinCode?: string;
        city?: string;
    };

    // Booking flow status
    status:
    | 'pending'              // Created, waiting for tech assignment
    | 'pending_assignment'   // System is actively matching
    | 'assigned'             // Tech assigned, not yet accepted
    | 'accepted'             // Tech accepted
    | 'inspection_scheduled' // Inspection scheduled
    | 'inspection_in_progress' // Tech is inspecting
    | 'awaiting_approval'    // Waiting for customer approval of quote
    | 'approved'             // Customer approved quote
    | 'in_progress'          // Work in progress
    | 'completed'            // Work completed
    | 'cancelled'            // Cancelled by customer/tech/admin
    | 'rejected'             // Tech rejected or customer rejected quote
    | 'pending_admin_review'; // Escalated to admin

    // Inspection flow
    requiresInspection: boolean;
    inspectionCharge: number; // Locked at booking creation
    inspectionCompleted: boolean;
    inspectionCompletedAt?: firestore.Timestamp;
    inspectionNotes?: string; // Tech's inspection notes
    inspectionImages?: string[]; // Images from inspection

    // Pricing - IMMUTABLE after customer approval
    pricing: {
        // Inspection
        inspectionCharge: number;

        // Sub-services (itemized)
        subServices: BookingSubService[];

        // Calculations
        subtotal: number; // Sum of all sub-service prices
        platformFee: number;
        technicianAmount: number; // Share for the technician
        gst: number;
        total: number;

        // Pricing snapshot (locked at approval)
        pricingLockedAt?: firestore.Timestamp;
        pricingApprovedBy?: string; // Customer UID
    };

    // Customer approval
    customerApproval?: {
        approved: boolean;
        approvedAt: firestore.Timestamp;
        rejectedReason?: string; // If rejected
        approvalMethod: 'app' | 'sms' | 'call'; // How they approved
    };

    // Scheduling
    scheduledTime?: firestore.Timestamp;
    preferredTimeSlot?: string; // e.g., "morning", "afternoon", "evening"

    // Timestamps
    createdAt: firestore.Timestamp;
    assignedAt?: firestore.Timestamp;
    acceptedAt?: firestore.Timestamp;
    startedAt?: firestore.Timestamp;
    completedAt?: firestore.Timestamp;
    cancelledAt?: firestore.Timestamp;

    // Payment (Razorpay Integration)
    payment: {
        // Payment status
        status: 'pending' | 'processing' | 'paid' | 'failed' | 'refunded' | 'partially_refunded';

        // Razorpay Order (created before payment)
        razorpayOrderId?: string;
        razorpayOrderCreatedAt?: firestore.Timestamp;

        // Razorpay Payment (after successful payment)
        razorpayPaymentId?: string;
        razorpaySignature?: string; // For webhook verification

        // Payment details
        amountPaid?: number; // Actual amount paid (should match pricing.total)
        currency: string; // Default: "INR"
        paymentMethod?: 'card' | 'netbanking' | 'upi' | 'wallet'; // Razorpay method

        // Timestamps
        paidAt?: firestore.Timestamp;

        // Payment metadata
        receipt?: string; // Booking number used as receipt
        notes?: string; // Additional notes

        // Failure tracking
        failureReason?: string;
        failedAt?: firestore.Timestamp;
        retryCount?: number;
    };

    // Refund (if applicable)
    refund?: {
        status: 'pending' | 'processing' | 'processed' | 'failed';
        razorpayRefundId?: string;
        refundAmount: number;
        refundReason: string;
        requestedBy: string; // Admin UID
        requestedAt: firestore.Timestamp;
        processedAt?: firestore.Timestamp;
        failureReason?: string;
    };

    // Technician Payout (Manual initially)
    payout?: {
        status: 'pending' | 'processing' | 'paid' | 'failed' | 'on_hold';

        // Amount calculation
        totalAmount: number; // From pricing.total
        platformFee: number; // Platform's cut
        gst: number; // GST amount
        technicianAmount: number; // What technician receives

        // Payout details
        paidBy?: string; // Admin UID who marked as paid
        paidAt?: firestore.Timestamp;
        paymentMethod?: 'bank_transfer' | 'upi' | 'cash' | 'wallet';
        transactionId?: string; // Bank/UPI transaction ID

        // Notes
        notes?: string;
        onHoldReason?: string; // If on hold
    };

    // Cancellation
    cancellation?: {
        cancelledBy: 'customer' | 'technician' | 'admin' | 'system';
        cancelledAt: firestore.Timestamp;
        reason: string;
        refundEligible: boolean;
        refundAmount?: number;
    };

    // Rating & Feedback
    rating?: {
        stars: number; // 1-5
        feedback?: string;
        ratedBy: string; // Customer UID
        ratedAt: firestore.Timestamp;
    };

    // Admin controls
    admin?: {
        notes?: string;
        flagged: boolean;
        flagReason?: string;
        flaggedBy?: string;
        flaggedAt?: firestore.Timestamp;
    };

    // --- Top-level convenience fields (often denormalized or legacy) ---
    assignedTechnicianId?: string;
    assignedTechnicianName?: string;
    assignedTechnicianPhone?: string;
    paymentStatus?: 'pending' | 'processing' | 'paid' | 'failed' | 'refunded' | 'partially_refunded' | 'refund_pending';
    razorpayOrderId?: string;
    refundRequestedAt?: firestore.Timestamp;
    cancellationReason?: string;
    cancelledBy?: string;
    isRated?: boolean;
    ratingId?: string;
    slotId?: string;
    finalAmount?: number;
    serviceTitle?: string; // Denormalized
}

/**
 * Sub-service item in a booking
 * Pricing is locked from the master catalog at the time of selection
 */
export interface BookingSubService {
    subServiceId: string;
    subServiceName: string;
    description: string;

    // Price locked from catalog
    fixedPrice: number;
    quantity: number; // Usually 1, but can be more (e.g., 2 fans)
    totalPrice: number; // fixedPrice * quantity

    // Metadata
    addedBy: 'customer' | 'technician'; // Who added this item
    addedAt: firestore.Timestamp;
    addedDuringInspection: boolean; // Was this added after inspection?

    // Completion tracking
    completed: boolean;
    completedAt?: firestore.Timestamp;
    warrantyDays?: number;
    warrantyExpiresAt?: firestore.Timestamp;
}
