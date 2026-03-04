
import * as admin from 'firebase-admin';

export const db = admin.firestore();

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
