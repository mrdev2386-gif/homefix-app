import * as admin from 'firebase-admin';
export interface TestResult {
    name: string;
    status: 'PASS' | 'FAIL' | 'SKIP';
    duration: number;
    error?: string;
    details?: Record<string, any>;
}
export interface TestSuite {
    name: string;
    tests: TestResult[];
    totalDuration: number;
    passCount: number;
    failCount: number;
    skipCount: number;
}
export declare class TestLogger {
    private results;
    private startTime;
    startTest(name: string): void;
    pass(name: string, details?: Record<string, any>): void;
    fail(name: string, error: string, details?: Record<string, any>): void;
    skip(name: string, reason: string): void;
    getResults(): TestResult[];
    getSummary(): TestSuite;
}
export declare class FirebaseTestHelper {
    private db;
    private auth;
    private storage;
    constructor();
    initializeApp(serviceAccountPath: string): Promise<void>;
    getFirestore(): admin.firestore.Firestore;
    getAuth(): admin.auth.Auth;
    getStorage(): admin.storage.Storage;
    createTestUser(email: string, password: string): Promise<string>;
    deleteTestUser(uid: string): Promise<void>;
    createTestDocument(collection: string, docId: string, data: Record<string, any>): Promise<void>;
    getTestDocument(collection: string, docId: string): Promise<Record<string, any> | null>;
    deleteTestDocument(collection: string, docId: string): Promise<void>;
    queryDocuments(collection: string, constraints: Array<[string, string, any]>): Promise<Record<string, any>[]>;
    cleanupTestData(collection: string, docId: string): Promise<void>;
}
export declare function printTestSummary(suite: TestSuite): void;
export declare function sleep(ms: number): Promise<void>;
//# sourceMappingURL=test_utils.d.ts.map