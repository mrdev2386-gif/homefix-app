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
exports.sendPushNotification = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("./utils");
const notify = __importStar(require("../shared/notification_helper"));
exports.sendPushNotification = functions.region('asia-south1').https.onCall(async (data, context) => {
    await (0, utils_1.assertAdmin)(context);
    const { target, title, body, imageUrl } = data; // target: 'all' | 'customers' | 'technicians' | 'uid'
    if (target.startsWith('user_')) {
        const uid = target.replace('user_', '');
        // Determine type based on some logic or default to general
        await notify.sendUserNotification({
            userId: uid,
            userType: 'technician', // Admin should specify this, but default to technician for now or try to detect
            title,
            body,
            type: 'admin_broadcast',
            imageUrl,
            priority: 'high'
        });
    }
    else {
        // Topic broadcast - for now we don't create 10k Firestore records for topics
        // unless we use a "global_notifications" collection the app checks.
        await admin.messaging().send({
            topic: target,
            notification: { title, body },
            data: { type: 'admin_broadcast' }
        });
    }
    await (0, utils_1.logAdminAction)(context.auth.uid, 'send_notification', target, { title, body });
    return { success: true };
});
//# sourceMappingURL=notifications.js.map