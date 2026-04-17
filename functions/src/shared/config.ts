import * as admin from 'firebase-admin';

// Lazy getter — Firestore is NOT instantiated at module load time.
// This prevents cold-start initialization failures.
let _db: admin.firestore.Firestore | null = null;
export const db = new Proxy({} as admin.firestore.Firestore, {
    get(_target, prop: string) {
        if (!_db) _db = admin.firestore();
        return (_db as any)[prop];
    }
});

export interface AppConfig {
    isTestMode: boolean;
    maintenanceMode?: boolean;
    minVersion?: string;
}

export async function getAppConfig(): Promise<AppConfig> {
    const doc = await db.doc('config/app').get();
    if (!doc.exists) {
        return { isTestMode: false };
    }
    return doc.data() as AppConfig;
}
