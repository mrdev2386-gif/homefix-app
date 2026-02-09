/**
 * Service Catalog Initialization Script
 * Run this from the functions directory using Firebase emulators
 * 
 * Usage: node -e "require('./lib/scripts/initialize-services').main()"
 */

const admin = require('firebase-admin');

// Initialize if not already initialized
if (!admin.apps.length) {
    admin.initializeApp({
        projectId: 'homefix-dev' // Required for emulator
    });
}

const db = admin.firestore();

// Use emulator if running locally
if (process.env.FIRESTORE_EMULATOR_HOST) {
    console.log('✅ Using Firestore Emulator:', process.env.FIRESTORE_EMULATOR_HOST);
} else {
    // Set emulator host if not set
    process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
    console.log('✅ Using Firestore Emulator: 127.0.0.1:8080');
}

// ============================================================================
// GLOBAL PRICING CONFIGURATION
// ============================================================================

const PRICING_CONFIG = {
    defaultInspectionCharge: 99,
    inspectionChargeRefundable: true,
    platformFeePercentage: 10,
    gstPercentage: 18,
    currency: 'INR',
    minBookingAmount: 50,
    maxBookingAmount: 50000,
    allowDynamicPricing: false,
    allowDiscounts: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: 'system'
};

// ============================================================================
// SERVICE CATEGORIES WITH SUB-SERVICES
// ============================================================================

