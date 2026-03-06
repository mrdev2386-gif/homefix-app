/**
 * Service Catalog Cleanup Script
 * 
 * This script identifies and removes invalid services from Firestore:
 * - Services with price = 0
 * - Services with missing duration
 * - Services with placeholder/test data
 * - Unused or deprecated services
 * 
 * Run this in Firebase Console or as a Cloud Function
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function cleanupServices() {
  console.log('🧹 Starting service catalog cleanup...\n');

  try {
    // Fetch all services
    const servicesSnapshot = await db.collection('services').get();
    console.log(`📊 Total services found: ${servicesSnapshot.size}\n`);

    const invalidServices = [];
    const validServices = [];

    // Analyze each service
    servicesSnapshot.forEach(doc => {
      const service = { id: doc.id, ...doc.data() };
      
      // Check for invalid conditions
      const isInvalid = 
        !service.basePrice || service.basePrice === 0 ||
        !service.estimatedDuration || service.estimatedDuration === '' ||
        !service.name || service.name === '' ||
        !service.categoryId || service.categoryId === '' ||
        service.name.toLowerCase().includes('test') ||
        service.name.toLowerCase().includes('sample') ||
        service.name.toLowerCase().includes('demo') ||
        service.description?.toLowerCase().includes('placeholder');

      if (isInvalid) {
        invalidServices.push(service);
      } else {
        validServices.push(service);
      }
    });

    console.log(`✅ Valid services: ${validServices.length}`);
    console.log(`❌ Invalid services to remove: ${invalidServices.length}\n`);

    // Display invalid services
    if (invalidServices.length > 0) {
      console.log('📋 Invalid services identified:\n');
      invalidServices.forEach(service => {
        console.log(`  - ${service.name} (${service.id})`);
        console.log(`    Price: ₹${service.basePrice || 0}`);
        console.log(`    Duration: ${service.estimatedDuration || 'N/A'}`);
        console.log(`    Category: ${service.categoryId || 'N/A'}`);
        console.log('');
      });

      // Delete invalid services
      console.log('🗑️  Deleting invalid services...\n');
      const batch = db.batch();
      
      invalidServices.forEach(service => {
        const serviceRef = db.collection('services').doc(service.id);
        batch.delete(serviceRef);
      });

      await batch.commit();
      console.log('✅ Invalid services deleted successfully!\n');
    } else {
      console.log('✅ No invalid services found. Catalog is clean!\n');
    }

    // Display valid services summary
    console.log('📊 Valid services summary:\n');
    const categoryCounts = {};
    validServices.forEach(service => {
      const catId = service.categoryId || 'uncategorized';
      categoryCounts[catId] = (categoryCounts[catId] || 0) + 1;
    });

    Object.entries(categoryCounts).forEach(([catId, count]) => {
      console.log(`  ${catId}: ${count} services`);
    });

    console.log('\n✅ Cleanup complete!');
    
    return {
      totalServices: servicesSnapshot.size,
      validServices: validServices.length,
      invalidServices: invalidServices.length,
      deletedServices: invalidServices.map(s => s.id)
    };

  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    throw error;
  }
}

// Export for Cloud Functions
exports.cleanupServices = cleanupServices;

// Run directly if executed as script
if (require.main === module) {
  cleanupServices()
    .then(result => {
      console.log('\n📊 Final Results:', result);
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Cleanup failed:', error);
      process.exit(1);
    });
}
