const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.submitReview = functions.https.onCall(async (data, context) => {
  try {
    // 1. Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
    }

    const userId = context.auth.uid;
    const { bookingId, technicianId, rating, reviewText } = data;

    // 2. Validate input
    if (!bookingId || !technicianId || !rating) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    if (rating < 1 || rating > 5) {
      throw new functions.https.HttpsError('invalid-argument', 'Rating must be between 1 and 5');
    }

    // 3. Verify booking exists
    const bookingDoc = await admin.firestore().collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking = bookingDoc.data();

    // 4. Verify booking belongs to customer
    if (booking.customerId !== userId) {
      throw new functions.https.HttpsError('permission-denied', 'Not your booking');
    }

    // 5. Verify booking is completed
    if (booking.status !== 'completed') {
      throw new functions.https.HttpsError('failed-precondition', 'Booking not completed');
    }

    // 6. Check if review already exists
    const existingReview = await admin.firestore()
        .collection('reviews')
        .where('bookingId', '==', bookingId)
        .limit(1)
        .get();

    if (!existingReview.empty) {
      throw new functions.https.HttpsError('already-exists', 'Review already submitted');
    }

    // 7. Create review document
    const reviewRef = admin.firestore().collection('reviews').doc();
    await reviewRef.set({
      bookingId,
      technicianId,
      customerId: userId,
      rating,
      reviewText: reviewText || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 8. Recalculate technician rating
    const allReviews = await admin.firestore()
        .collection('reviews')
        .where('technicianId', '==', technicianId)
        .get();

    let totalRating = 0;
    allReviews.forEach(doc => {
      totalRating += doc.data().rating;
    });

    const averageRating = totalRating / allReviews.size;

    // 9. Update technician document
    await admin.firestore().collection('technicians').doc(technicianId).update({
      averageRating: Math.round(averageRating * 10) / 10,
      totalReviews: allReviews.size,
    });

    return { success: true, message: 'Review submitted successfully' };
  } catch (error) {
    console.error('submitReview error:', error);
    throw error;
  }
});
