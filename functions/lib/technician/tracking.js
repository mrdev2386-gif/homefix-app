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
exports.toggleOnlineStatus = exports.updateLocation = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("../shared/security");
const geoutils_1 = require("../shared/geoutils");
const db = admin.firestore();
exports.updateLocation = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { location, timestamp } = data; // { lat, lng }
    if (!location || !location.lat || !location.lng) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid location data');
    }
    const techRef = db.collection('technicians').doc(uid);
    const techDoc = await techRef.get();
    if (!techDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Technician profile not found');
    }
    const techData = techDoc.data();
    // Anti-Spoofing Check: Speed Calculation
    if (techData.lastLocation && techData.lastSeen) {
        const lastCoords = { lat: techData.lastLocation.latitude, lng: techData.lastLocation.longitude };
        const newCoords = { lat: location.lat, lng: location.lng };
        const distanceKm = (0, geoutils_1.calculateDistance)(lastCoords, newCoords);
        const timeDiffSec = (timestamp - techData.lastSeen.toMillis()) / 1000;
        if (timeDiffSec > 0) {
            const speedKmph = (distanceKm / (timeDiffSec / 3600));
            if (speedKmph > 200) { // Impossible speed
                console.warn(`Suspicious speed detected for ${uid}: ${speedKmph} km/h`);
                // Log suspicious activity
                await db.collection('fraud_alerts').add({
                    technicianId: uid,
                    type: 'speed_spoofing',
                    speedKmph,
                    location: newCoords,
                    timestamp: admin.firestore.FieldValue.serverTimestamp()
                });
                // Optional: Auto-suspend? No, just log for now.
            }
        }
    }
    await techRef.update({
        lastLocation: new admin.firestore.GeoPoint(location.lat, location.lng),
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        // geohash: encodeGeohash(location.lat, location.lng) // If we had geohash lib
    });
    return { success: true };
});
exports.toggleOnlineStatus = functions.region('asia-south1').https.onCall(async (data, context) => {
    (0, security_1.assertAuthenticated)(context);
    const uid = context.auth.uid;
    const { isOnline } = data;
    await db.collection('technicians').doc(uid).update({
        isOnline: !!isOnline,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return { success: true };
});
//# sourceMappingURL=tracking.js.map