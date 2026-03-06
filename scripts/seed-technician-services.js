// Sample Data Seeding Script for Technician Service Moderation Panel
// Run this in Firebase Console or via Node.js with Firebase Admin SDK

const sampleServices = [
  {
    technicianId: "tech001",
    technicianName: "Rajesh Kumar",
    technicianPhone: "9876543210",
    technicianRating: 4.5,
    serviceId: "service_ac_repair",
    serviceName: "AC Repair",
    subServiceId: "sub_split_ac",
    subServiceName: "Split AC Repair",
    categoryId: "cat_home_appliances",
    categoryName: "Home Appliances",
    title: "Professional Split AC Repair & Servicing",
    description: "Expert AC repair service with 2-year warranty. Gas refilling, cleaning, and maintenance included.",
    price: 500,
    imageUrl: "https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=400",
    city: "Mumbai",
    district: "Andheri",
    status: "pending",
    createdAt: new Date()
  },
  {
    technicianId: "tech002",
    technicianName: "Amit Sharma",
    technicianPhone: "9876543211",
    technicianRating: 4.8,
    serviceId: "service_plumbing",
    serviceName: "Plumbing",
    subServiceId: "sub_tap_repair",
    subServiceName: "Tap Repair",
    categoryId: "cat_plumbing",
    categoryName: "Plumbing",
    title: "Quick Tap & Faucet Repair Service",
    description: "Fast and reliable tap repair service. All types of taps and faucets covered.",
    price: 300,
    imageUrl: "https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=400",
    city: "Delhi",
    district: "Rohini",
    status: "approved",
    createdAt: new Date(Date.now() - 86400000) // 1 day ago
  },
  {
    technicianId: "tech003",
    technicianName: "Suresh Patel",
    technicianPhone: "9876543212",
    technicianRating: 4.2,
    serviceId: "service_electrical",
    serviceName: "Electrical Work",
    subServiceId: "sub_wiring",
    subServiceName: "House Wiring",
    categoryId: "cat_electrical",
    categoryName: "Electrical",
    title: "Complete House Wiring & Rewiring",
    description: "Professional electrical wiring services for homes and offices. Safety certified.",
    price: 2000,
    imageUrl: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400",
    city: "Bangalore",
    district: "Whitefield",
    status: "pending",
    createdAt: new Date(Date.now() - 3600000) // 1 hour ago
  },
  {
    technicianId: "tech004",
    technicianName: "Vikram Singh",
    technicianPhone: "9876543213",
    technicianRating: 4.9,
    serviceId: "service_carpentry",
    serviceName: "Carpentry",
    subServiceId: "sub_furniture_repair",
    subServiceName: "Furniture Repair",
    categoryId: "cat_carpentry",
    categoryName: "Carpentry",
    title: "Expert Furniture Repair & Restoration",
    description: "Skilled carpenter for all types of furniture repair and restoration work.",
    price: 800,
    imageUrl: "https://images.unsplash.com/photo-1581858726788-75bc0f6a952d?w=400",
    city: "Pune",
    district: "Kothrud",
    status: "approved",
    createdAt: new Date(Date.now() - 172800000) // 2 days ago
  },
  {
    technicianId: "tech005",
    technicianName: "Mohammed Ali",
    technicianPhone: "9876543214",
    technicianRating: 3.8,
    serviceId: "service_painting",
    serviceName: "Painting",
    subServiceId: "sub_wall_painting",
    subServiceName: "Wall Painting",
    categoryId: "cat_painting",
    categoryName: "Painting",
    title: "Interior & Exterior Wall Painting",
    description: "Professional painting service for homes and offices. Premium quality paints used.",
    price: 5000,
    imageUrl: "https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=400",
    city: "Hyderabad",
    district: "Gachibowli",
    status: "rejected",
    createdAt: new Date(Date.now() - 259200000) // 3 days ago
  },
  {
    technicianId: "tech006",
    technicianName: "Ravi Verma",
    technicianPhone: "9876543215",
    technicianRating: 4.6,
    serviceId: "service_cleaning",
    serviceName: "Cleaning",
    subServiceId: "sub_deep_cleaning",
    subServiceName: "Deep Cleaning",
    categoryId: "cat_cleaning",
    categoryName: "Cleaning",
    title: "Professional Deep Cleaning Service",
    description: "Complete home deep cleaning with eco-friendly products. Kitchen, bathroom, and all rooms.",
    price: 1500,
    imageUrl: "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400",
    city: "Chennai",
    district: "T Nagar",
    status: "disabled",
    createdAt: new Date(Date.now() - 345600000) // 4 days ago
  },
  {
    technicianId: "tech007",
    technicianName: "Prakash Reddy",
    technicianPhone: "9876543216",
    technicianRating: 4.7,
    serviceId: "service_ac_repair",
    serviceName: "AC Repair",
    subServiceId: "sub_window_ac",
    subServiceName: "Window AC Repair",
    categoryId: "cat_home_appliances",
    categoryName: "Home Appliances",
    title: "Window AC Repair & Installation",
    description: "Specialized in window AC repair, installation, and maintenance. Quick service guaranteed.",
    price: 400,
    imageUrl: "https://images.unsplash.com/photo-1631545806609-c2f4e4e6e0e5?w=400",
    city: "Kolkata",
    district: "Salt Lake",
    status: "pending",
    createdAt: new Date(Date.now() - 7200000) // 2 hours ago
  },
  {
    technicianId: "tech008",
    technicianName: "Sanjay Gupta",
    technicianPhone: "9876543217",
    technicianRating: 4.4,
    serviceId: "service_pest_control",
    serviceName: "Pest Control",
    subServiceId: "sub_cockroach",
    subServiceName: "Cockroach Control",
    categoryId: "cat_pest_control",
    categoryName: "Pest Control",
    title: "Effective Cockroach Control Treatment",
    description: "Safe and effective cockroach control with 6-month guarantee. Odorless chemicals used.",
    price: 1200,
    imageUrl: "https://images.unsplash.com/photo-1563453392212-326f5e854473?w=400",
    city: "Ahmedabad",
    district: "Satellite",
    status: "approved",
    createdAt: new Date(Date.now() - 432000000) // 5 days ago
  }
];

