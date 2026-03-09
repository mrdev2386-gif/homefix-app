/**
 * HomeFix Technician Services Visibility Audit
 * 
 * READ-ONLY script to verify why technician-created services are not appearing in customer app.
 * 
 * Investigates:
 * 1. Technician services collection state
 * 2. Customer location data completeness
 * 3. Location matching between services and customers
 * 4. Technician profile location data
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';

if (!admin.apps.length) {
    try {
        const serviceAccount = require(SERVICE_ACCOUNT_PATH);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('✅ Firebase Admin initialized\n');
    } catch (error) {
        console.error('❌ Error initializing Firebase Admin:', error.message);
        process.exit(1);
    }
}

const db = admin.firestore();

// ============================================================================
// AUDIT FUNCTIONS
// ============================================================================

async function auditTechnicianServices() {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('1️⃣  TECHNICIAN SERVICES COLLECTION AUDIT');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const servicesSnap = await db.collection('technician_services').get();
    const total = servicesSnap.size;

    let pending = 0;
    let approved = 0;
    let rejected = 0;
    let activeTrue = 0;
    let activeFalse = 0;
    let missingFields = [];
    let locationData = { states: new Set(), districts: new Set() };
    let sampleService = null;

    servicesSnap.forEach(doc => {
        const data = doc.data();
        
        // Count by status
        if (data.status === 'pending') pending++;
        if (data.status === 'approved') approved++;
        if (data.status === 'rejected') rejected++;
        
        // Count by isActive
        if (data.isActive === true) activeTrue++;
        if (data.isActive === false) activeFalse++;
        
        // Collect location data
        if (data.state) locationData.states.add(data.state);
        if (data.district) locationData.districts.add(data.district);
        
        // Check for missing fields
        const requiredFields = ['technicianId', 'name', 'category', 'price', 'district', 'state', 'status', 'isActive', 'createdAt'];
        const missing = requiredFields.filter(field => !data[field]);
        if (missing.length > 0) {
            missingFields.push({ id: doc.id, missing });
        }
        
        // Save first approved service as sample
        if (!sampleService && data.status === 'approved') {
            sampleService = { id: doc.id, ...data };
        }
    });

    console.log(`📊 Total Services: ${total}`);
    console.log(`   ├─ Status: pending = ${pending}`);
    console.log(`   ├─ Status: approved = ${approved}`);
    console.log(`   ├─ Status: rejected = ${rejected}`);
    console.log(`   ├─ isActive: true = ${activeTrue}`);
    console.log(`   └─ isActive: false = ${activeFalse}`);
    console.log();
    
    console.log(`📍 Service Locations:`);
    console.log(`   ├─ Unique States: ${locationData.states.size} → [${Array.from(locationData.states).join(', ')}]`);
    console.log(`   └─ Unique Districts: ${locationData.districts.size} → [${Array.from(locationData.districts).join(', ')}]`);
    console.log();

    if (missingFields.length > 0) {
        console.log(`⚠️  Services with Missing Fields: ${missingFields.length}`);
        missingFields.slice(0, 3).forEach(item => {
            console.log(`   └─ ${item.id}: missing [${item.missing.join(', ')}]`);
        });
        console.log();
    } else {
        console.log(`✅ All services have required fields\n`);
    }

    if (sampleService) {
        console.log(`📄 Sample Approved Service:`);
        console.log(`   ID: ${sampleService.id}`);
        console.log(`   Name: ${sampleService.name}`);
        console.log(`   Status: ${sampleService.status}`);
        console.log(`   isActive: ${sampleService.isActive}`);
        console.log(`   State: ${sampleService.state}`);
        console.log(`   District: ${sampleService.district}`);
        console.log(`   Category: ${sampleService.category}`);
        console.log(`   Price: ₹${sampleService.price}`);
        console.log();
    }

    return {
        total,
        approved,
        activeTrue,
        serviceLocations: {
            states: Array.from(locationData.states),
            districts: Array.from(locationData.districts)
        },
        sampleService
    };
}

async function auditApprovedServices() {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('2️⃣  APPROVED SERVICES VERIFICATION');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const approvedSnap = await db.collection('technician_services')
        .where('status', '==', 'approved')
        .get();

    console.log(`✅ Services with status='approved': ${approvedSnap.size}`);
    
    if (approvedSnap.size > 0) {
        console.log(`\n📋 Approved Services List:`);
        approvedSnap.forEach((doc, index) => {
            const data = doc.data();
            console.log(`   ${index + 1}. ${data.name || 'Unnamed'}`);
            console.log(`      ├─ ID: ${doc.id}`);
            console.log(`      ├─ State: ${data.state || 'MISSING'}`);
            console.log(`      ├─ District: ${data.district || 'MISSING'}`);
            console.log(`      ├─ isActive: ${data.isActive}`);
            console.log(`      └─ Category: ${data.category || 'N/A'}`);
        });
    }
    console.log();

    return approvedSnap.size;
}

async function auditCustomerProfiles() {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('3️⃣  CUSTOMER PROFILES AUDIT');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const customersSnap = await db.collection('customers').get();
    const total = customersSnap.size;

    let withPrimaryAddress = 0;
    let withoutPrimaryAddress = 0;
    let sampleCustomer = null;

    customersSnap.forEach(doc => {
        const data = doc.data();
        
        if (data.primaryAddressId) {
            withPrimaryAddress++;
            if (!sampleCustomer) {
                sampleCustomer = { id: doc.id, primaryAddressId: data.primaryAddressId };
            }
        } else {
            withoutPrimaryAddress++;
        }
    });

    console.log(`👥 Total Customers: ${total}`);
    console.log(`   ├─ With primaryAddressId: ${withPrimaryAddress} (${((withPrimaryAddress/total)*100).toFixed(1)}%)`);
    console.log(`   └─ WITHOUT primaryAddressId: ${withoutPrimaryAddress} (${((withoutPrimaryAddress/total)*100).toFixed(1)}%)`);
    console.log();

    if (withoutPrimaryAddress > 0) {
        console.log(`⚠️  CRITICAL: ${withoutPrimaryAddress} customers have NO primary address set!`);
        console.log(`   This means they CANNOT see any services in the app.\n`);
    }

    return { total, withPrimaryAddress, withoutPrimaryAddress, sampleCustomer };
}

async function auditCustomerAddresses(sampleCustomer) {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('4️⃣  CUSTOMER ADDRESSES AUDIT');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    if (!sampleCustomer) {
        console.log('⚠️  No customer with primaryAddressId found. Skipping address audit.\n');
        return { totalAddresses: 0, missingState: 0, missingDistrict: 0 };
    }

    // Get all addresses across all customers
    const customersSnap = await db.collection('customers').get();
    let totalAddresses = 0;
    let missingState = 0;
    let missingDistrict = 0;
    let customerLocations = { states: new Set(), districts: new Set() };
    let sampleAddress = null;

    for (const customerDoc of customersSnap.docs) {
        const addressesSnap = await customerDoc.ref.collection('addresses').get();
        totalAddresses += addressesSnap.size;

        addressesSnap.forEach(addrDoc => {
            const data = addrDoc.data();
            
            if (!data.state) missingState++;
            if (!data.district) missingDistrict++;
            
            if (data.state) customerLocations.states.add(data.state);
            if (data.district) customerLocations.districts.add(data.district);
            
            if (!sampleAddress && data.state && data.district) {
                sampleAddress = {
                    customerId: customerDoc.id,
                    addressId: addrDoc.id,
                    state: data.state,
                    district: data.district
                };
            }
        });
    }

    console.log(`📍 Total Customer Addresses: ${totalAddresses}`);
    console.log(`   ├─ Missing 'state': ${missingState}`);
    console.log(`   └─ Missing 'district': ${missingDistrict}`);
    console.log();

    console.log(`📍 Customer Locations:`);
    console.log(`   ├─ Unique States: ${customerLocations.states.size} → [${Array.from(customerLocations.states).join(', ')}]`);
    console.log(`   └─ Unique Districts: ${customerLocations.districts.size} → [${Array.from(customerLocations.districts).join(', ')}]`);
    console.log();

    if (sampleAddress) {
        console.log(`📄 Sample Customer Address:`);
        console.log(`   Customer ID: ${sampleAddress.customerId}`);
        console.log(`   Address ID: ${sampleAddress.addressId}`);
        console.log(`   State: ${sampleAddress.state}`);
        console.log(`   District: ${sampleAddress.district}`);
        console.log();
    }

    return {
        totalAddresses,
        missingState,
        missingDistrict,
        customerLocations: {
            states: Array.from(customerLocations.states),
            districts: Array.from(customerLocations.districts)
        },
        sampleAddress
    };
}

async function auditLocationMatching(serviceLocations, customerLocations) {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('5️⃣  LOCATION MATCHING ANALYSIS');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const serviceStates = new Set(serviceLocations.states);
    const serviceDistricts = new Set(serviceLocations.districts);
    const customerStates = new Set(customerLocations.states);
    const customerDistricts = new Set(customerLocations.districts);

    // Find matching states
    const matchingStates = [...serviceStates].filter(s => customerStates.has(s));
    const matchingDistricts = [...serviceDistricts].filter(d => customerDistricts.has(d));

    console.log(`🔍 Location Overlap Analysis:`);
    console.log(`   Service States: [${Array.from(serviceStates).join(', ')}]`);
    console.log(`   Customer States: [${Array.from(customerStates).join(', ')}]`);
    console.log(`   ├─ Matching States: ${matchingStates.length} → [${matchingStates.join(', ')}]`);
    console.log();
    console.log(`   Service Districts: [${Array.from(serviceDistricts).join(', ')}]`);
    console.log(`   Customer Districts: [${Array.from(customerDistricts).join(', ')}]`);
    console.log(`   └─ Matching Districts: ${matchingDistricts.length} → [${matchingDistricts.join(', ')}]`);
    console.log();

    // Check for case mismatches
    const stateCaseMismatches = [];
    const districtCaseMismatches = [];

    serviceStates.forEach(serviceState => {
        customerStates.forEach(customerState => {
            if (serviceState.toLowerCase() === customerState.toLowerCase() && serviceState !== customerState) {
                stateCaseMismatches.push({ service: serviceState, customer: customerState });
            }
        });
    });

    serviceDistricts.forEach(serviceDistrict => {
        customerDistricts.forEach(customerDistrict => {
            if (serviceDistrict.toLowerCase() === customerDistrict.toLowerCase() && serviceDistrict !== customerDistrict) {
                districtCaseMismatches.push({ service: serviceDistrict, customer: customerDistrict });
            }
        });
    });

    if (stateCaseMismatches.length > 0) {
        console.log(`⚠️  STATE CASE MISMATCHES DETECTED:`);
        stateCaseMismatches.forEach(m => {
            console.log(`   └─ Service: "${m.service}" vs Customer: "${m.customer}"`);
        });
        console.log();
    }

    if (districtCaseMismatches.length > 0) {
        console.log(`⚠️  DISTRICT CASE MISMATCHES DETECTED:`);
        districtCaseMismatches.forEach(m => {
            console.log(`   └─ Service: "${m.service}" vs Customer: "${m.customer}"`);
        });
        console.log();
    }

    // Check if ANY approved service matches ANY customer location
    const approvedServicesSnap = await db.collection('technician_services')
        .where('status', '==', 'approved')
        .get();

    let matchFound = false;
    let matchDetails = null;

    for (const serviceDoc of approvedServicesSnap.docs) {
        const serviceData = serviceDoc.data();
        
        for (const customerState of customerStates) {
            for (const customerDistrict of customerDistricts) {
                if (serviceData.state === customerState && serviceData.district === customerDistrict) {
                    matchFound = true;
                    matchDetails = {
                        serviceId: serviceDoc.id,
                        serviceName: serviceData.name,
                        state: serviceData.state,
                        district: serviceData.district
                    };
                    break;
                }
            }
            if (matchFound) break;
        }
        if (matchFound) break;
    }

    if (matchFound) {
        console.log(`✅ MATCH FOUND! At least one approved service matches customer location:`);
        console.log(`   Service: ${matchDetails.serviceName} (${matchDetails.serviceId})`);
        console.log(`   Location: ${matchDetails.state} / ${matchDetails.district}`);
        console.log();
    } else {
        console.log(`❌ NO MATCHES FOUND! No approved services match any customer location.`);
        console.log(`   This is why services are NOT appearing in the customer app!\n`);
    }

    return { matchFound, matchingStates, matchingDistricts, caseMismatches: stateCaseMismatches.length + districtCaseMismatches.length };
}

async function auditTechnicianProfiles() {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('6️⃣  TECHNICIAN PROFILES AUDIT');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const techniciansSnap = await db.collection('technicians').get();
    const total = techniciansSnap.size;

    let withState = 0;
    let withDistrict = 0;
    let approved = 0;

    techniciansSnap.forEach(doc => {
        const data = doc.data();
        
        if (data.state) withState++;
        if (data.district) withDistrict++;
        if (data.status === 'approved') approved++;
    });

    console.log(`👨‍🔧 Total Technicians: ${total}`);
    console.log(`   ├─ With 'state': ${withState} (${((withState/total)*100).toFixed(1)}%)`);
    console.log(`   ├─ With 'district': ${withDistrict} (${((withDistrict/total)*100).toFixed(1)}%)`);
    console.log(`   └─ Approved: ${approved}`);
    console.log();

    return { total, withState, withDistrict, approved };
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================

async function runFullAudit() {
    console.log('\n');
    console.log('╔═══════════════════════════════════════════════════════════════╗');
    console.log('║   HOMEFIX TECHNICIAN SERVICES VISIBILITY AUDIT                ║');
    console.log('║   Read-Only Database Verification                             ║');
    console.log('╚═══════════════════════════════════════════════════════════════╝');
    console.log();

    try {
        // 1. Audit technician services
        const servicesData = await auditTechnicianServices();

        // 2. Audit approved services
        const approvedCount = await auditApprovedServices();

        // 3. Audit customer profiles
        const customerData = await auditCustomerProfiles();

        // 4. Audit customer addresses
        const addressData = await auditCustomerAddresses(customerData.sampleCustomer);

        // 5. Audit location matching
        const matchingData = await auditLocationMatching(
            servicesData.serviceLocations,
            addressData.customerLocations
        );

        // 6. Audit technician profiles
        const technicianData = await auditTechnicianProfiles();

        // ============================================================================
        // FINAL REPORT
        // ============================================================================

        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('7️⃣  FINAL ROOT CAUSE ANALYSIS');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

        console.log('📊 SUMMARY:');
        console.log(`   ├─ Total Services: ${servicesData.total}`);
        console.log(`   ├─ Approved Services: ${approvedCount}`);
        console.log(`   ├─ Active Services: ${servicesData.activeTrue}`);
        console.log(`   ├─ Total Customers: ${customerData.total}`);
        console.log(`   ├─ Customers with Primary Address: ${customerData.withPrimaryAddress}`);
        console.log(`   ├─ Customers WITHOUT Primary Address: ${customerData.withoutPrimaryAddress}`);
        console.log(`   ├─ Total Addresses: ${addressData.totalAddresses}`);
        console.log(`   ├─ Addresses Missing State: ${addressData.missingState}`);
        console.log(`   ├─ Addresses Missing District: ${addressData.missingDistrict}`);
        console.log(`   └─ Location Matches Found: ${matchingData.matchFound ? 'YES' : 'NO'}`);
        console.log();

        console.log('🎯 ROOT CAUSE DETERMINATION:\n');

        const issues = [];

        if (servicesData.total === 0) {
            issues.push('A) NO SERVICES EXIST - No technician services have been created');
        }

        if (approvedCount === 0 && servicesData.total > 0) {
            issues.push('B) NO APPROVED SERVICES - All services are pending/rejected');
        }

        if (servicesData.activeTrue === 0 && approvedCount > 0) {
            issues.push('C) NO ACTIVE SERVICES - Approved services have isActive=false');
        }

        if (customerData.withoutPrimaryAddress > 0) {
            issues.push(`D) MISSING CUSTOMER LOCATION - ${customerData.withoutPrimaryAddress} customers have no primaryAddressId`);
        }

        if (addressData.missingState > 0 || addressData.missingDistrict > 0) {
            issues.push(`E) INCOMPLETE ADDRESS DATA - ${addressData.missingState} addresses missing state, ${addressData.missingDistrict} missing district`);
        }

        if (!matchingData.matchFound && approvedCount > 0 && customerData.withPrimaryAddress > 0) {
            issues.push('F) LOCATION MISMATCH - No approved services match any customer location');
        }

        if (matchingData.caseMismatches > 0) {
            issues.push(`G) CASE SENSITIVITY ISSUE - ${matchingData.caseMismatches} location name case mismatches detected`);
        }

        if (issues.length === 0) {
            console.log('✅ NO ISSUES DETECTED - Services should be visible to customers!');
            console.log('   If services are still not showing, check:');
            console.log('   - Customer app query logic');
            console.log('   - Firestore security rules');
            console.log('   - Network connectivity');
        } else {
            console.log('❌ ISSUES DETECTED:\n');
            issues.forEach((issue, index) => {
                console.log(`   ${index + 1}. ${issue}`);
            });
        }

        console.log();
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('✅ AUDIT COMPLETE');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    } catch (error) {
        console.error('\n❌ AUDIT FAILED:', error.message);
        console.error(error);
    }

    process.exit(0);
}

// Run the audit
runFullAudit();
