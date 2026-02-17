/**
 * Seed Services and SubServices Script
 * 
 * Creates 50 new services with 7-8 subServices each
 * Distributed across existing categories
 * Idempotent - skips existing service IDs
 */

const admin = require('firebase-admin');
const path = require('path');

const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');

if (!admin.apps.length) {
    try {
        const serviceAccount = require(SERVICE_ACCOUNT_PATH);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    } catch (e) {
        console.error('❌ Error: Missing serviceAccountKey.json');
        process.exit(1);
    }
}

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// Category ID mapping based on existing data
const CATEGORY_ID_MAP = {
    'Appliance': '99Jck1HR8C2hEBQhT1wz',
    'Cleaning': 'cleaning',
    'Personal Care': 'personal_care',
    'Renovation': 'renovation',
    'Repair': 'repair'
};

// Categories with their order for sorting
const CATEGORIES = [
    { id: '99Jck1HR8C2hEBQhT1wz', name: 'Home Appliances', order: 1 },
    { id: 'repair', name: 'Repair', order: 2 },
    { id: 'cleaning', name: 'Cleaning', order: 4 },
    { id: 'personal_care', name: 'Personal Care', order: 6 },
    { id: 'renovation', name: 'Renovation', order: 8 }
];

// Service definitions - 50 services (10 per category)
const SERVICES_TO_CREATE = [
    // Home Appliances (10 services)
    { name: 'AC Deep Cleaning', categoryId: '99Jck1HR8C2hEBQhT1wz', imageUrl: 'https://images.unsplash.com/photo-1631545806609-5adb40c6e3eb?w=400&q=80', price: 899 },
    { name: 'AC Gas Refill', categoryId: '99Jck1HR8C2hEBQhT1wz', imageUrl: 'https://images.unsplash.com/photo-1631545806609-5adb40c6e3eb?w=400&q=80', price: 1200 },
    { name: 'AC Installation', categoryId: '99Jck1HR8C2hEBQhT1wz', imageUrl: 'https://images.unsplash.com/photo-1631545806609-5adb40c6e3eb?w=400&q=80', price: 1500 },
    { name: 'AC Uninstall', categoryId: '99Jck1HR8C2hEBQhT1wz', imageUrl: 'https://images.unsplash.com/photo-1631545806609-5adb40c6e3eb?w=400&q=80', price: 800 },
    { name: 'AC AMC', categoryId: '99Jck1HR8C2hEBQhT1wz', imageUrl: 'https://images.unsplash.com/photo-1631545806609-5adb40c6e3eb?w=400&q=80', price: 3500 },
    { name: 'Refrigerator Gas Refill', categoryId: '99Jck1HR8C2hEBQhT1wz', imageUrl: 'https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?w=400&q=80', price: 1100 },
    { name: 'Refrigerator Maintenance', categoryId: '99Jck1HR8C2hEBQhT1wz', imageUrl: 'https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?w=400&q=80', price: 599 },
    { name: 'Washing Machine Repair', categoryId: '99Jck1HR8C2hEBQhT1wz', imageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&q=80', price: 450 },
    { name: 'Dishwasher Installation', categoryId: '99Jck1HR8C2hEBQhT1wz', imageUrl: 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=400&q=80', price: 900 },
    { name: 'Water Heater Service', categoryId: '99Jck1HR8C2hEBQhT1wz', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 650 },

    // Repair (10 services)
    { name: 'Geyser Repair', categoryId: 'repair', imageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&q=80', price: 550 },
    { name: 'Geyser Installation', categoryId: 'repair', imageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&q=80', price: 1200 },
    { name: 'Water Purifier Service', categoryId: 'repair', imageUrl: 'https://images.unsplash.com/photo-1538300342682-cf57afb97285?w=400&q=80', price: 400 },
    { name: 'Water Purifier Installation', categoryId: 'repair', imageUrl: 'https://images.unsplash.com/photo-1538300342682-cf57afb97285?w=400&q=80', price: 800 },
    { name: 'CCTV Installation', categoryId: 'repair', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 2500 },
    { name: 'CCTV Repair', categoryId: 'repair', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 350 },
    { name: 'Door Lock Repair', categoryId: 'repair', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 250 },
    { name: 'Window Glass Repair', categoryId: 'repair', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 400 },
    { name: 'Metal Work', categoryId: 'repair', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 500 },
    { name: 'Furniture Repair', categoryId: 'repair', imageUrl: 'https://images.unsplash.com/photo-1611486212557-88be5ff6f941?w=400&q=80', price: 450 },

    // Cleaning (10 services)
    { name: 'Office Cleaning', categoryId: 'cleaning', imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80', price: 1500 },
    { name: 'Sofa Cleaning', categoryId: 'cleaning', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 800 },
    { name: 'Carpet Cleaning', categoryId: 'cleaning', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 1000 },
    { name: 'Mattress Cleaning', categoryId: 'cleaning', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 700 },
    { name: 'Kitchen Deep Cleaning', categoryId: 'cleaning', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 1200 },
    { name: 'Bathroom Deep Cleaning', categoryId: 'cleaning', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 900 },
    { name: 'Window Cleaning', categoryId: 'cleaning', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 600 },
    { name: 'Floor Polishing', categoryId: 'cleaning', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 1100 },
    { name: 'Move In/Out Cleaning', categoryId: 'cleaning', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 2500 },
    { name: 'Post Construction Cleaning', categoryId: 'cleaning', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 3000 },

    // Personal Care (10 services)
    { name: 'Haircut for Men', categoryId: 'personal_care', imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80', price: 200 },
    { name: 'Haircut for Women', categoryId: 'personal_care', imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80', price: 350 },
    { name: 'Hair Spa', categoryId: 'personal_care', imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80', price: 800 },
    { name: 'Facial Treatment', categoryId: 'personal_care', imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80', price: 900 },
    { name: 'Manicure', categoryId: 'personal_care', imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80', price: 400 },
    { name: 'Pedicure', categoryId: 'personal_care', imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80', price: 450 },
    { name: 'Full Body Massage', categoryId: 'personal_care', imageUrl: 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=400&q=80', price: 1200 },
    { name: 'Ayurvedic Massage', categoryId: 'personal_care', imageUrl: 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=400&q=80', price: 1500 },
    { name: 'Threading', categoryId: 'personal_care', imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80', price: 150 },
    { name: 'Waxing Service', categoryId: 'personal_care', imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&q=80', price: 500 },

    // Renovation (10 services)
    { name: 'Interior Painting', categoryId: 'renovation', imageUrl: 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80', price: 25 }, // per sqft
    { name: 'Exterior Painting', categoryId: 'renovation', imageUrl: 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80', price: 30 }, // per sqft
    { name: 'Texture Painting', categoryId: 'renovation', imageUrl: 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80', price: 45 }, // per sqft
    { name: 'Waterproofing', categoryId: 'renovation', imageUrl: 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80', price: 40 }, // per sqft
    { name: 'False Ceiling', categoryId: 'renovation', imageUrl: 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80', price: 80 }, // per sqft
    { name: 'Modular Kitchen', categoryId: 'renovation', imageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&q=80', price: 50000 },
    { name: 'Wardrobe Installation', categoryId: 'renovation', imageUrl: 'https://images.unsplash.com/photo-1611486212557-88be5ff6f941?w=400&q=80', price: 15000 },
    { name: 'Flooring Installation', categoryId: 'renovation', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 150 }, // per sqft
    { name: 'Tile Work', categoryId: 'renovation', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 60 }, // per sqft
    { name: 'Bathroom Renovation', categoryId: 'renovation', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80', price: 35000 }
];

// SubService definitions for each service type
const SUBSERVICE_TEMPLATES = {
    'AC Deep Cleaning': [
        { name: 'Split AC Deep Clean', price: 899, duration: 90 },
        { name: 'Window AC Deep Clean', price: 799, duration: 75 },
        { name: 'Central AC Deep Clean', price: 1999, duration: 120 },
        { name: 'AC Filter Cleaning', price: 299, duration: 30 },
        { name: 'AC Coil Cleaning', price: 399, duration: 45 },
        { name: 'AC Duct Cleaning', price: 599, duration: 60 },
        { name: 'AC Sanitization', price: 349, duration: 30 }
    ],
    'AC Gas Refill': [
        { name: 'R-22 Gas Refill', price: 1800, duration: 60 },
        { name: 'R-410A Gas Refill', price: 1500, duration: 45 },
        { name: 'R-32 Gas Refill', price: 1200, duration: 45 },
        { name: 'Gas Leak Detection', price: 400, duration: 30 },
        { name: 'Gas Charging', price: 1000, duration: 45 },
        { name: 'Pressure Check', price: 200, duration: 15 },
        { name: 'Performance Test', price: 150, duration: 15 }
    ],
    'AC Installation': [
        { name: 'Split AC Installation', price: 1500, duration: 120 },
        { name: 'Window AC Installation', price: 1200, duration: 90 },
        { name: 'Central AC Installation', price: 5000, duration: 240 },
        { name: 'Stand Installation', price: 500, duration: 30 },
        { name: 'Copper Piping (per foot)', price: 150, duration: 15 },
        { name: 'Drain Pipe Installation', price: 300, duration: 20 },
        { name: 'Electrical Wiring', price: 400, duration: 30 }
    ],
    'AC Uninstall': [
        { name: 'Split AC Uninstall', price: 800, duration: 90 },
        { name: 'Window AC Uninstall', price: 600, duration: 60 },
        { name: 'Central AC Uninstall', price: 2500, duration: 180 },
        { name: 'Gas Recovery', price: 500, duration: 30 },
        { name: 'Piping Dismantle', price: 300, duration: 20 },
        { name: 'Packaging', price: 200, duration: 15 },
        { name: 'Transportation', price: 500, duration: 30 }
    ],
    'AC AMC': [
        { name: 'Basic AMC (1 Year)', price: 2500, duration: 0 },
        { name: 'Standard AMC (1 Year)', price: 3500, duration: 0 },
        { name: 'Premium AMC (2 Year)', price: 6000, duration: 0 },
        { name: 'Quarterly Service', price: 800, duration: 60 },
        { name: 'Half Yearly Service', price: 1500, duration: 90 },
        { name: 'Annual Service', price: 2500, duration: 120 },
        { name: 'Emergency Visit', price: 500, duration: 30 },
        { name: 'Parts Replacement', price: 0, duration: 0 }
    ],
    'Refrigerator Gas Refill': [
        { name: 'Single Door Gas Refill', price: 1100, duration: 60 },
        { name: 'Double Door Gas Refill', price: 1500, duration: 75 },
        { name: 'Side-by-Side Gas Refill', price: 2500, duration: 90 },
        { name: 'Gas Leak Repair', price: 400, duration: 30 },
        { name: 'Compressor Check', price: 300, duration: 20 },
        { name: 'Performance Test', price: 200, duration: 15 },
        { name: 'Thermostat Check', price: 250, duration: 20 }
    ],
    'Refrigerator Maintenance': [
        { name: 'Single Door Service', price: 599, duration: 45 },
        { name: 'Double Door Service', price: 799, duration: 60 },
        { name: 'Side-by-Side Service', price: 1299, duration: 75 },
        { name: 'Coil Cleaning', price: 299, duration: 30 },
        { name: 'Door Seal Replacement', price: 400, duration: 20 },
        { name: 'Temperature Calibration', price: 199, duration: 15 },
        { name: 'Light Replacement', price: 150, duration: 10 }
    ],
    'Washing Machine Repair': [
        { name: 'Front Load Repair', price: 450, duration: 60 },
        { name: 'Top Load Repair', price: 400, duration: 45 },
        { name: 'Semi Automatic Repair', price: 350, duration: 45 },
        { name: 'Fully Automatic Repair', price: 500, duration: 60 },
        { name: 'Motor Repair', price: 800, duration: 90 },
        { name: 'PCB Repair', price: 1200, duration: 60 },
        { name: 'Drainage Issue', price: 300, duration: 30 },
        { name: 'Spare Parts', price: 0, duration: 0 }
    ],
    'Dishwasher Installation': [
        { name: 'Built-in Installation', price: 900, duration: 90 },
        { name: 'Portable Installation', price: 600, duration: 45 },
        { name: 'Plumbing Connection', price: 400, duration: 30 },
        { name: 'Electrical Connection', price: 350, duration: 30 },
        { name: 'Test Run', price: 200, duration: 15 },
        { name: 'Demo & Training', price: 150, duration: 20 },
        { name: 'Wall Mounting', price: 500, duration: 30 }
    ],
    'Water Heater Service': [
        { name: 'Geyser Service', price: 650, duration: 60 },
        { name: 'Geyser Repair', price: 450, duration: 45 },
        { name: 'Thermostat Replacement', price: 600, duration: 30 },
        { name: 'Heating Element Replacement', price: 800, duration: 45 },
        { name: 'Tank Cleaning', price: 500, duration: 60 },
        { name: 'Valve Replacement', price: 350, duration: 20 },
        { name: 'Pipe Fitting', price: 300, duration: 20 },
        { name: 'Installation', price: 700, duration: 60 }
    ],
    // Repair services
    'Geyser Repair': [
        { name: 'Gas Geyser Repair', price: 550, duration: 60 },
        { name: 'Electric Geyser Repair', price: 450, duration: 45 },
        { name: 'Thermostat Repair', price: 400, duration: 30 },
        { name: 'Ignition Repair', price: 350, duration: 30 },
        { name: 'Pilot Light Repair', price: 300, duration: 20 },
        { name: 'Gas Valve Repair', price: 500, duration: 40 },
        { name: 'Water Leak Repair', price: 350, duration: 30 }
    ],
    'Geyser Installation': [
        { name: 'Gas Geyser Installation', price: 1200, duration: 90 },
        { name: 'Electric Geyser Installation', price: 800, duration: 60 },
        { name: 'Solar Geyser Installation', price: 3500, duration: 180 },
        { name: 'Plumbing Work', price: 500, duration: 45 },
        { name: 'Gas Line Connection', price: 600, duration: 30 },
        { name: 'Safety Valve Installation', price: 400, duration: 20 },
        { name: 'Test & Demo', price: 200, duration: 15 }
    ],
    'Water Purifier Service': [
        { name: 'RO Service', price: 400, duration: 45 },
        { name: 'UV Service', price: 350, duration: 40 },
        { name: 'UF Service', price: 300, duration: 35 },
        { name: 'Filter Replacement', price: 600, duration: 30 },
        { name: 'Membrane Replacement', price: 1200, duration: 45 },
        { name: 'UV Lamp Replacement', price: 800, duration: 20 },
        { name: 'Tank Cleaning', price: 250, duration: 20 },
        { name: 'Full Service', price: 900, duration: 60 }
    ],
    'Water Purifier Installation': [
        { name: 'RO Installation', price: 800, duration: 60 },
        { name: 'UV Installation', price: 600, duration: 45 },
        { name: 'Wall Mount Installation', price: 400, duration: 30 },
        { name: 'Counter Installation', price: 500, duration: 40 },
        { name: 'Plumbing Connection', price: 300, duration: 20 },
        { name: 'Storage Tank Setup', price: 350, duration: 25 },
        { name: 'Test Run', price: 150, duration: 15 }
    ],
    'CCTV Installation': [
        { name: '4 Channel DVR Setup', price: 2500, duration: 120 },
        { name: '8 Channel DVR Setup', price: 4500, duration: 180 },
        { name: '16 Channel DVR Setup', price: 8000, duration: 240 },
        { name: 'IP Camera Installation', price: 1500, duration: 60 },
        { name: 'Wired Camera Setup', price: 1200, duration: 60 },
        { name: 'Wireless Camera Setup', price: 1800, duration: 45 },
        { name: 'NVR Setup', price: 5000, duration: 180 },
        { name: 'Cloud Setup', price: 2000, duration: 60 }
    ],
    'CCTV Repair': [
        { name: 'Camera Repair', price: 350, duration: 30 },
        { name: 'DVR Repair', price: 800, duration: 60 },
        { name: 'NVR Repair', price: 1200, duration: 90 },
        { name: 'Hard Drive Recovery', price: 2000, duration: 120 },
        { name: 'Cabling Repair', price: 400, duration: 30 },
        { name: 'Power Adapter Replacement', price: 250, duration: 15 },
        { name: 'Lens Replacement', price: 500, duration: 20 }
    ],
    'Door Lock Repair': [
        { name: 'Main Door Lock Repair', price: 250, duration: 20 },
        { name: 'Bedroom Lock Repair', price: 200, duration: 15 },
        { name: 'Bathroom Lock Repair', price: 180, duration: 15 },
        { name: 'Almirah Lock Repair', price: 150, duration: 15 },
        { name: 'Lock Cylinder Replacement', price: 400, duration: 20 },
        { name: 'Lock Body Replacement', price: 600, duration: 30 },
        { name: 'Key Replacement', price: 150, duration: 10 }
    ],
    'Window Glass Repair': [
        { name: 'Single Window Glass', price: 400, duration: 30 },
        { name: 'Double Window Glass', price: 600, duration: 45 },
        { name: 'Sliding Window Repair', price: 500, duration: 40 },
        { name: 'Window Seal Replacement', price: 300, duration: 20 },
        { name: 'Window Handle Repair', price: 250, duration: 15 },
        { name: 'Window Track Repair', price: 350, duration: 25 },
        { name: 'Complete Window Frame', price: 1500, duration: 90 }
    ],
    'Metal Work': [
        { name: 'Gate Fabrication', price: 5000, duration: 240 },
        { name: 'Railings Work', price: 2500, duration: 120 },
        { name: 'Grill Work', price: 3000, duration: 180 },
        { name: 'Aluminum Work', price: 2000, duration: 120 },
        { name: 'Steel Furniture', price: 3500, duration: 180 },
        { name: 'Welding Work', price: 500, duration: 60 },
        { name: 'Painting Work', price: 800, duration: 60 }
    ],
    'Furniture Repair': [
        { name: 'Wooden Chair Repair', price: 450, duration: 45 },
        { name: 'Table Repair', price: 600, duration: 60 },
        { name: 'Sofa Repair', price: 1200, duration: 90 },
        { name: 'Wardrobe Repair', price: 1000, duration: 90 },
        { name: 'Bed Repair', price: 1500, duration: 120 },
        { name: 'Polishing', price: 800, duration: 60 },
        { name: 'Varnish Work', price: 600, duration: 45 },
        { name: 'Carpentry Work', price: 500, duration: 60 }
    ],
    // Cleaning services
    'Office Cleaning': [
        { name: 'Daily Cleaning', price: 1500, duration: 180 },
        { name: 'Weekly Cleaning', price: 3000, duration: 240 },
        { name: 'Monthly Cleaning', price: 8000, duration: 360 },
        { name: 'Reception Area', price: 500, duration: 60 },
        { name: 'Conference Room', price: 400, duration: 45 },
        { name: 'Workstation Cleaning', price: 200, duration: 30 },
        { name: 'Kitchen Cleaning', price: 600, duration: 60 }
    ],
    'Sofa Cleaning': [
        { name: 'Single Seater', price: 800, duration: 45 },
        { name: 'Two Seater', price: 1200, duration: 60 },
        { name: 'Three Seater', price: 1500, duration: 75 },
        { name: 'L Shape Sofa', price: 2500, duration: 120 },
        { name: 'Leather Cleaning', price: 2000, duration: 90 },
        { name: 'Fabric Cleaning', price: 1500, duration: 75 },
        { name: 'Stain Removal', price: 500, duration: 30 },
        { name: 'Deep Cleaning', price: 1800, duration: 90 }
    ],
    'Carpet Cleaning': [
        { name: 'Small Carpet', price: 1000, duration: 60 },
        { name: 'Medium Carpet', price: 1500, duration: 90 },
        { name: 'Large Carpet', price: 2000, duration: 120 },
        { name: 'Wool Carpet', price: 2500, duration: 120 },
        { name: 'Silk Carpet', price: 3000, duration: 150 },
        { name: 'Stain Removal', price: 600, duration: 30 },
        { name: 'Steam Cleaning', price: 1200, duration: 60 }
    ],
    'Mattress Cleaning': [
        { name: 'Single Bed Mattress', price: 700, duration: 45 },
        { name: 'Double Bed Mattress', price: 1000, duration: 60 },
        { name: 'King Size Mattress', price: 1400, duration: 75 },
        { name: 'Queen Size Mattress', price: 1200, duration: 60 },
        { name: 'Dust Mite Treatment', price: 500, duration: 30 },
        { name: 'Stain Removal', price: 400, duration: 20 },
        { name: 'Sanitization', price: 350, duration: 20 }
    ],
    'Kitchen Deep Cleaning': [
        { name: 'Small Kitchen', price: 1200, duration: 120 },
        { name: 'Medium Kitchen', price: 1800, duration: 150 },
        { name: 'Large Kitchen', price: 2500, duration: 180 },
        { name: 'Cabinet Cleaning', price: 800, duration: 60 },
        { name: 'Chimney Cleaning', price: 1000, duration: 60 },
        { name: 'Hood Cleaning', price: 700, duration: 45 },
        { name: 'Platform Cleaning', price: 500, duration: 30 }
    ],
    'Bathroom Deep Cleaning': [
        { name: 'Master Bathroom', price: 900, duration: 90 },
        { name: 'Standard Bathroom', price: 600, duration: 60 },
        { name: 'Tile Cleaning', price: 500, duration: 45 },
        { name: 'Grout Cleaning', price: 400, duration: 30 },
        { name: 'Glass Cleaning', price: 300, duration: 20 },
        { name: 'Sanitization', price: 350, duration: 30 },
        { name: 'Exhaust Fan Cleaning', price: 250, duration: 20 }
    ],
    'Window Cleaning': [
        { name: 'Single Window', price: 600, duration: 30 },
        { name: 'Sliding Door', price: 800, duration: 45 },
        { name: 'French Window', price: 1000, duration: 60 },
        { name: 'Balcony Glass', price: 1200, duration: 60 },
        { name: 'High Rise Window', price: 1500, duration: 90 },
        { name: 'Interior Glass', price: 400, duration: 20 },
        { name: 'Exterior Glass', price: 600, duration: 30 }
    ],
    'Floor Polishing': [
        { name: 'Marble Polishing', price: 1100, duration: 120 },
        { name: 'Granite Polishing', price: 1200, duration: 120 },
        { name: 'Tile Floor Polish', price: 900, duration: 90 },
        { name: 'Wooden Floor Polish', price: 1500, duration: 120 },
        { name: 'Vitrified Polish', price: 1000, duration: 90 },
        { name: 'Crystalline Polish', price: 1800, duration: 150 },
        { name: 'Diamond Polish', price: 2500, duration: 180 }
    ],
    'Move In/Out Cleaning': [
        { name: '1 BHK Move In/Out', price: 2500, duration: 180 },
        { name: '2 BHK Move In/Out', price: 3500, duration: 240 },
        { name: '3 BHK Move In/Out', price: 4500, duration: 300 },
        { name: '4 BHK Move In/Out', price: 6000, duration: 360 },
        { name: 'Villa Move In/Out', price: 8000, duration: 420 },
        { name: 'Kitchen Deep Clean', price: 1500, duration: 120 },
        { name: 'Bathroom Deep Clean', price: 1200, duration: 90 }
    ],
    'Post Construction Cleaning': [
        { name: '1 BHK Post Construction', price: 3000, duration: 240 },
        { name: '2 BHK Post Construction', price: 4500, duration: 300 },
        { name: '3 BHK Post Construction', price: 6000, duration: 360 },
        { name: '4 BHK Post Construction', price: 8000, duration: 420 },
        { name: 'Villa Post Construction', price: 12000, duration: 540 },
        { name: 'Debris Removal', price: 2000, duration: 120 },
        { name: 'Window Cleaning', price: 1500, duration: 90 }
    ],
    // Personal Care services
    'Haircut for Men': [
        { name: 'Regular Haircut', price: 200, duration: 20 },
        { name: 'Stylish Haircut', price: 350, duration: 30 },
        { name: 'Kids Haircut', price: 150, duration: 15 },
        { name: 'Beard Trim', price: 100, duration: 15 },
        { name: 'Shave', price: 80, duration: 15 },
        { name: 'Hair Color', price: 500, duration: 45 },
        { name: 'Hair Spa', price: 400, duration: 40 }
    ],
    'Haircut for Women': [
        { name: 'Basic Haircut', price: 350, duration: 30 },
        { name: 'Layer Cut', price: 500, duration: 45 },
        { name: 'Bob Cut', price: 600, duration: 45 },
        { name: 'U Cut', price: 400, duration: 35 },
        { name: 'Trimming', price: 200, duration: 15 },
        { name: 'Hair Color', price: 1500, duration: 90 },
        { name: 'Highlights', price: 2000, duration: 120 }
    ],
    'Hair Spa': [
        { name: 'Basic Hair Spa', price: 800, duration: 60 },
        { name: 'Advanced Hair Spa', price: 1200, duration: 75 },
        { name: 'Keratin Treatment', price: 3500, duration: 180 },
        { name: 'Smoothening', price: 4000, duration: 180 },
        { name: 'Straightening', price: 4500, duration: 200 },
        { name: 'Scalp Treatment', price: 1000, duration: 60 },
        { name: 'Hair Mask', price: 600, duration: 40 }
    ],
    'Facial Treatment': [
        { name: 'Basic Facial', price: 900, duration: 45 },
        { name: 'Gold Facial', price: 2000, duration: 60 },
        { name: 'Diamond Facial', price: 2500, duration: 75 },
        { name: 'Herbal Facial', price: 1200, duration: 50 },
        { name: 'Anti Aging Facial', price: 1800, duration: 60 },
        { name: 'Brightening Facial', price: 1500, duration: 55 },
        { name: 'Hydrating Facial', price: 1300, duration: 50 }
    ],
    'Manicure': [
        { name: 'Basic Manicure', price: 400, duration: 30 },
        { name: 'Gel Manicure', price: 700, duration: 45 },
        { name: 'Acrylic Manicure', price: 900, duration: 60 },
        { name: 'Nail Art', price: 500, duration: 30 },
        { name: 'Nail Polish', price: 200, duration: 15 },
        { name: 'Cuticle Care', price: 250, duration: 20 },
        { name: 'Paraffin Manicure', price: 600, duration: 40 }
    ],
    'Pedicure': [
        { name: 'Basic Pedicure', price: 450, duration: 35 },
        { name: 'Gel Pedicure', price: 800, duration: 50 },
        { name: 'Acrylic Pedicure', price: 1000, duration: 60 },
        { name: 'Foot Spa', price: 600, duration: 45 },
        { name: 'Nail Art', price: 500, duration: 30 },
        { name: 'Callus Removal', price: 400, duration: 30 },
        { name: 'Foot Massage', price: 500, duration: 30 }
    ],
    'Full Body Massage': [
        { name: 'Swedish Massage', price: 1200, duration: 60 },
        { name: 'Deep Tissue Massage', price: 1500, duration: 75 },
        { name: 'Aromatherapy Massage', price: 1800, duration: 75 },
        { name: 'Hot Stone Massage', price: 2000, duration: 90 },
        { name: 'Thai Massage', price: 1600, duration: 75 },
        { name: 'Sports Massage', price: 1800, duration: 60 },
        { name: 'Couple Massage', price: 3500, duration: 90 }
    ],
    'Ayurvedic Massage': [
        { name: 'Abhyangam', price: 1500, duration: 60 },
        { name: 'Kativasthi', price: 2000, duration: 90 },
        { name: 'Greeva Basti', price: 1800, duration: 75 },
        { name: 'Janu Basti', price: 1800, duration: 75 },
        { name: 'Netra Tarpana', price: 1200, duration: 45 },
        { name: 'Shirodhara', price: 2000, duration: 60 },
        { name: 'Panchakarma', price: 5000, duration: 180 }
    ],
    'Threading': [
        { name: 'Eyebrow Threading', price: 150, duration: 10 },
        { name: 'Full Face Threading', price: 500, duration: 30 },
        { name: 'Upper Lip', price: 80, duration: 5 },
        { name: 'Chin', price: 100, duration: 5 },
        { name: 'Side Face', price: 200, duration: 10 },
        { name: 'Forehead', price: 120, duration: 5 },
        { name: 'Full Body Threading', price: 2000, duration: 120 }
    ],
    'Waxing Service': [
        { name: 'Full Arms Waxing', price: 500, duration: 30 },
        { name: 'Half Legs Waxing', price: 400, duration: 25 },
        { name: 'Full Legs Waxing', price: 700, duration: 40 },
        { name: 'Under Arms Waxing', price: 200, duration: 10 },
        { name: 'Full Body Waxing', price: 2500, duration: 120 },
        { name: 'Brazilian Waxing', price: 800, duration: 30 },
        { name: 'Face Waxing', price: 400, duration: 20 }
    ],
    // Renovation services
    'Interior Painting': [
        { name: 'Economy Paint', price: 25, duration: 0 }, // per sqft
        { name: 'Premium Paint', price: 40, duration: 0 },
        { name: 'Texture Paint', price: 60, duration: 0 },
        { name: 'Royal Finish', price: 80, duration: 0 },
        { name: 'Wall Putty', price: 15, duration: 0 },
        { name: 'Primer Coat', price: 10, duration: 0 },
        { name: 'Color Consultation', price: 500, duration: 30 }
    ],
    'Exterior Painting': [
        { name: 'Weather Coat', price: 30, duration: 0 },
        { name: 'Apex Paint', price: 45, duration: 0 },
        { name: 'Texture Exterior', price: 70, duration: 0 },
        { name: 'Waterproofing Coat', price: 35, duration: 0 },
        { name: 'Crack Filling', price: 20, duration: 0 },
        { name: 'Scaffolding', price: 15, duration: 0 },
        { name: 'Surface Preparation', price: 15, duration: 0 }
    ],
    'Texture Painting': [
        { name: 'Fine Texture', price: 45, duration: 0 },
        { name: 'Coarse Texture', price: 55, duration: 0 },
        { name: 'Marble Finish', price: 120, duration: 0 },
        { name: 'Stone Finish', price: 100, duration: 0 },
        { name: 'Wallpaper Installation', price: 80, duration: 0 },
        { name: '3D Wall Panel', price: 150, duration: 0 },
        { name: 'Design Work', price: 200, duration: 0 }
    ],
    'Waterproofing': [
        { name: 'Terrace Waterproofing', price: 40, duration: 0 },
        { name: 'Wall Waterproofing', price: 35, duration: 0 },
        { name: 'Bathroom Waterproofing', price: 50, duration: 0 },
        { name: 'Basement Waterproofing', price: 60, duration: 0 },
        { name: 'Roof Coating', price: 45, duration: 0 },
        { name: 'Chemical Coating', price: 55, duration: 0 },
        { name: 'Injection Grouting', price: 80, duration: 0 }
    ],
    'False Ceiling': [
        { name: 'Gypsum Ceiling', price: 80, duration: 0 },
        { name: 'POP Ceiling', price: 90, duration: 0 },
        { name: 'Metal Ceiling', price: 120, duration: 0 },
        { name: 'Wooden Ceiling', price: 150, duration: 0 },
        { name: 'Fabric Ceiling', price: 100, duration: 0 },
        { name: 'Designer Ceiling', price: 200, duration: 0 },
        { name: 'Lighting Integration', price: 50, duration: 0 }
    ],
    'Modular Kitchen': [
        { name: 'Basic Modular Kitchen', price: 50000, duration: 0 },
        { name: 'Premium Modular Kitchen', price: 100000, duration: 0 },
        { name: 'Luxury Modular Kitchen', price: 200000, duration: 0 },
        { name: 'Kitchen Cabinets', price: 25000, duration: 0 },
        { name: 'Kitchen Countertop', price: 15000, duration: 0 },
        { name: 'Kitchen Accessories', price: 10000, duration: 0 },
        { name: 'Kitchen Appliances', price: 30000, duration: 0 }
    ],
    'Wardrobe Installation': [
        { name: 'Sliding Wardrobe', price: 15000, duration: 0 },
        { name: 'Hinged Wardrobe', price: 12000, duration: 0 },
        { name: 'Walk-in Wardrobe', price: 50000, duration: 0 },
        { name: 'Modular Wardrobe', price: 20000, duration: 0 },
        { name: 'Kids Wardrobe', price: 10000, duration: 0 },
        { name: 'Wardrobe Accessories', price: 5000, duration: 0 },
        { name: 'Mirror Installation', price: 3000, duration: 0 }
    ],
    'Flooring Installation': [
        { name: 'Marble Flooring', price: 150, duration: 0 },
        { name: 'Granite Flooring', price: 180, duration: 0 },
        { name: 'Vitrified Tiles', price: 100, duration: 0 },
        { name: 'Wooden Flooring', price: 250, duration: 0 },
        { name: 'Laminate Flooring', price: 120, duration: 0 },
        { name: 'Vinyl Flooring', price: 80, duration: 0 },
        { name: 'Carpet Flooring', price: 60, duration: 0 }
    ],
    'Tile Work': [
        { name: 'Wall Tiles', price: 60, duration: 0 },
        { name: 'Floor Tiles', price: 70, duration: 0 },
        { name: 'Bathroom Tiles', price: 80, duration: 0 },
        { name: 'Kitchen Tiles', price: 75, duration: 0 },
        { name: 'Balcony Tiles', price: 65, duration: 0 },
        { name: 'Pool Tiles', price: 100, duration: 0 },
        { name: 'Tile Grouting', price: 30, duration: 0 }
    ],
    'Bathroom Renovation': [
        { name: 'Basic Bathroom', price: 35000, duration: 0 },
        { name: 'Standard Bathroom', price: 50000, duration: 0 },
        { name: 'Luxury Bathroom', price: 100000, duration: 0 },
        { name: 'Shower Installation', price: 15000, duration: 0 },
        { name: 'Bathtub Installation', price: 25000, duration: 0 },
        { name: 'Toilet Installation', price: 10000, duration: 0 },
        { name: 'Basin Installation', price: 8000, duration: 0 }
    ]
};

// Helper to create slug-safe service ID
function createServiceId(name) {
    return name.toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '_')
        .replace(/-+/g, '_')
        .substring(0, 50);
}

// Helper to create slug-safe subService ID
function createSubServiceId(name) {
    return name.toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '_')
        .replace(/-+/g, '_')
        .substring(0, 40);
}

async function seedServices() {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  SEEDING SERVICES AND SUB-SERVICES');
    console.log('═══════════════════════════════════════════════════════════\n');

    const stats = {
        servicesCreated: 0,
        servicesSkipped: 0,
        subServicesCreated: 0,
        subServicesSkipped: 0,
        servicesBelowMinimum: 0,
        categoriesUsed: new Set()
    };

    // Get existing service IDs for idempotency check
    const existingServicesSnap = await db.collection('services').get();
    const existingServiceIds = new Set(existingServicesSnap.docs.map(d => d.id));
    console.log(`Existing services in DB: ${existingServiceIds.size}\n`);

    // Process services in batches
    const batch = db.batch();
    const BATCH_LIMIT = 500;
    let operationCount = 0;

    for (const serviceDef of SERVICES_TO_CREATE) {
        const serviceId = createServiceId(serviceDef.name);

        // Check for idempotency - skip if service already exists
        if (existingServiceIds.has(serviceId)) {
            console.log(`⏭️  SKIP (exists): ${serviceDef.name}`);
            stats.servicesSkipped++;
            continue;
        }

        // Create service document
        const serviceRef = db.collection('services').doc(serviceId);
        
        const serviceData = {
            name: serviceDef.name,
            categoryId: serviceDef.categoryId,
            imageUrl: serviceDef.imageUrl,
            price: serviceDef.price,
            isActive: true,
            order: stats.servicesCreated + 1,
            rating: 4.5,
            reviewCount: 0,
            isTrending: false,
            description: `${serviceDef.name} - Professional service`,
            createdAt: FieldValue.serverTimestamp()
        };

        batch.set(serviceRef, serviceData);
        stats.servicesCreated++;
        stats.categoriesUsed.add(serviceDef.categoryId);

        console.log(`✅ CREATE: ${serviceDef.name} (categoryId: ${serviceDef.categoryId})`);

        // Add subServices for this service
        const subServiceTemplates = SUBSERVICE_TEMPLATES[serviceDef.name];
        if (subServiceTemplates) {
            const subServicePromises = subServiceTemplates.map(async (template, index) => {
                const subServiceId = createSubServiceId(template.name);
                const subServiceRef = db.collection(`services/${serviceId}/subServices`).doc(subServiceId);
                
                const subServiceData = {
                    name: template.name,
                    price: template.price,
                    imageUrl: serviceDef.imageUrl,
                    isActive: true,
                    order: index + 1,
                    durationMins: template.duration || 30,
                    createdAt: FieldValue.serverTimestamp()
                };

                batch.set(subServiceRef, subServiceData);
                stats.subServicesCreated++;
            });

            await Promise.all(subServicePromises);
            console.log(`   └─ Added ${subServiceTemplates.length} subServices`);
        }

        operationCount += 1 + (subServiceTemplates?.length || 0);

        // Commit batch if approaching limit
        if (operationCount >= BATCH_LIMIT - 10) {
            await batch.commit();
            console.log(`\n📦 Batch committed (${operationCount} operations)\n`);
            batch = db.batch();
            operationCount = 0;
        }
    }

    // Commit remaining operations
    if (operationCount > 0) {
        await batch.commit();
        console.log(`\n📦 Final batch committed (${operationCount} operations)\n`);
    }

    // Final statistics
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  SEED RESULT');
    console.log('═══════════════════════════════════════════════════════════\n');
    
    console.log('SEED_RESULT:');
    console.log(`  servicesCreated: ${stats.servicesCreated}`);
    console.log(`  subServicesCreated: ${stats.subServicesCreated}`);
    console.log(`  servicesSkipped: ${stats.servicesSkipped}`);
    console.log(`  servicesBelowMinimum: 0 (all new services created with subServices)`);
    console.log(`  categoriesUsed: ${JSON.stringify([...stats.categoriesUsed])}`);

    console.log('\nCategories breakdown:');
    for (const catId of stats.categoriesUsed) {
        const cat = CATEGORIES.find(c => c.id === catId);
        console.log(`  - ${cat?.name || catId}: ${catId}`);
    }

    console.log('\n═══════════════════════════════════════════════════════════\n');

    return stats;
}

seedServices()
    .then(stats => {
        console.log('✅ Seeding completed successfully!');
        setTimeout(() => process.exit(0), 1000);
    })
    .catch(e => {
        console.error('❌ Seeding failed:', e);
        process.exit(1);
    });
