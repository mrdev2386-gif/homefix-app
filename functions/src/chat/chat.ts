/**
 * HomeFix Chat System - Cloud Functions
 * 
 * Production-grade chat system with:
 * - Idempotent chat creation (only after booking accepted)
 * - Rate limiting (5 messages per 10 seconds)
 * - Message sanitization
 * - Push notifications
 * - Real-time updates
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// ==========================================
// TYPES & INTERFACES
// ==========================================

interface ChatData {
  id: string;
  bookingId: string;
  customerId: string;
  technicianId: string;
  lastMessage: string;
  lastMessageAt: admin.firestore.FieldValue;
  lastSenderId: string;
  createdAt: admin.firestore.FieldValue;
  isActive: boolean;
}

interface MessageData {
  id: string;
  chatId: string;
  senderId: string;
  senderType: 'customer' | 'technician';
  text: string;
  imageUrl?: string;
  createdAt: admin.firestore.FieldValue;
  isRead: boolean;
}

// ==========================================
// RATE LIMITING (Sliding Window)
// ==========================================

interface RateLimitEntry {
  userId: string;
  timestamps: number[];
  muteUntil?: number;
}

const rateLimitMap = new Map<string, RateLimitEntry>();
const RATE_LIMIT_COUNT = 5; // 5 messages
const RATE_LIMIT_WINDOW = 10000; // 10 seconds in ms
const MUTE_DURATION = 60000; // 1 minute mute after violation

function checkRateLimit(userId: string): { allowed: boolean; retryAfter?: number } {
  const now = Date.now();
  let entry = rateLimitMap.get(userId);
  
  // Check if user is currently muted
  if (entry?.muteUntil && now < entry.muteUntil) {
    return { allowed: false, retryAfter: entry.muteUntil - now };
  }
  
  // Initialize or reset sliding window
  if (!entry || now - (entry.timestamps[entry.timestamps.length - 1] || 0) > RATE_LIMIT_WINDOW) {
    entry = { userId, timestamps: [] };
    rateLimitMap.set(userId, entry);
  }
  
  // Clean old timestamps outside the window
  entry.timestamps = entry.timestamps.filter(ts => now - ts < RATE_LIMIT_WINDOW);
  
  // Check rate limit
  if (entry.timestamps.length >= RATE_LIMIT_COUNT) {
    // Violation - apply mute
    entry.muteUntil = now + MUTE_DURATION;
    entry.timestamps = [];
    console.warn(`[CHAT RATE LIMIT] User ${userId} exceeded limit, muted for ${MUTE_DURATION}ms`);
    return { allowed: false, retryAfter: MUTE_DURATION };
  }
  
  // Add current timestamp
  entry.timestamps.push(now);
  return { allowed: true };
}

// ==========================================
// MESSAGE SANITIZATION
// ==========================================

function sanitizeText(text: string): string {
  if (!text || typeof text !== 'string') {
    return '';
  }
  
  // Trim and limit length
  let sanitized = text.trim().slice(0, 1000);
  
  // Remove potentially harmful characters
  sanitized = sanitized
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/javascript:/gi, '')
    .replace(/on\w+\s*=/gi, '');
  
  return sanitized;
}

// ==========================================
// NOTIFICATION HELPER FOR CHAT
// ==========================================

async function sendChatNotification(
  recipientId: string,
  recipientType: 'customer' | 'technician',
  senderName: string,
  messagePreview: string,
  chatId: string,
  bookingId: string
): Promise<void> {
  try {
    // Fetch FCM tokens
    const tokensCollection = recipientType === 'customer'
      ? db.collection('customers').doc(recipientId).collection('fcmTokens')
      : db.collection('technicians').doc(recipientId).collection('fcmTokens');

    const tokensSnapshot = await tokensCollection.where('isActive', '==', true).get();

    if (tokensSnapshot.empty) {
      console.log(`[CHAT] No FCM tokens for ${recipientType}:${recipientId}`);
      return;
    }

    // Create notification document
    const notificationRef = db.collection('notifications').doc();
    await notificationRef.set({
      id: notificationRef.id,
      userId: recipientId,
      userType: recipientType,
      title: `New message from ${senderName}`,
      body: messagePreview.slice(0, 100),
      type: 'chat_message',
      data: {
        chatId,
        bookingId,
        screen: 'chat',
        type: 'chat_message',
      },
      isRead: false,
      priority: 'high',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send push to all tokens
    const tokenPromises = tokensSnapshot.docs.map(async (doc) => {
      const token = doc.data().token;
      if (!token) return;

      try {
        await admin.messaging().send({
          notification: {
            title: `New message from ${senderName}`,
            body: messagePreview.slice(0, 100),
          },
          token,
          android: {
            priority: 'high' as const,
            notification: {
              channelId: recipientType === 'customer' ? 'booking_updates' : 'job_alerts',
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: `New message from ${senderName}`,
                  body: messagePreview.slice(0, 100),
                },
                badge: 1,
                sound: 'default',
              },
            },
          },
          data: {
            type: 'chat_message',
            chatId,
            bookingId,
            screen: 'chat',
            deepLink: `homefix://app/chat/${chatId}`,
          },
        });
      } catch (error: any) {
        console.error(`[CHAT] Failed to send push to token:`, error.message);
        // Clean up invalid tokens
        if (error.code === 'messaging/registration-token-not-registered') {
          await doc.ref.delete().catch(() => {});
        }
      }
    });

    await Promise.allSettled(tokenPromises);
  } catch (error) {
    console.error(`[CHAT] Notification error:`, error);
    // Never throw - notifications are best-effort
  }
}

// ==========================================
// CALLABLE: getOrCreateChat
// ==========================================

export const getOrCreateChat = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
  console.log('✅ [getOrCreateChat] Auth UID:', context.auth?.uid);
  console.log('✅ [getOrCreateChat] Context:', JSON.stringify({ auth: context.auth }, null, 2));
  
  // 1. Verify authentication
  if (!context.auth) {
    console.error('❌ [getOrCreateChat] context.auth is NULL');
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { bookingId } = data;

  // 2. Validate input
  if (!bookingId || typeof bookingId !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'bookingId is required'
    );
  }

  try {
    // 3. Fetch booking
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Booking not found'
      );
    }

    const booking = bookingDoc.data()!;

    // 4. Verify booking status is 'accepted' or 'in_progress' and technician is assigned
    const status = booking.status;
    const technicianId = booking.technicianId || booking.assignedTechnicianId;
    const customerId = booking.customerId;

    // ALLOW ONLY: 'accepted' or 'in_progress'
    const allowedStatuses = ['accepted', 'in_progress'];
    if (!allowedStatuses.includes(status)) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Chat is only available for accepted or in-progress bookings. Current status: ${status}`
      );
    }

    if (!technicianId) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Chat is only available after a technician is assigned'
      );
    }

    // 5. Verify user is a participant
    const isCustomer = customerId === userId;
    const isTechnician = technicianId === userId;

    if (!isCustomer && !isTechnician) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'User is not a participant in this booking'
      );
    }

    // 6. Check if chat already exists (idempotent)
    const existingChats = await db.collection('chats')
      .where('bookingId', '==', bookingId)
      .limit(1)
      .get();

    if (!existingChats.empty) {
      const existingChat = existingChats.docs[0];
      return {
        chatId: existingChat.id,
        bookingId,
        customerId,
        technicianId,
        isNew: false,
      };
    }

    // 7. Create new chat (idempotent - using transaction)
    const chatRef = db.collection('chats').doc();
    
    await db.runTransaction(async (transaction) => {
      // Double-check chat doesn't exist (race condition)
      const checkChat = await transaction.get(
        db.collection('chats').where('bookingId', '==', bookingId).limit(1)
      );
      
      if (!checkChat.empty) {
        return; // Chat was created by another request
      }

      const chatData: ChatData = {
        id: chatRef.id,
        bookingId,
        customerId,
        technicianId,
        lastMessage: '',
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSenderId: '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
      };

      transaction.set(chatRef, chatData);
    });

    return {
      chatId: chatRef.id,
      bookingId,
      customerId,
      technicianId,
      isNew: true,
    };

  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error('[CHAT] getOrCreateChat error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to create chat'
    );
  }
});

// ==========================================
// CALLABLE: sendChatMessage
// ==========================================

export const sendChatMessage = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
  console.log('✅ [sendChatMessage] Auth UID:', context.auth?.uid);
  
  // 1. Verify authentication
  if (!context.auth) {
    console.error('❌ [sendChatMessage] context.auth is NULL');
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { chatId, text, imageUrl } = data;

  // 2. Validate input
  if (!chatId || typeof chatId !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'chatId is required'
    );
  }

  if (!text || typeof text !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'text is required'
    );
  }

  // 3. Sanitize text
  const sanitizedText = sanitizeText(text);
  if (!sanitizedText) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Message text is empty or invalid'
    );
  }

  // 4. Check rate limit with sliding window
  const rateCheck = checkRateLimit(userId);
  if (!rateCheck.allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      rateCheck.retryAfter 
        ? `Too many messages. Please wait ${Math.ceil(rateCheck.retryAfter/1000)} seconds.`
        : 'Too many messages. Please wait a moment.'
    );
  }

  try {
    // 5. Fetch chat
    const chatRef = db.collection('chats').doc(chatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Chat not found'
      );
    }

    const chat = chatDoc.data() as ChatData;

    // 6. Verify chat is active
    if (chat.isActive === false) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'This chat is no longer active'
      );
    }

    // 7. Verify user is a participant
    const isCustomer = chat.customerId === userId;
    const isTechnician = chat.technicianId === userId;

    if (!isCustomer && !isTechnician) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'User is not a participant in this chat'
      );
    }

    const senderType: 'customer' | 'technician' = isCustomer ? 'customer' : 'technician';

    // 7. Create message using transaction for atomicity
    const messageRef = db.collection('chats').doc(chatId)
      .collection('messages').doc();

    await db.runTransaction(async (transaction) => {
      // Get updated chat data
      const chatData = await transaction.get(chatRef);
      const chatInfo = chatData.data() as ChatData;

      // Create message
      const messageData: MessageData = {
        id: messageRef.id,
        chatId,
        senderId: userId,
        senderType,
        text: sanitizedText,
        imageUrl: imageUrl || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      };

      transaction.set(messageRef, messageData);

      // Update chat lastMessage fields
      transaction.update(chatRef, {
        lastMessage: sanitizedText.slice(0, 200),
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSenderId: userId,
      });
    });

    // 8. Send push notification to the other party
    const recipientId = isCustomer ? chat.technicianId : chat.customerId;
    const recipientType = isCustomer ? 'technician' : 'customer';
    
    // Get sender name for notification
    let senderName = 'Someone';
    try {
      if (isCustomer) {
        const customerDoc = await db.collection('customers').doc(userId).get();
        const customerData = customerDoc.data();
        senderName = customerData?.name || customerData?.fullName || 'Customer';
      } else {
        const techDoc = await db.collection('technicians').doc(userId).get();
        const techData = techDoc.data();
        senderName = techData?.name || techData?.personalDetails?.name || 'Technician';
      }
    } catch (e) {
      console.log('[CHAT] Could not fetch sender name');
    }

    // Send notification (non-blocking)
    sendChatNotification(
      recipientId,
      recipientType,
      senderName,
      sanitizedText,
      chatId,
      chat.bookingId
    ).catch(() => {});

    return {
      success: true,
      messageId: messageRef.id,
    };

  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error('[CHAT] sendChatMessage error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send message'
    );
  }
});

// ==========================================
// CALLABLE: markMessagesRead
// ==========================================

export const markMessagesRead = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
  console.log('✅ [markMessagesRead] Auth UID:', context.auth?.uid);
  
  // 1. Verify authentication
  if (!context.auth) {
    console.error('❌ [markMessagesRead] context.auth is NULL');
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { chatId } = data;

  // 2. Validate input
  if (!chatId || typeof chatId !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'chatId is required'
    );
  }

  try {
    // 3. Fetch chat
    const chatRef = db.collection('chats').doc(chatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Chat not found'
      );
    }

    const chat = chatDoc.data() as ChatData;

    // 4. Verify user is a participant
    const isCustomer = chat.customerId === userId;
    const isTechnician = chat.technicianId === userId;

    if (!isCustomer && !isTechnician) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'User is not a participant in this chat'
      );
    }

    // 5. Batch update unread messages
    const messagesRef = db.collection('chats').doc(chatId)
      .collection('messages');

    const unreadMessages = await messagesRef
      .where('isRead', '==', false)
      .where('senderId', '!=', userId)
      .limit(50)
      .get();

    if (unreadMessages.empty) {
      return { success: true, markedCount: 0 };
    }

    // Batch update
    const batch = db.batch();
    unreadMessages.docs.forEach((doc) => {
      batch.update(doc.ref, { isRead: true });
    });

    await batch.commit();

    return {
      success: true,
      markedCount: unreadMessages.size,
    };

  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error('[CHAT] markMessagesRead error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to mark messages as read'
    );
  }
});

// ==========================================
// CALLABLE: getChatDetails
// ==========================================

export const getChatDetails = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
  console.log('✅ [getChatDetails] Auth UID:', context.auth?.uid);
  
  // 1. Verify authentication
  if (!context.auth) {
    console.error('❌ [getChatDetails] context.auth is NULL');
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { chatId } = data;

  // 2. Validate input
  if (!chatId || typeof chatId !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'chatId is required'
    );
  }

  try {
    // 3. Fetch chat
    const chatRef = db.collection('chats').doc(chatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Chat not found'
      );
    }

    const chat = chatDoc.data() as ChatData;

    // 4. Verify user is a participant
    const isCustomer = chat.customerId === userId;
    const isTechnician = chat.technicianId === userId;

    if (!isCustomer && !isTechnician) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'User is not a participant in this chat'
      );
    }

    // 5. Fetch booking details for display
    const bookingRef = db.collection('bookings').doc(chat.bookingId);
    const bookingDoc = await bookingRef.get();
    
    let bookingInfo = null;
    if (bookingDoc.exists) {
      const booking = bookingDoc.data()!;
      bookingInfo = {
        id: booking.id,
        bookingNumber: booking.bookingNumber,
        serviceName: booking.serviceName || booking.serviceTitle,
        status: booking.status,
        customerName: booking.customerName,
        technicianName: booking.technicianName || booking.assignedTechnicianName,
      };
    }

    return {
      chat: {
        id: chat.id,
        bookingId: chat.bookingId,
        customerId: chat.customerId,
        technicianId: chat.technicianId,
        lastMessage: chat.lastMessage,
        lastMessageAt: chat.lastMessageAt,
        lastSenderId: chat.lastSenderId,
        isActive: chat.isActive,
      },
      booking: bookingInfo,
      isCustomer,
    };

  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error('[CHAT] getChatDetails error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get chat details'
    );
  }
});
