
import { firestore } from 'firebase-admin';

// --- SERVICE CATALOG ---

export interface Service {
    id: string;
    name: string;
    category: string;
    icon: string;
    description: string;
    isActive: boolean;
    order: number;
    metadata: {
        totalSubServices: number;
        activeTechnicians: number;
        avgRating: number;
    };
    createdAt: firestore.Timestamp;
    updatedAt: firestore.Timestamp;
}

export interface SubService {
    id: string;
    serviceId: string;
    name: string;
    description: string;
    isActive: boolean;
    basePrice: number;
    estimatedDuration: number;
    requiredTools: string[];
    requiredCertifications: string[];
    order: number;
    createdAt: firestore.Timestamp;
    updatedAt: firestore.Timestamp;
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

export interface Technician extends Omit<TechnicianApplication, 'id' | 'currentStep' | 'bankDetails' | 'training'> {
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

export interface Booking {
    id: string;
    customerId: string;
    technicianId?: string;
    subServiceId: string;
    serviceId: string; // Redundant for easier querying

    location: {
        address: string;
        coordinates: firestore.GeoPoint;
    };

    status: 'pending' | 'accepted' | 'rejected' | 'in_progress' | 'completed' | 'cancelled';
    price: number;

    scheduledTime: firestore.Timestamp;

    createdAt: firestore.Timestamp;
    acceptedAt?: firestore.Timestamp;
    startedAt?: firestore.Timestamp;
    completedAt?: firestore.Timestamp;
    cancelledAt?: firestore.Timestamp;

    paymentStatus: 'pending' | 'paid' | 'refunded';
}
