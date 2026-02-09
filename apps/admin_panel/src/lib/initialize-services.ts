/**
 * Quick Service Initialization Function
 * 
 * This can be called from the admin panel's system tests page
 * to populate the database with all services
 */

import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';

export interface ServiceData {
    name: string;
    slug: string;
    category: string;
    icon: string;
    description: string;
    requiresInspection: boolean;
    inspectionCharge: number;
    inspectionDuration: number;
    isFeatured: boolean;
    order: number;
}

export interface SubServiceData {
    serviceId: string;
    name: string;
    slug: string;
    description: string;
    detailedDescription?: string;
    fixedPrice: number;
    estimatedDuration: number;
    warrantyDays?: number;
    requiredTools: string[];
    requiredCertifications: string[];
    skillLevel: 'basic' | 'intermediate' | 'advanced';
    requiresInspection: boolean;
    canBeAddedAfterInspection: boolean;
    order: number;
    tags: string[];
}

// Complete service catalog data
const SERVICES_CATALOG = [
    {
        service: {
            name: 'Air Conditioner',
            slug: 'ac',
            category: 'Appliances',
            icon: 'ac',
            description: 'AC repair, installation, gas refill, and maintenance services',
            requiresInspection: true,
            inspectionCharge: 99,
            inspectionDuration: 30,
            isFeatured: true,
            order: 1
        },
        subServices: [
            {
                name: 'Gas Refill (R22/R32/R410A)',
                slug: 'gas-refill',
                description: 'Complete gas refilling service for all AC types',
                detailedDescription: 'Professional gas refilling service using genuine refrigerant. Includes leak detection, pressure testing, and gas charging.',
                fixedPrice: 1499,
                estimatedDuration: 45,
                warrantyDays: 30,
                requiredTools: ['Manifold Gauge', 'Vacuum Pump', 'Gas Cylinder'],
                requiredCertifications: ['HVAC Certified'],
                skillLevel: 'intermediate' as const,
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                order: 1,
                tags: ['gas', 'refill', 'cooling', 'refrigerant']
            },
            {
                name: 'Capacitor Replacement',
                slug: 'capacitor-replacement',
                description: 'Replace faulty AC capacitor',
                detailedDescription: 'Replacement of defective capacitor with genuine part. Includes testing and warranty.',
                fixedPrice: 599,
                estimatedDuration: 30,
                warrantyDays: 90,
                requiredTools: ['Multimeter', 'Screwdriver Set'],
                requiredCertifications: [],
                skillLevel: 'basic' as const,
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                order: 2,
                tags: ['capacitor', 'electrical', 'not cooling']
            },
            {
                name: 'PCB Repair',
                slug: 'pcb-repair',
                description: 'AC circuit board repair or replacement',
                detailedDescription: 'Professional PCB diagnosis and repair. Includes component-level repair or full board replacement if needed.',
                fixedPrice: 2499,
                estimatedDuration: 90,
                warrantyDays: 60,
                requiredTools: ['Soldering Iron', 'Multimeter', 'PCB Testing Kit'],
                requiredCertifications: ['Electronics Certified'],
                skillLevel: 'advanced' as const,
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                order: 3,
                tags: ['pcb', 'circuit', 'electronics', 'not working']
            },
            {
                name: 'Fan Motor Replacement',
                slug: 'fan-motor-replacement',
                description: 'Replace indoor or outdoor fan motor',
                detailedDescription: 'Complete fan motor replacement with genuine parts. Includes testing and balancing.',
                fixedPrice: 1899,
                estimatedDuration: 60,
                warrantyDays: 90,
                requiredTools: ['Wrench Set', 'Screwdriver Set'],
                requiredCertifications: [],
                skillLevel: 'intermediate' as const,
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                order: 4,
                tags: ['fan', 'motor', 'noise', 'not cooling']
            },
            {
                name: 'AC Installation (Split)',
                slug: 'ac-installation-split',
                description: 'Complete split AC installation with piping',
                detailedDescription: 'Professional split AC installation including wall mounting, piping (up to 3 meters), wiring, and testing.',
                fixedPrice: 2999,
                estimatedDuration: 120,
                warrantyDays: 180,
                requiredTools: ['Drill Machine', 'Pipe Bender', 'Vacuum Pump'],
                requiredCertifications: ['HVAC Certified'],
                skillLevel: 'advanced' as const,
                requiresInspection: false,
                canBeAddedAfterInspection: false,
                order: 5,
                tags: ['installation', 'new', 'split ac']
            },
            {
                name: 'AC Uninstallation',
                slug: 'ac-uninstallation',
                description: 'Safe AC removal and gas recovery',
                detailedDescription: 'Professional AC uninstallation with gas recovery, safe dismounting, and optional storage.',
                fixedPrice: 899,
                estimatedDuration: 45,
                warrantyDays: 0,
                requiredTools: ['Manifold Gauge', 'Wrench Set'],
                requiredCertifications: [],
                skillLevel: 'intermediate' as const,
                requiresInspection: false,
                canBeAddedAfterInspection: false,
                order: 6,
                tags: ['uninstallation', 'removal', 'shifting']
            },
            {
                name: 'Deep Cleaning Service',
                slug: 'deep-cleaning',
                description: 'Complete AC deep cleaning with jet wash',
                detailedDescription: 'Thorough cleaning of indoor and outdoor units using jet wash. Includes filter cleaning, coil cleaning, and sanitization.',
                fixedPrice: 799,
                estimatedDuration: 60,
                warrantyDays: 0,
                requiredTools: ['Jet Spray', 'Cleaning Solution', 'Protective Cover'],
                requiredCertifications: [],
                skillLevel: 'basic' as const,
                requiresInspection: false,
                canBeAddedAfterInspection: true,
                order: 7,
                tags: ['cleaning', 'maintenance', 'smell', 'hygiene']
            }
        ]
    },
    // Add more services here (Fridge, Fan, etc.) - truncated for brevity
];

