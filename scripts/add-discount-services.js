/**
 * Add Discount Services Test Script
 * 
 * Creates sample services with discount pricing to test the complete discount system:
 * - Services with both originalPrice and offerPrice
 * - Services without discount (control test)
 * - Real technician data for proper display
 * 
 * Usage: node scripts/add-discount-services.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'homefix-c2137.appspot.com'
});

const db = admin.firestore();

// Sample services with discount pricing
const discountServices = [
  {
    id: 'ac-repair-discount',
    title: 'AC Repair & Service',
    description: 'Complete AC repair and maintenance service with 6-month warranty. Expert technicians with 5+ years experience.',
    category: 'ac',
    categoryName: 'AC Services',
    price: 600,           // Final price (offer price)
    basePrice: 800,       // Original price for strikethrough
    offerPrice: 600,      // Discounted price
    imageUrl: 'https://firebasestorage.googleapis.com/v0/b/homefix-c2137.appspot.com/o/services%2Fac-repair.jpg?alt=media',
    technicianId: 'sample-tech-1',
    technicianName: 'Rajesh Kumar',
    technicianDistrict: 'Mumbai',
    rating: 4.8,
    reviewCount: 25,
    status: 'approved',
    isActive: true,
    isPublished: true,
    technicianApproved: true
  },
  {
    id: 'deep-cleaning-discount',
    title: 'Deep Home Cleaning',
    description: 'Professional deep cleaning service for your entire home. Includes kitchen, bathroom, and all rooms with eco-friendly products.',
    category: 'cleaning',
    categoryName: 'Cleaning Services',
    price: 1200,          // Final price (offer price)
    basePrice: 2000,      // Original price for strikethrough
    offerPrice: 1200,     // Discounted price (40% OFF)
    imageUrl: 'https://firebasestorage.googleapis.com/v0/b/homefix-c2137.appspot.com/o/services%2Fcleaning.jpg?alt=media',
    technicianId: 'sample-tech-2',
    technicianName: 'Priya Sharma',
    technicianDistrict: 'Delhi',
    rating: 4.9,
    reviewCount: 42,
    status: 'approved',
    isActive: true,
    isPublished: true,
    technicianApproved: true
  },
  {
    id: 'plumbing-discount',
    title: 'Plumbing Repair Service',
    description: 'Expert plumbing solutions for leaks, blockages, and installations. 24/7 emergency service available.',
    category: 'plumbing',
    categoryName: 'Plumbing Services',
    price: 1050,          // Final price (offer price)
    basePrice: 1500,      // Original price for strikethrough
    offerPrice: 1050,     // Discounted price (30% OFF)
    imageUrl: 'https://firebasestorage.googleapis.com/v0/b/homefix-c2137.appspot.com/o/services%2Fplumbing.jpg?alt=media',
    technicianId: 'sample-tech-3',
    technicianName: 'Amit Singh',
    technicianDistrict: 'Bangalore',
    rating: 4.7,
    reviewCount: 18,
    status: 'approved',
    isActive: true,
    isPublished: true,
    technicianApproved: true
  },
  {
    id: 'electrical-no-discount',
    title: 'Electrical Repair Service',
    description: 'Professional electrical repairs and installations. Licensed electricians with safety guarantee.',
    category: 'electrical',
    categoryName: 'Electrical Services',
    price: 500,           // Regular price (no discount)
    basePrice: 500,       // Same as price
    offerPrice: null,     // No offer price
    imageUrl: 'https://firebasestorage.googleapis.com/v0/b/homefix-c2137.appspot.com/o/services%2Felectrical.jpg?alt=media',
    technicianId: 'sample-tech-4',
    technicianName: 'Suresh Patel',
    technicianDistrict: 'Pune',
    rating: 4.6,
    reviewCount: 12,
    status: 'approved',
    isActive: true,
    isPublished: true,
    technicianApproved: true
  }
];

async function addDiscountServices() {
  console.log('🚀 Adding discount services to test pricing system...\n');

  try {
    const batch = db.batch();

    for (const service of discountServices) {
      const serviceRef = db.collection('technician_services').doc(service.id);
      
      const serviceData = {
        ...service,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
        order: 0,
        isTrending: false,
        isRecommended: true,
        duration: '1-2 hours',
        urgentBookingEnabled: false
      };

      batch.set(serviceRef, serviceData);
      
      // Calculate discount percentage for logging
      const hasDiscount = service.offerPrice && service.offerPrice < service.basePrice;
      const discountPercent = hasDiscount 
        ? Math.round(((service.basePrice - service.offerPrice) / service.basePrice) * 100)
        : 0;
      
      console.log(`✅ ${service.title}`);
      console.log(`   💰 Price: ₹${service.price}`);
      if (hasDiscount) {
        console.log(`   🏷️  Original: ₹${service.basePrice} → Offer: ₹${service.offerPrice} (${discountPercent}% OFF)`);
      } else {
        console.log(`   📝 No discount (control test)`);
      }
      console.log(`   👨‍🔧 Technician: ${service.technicianName} (${service.technicianDistrict})`);
      console.log(`   ⭐ Rating: ${service.rating} (${service.reviewCount} reviews)\n`);
    }

    await batch.commit();
    
    console.log('🎉 All discount services added successfully!\n');
    
    console.log('📋 TESTING CHECKLIST:');
    console.log('1. ✅ Open customer app');
    console.log('2. ✅ Navigate to home screen');
    console.log('3. ✅ Look for discount badges on service cards');
    console.log('4. ✅ Verify strikethrough original prices');
    console.log('5. ✅ Check service detail screens show discount pricing');
    console.log('6. ✅ Confirm services without discount show regular pricing');
    console.log('7. ✅ Monitor debug logs for discount detection\n');
    
    console.log('🔍 DEBUG LOGS TO WATCH FOR:');
    console.log('- 💰 [SERVICE_PRICES] logs in HomeService model');
    console.log('- 🏷️ [DISCOUNT_CARD] logs in UniversalServiceCard');
    console.log('- 🔍 [PRICE_DEBUG] logs for raw price data parsing\n');
    
    console.log('🎯 EXPECTED RESULTS:');
    console.log('- AC Repair: ₹800 → ₹600 (25% OFF badge)');
    console.log('- Deep Cleaning: ₹2000 → ₹1200 (40% OFF badge)');
    console.log('- Plumbing: ₹1500 → ₹1050 (30% OFF badge)');
    console.log('- Electrical: ₹500 (no discount badge)\n');

  } catch (error) {
    console.error('❌ Error adding discount services:', error);
    process.exit(1);
  }
}

// Run the script
addDiscountServices()
  .then(() => {
    console.log('✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });