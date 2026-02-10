import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

// ============================================================================
// 1. DATA DEFINITIONS
// ============================================================================

const TECHNICIAN_CATEGORIES = [
    { id: 'cleaning', name: 'Cleaning Services', order: 1, subs: ['Deep Cleaning', 'Bathroom Cleaning', 'Kitchen Cleaning', 'Sofa Cleaning', 'Carpet Cleaning', 'Window Cleaning'] },
    { id: 'ac_repair', name: 'AC Services', order: 2, subs: ['AC Repair', 'AC Service', 'AC Installation', 'AC Uninstallation', 'Gas Refill', 'PCB Repair'] },
    { id: 'appliance', name: 'Appliances', order: 3, subs: ['Washing Machine', 'Refrigerator', 'Microwave', 'TV Repair', 'Water Purifier', 'Geyser Service'] },
    { id: 'electrician', name: 'Electrician', order: 4, subs: ['Switch & Socket', 'Fan Repair', 'Light Installation', 'MCB & Fuse', 'Inverter Service', 'Wiring'] },
    { id: 'plumber', name: 'Plumber', order: 5, subs: ['Leakage Repair', 'Tap Installation', 'Pipe Fitting', 'Water Tank', 'Basin & Sink', 'Toilet Repair'] },
    { id: 'carpenter', name: 'Carpenter', order: 6, subs: ['Furniture Repair', 'Door & Window', 'Cupboard Work', 'Bed Repair', 'Furniture Assembly', 'Polishing'] },
    { id: 'painter', name: 'Painting', order: 7, subs: ['Full Home Painting', 'Wall Texture', 'Waterproofing', 'Wall Putty', 'Exterior Painting', 'Wallpaper'] },
    { id: 'pest_control', name: 'Pest Control', order: 8, subs: ['Cockroach Control', 'Termite Control', 'Bed Bug Control', 'Ant Control', 'Rat Control', 'Mosquito Control'] },
    { id: 'home_security', name: 'Home Security', order: 9, subs: ['CCTV Installation', 'Smart Lock', 'Video Door Phone', 'Biometric System', 'Fire Alarm', 'Intruder Alarm'] },
    { id: 'smart_home', name: 'Smart Home', order: 10, subs: ['Home Automation', 'Smart Lighting', 'Voice Assistant Setup', 'Smart Curtains', 'Sensor Installation'] },
    { id: 'gardening', name: 'Gardening', order: 11, subs: ['Lawn Mowing', 'Plant Care', 'Landscaping', 'Vertical Garden', 'Pest Management', 'Fertilizing'] },
    { id: 'computer_repair', name: 'Computer Repair', order: 12, subs: ['Laptop Repair', 'Desktop Repair', 'OS Installation', 'Data Recovery', 'Virus Removal', 'Hardware Upgrade'] },
    { id: 'mens_salon', name: 'Men\'s Salon', order: 13, subs: ['Haircut', 'Shaving', 'Face Massage', 'Hair Color', 'Detan Pack', 'Head Massage'] },
    { id: 'womens_salon', name: 'Women\'s Salon', order: 14, subs: ['Haircut', 'Waxing', 'Facial', 'Manicure', 'Pedicure', 'Threading'] },
    { id: 'massage', name: 'Massage Therapy', order: 15, subs: ['Full Body Massage', 'Head Massage', 'Foot Massage', 'Back Massage', 'Stress Relief', 'Pain Relief'] },
    { id: 'makeup', name: 'Makeup Artist', order: 16, subs: ['Bridal Makeup', 'Party Makeup', 'Engagement Makeup', 'Saree Draping', 'Hairstyling'] },
    { id: 'mehendi', name: 'Mehendi Artist', order: 17, subs: ['Bridal Mehendi', 'Arabic Mehendi', 'Guest Mehendi', 'Figure Mehendi'] },
    { id: 'photographer', name: 'Photography', order: 18, subs: ['Wedding Shoot', 'Event Shoot', 'Product Shoot', 'Portrait Shoot', 'Baby Shoot'] },
    { id: 'event_planner', name: 'Event Planner', order: 19, subs: ['Birthday Decoration', 'Wedding Planning', 'Corporate Events', 'Baby Shower', 'Anniversary Decor'] },
    { id: 'driver', name: 'Driver Services', order: 20, subs: ['Hourly Driver', 'Outstation Driver', 'Permanent Driver', 'Valet Parking'] },
    { id: 'cook', name: 'Cooking Services', order: 21, subs: ['Home Cook', 'Partition Cook', 'Chef', 'Catering Service'] },
    { id: 'laundry', name: 'Laundry', order: 22, subs: ['Wash & Fold', 'Dry Cleaning', 'Ironing', 'Shoe Cleaning', 'Curtain Cleaning'] },
    { id: 'car_cleaning', name: 'Car Cleaning', order: 23, subs: ['Car Wash', 'Interior Cleaning', 'Car Polishing', 'Teflon Coating', 'Ceramic Coating'] },
    { id: 'chimney', name: 'Chimney Service', order: 24, subs: ['Chimney Cleaning', 'Chimney Repair', 'Chimney Installation'] },
    { id: 'hob_service', name: 'Hob & Stove', order: 25, subs: ['Hob Repair', 'Gas Stove Repair', 'Burner Cleaning', 'Pipeline Installation'] },
    { id: 'water_filter', name: 'RO Service', order: 26, subs: ['RO Installation', 'RO Repair', 'Filter Change', 'Membrane Change'] },
    { id: 'solar', name: 'Solar Services', order: 27, subs: ['Solar Panel Cleaning', 'Solar Installation', 'Inverter Connection'] },
    { id: 'tank_cleaning', name: 'Tank Cleaning', order: 28, subs: ['Overhead Tank', 'Underground Tank', 'Sump Cleaning'] },
    { id: 'civil_work', name: 'Civil Work', order: 29, subs: ['Tile Fixing', 'Grouting', 'Renovation', 'Flooring', 'Wall Repair'] },
    { id: 'fabrication', name: 'Fabrication', order: 30, subs: ['Grill Work', 'Gate Repair', 'Welding', 'Shed Work'] },
    { id: 'glass_work', name: 'Glass Work', order: 31, subs: ['Window Glass', 'Table Top', 'Mirror Fixing', 'Glass Partition'] },
    { id: 'aluminum', name: 'Aluminum Work', order: 32, subs: ['Sliding Windows', 'Partitions', 'Mosquito Mesh', 'Door Repair'] },
    { id: 'interior', name: 'Interior Design', order: 33, subs: ['Consultation', '2D/3D Design', 'Modular Kitchen', 'Wardrobe Design'] },
    { id: 'movers', name: 'Packers & Movers', order: 34, subs: ['House Shifting', 'Office Shifting', 'Vehicle Transport', 'Storage'] },
    { id: 'garbage', name: 'Junk Removal', order: 35, subs: ['E-Waste', 'Furniture Disposal', 'Debris Removal'] },
];

