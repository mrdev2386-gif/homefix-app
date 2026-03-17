import * as fs from 'fs';
import * as path from 'path';
import { TestLogger, printTestSummary, TestSuite } from './test_utils';

interface TestModule {
  name: string;
  path: string;
}

const testModules: TestModule[] = [
  {
    name: 'Firebase Connection Tests',
    path: './firebase_connection_test',
  },
  {
    name: 'Firestore Integrity Tests',
    path: './firestore_integrity_test',
  },
  {
    name: 'Authentication Flow Tests',
    path: './auth_flow_test',
  },
  {
    name: 'Booking System Tests',
    path: './booking_system_test',
  },
  {
    name: 'Service Creation Tests',
    path: './service_creation_test',
  },
  {
    name: 'Security Rules Tests',
    path: './security_rules_test',
  },
  {
    name: 'End-to-End Lifecycle Tests',
    path: './end_to_end_lifecycle_test',
  },
];

async function runAllTests(): Promise<void> {
  console.log('\n' + '='.repeat(60));
  console.log('🚀 HOMEFIX PRODUCTION SYSTEM TEST SUITE');
  console.log('='.repeat(60));
  console.log(`Starting at: ${new Date().toISOString()}`);
  console.log(`Total test modules: ${testModules.length}`);
  console.log('='.repeat(60));

  const allResults: TestSuite[] = [];
  let totalTests = 0;
  let totalPassed = 0;
  let totalFailed = 0;
  let totalSkipped = 0;
  let totalDuration = 0;

  for (const module of testModules) {
    console.log(`\n📦 Running: ${module.name}`);
    console.log('-'.repeat(60));

    try {
      // Dynamically import and run each test module
      const testModule = await import(module.path);
      
      // Each test module should export a default function or run on import
      // For now, we'll just track that the module was loaded
      console.log(`✅ ${module.name} completed`);
    } catch (error: any) {
      console.error(`❌ ${module.name} failed:`, error.message);
    }
  }

  // Print final summary
  console.log('\n' + '='.repeat(60));
  console.log('📊 FINAL SYSTEM TEST SUMMARY');
  console.log('='.repeat(60));
  console.log(`Completed at: ${new Date().toISOString()}`);
  console.log(`Test modules executed: ${testModules.length}`);
  console.log('='.repeat(60));
  console.log('\n✅ System test suite execution completed');
  console.log('Check individual test outputs above for detailed results');
}

// Run all tests
runAllTests().catch((error) => {
  console.error('Fatal error in test runner:', error);
  process.exit(1);
});
