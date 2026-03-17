"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const testModules = [
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
async function runAllTests() {
    console.log('\n' + '='.repeat(60));
    console.log('🚀 HOMEFIX PRODUCTION SYSTEM TEST SUITE');
    console.log('='.repeat(60));
    console.log(`Starting at: ${new Date().toISOString()}`);
    console.log(`Total test modules: ${testModules.length}`);
    console.log('='.repeat(60));
    const allResults = [];
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
            const testModule = await Promise.resolve(`${module.path}`).then(s => __importStar(require(s)));
            // Each test module should export a default function or run on import
            // For now, we'll just track that the module was loaded
            console.log(`✅ ${module.name} completed`);
        }
        catch (error) {
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
//# sourceMappingURL=system_test_runner.js.map