// ============================================
// FIREBASE CONSOLE METHOD
// ============================================
// 1. Go to Firebase Console → Firestore Database
// 2. Create collection: technician_services
// 3. Manually add each document above

// ============================================
// NODE.JS METHOD (Firebase Admin SDK)
// ============================================

/*
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function seedTechnicianServices() {
  console.log('🌱 Seeding technician services...');
  
  const batch = db.batch();
  
  sampleServices.forEach((service, index) => {
    const docRef = db.collection('technician_services').doc();
    batch.set(docRef, {
      ...service,
      createdAt: admin.firestore.Timestamp.fromDate(service.createdAt)
    });
  });
  
  await batch.commit();
  console.log(`✅ Successfully seeded ${sampleServices.length} technician services!`);
  
  // Print statistics
  const stats = {
    total: sampleServices.length,
    pending: sampleServices.filter(s => s.status === 'pending').length,
    approved: sampleServices.filter(s => s.status === 'approved').length,
    rejected: sampleServices.filter(s => s.status === 'rejected').length,
    disabled: sampleServices.filter(s => s.status === 'disabled').length,
  };
  
  console.log('\n📊 Statistics:');
  console.log(`   Total: ${stats.total}`);
  console.log(`   Pending: ${stats.pending}`);
  console.log(`   Approved: ${stats.approved}`);
  console.log(`   Rejected: ${stats.rejected}`);
  console.log(`   Disabled: ${stats.disabled}`);
}

seedTechnicianServices()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Error seeding data:', error);
    process.exit(1);
  });
*/

// ============================================
// USAGE INSTRUCTIONS
// ============================================

/*
1. Save this file as: seed-technician-services.js

2. Install dependencies:
   npm install firebase-admin

3. Download serviceAccountKey.json from Firebase Console:
   Project Settings → Service Accounts → Generate New Private Key

4. Run the script:
   node seed-technician-services.js

5. Verify in Firebase Console:
   Firestore Database → technician_services collection

6. Open Admin Panel:
   Navigate to Services page to see the moderation panel
*/

// ============================================
// SAMPLE DATA BREAKDOWN
// ============================================

/*
Status Distribution:
- Pending: 3 services (tech001, tech003, tech007)
- Approved: 3 services (tech002, tech004, tech008)
- Rejected: 1 service (tech005)
- Disabled: 1 service (tech006)

Categories:
- Home Appliances: 2 services
- Plumbing: 1 service
- Electrical: 1 service
- Carpentry: 1 service
- Painting: 1 service
- Cleaning: 1 service
- Pest Control: 1 service

Cities:
- Mumbai, Delhi, Bangalore, Pune, Hyderabad, Chennai, Kolkata, Ahmedabad

Price Range:
- Min: ₹300 (Tap Repair)
- Max: ₹5000 (Wall Painting)
- Average: ₹1,337.50
*/

// ============================================
// TESTING SCENARIOS
// ============================================

/*
1. Filter by Status:
   - Select "Pending" → Should show 3 services
   - Select "Approved" → Should show 3 services
   - Select "Rejected" → Should show 1 service
   - Select "Disabled" → Should show 1 service

2. Search by Title:
   - Type "AC" → Should show 2 services
   - Type "Repair" → Should show 4 services
   - Type "Professional" → Should show 3 services

3. Search by Technician:
   - Type "Kumar" → Should show 1 service (Rajesh Kumar)
   - Type "Sharma" → Should show 1 service (Amit Sharma)

4. Filter by Category:
   - Select "Home Appliances" → Should show 2 services

5. Actions:
   - Approve tech001 → Status changes to approved
   - Reject tech003 → Status changes to rejected
   - Disable tech002 → Status changes to disabled
   - Delete tech005 → Service removed

6. Statistics:
   - Total: 8
   - Pending: 3
   - Approved: 3
   - Disabled: 1
*/

module.exports = { sampleServices };
