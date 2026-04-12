"use strict";
/**
 * Booking Actions
 *
 * This file exports booking action functions that were previously referenced
 * but not implemented. These are stub exports to maintain backward compatibility.
 *
 * TODO: Implement these functions properly
 */
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
exports.rejectJobQuote = exports.approveJobQuote = exports.completeJob = exports.startJob = exports.submitInspectionReport = exports.startInspection = exports.scheduleInspection = void 0;
const functions = __importStar(require("firebase-functions"));
const security_1 = require("./shared/security");
// Stub implementations - these should be replaced with actual implementations
// or connected to existing functions in booking_lifecycle.ts
exports.scheduleInspection = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    throw new functions.https.HttpsError('unimplemented', 'scheduleInspection is not implemented yet');
}));
exports.startInspection = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    throw new functions.https.HttpsError('unimplemented', 'startInspection is not implemented yet');
}));
exports.submitInspectionReport = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    throw new functions.https.HttpsError('unimplemented', 'submitInspectionReport is not implemented yet');
}));
exports.startJob = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    throw new functions.https.HttpsError('unimplemented', 'startJob is not implemented yet');
}));
exports.completeJob = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    throw new functions.https.HttpsError('unimplemented', 'completeJob is not implemented yet');
}));
exports.approveJobQuote = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    throw new functions.https.HttpsError('unimplemented', 'approveJobQuote is not implemented yet');
}));
exports.rejectJobQuote = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    throw new functions.https.HttpsError('unimplemented', 'rejectJobQuote is not implemented yet');
}));
//# sourceMappingURL=booking_actions.js.map