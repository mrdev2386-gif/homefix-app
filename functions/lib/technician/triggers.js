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
exports.syncTechnicianApprovalToServices = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * Sync technician approval status to all their services
 * When a technician is approved/suspended, update all their service listings
 */
exports.syncTechnicianApprovalToServices = functions.firestore
    .document('technicians/{techId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after)
        return;
    // Check if isApproved status changed
    if (before.isApproved !== after.isApproved) {
        const techId = context.params.techId;
        const isApproved = after.isApproved;
        console.log(`[TRIGGER] Technician ${techId} isApproved changed from ${before.isApproved} to ${isApproved}. Syncing to services...`);
        const servicesSnap = await db.collection('technician_services')
            .where('technicianId', '==', techId)
            .get();
        if (servicesSnap.empty) {
            console.log(`[TRIGGER] No services found for technician ${techId}`);
            return;
        }
        const batch = db.batch();
        servicesSnap.docs.forEach(doc => {
            batch.update(doc.ref, {
                technicianApproved: isApproved,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        await batch.commit();
        console.log(`[TRIGGER] Updated ${servicesSnap.size} services for technician ${techId} with technicianApproved=${isApproved}`);
    }
});
//# sourceMappingURL=triggers.js.map