const admin = require('firebase-admin');
const { getApps } = require('firebase-admin/app');

// Initialize Firebase Admin if not already initialized
if (!getApps().length) {
    admin.initializeApp({
        projectId: 'homefix-aa42d'
    });
}

const functions = admin.functions();

async function testApproval() {
    try {
        console.log('🧪 Testing admin_approveTechnician function...');
        
        // Test with a sample technician ID
        const testData = {
            techId: 'test-technician-123',
            approve: true,
            reason: 'Test approval'
        };
        
        console.log('📤 Sending test data:', testData);
        
        const callable = functions.httpsCallable('admin_approveTechnician');
        const result = await callable(testData);
        
        console.log('✅ Function call successful:', result.data);
        
    } catch (error) {
        console.error('❌ Function call failed:', {
            code: error.code,
            message: error.message,
            details: error.details
        });
        
        // Check if it's the expected "not found" error (which means the function is working)
        if (error.code === 'not-found' && error.message.includes('Technician not found')) {
            console.log('✅ Function is working correctly - it properly validated the technician ID');
        }
    }
}

testApproval();