const CLEANING_ESSENTIALS = [
    { id: 'sofa_cleaning', title: "Sofa Deep Cleaning", imageUrl: "https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?auto=format&fit=crop&q=80&w=800", categoryKey: "cleaning", order: 1 },
    { id: 'bathroom_cleaning', title: "Bathroom Cleaning", imageUrl: "https://images.unsplash.com/photo-1584622050111-993a426fbf0a?auto=format&fit=crop&q=80&w=800", categoryKey: "cleaning", order: 2 },
    { id: 'kitchen_cleaning', title: "Kitchen Deep Clean", imageUrl: "https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&q=80&w=800", categoryKey: "cleaning", order: 3 },
    { id: 'full_home_cleaning', title: "Full Home Cleaning", imageUrl: "https://images.unsplash.com/photo-1581578731117-104f2a41272c?auto=format&fit=crop&q=80&w=800", categoryKey: "cleaning", order: 4 },
];

const PRO_REELS = [
    { id: 'ac_repair_reel', title: "AC Repair Masterclass", videoUrl: "https://assets.mixkit.co/videos/preview/mixkit-man-working-on-an-air-conditioner-condenser-40899-large.mp4", order: 1, thumbnailUrl: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&q=80&w=800" },
    { id: 'cleaning_reel', title: "Professional Cleaning", videoUrl: "https://assets.mixkit.co/videos/preview/mixkit-woman-cleaning-a-glass-window-with-a-squeegee-40938-large.mp4", order: 2, thumbnailUrl: "https://images.unsplash.com/photo-1581578731117-104f2a41272c?auto=format&fit=crop&q=80&w=800" },
    { id: 'plumbing_reel', title: "Expert Plumbing", videoUrl: "https://assets.mixkit.co/videos/preview/mixkit-plumber-fixing-a-sink-pipe-40922-large.mp4", order: 3, thumbnailUrl: "https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?auto=format&fit=crop&q=80&w=800" },
    { id: 'electrical_reel', title: "Electrical Safety", videoUrl: "https://assets.mixkit.co/videos/preview/mixkit-electrician-working-on-a-fuse-box-40915-large.mp4", order: 4, thumbnailUrl: "https://images.unsplash.com/photo-1621905252507-b35a83013b0b?auto=format&fit=crop&q=80&w=800" },
];

const SERVICE_BANNERS = [
    { id: 'banner_1', title: 'Summer Ready', description: 'Get your AC serviced today', imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&q=80&w=800', order: 1 },
    { id: 'banner_2', title: 'Deep Cleaning', description: 'Make your home sparkle', imageUrl: 'https://images.unsplash.com/photo-1581578731117-104f2a41272c?auto=format&fit=crop&q=80&w=800', order: 2 },
    { id: 'banner_3', title: 'Pest Control', description: 'Safe & effective treatment', imageUrl: 'https://images.unsplash.com/photo-1626876115993-9c8a0029b9dc?auto=format&fit=crop&q=80&w=800', order: 3 },
];

export const admin_initializeHomeContent = functions.https.onCall(async (data, context) => {
    // 1. Security Check
    if (!context.auth || context.auth.token.admin !== true) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can initialize system data.');
    }

    const batch = db.batch();
    let opCount = 0;
    const MAX_BATCH_SIZE = 450;

    // Track if we did any work
    let seededCategories = false;
    let seededCleaning = false;
    let seededPros = false;
    let seededBanners = false;

    // 1. Technician Categories & Subcategories
    const catSnap = await db.collection('technician_categories').limit(1).get();
    if (catSnap.empty) {
        seededCategories = true;
        for (const cat of TECHNICIAN_CATEGORIES) {
            const catRef = db.collection('technician_categories').doc(cat.id);
            batch.set(catRef, {
                id: cat.id,
                name: cat.name,
                order: cat.order,
                isActive: true
            });
            opCount++;

            let subOrder = 1;
            for (const subName of cat.subs) {
                const subId = `${cat.id}_${subName.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '')}`;
                const subRef = db.collection('technician_subcategories').doc(subId);
                batch.set(subRef, {
                    id: subId,
                    categoryId: cat.id,
                    name: subName,
                    order: subOrder++,
                    isActive: true
                });
                opCount++;
            }
        }
    }

    // 2. Cleaning Essentials
    const cleanSnap = await db.collection('cleaning_essentials').limit(1).get();
    if (cleanSnap.empty) {
        seededCleaning = true;
        for (const item of CLEANING_ESSENTIALS) {
            const ref = db.collection('cleaning_essentials').doc(item.id);
            // Prompt requires: id, title, imageUrl, categoryId, order, isActive
            // item has categoryKey, map to categoryId
            batch.set(ref, {
                id: item.id,
                title: item.title,
                imageUrl: item.imageUrl,
                categoryId: item.categoryKey, // Mapping key to Id as requested
                order: item.order,
                isActive: true
            });
            opCount++;
        }
    }

    // 3. Celebrating Professionals
    const proSnap = await db.collection('celebrating_professionals').limit(1).get();
    if (proSnap.empty) {
        seededPros = true;
        for (const item of PRO_REELS) {
            const ref = db.collection('celebrating_professionals').doc(item.id);
            // Prompt requires: id, videoUrl, order, isActive. 
            // We can keep title/thumbnail as extra if not strictly forbidden, but let's stick to core functionality or minimal superset.
            // videoUrl is in item.
            batch.set(ref, {
                id: item.id,
                videoUrl: item.videoUrl,
                order: item.order,
                isActive: true,
                // Keeping thumbnail/title as they are useful for UI even if not explicitly demanded in minimum valid schema
                thumbnailUrl: item.thumbnailUrl,
                title: item.title
            });
            opCount++;
        }
    }

    // 4. Service Bottom Banners
    const bannerSnap = await db.collection('service_bottom_banners').limit(1).get();
    if (bannerSnap.empty) {
        seededBanners = true;
        for (const item of SERVICE_BANNERS) {
            const ref = db.collection('service_bottom_banners').doc(item.id);
            batch.set(ref, {
                id: item.id,
                imageUrl: item.imageUrl,
                title: item.title,
                description: item.description,
                order: item.order,
                isActive: true
            });
            opCount++;
        }
    }

    if (opCount > 0) {
        await batch.commit();
        return {
            success: true,
            message: `Initialization complete. seededCategories=${seededCategories}, seededCleaning=${seededCleaning}, seededPros=${seededPros}, seededBanners=${seededBanners}`
        };
    } else {
        return {
            success: true,
            message: 'All collections already contain data. No changes made.'
        };
    }
});