/**
 * Initialize all services and sub-services
 */
export async function initializeServiceCatalog(onProgress?: (message: string) => void) {
    const createService = httpsCallable(functions, 'createService');
    const createSubService = httpsCallable(functions, 'createSubService');

    const results = {
        servicesCreated: 0,
        subServicesCreated: 0,
        errors: [] as string[]
    };

    try {
        for (const catalogItem of SERVICES_CATALOG) {
            onProgress?.(`Creating service: ${catalogItem.service.name}...`);

            try {
                // Create service
                const serviceResult = await createService(catalogItem.service);
                const serviceId = (serviceResult.data as any).serviceId;
                results.servicesCreated++;

                // Create sub-services
                for (const subService of catalogItem.subServices) {
                    onProgress?.(`  Creating: ${subService.name}...`);

                    try {
                        await createSubService({
                            ...subService,
                            serviceId
                        });
                        results.subServicesCreated++;
                    } catch (error: any) {
                        const errorMsg = `Failed to create sub-service ${subService.name}: ${error.message}`;
                        results.errors.push(errorMsg);
                        onProgress?.(` ❌ ${errorMsg}`);
                    }
                }

                onProgress?.(`✅ ${catalogItem.service.name} complete\n`);
            } catch (error: any) {
                const errorMsg = `Failed to create service ${catalogItem.service.name}: ${error.message}`;
                results.errors.push(errorMsg);
                onProgress?.(` ❌ ${errorMsg}\n`);
            }
        }

        return results;
    } catch (error: any) {
        throw new Error(`Initialization failed: ${error.message}`);
    }
}

/**
 * Initialize global pricing configuration
 */
export async function initializePricingConfig() {
    const updatePricingConfig = httpsCallable(functions, 'updatePricingConfig');

    try {
        await updatePricingConfig({
            updates: {
                defaultInspectionCharge: 99,
                inspectionChargeRefundable: true,
                platformFeePercentage: 10,
                gstPercentage: 18,
                minBookingAmount: 50,
                maxBookingAmount: 50000,
                allowDynamicPricing: false,
                allowDiscounts: true
            }
        });

        return { success: true };
    } catch (error: any) {
        throw new Error(`Failed to initialize pricing config: ${error.message}`);
    }
}

/**
 * Complete initialization (pricing + services)
 */
export async function completeInitialization(onProgress?: (message: string) => void) {
    onProgress?.('═══════════════════════════════════════════════════════════');
    onProgress?.('  HomeFix Service Catalog Initialization');
    onProgress?.('  Urban Company Style - Platform-Controlled Pricing');
    onProgress?.('═══════════════════════════════════════════════════════════\n');

    // Step 1: Initialize pricing config
    onProgress?.('📋 Initializing global pricing configuration...');
    try {
        await initializePricingConfig();
        onProgress?.('✅ Pricing configuration created successfully\n');
    } catch (error: any) {
        onProgress?.(`❌ Failed to create pricing config: ${error.message}\n`);
        throw error;
    }

    // Step 2: Initialize services
    onProgress?.('🏗️  Initializing service catalog...\n');
    const results = await initializeServiceCatalog(onProgress);

    // Summary
    onProgress?.('\n═══════════════════════════════════════════════════════════');
    onProgress?.(`  ✅ INITIALIZATION COMPLETE`);
    onProgress?.(`  Services Created: ${results.servicesCreated}`);
    onProgress?.(`  Sub-Services Created: ${results.subServicesCreated}`);
    if (results.errors.length > 0) {
        onProgress?.(`  Errors: ${results.errors.length}`);
    }
    onProgress?.('═══════════════════════════════════════════════════════════\n');

    return results;
}
