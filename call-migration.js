// Script to call the migrateServicesToNested function with admin authentication
const { initializeApp, getApps } = require('firebase/app');
const { getFunctions, httpsCallable } = require('firebase/functions');
const { getAuth, signInWithCustomToken } = require('firebase/auth');
const { GoogleAuth } = require('google-auth-library');
const https = require('https');

const PROJECT_ID = 'homefix-aa42d';

// Firebase config - using the one from the project
const firebaseConfig = {
  apiKey: "AIzaSyC5iX4TkT2l9nT3vJ5R6Y8M1W2X4Z9P0Q",
  authDomain: "homefix-aa42d.firebaseapp.com",
  projectId: PROJECT_ID,
  storageBucket: "homefix-aa42d.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456"
};

async function getAccessToken() {
  const auth = new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform']
  });
  
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return token.token;
}

async function callCallableFunction() {
  try {
    console.log('Getting access token via Google Auth...');
    const accessToken = await getAccessToken();
    
    if (!accessToken) {
      throw new Error('Failed to get access token');
    }
    
    console.log('Access token obtained successfully');
    
    // Call the Firebase callable function using HTTP
    // Firebase callable functions expect a specific format
    const functionUrl = `https://${PROJECT_ID}.cloudfunctions.net/migrateServicesToNested`;
    
    const payload = {
      data: {}
    };
    
    const postData = JSON.stringify(payload);
    
    const options = {
      hostname: `${PROJECT_ID}.cloudfunctions.net`,
      path: `/migrateServicesToNested`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
        'Accept': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };
    
    console.log(`Calling ${functionUrl}...`);
    
    return new Promise((resolve, reject) => {
      const req = https.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
          data += chunk;
        });
        
        res.on('end', () => {
          console.log(`Response status: ${res.statusCode}`);
          console.log('Response headers:', JSON.stringify(res.headers));
          console.log('Response body:', data);
          
          if (res.statusCode >= 200 && res.statusCode < 300) {
            try {
              const result = JSON.parse(data);
              console.log('Migration completed!');
              console.log('Full response:', JSON.stringify(result, null, 2));
              
              // Output in the format required
              console.log('\n=== EXECUTION RESULT ===');
              console.log(`totalRootServices: ${result.result?.totalRootServices || result.totalRootServices || 'N/A'}`);
              console.log(`totalMigrated: ${result.result?.totalMigrated || result.totalMigrated || 'N/A'}`);
              console.log(`totalSkippedAlreadyExists: ${result.result?.totalSkippedAlreadyExists || result.totalSkippedAlreadyExists || 'N/A'}`);
              console.log(`totalErrors: ${result.result?.totalErrors || result.totalErrors || 'N/A'}`);
              
              resolve(result);
            } catch (e) {
              console.log('Could not parse response as JSON:', data);
              resolve({ raw: data });
            }
          } else {
            console.error('Error response:', data);
            reject(new Error(`HTTP ${res.statusCode}: ${data}`));
          }
        });
      });
      
      req.on('error', (error) => {
        console.error('Request error:', error);
        reject(error);
      });
      
      req.write(postData);
      req.end();
    });
    
  } catch (error) {
    console.error('Error calling function:', error.message);
    if (error.response) {
      console.error('Error response:', error.response.data);
    }
    throw error;
  }
}

callCallableFunction()
  .then(() => {
    console.log('\nMigration execution completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\nMigration execution failed:', error.message);
    process.exit(1);
  });