const SERVICES_DATA = [
    // AC Service
    {
        service: {
            name: 'Air Conditioner',
            slug: 'ac',
            category: 'Appliances',
            icon: 'ac',
            description: 'AC repair, installation, gas refill, and maintenance services',
            isActive: true,
            isFeatured: true,
            order: 1,
            requiresInspection: true,
            inspectionCharge: 99,
            inspectionDuration: 30,
            metadata: { totalSubServices: 0, activeSubServices: 0, activeTechnicians: 0, avgRating: 0, totalBookings: 0 }
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
                skillLevel: 'intermediate',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
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
                skillLevel: 'basic',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
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
                skillLevel: 'advanced',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
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
                skillLevel: 'intermediate',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
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
                skillLevel: 'advanced',
                requiresInspection: false,
                canBeAddedAfterInspection: false,
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
                skillLevel: 'intermediate',
                requiresInspection: false,
                canBeAddedAfterInspection: false,
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
                skillLevel: 'basic',
                requiresInspection: false,
                canBeAddedAfterInspection: true,
                tags: ['cleaning', 'maintenance', 'smell', 'hygiene']
            }
        ]
    },
    // Refrigerator
    {
        service: {
            name: 'Refrigerator',
            slug: 'fridge',
            category: 'Appliances',
            icon: 'fridge',
            description: 'Fridge repair, gas refill, compressor replacement, and maintenance',
            isActive: true,
            isFeatured: true,
            order: 2,
            requiresInspection: true,
            inspectionCharge: 99,
            inspectionDuration: 30,
            metadata: { totalSubServices: 0, activeSubServices: 0, activeTechnicians: 0, avgRating: 0, totalBookings: 0 }
        },
        subServices: [
            {
                name: 'Cooling Issue Diagnosis & Repair',
                slug: 'cooling-issue',
                description: 'Fix refrigerator not cooling properly',
                detailedDescription: 'Complete diagnosis and repair of cooling issues including thermostat, sensor, and refrigerant level checks.',
                fixedPrice: 1299,
                estimatedDuration: 60,
                warrantyDays: 30,
                requiredTools: ['Multimeter', 'Thermometer', 'Leak Detector'],
                requiredCertifications: [],
                skillLevel: 'intermediate',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['cooling', 'not cold', 'warm']
            },
            {
                name: 'Compressor Replacement',
                slug: 'compressor-replacement',
                description: 'Replace faulty refrigerator compressor',
                detailedDescription: 'Professional compressor replacement with genuine parts. Includes gas charging and testing.',
                fixedPrice: 4999,
                estimatedDuration: 120,
                warrantyDays: 180,
                requiredTools: ['Welding Kit', 'Vacuum Pump', 'Manifold Gauge'],
                requiredCertifications: ['Refrigeration Certified'],
                skillLevel: 'advanced',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['compressor', 'not working', 'major repair']
            },
            {
                name: 'Thermostat Replacement',
                slug: 'thermostat-replacement',
                description: 'Replace defective thermostat',
                detailedDescription: 'Replacement of faulty thermostat with genuine part. Includes calibration and testing.',
                fixedPrice: 899,
                estimatedDuration: 45,
                warrantyDays: 90,
                requiredTools: ['Screwdriver Set', 'Multimeter'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['thermostat', 'temperature', 'control']
            },
            {
                name: 'Gas Refill',
                slug: 'gas-refill',
                description: 'Refrigerant gas refilling service',
                detailedDescription: 'Complete gas refilling with leak detection and pressure testing. Uses genuine refrigerant.',
                fixedPrice: 1799,
                estimatedDuration: 60,
                warrantyDays: 30,
                requiredTools: ['Manifold Gauge', 'Vacuum Pump', 'Gas Cylinder'],
                requiredCertifications: ['Refrigeration Certified'],
                skillLevel: 'intermediate',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['gas', 'refill', 'cooling']
            },
            {
                name: 'Door Seal Replacement',
                slug: 'door-seal-replacement',
                description: 'Replace worn-out door gasket',
                detailedDescription: 'Replacement of damaged door seal/gasket to prevent air leakage and improve cooling efficiency.',
                fixedPrice: 699,
                estimatedDuration: 30,
                warrantyDays: 60,
                requiredTools: ['Screwdriver Set', 'Adhesive'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: false,
                canBeAddedAfterInspection: true,
                tags: ['door', 'seal', 'gasket', 'air leak']
            },
            {
                name: 'Water Leakage Repair',
                slug: 'water-leakage',
                description: 'Fix water leaking from refrigerator',
                detailedDescription: 'Diagnosis and repair of water leakage issues including drain tube cleaning and defrost system repair.',
                fixedPrice: 799,
                estimatedDuration: 45,
                warrantyDays: 30,
                requiredTools: ['Pipe Cleaner', 'Screwdriver Set'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['water', 'leak', 'drain']
            }
        ]
    },
    // Ceiling Fan
    {
        service: {
            name: 'Ceiling Fan',
            slug: 'ceiling-fan',
            category: 'Appliances',
            icon: 'fan',
            description: 'Fan repair, installation, capacitor replacement, and maintenance',
            isActive: true,
            isFeatured: true,
            order: 3,
            requiresInspection: false,
            inspectionCharge: 0,
            inspectionDuration: 15,
            metadata: { totalSubServices: 0, activeSubServices: 0, activeTechnicians: 0, avgRating: 0, totalBookings: 0 }
        },
        subServices: [
            {
                name: 'Capacitor Replacement',
                slug: 'capacitor-replacement',
                description: 'Replace faulty fan capacitor',
                detailedDescription: 'Replacement of defective capacitor to restore fan speed and performance.',
                fixedPrice: 299,
                estimatedDuration: 20,
                warrantyDays: 90,
                requiredTools: ['Screwdriver Set', 'Tester'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: false,
                canBeAddedAfterInspection: false,
                tags: ['capacitor', 'slow', 'not working']
            },
            {
                name: 'Winding Repair/Replacement',
                slug: 'winding-repair',
                description: 'Motor winding repair or rewinding',
                detailedDescription: 'Professional motor winding repair or complete rewinding service with copper wire.',
                fixedPrice: 899,
                estimatedDuration: 60,
                warrantyDays: 180,
                requiredTools: ['Winding Machine', 'Multimeter'],
                requiredCertifications: [],
                skillLevel: 'advanced',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['winding', 'motor', 'burnt', 'not working']
            },
            {
                name: 'Regulator Replacement',
                slug: 'regulator-replacement',
                description: 'Replace fan speed regulator',
                detailedDescription: 'Replacement of faulty regulator with electronic or mechanical type as per requirement.',
                fixedPrice: 399,
                estimatedDuration: 25,
                warrantyDays: 90,
                requiredTools: ['Screwdriver Set', 'Tester'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: false,
                canBeAddedAfterInspection: false,
                tags: ['regulator', 'speed control', 'dimmer']
            },
            {
                name: 'Fan Installation',
                slug: 'fan-installation',
                description: 'New ceiling fan installation',
                detailedDescription: 'Complete ceiling fan installation including wiring, mounting, and testing. Hook installation included.',
                fixedPrice: 499,
                estimatedDuration: 45,
                warrantyDays: 90,
                requiredTools: ['Drill Machine', 'Screwdriver Set', 'Wire Stripper'],
                requiredCertifications: [],
                skillLevel: 'intermediate',
                requiresInspection: false,
                canBeAddedAfterInspection: false,
                tags: ['installation', 'new fan', 'mounting']
            },
            {
                name: 'Bearing Replacement & Lubrication',
                slug: 'bearing-replacement',
                description: 'Replace worn bearings and lubricate',
                detailedDescription: 'Replacement of worn-out bearings and complete lubrication to eliminate noise and improve performance.',
                fixedPrice: 599,
                estimatedDuration: 40,
                warrantyDays: 120,
                requiredTools: ['Bearing Puller', 'Lubricant'],
                requiredCertifications: [],
                skillLevel: 'intermediate',
                requiresInspection: false,
                canBeAddedAfterInspection: true,
                tags: ['bearing', 'noise', 'lubrication', 'wobbling']
            },
            {
                name: 'Noise Issue Repair',
                slug: 'noise-repair',
                description: 'Fix fan making unusual noise',
                detailedDescription: 'Diagnosis and repair of noise issues including blade balancing, bearing check, and motor inspection.',
                fixedPrice: 499,
                estimatedDuration: 35,
                warrantyDays: 60,
                requiredTools: ['Screwdriver Set', 'Balancing Kit'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['noise', 'sound', 'rattling', 'wobbling']
            }
        ]
    },
    // Washing Machine
    {
        service: {
            name: 'Washing Machine',
            slug: 'washing-machine',
            category: 'Appliances',
            icon: 'washing-machine',
            description: 'Washing machine repair, drum replacement, and maintenance',
            isActive: true,
            isFeatured: true,
            order: 4,
            requiresInspection: true,
            inspectionCharge: 99,
            inspectionDuration: 30,
            metadata: { totalSubServices: 0, activeSubServices: 0, activeTechnicians: 0, avgRating: 0, totalBookings: 0 }
        },
        subServices: [
            {
                name: 'Not Draining - Pump Repair',
                slug: 'drain-pump-repair',
                description: 'Fix drainage pump issue',
                detailedDescription: 'Repair or replacement of drainage pump to fix water draining issues.',
                fixedPrice: 1299,
                estimatedDuration: 60,
                warrantyDays: 90,
                requiredTools: ['Wrench Set', 'Multimeter'],
                requiredCertifications: [],
                skillLevel: 'intermediate',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['drain', 'pump', 'water', 'not draining']
            },
            {
                name: 'Motor Replacement',
                slug: 'motor-replacement',
                description: 'Replace washing machine motor',
                detailedDescription: 'Complete motor replacement with genuine parts. Includes testing and warranty.',
                fixedPrice: 3499,
                estimatedDuration: 90,
                warrantyDays: 180,
                requiredTools: ['Wrench Set', 'Screwdriver Set'],
                requiredCertifications: [],
                skillLevel: 'advanced',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['motor', 'not spinning', 'not working']
            },
            {
                name: 'PCB Repair',
                slug: 'pcb-repair',
                description: 'Circuit board repair or replacement',
                detailedDescription: 'Professional PCB diagnosis and repair for display and control issues.',
                fixedPrice: 2299,
                estimatedDuration: 75,
                warrantyDays: 60,
                requiredTools: ['Multimeter', 'Soldering Iron'],
                requiredCertifications: ['Electronics Certified'],
                skillLevel: 'advanced',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['pcb', 'display', 'control', 'electronics']
            },
            {
                name: 'Door Lock Replacement',
                slug: 'door-lock-replacement',
                description: 'Replace faulty door lock mechanism',
                detailedDescription: 'Replacement of defective door lock assembly to fix door not closing or locking issues.',
                fixedPrice: 899,
                estimatedDuration: 40,
                warrantyDays: 90,
                requiredTools: ['Screwdriver Set'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: false,
                canBeAddedAfterInspection: true,
                tags: ['door', 'lock', 'not closing']
            },
            {
                name: 'Water Inlet Valve Replacement',
                slug: 'inlet-valve-replacement',
                description: 'Replace water inlet valve',
                detailedDescription: 'Replacement of faulty water inlet valve to fix water filling issues.',
                fixedPrice: 799,
                estimatedDuration: 35,
                warrantyDays: 90,
                requiredTools: ['Wrench Set', 'Screwdriver Set'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: false,
                canBeAddedAfterInspection: true,
                tags: ['water', 'inlet', 'valve', 'not filling']
            }
        ]
    },
    // Microwave
    {
        service: {
            name: 'Microwave Oven',
            slug: 'microwave',
            category: 'Appliances',
            icon: 'microwave',
            description: 'Microwave repair, magnetron replacement, and maintenance',
            isActive: true,
            isFeatured: false,
            order: 5,
            requiresInspection: true,
            inspectionCharge: 99,
            inspectionDuration: 25,
            metadata: { totalSubServices: 0, activeSubServices: 0, activeTechnicians: 0, avgRating: 0, totalBookings: 0 }
        },
        subServices: [
            {
                name: 'Not Heating - Magnetron Replacement',
                slug: 'magnetron-replacement',
                description: 'Replace faulty magnetron',
                detailedDescription: 'Professional magnetron replacement to restore heating functionality.',
                fixedPrice: 2499,
                estimatedDuration: 60,
                warrantyDays: 90,
                requiredTools: ['Screwdriver Set', 'Multimeter'],
                requiredCertifications: ['Electronics Certified'],
                skillLevel: 'advanced',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['magnetron', 'not heating', 'not working']
            },
            {
                name: 'Turntable Motor Replacement',
                slug: 'turntable-motor',
                description: 'Replace turntable motor',
                detailedDescription: 'Replacement of turntable motor to fix rotation issues.',
                fixedPrice: 799,
                estimatedDuration: 30,
                warrantyDays: 90,
                requiredTools: ['Screwdriver Set'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: false,
                canBeAddedAfterInspection: true,
                tags: ['turntable', 'rotation', 'not rotating']
            },
            {
                name: 'Door Switch Replacement',
                slug: 'door-switch-replacement',
                description: 'Replace faulty door switch',
                detailedDescription: 'Replacement of defective door switch to fix door detection issues.',
                fixedPrice: 599,
                estimatedDuration: 25,
                warrantyDays: 60,
                requiredTools: ['Screwdriver Set', 'Multimeter'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: false,
                canBeAddedAfterInspection: true,
                tags: ['door', 'switch', 'not starting']
            },
            {
                name: 'Control Panel Repair',
                slug: 'control-panel-repair',
                description: 'Fix control panel or display issues',
                detailedDescription: 'Repair or replacement of control panel for button or display malfunctions.',
                fixedPrice: 1499,
                estimatedDuration: 45,
                warrantyDays: 60,
                requiredTools: ['Screwdriver Set', 'Multimeter'],
                requiredCertifications: [],
                skillLevel: 'intermediate',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['control', 'panel', 'display', 'buttons']
            }
        ]
    },
    // Water Purifier
    {
        service: {
            name: 'Water Purifier (RO)',
            slug: 'water-purifier',
            category: 'Appliances',
            icon: 'water-purifier',
            description: 'RO service, filter replacement, and installation',
            isActive: true,
            isFeatured: false,
            order: 6,
            requiresInspection: false,
            inspectionCharge: 0,
            inspectionDuration: 20,
            metadata: { totalSubServices: 0, activeSubServices: 0, activeTechnicians: 0, avgRating: 0, totalBookings: 0 }
        },
        subServices: [
            {
                name: 'Complete RO Service',
                slug: 'ro-service',
                description: 'Full RO servicing and maintenance',
                detailedDescription: 'Complete RO service including filter cleaning, membrane check, and sanitization.',
                fixedPrice: 599,
                estimatedDuration: 45,
                warrantyDays: 30,
                requiredTools: ['Wrench Set', 'Sanitizer'],
                requiredCertifications: [],
                skillLevel: 'intermediate',
                requiresInspection: false,
                canBeAddedAfterInspection: false,
                tags: ['service', 'maintenance', 'cleaning']
            },
            {
                name: 'Filter Replacement (Set of 3)',
                slug: 'filter-replacement',
                description: 'Replace pre-filters (sediment, carbon)',
                detailedDescription: 'Replacement of sediment and carbon pre-filters with genuine parts.',
                fixedPrice: 899,
                estimatedDuration: 30,
                warrantyDays: 180,
                requiredTools: ['Wrench Set'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: false,
                canBeAddedAfterInspection: false,
                tags: ['filter', 'replacement', 'cartridge']
            },
            {
                name: 'RO Membrane Replacement',
                slug: 'membrane-replacement',
                description: 'Replace RO membrane',
                detailedDescription: 'Replacement of RO membrane with genuine part. Includes flushing and testing.',
                fixedPrice: 1799,
                estimatedDuration: 40,
                warrantyDays: 365,
                requiredTools: ['Wrench Set'],
                requiredCertifications: [],
                skillLevel: 'intermediate',
                requiresInspection: false,
                canBeAddedAfterInspection: false,
                tags: ['membrane', 'ro', 'replacement']
            },
            {
                name: 'RO Installation',
                slug: 'ro-installation',
                description: 'New RO purifier installation',
                detailedDescription: 'Complete RO installation including wall mounting, plumbing, and testing.',
                fixedPrice: 799,
                estimatedDuration: 60,
                warrantyDays: 90,
                requiredTools: ['Drill Machine', 'Wrench Set', 'Pipe Cutter'],
                requiredCertifications: [],
                skillLevel: 'intermediate',
                requiresInspection: false,
                canBeAddedAfterInspection: false,
                tags: ['installation', 'new', 'setup']
            }
        ]
    },
    // Geyser
    {
        service: {
            name: 'Geyser / Water Heater',
            slug: 'geyser',
            category: 'Appliances',
            icon: 'geyser',
            description: 'Geyser repair, element replacement, and installation',
            isActive: true,
            isFeatured: false,
            order: 7,
            requiresInspection: true,
            inspectionCharge: 99,
            inspectionDuration: 25,
            metadata: { totalSubServices: 0, activeSubServices: 0, activeTechnicians: 0, avgRating: 0, totalBookings: 0 }
        },
        subServices: [
            {
                name: 'Heating Element Replacement',
                slug: 'element-replacement',
                description: 'Replace faulty heating element',
                detailedDescription: 'Replacement of defective heating element with genuine part. Includes testing.',
                fixedPrice: 1299,
                estimatedDuration: 45,
                warrantyDays: 90,
                requiredTools: ['Wrench Set', 'Multimeter'],
                requiredCertifications: [],
                skillLevel: 'intermediate',
                requiresInspection: true,
                canBeAddedAfterInspection: true,
                tags: ['element', 'not heating', 'heating']
            },
            {
                name: 'Thermostat Replacement',
                slug: 'thermostat-replacement',
                description: 'Replace geyser thermostat',
                detailedDescription: 'Replacement of faulty thermostat to fix temperature control issues.',
                fixedPrice: 799,
                estimatedDuration: 35,
                warrantyDays: 90,
                requiredTools: ['Screwdriver Set', 'Multimeter'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: false,
                canBeAddedAfterInspection: true,
                tags: ['thermostat', 'temperature', 'overheating']
            },
            {
                name: 'Safety Valve Replacement',
                slug: 'safety-valve-replacement',
                description: 'Replace pressure relief valve',
                detailedDescription: 'Replacement of safety/pressure relief valve to prevent leakage and ensure safety.',
                fixedPrice: 599,
                estimatedDuration: 30,
                warrantyDays: 60,
                requiredTools: ['Wrench Set', 'Teflon Tape'],
                requiredCertifications: [],
                skillLevel: 'basic',
                requiresInspection: false,
                canBeAddedAfterInspection: true,
                tags: ['valve', 'safety', 'leak', 'dripping']
            },
            {
                name: 'Geyser Installation',
                slug: 'geyser-installation',
                description: 'New geyser installation',
                detailedDescription: 'Complete geyser installation including wall mounting, plumbing, wiring, and testing.',
                fixedPrice: 999,
                estimatedDuration: 60,
                warrantyDays: 90,
                requiredTools: ['Drill Machine', 'Wrench Set', 'Wire Stripper'],
                requiredCertifications: [],
                skillLevel: 'intermediate',
                requiresInspection: false,
                canBeAddedAfterInspection: false,
                tags: ['installation', 'new', 'setup']
            }
        ]
    }
];

// ============================================================================
// INITIALIZATION FUNCTIONS
// ============================================================================

async function initializePricingConfig() {
    console.log('\n📋 Initializing global pricing configuration...');

    try {
        await db.collection('app_config').doc('pricing').set(PRICING_CONFIG);
        console.log('✅ Pricing configuration created successfully');
    } catch (error) {
        console.error('❌ Error creating pricing config:', error);
        throw error;
    }
}

async function initializeServices() {
    console.log('\n🏗️  Initializing service catalog...\n');

    const batch = db.batch();
    let serviceCount = 0;
    let subServiceCount = 0;

    for (const serviceData of SERVICES_DATA) {
        const serviceRef = db.collection('services').doc();
        const serviceId = serviceRef.id;

        const serviceDoc = {
            ...serviceData.service,
            id: serviceId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: 'system',
            metadata: {
                ...serviceData.service.metadata,
                totalSubServices: serviceData.subServices.length,
                activeSubServices: serviceData.subServices.length
            }
        };

        batch.set(serviceRef, serviceDoc);
        serviceCount++;

        console.log(`📦 Creating service: ${serviceData.service.name} (${serviceData.subServices.length} sub-services)`);

        for (const subService of serviceData.subServices) {
            const subServiceRef = db.collection('subServices').doc();
            const subServiceId = subServiceRef.id;

            const subServiceDoc = {
                ...subService,
                id: subServiceId,
                serviceId: serviceId,
                serviceName: serviceData.service.name,
                currency: 'INR',
                isActive: true,
                metadata: {
                    totalBookings: 0,
                    avgRating: 0,
                    completionRate: 0
                },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                createdBy: 'system',
                priceHistory: []
            };

            batch.set(subServiceRef, subServiceDoc);
            subServiceCount++;

            console.log(`  ├─ ${subService.name} - ₹${subService.fixedPrice}`);
        }

        console.log('');
    }

    try {
        await batch.commit();
        console.log(`\n✅ Successfully created ${serviceCount} services and ${subServiceCount} sub-services`);
    } catch (error) {
        console.error('❌ Error committing batch:', error);
        throw error;
    }
}

async function verifyInitialization() {
    console.log('\n🔍 Verifying initialization...\n');

    const pricingDoc = await db.collection('app_config').doc('pricing').get();
    console.log(`✅ Pricing config: ${pricingDoc.exists ? 'EXISTS' : 'MISSING'}`);

    const servicesSnapshot = await db.collection('services').get();
    console.log(`✅ Services created: ${servicesSnapshot.size}`);

    const subServicesSnapshot = await db.collection('subServices').get();
    console.log(`✅ Sub-services created: ${subServicesSnapshot.size}`);

    console.log('\n📊 Summary by Service:\n');

    for (const serviceDoc of servicesSnapshot.docs) {
        const service = serviceDoc.data();
        const subServices = await db.collection('subServices')
            .where('serviceId', '==', serviceDoc.id)
            .get();

        console.log(`${service.name}:`);
        console.log(`  ├─ Sub-services: ${subServices.size}`);
        console.log(`  ├─ Inspection: ${service.requiresInspection ? `₹${service.inspectionCharge}` : 'Not required'}`);
        console.log(`  └─ Status: ${service.isActive ? 'Active' : 'Inactive'}\n`);
    }
}

async function main() {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  HomeFix Service Catalog Initialization');
    console.log('  Urban Company Style - Platform-Controlled Pricing');
    console.log('═══════════════════════════════════════════════════════════');

    try {
        await initializePricingConfig();
        await initializeServices();
        await verifyInitialization();

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('  ✅ INITIALIZATION COMPLETE');
        console.log('═══════════════════════════════════════════════════════════\n');

        process.exit(0);
    } catch (error) {
        console.error('\n❌ INITIALIZATION FAILED:', error);
        process.exit(1);
    }
}

module.exports = { main, SERVICES_DATA, PRICING_CONFIG };

// Auto-run if called directly
if (require.main === module) {
    main();
}
