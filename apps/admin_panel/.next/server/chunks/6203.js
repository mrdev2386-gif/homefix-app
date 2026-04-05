"use strict";
exports.id = 6203;
exports.ids = [6203];
exports.modules = {

/***/ 6203:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   B_: () => (/* binding */ markBookingCompleted),
/* harmony export */   Cp: () => (/* binding */ subscribeToBookings),
/* harmony export */   E7: () => (/* binding */ markBookingActive),
/* harmony export */   VA: () => (/* binding */ approveBookingAction),
/* harmony export */   db: () => (/* binding */ getCustomerBookingCount),
/* harmony export */   k4: () => (/* binding */ rejectBookingAction),
/* harmony export */   ob: () => (/* binding */ subscribeToBooking),
/* harmony export */   pz: () => (/* binding */ updatePaymentStatus)
/* harmony export */ });
/* unused harmony exports getPaginatedBookings, getBookingById, assignTechnician */
/* harmony import */ var _lib_firebase__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(4961);
/* harmony import */ var firebase_firestore__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(1522);
/* harmony import */ var firebase_functions__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(3997);




// Helper function to parse booking data
function parseBookingData(bookingDoc, user, technician, service) {
    const data = bookingDoc.data();
    let addressText = "";
    if (typeof data.address === "string") {
        addressText = data.address;
    } else if (data.address && typeof data.address === "object") {
        addressText = data.address.text || data.address.line1 || "";
    } else if (user?.address) {
        addressText = typeof user.address === "string" ? user.address : user.address.text || user.address.line1 || "";
    }
    return {
        id: bookingDoc.id,
        customerId: data.customerId,
        customerName: user?.name || data.customerName || "Unknown Customer",
        customerPhone: user?.phone || data.customerPhone || "",
        customerEmail: user?.email || data.customerEmail || "",
        customerAddress: addressText,
        city: data.city || user?.city || "",
        technicianId: data.technicianId,
        technicianName: technician?.name || data.technicianName,
        technicianPhone: technician?.phone || data.technicianPhone,
        technicianRating: technician?.rating,
        technicianExperience: technician?.experience,
        technicianPhoto: technician?.photo || technician?.profileImage || data.technicianPhoto,
        technicianTotalJobs: technician?.totalJobs || technician?.completedJobs || data.technicianTotalJobs,
        serviceId: data.serviceId,
        serviceName: service?.name || data.serviceName || "Unknown Service",
        serviceDescription: service?.description || data.serviceDescription || "",
        categoryName: service?.category || data.categoryName || "",
        servicePrice: data.totalPrice || data.price || 0,
        offerPrice: service?.offerPrice || data.offerPrice,
        serviceImage: service?.image || data.serviceImage,
        bookingDate: data.bookingDate || data.scheduledDate,
        timeSlot: data.timeSlot || data.scheduledTime || "",
        notes: data.notes || data.customerNotes || "",
        status: data.status,
        paymentStatus: data.paymentStatus || "PENDING",
        paymentMethod: data.paymentMethod,
        transactionId: data.transactionId,
        createdAt: data.createdAt,
        adminApprovedAt: data.adminApprovedAt,
        technicianAcceptedAt: data.technicianAcceptedAt,
        serviceStartedAt: data.serviceStartedAt,
        completedAt: data.completedAt,
        cancelledAt: data.cancelledAt,
        rejectionReason: data.rejectionReason
    };
}
// Subscribe to single booking with real-time updates
function subscribeToBooking(bookingId, callback) {
    return (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .onSnapshot */ .cf)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .doc */ .JU)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__.db, "bookings", bookingId), async (snapshot)=>{
        try {
            if (!snapshot.exists()) {
                callback(null);
                return;
            }
            const data = snapshot.data();
            const [userSnap, technicianSnap, serviceSnap] = await Promise.all([
                data.customerId ? (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .getDoc */ .QT)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .doc */ .JU)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__.db, "users", data.customerId)) : Promise.resolve(null),
                data.technicianId ? (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .getDoc */ .QT)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .doc */ .JU)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__.db, "technicians", data.technicianId)) : Promise.resolve(null),
                data.serviceId ? (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .getDoc */ .QT)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .doc */ .JU)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__.db, "services", data.serviceId)) : Promise.resolve(null)
            ]);
            const user = userSnap?.exists() ? userSnap.data() : null;
            const technician = technicianSnap?.exists() ? technicianSnap.data() : null;
            const service = serviceSnap?.exists() ? serviceSnap.data() : null;
            const booking = parseBookingData(snapshot, user, technician, service);
            callback(booking);
        } catch (error) {
            console.error("Error in booking subscription:", error);
            callback(null);
        }
    });
}
// Optimized: Fetch paginated bookings with minimal data
async function getPaginatedBookings(pageSize = 20, cursor, filters) {
    try {
        const constraints = [
            orderBy("createdAt", "desc"),
            firestoreLimit(pageSize + 1)
        ];
        if (filters?.status) {
            constraints.push(where("status", "==", filters.status));
        }
        if (filters?.paymentStatus) {
            constraints.push(where("paymentStatus", "==", filters.paymentStatus));
        }
        if (cursor) {
            constraints.push(startAfter(cursor));
        }
        const q = query(collection(db, "bookings"), ...constraints);
        const snapshot = await getDocs(q);
        const docs = snapshot.docs.slice(0, pageSize);
        const hasMore = snapshot.docs.length > pageSize;
        const nextCursor = docs.length > 0 ? docs[docs.length - 1] : undefined;
        // Fetch related data only for current page
        const bookingIds = docs.map((d)=>d.id);
        const customerIds = [
            ...new Set(docs.map((d)=>d.data().customerId))
        ];
        const technicianIds = [
            ...new Set(docs.map((d)=>d.data().technicianId).filter(Boolean))
        ];
        const serviceIds = [
            ...new Set(docs.map((d)=>d.data().serviceId))
        ];
        const [usersSnap, techniciansSnap, servicesSnap] = await Promise.all([
            customerIds.length > 0 ? getDocs(query(collection(db, "users"), where("__name__", "in", customerIds))) : Promise.resolve({
                docs: []
            }),
            technicianIds.length > 0 ? getDocs(query(collection(db, "technicians"), where("__name__", "in", technicianIds))) : Promise.resolve({
                docs: []
            }),
            serviceIds.length > 0 ? getDocs(query(collection(db, "services"), where("__name__", "in", serviceIds))) : Promise.resolve({
                docs: []
            })
        ]);
        const usersMap = new Map(usersSnap.docs.map((d)=>[
                d.id,
                d.data()
            ]));
        const techniciansMap = new Map(techniciansSnap.docs.map((d)=>[
                d.id,
                d.data()
            ]));
        const servicesMap = new Map(servicesSnap.docs.map((d)=>[
                d.id,
                d.data()
            ]));
        const bookings = docs.map((bookingDoc)=>{
            const data = bookingDoc.data();
            const user = usersMap.get(data.customerId);
            const technician = data.technicianId ? techniciansMap.get(data.technicianId) : null;
            const service = servicesMap.get(data.serviceId);
            return parseBookingData(bookingDoc, user, technician, service);
        });
        return {
            docs: bookings,
            hasMore,
            nextCursor
        };
    } catch (error) {
        console.error("Error fetching paginated bookings:", error);
        throw error;
    }
}
// Optimized: Get booking by ID with minimal queries
async function getBookingById(bookingId) {
    try {
        const bookingDoc = await getDoc(doc(db, "bookings", bookingId));
        if (!bookingDoc.exists()) {
            return null;
        }
        const data = bookingDoc.data();
        const [userSnap, technicianSnap, serviceSnap] = await Promise.all([
            data.customerId ? getDoc(doc(db, "users", data.customerId)) : Promise.resolve(null),
            data.technicianId ? getDoc(doc(db, "technicians", data.technicianId)) : Promise.resolve(null),
            data.serviceId ? getDoc(doc(db, "services", data.serviceId)) : Promise.resolve(null)
        ]);
        const user = userSnap?.exists() ? userSnap.data() : null;
        const technician = technicianSnap?.exists() ? technicianSnap.data() : null;
        const service = serviceSnap?.exists() ? serviceSnap.data() : null;
        return parseBookingData(bookingDoc, user, technician, service);
    } catch (error) {
        console.error("Error fetching booking by ID:", error);
        throw error;
    }
}
// Optimized: Subscribe to paginated bookings
function subscribeToBookings(callback, pageSize = 20, filters) {
    const constraints = [
        (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .orderBy */ .Xo)("createdAt", "desc"),
        (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .limit */ .b9)(pageSize)
    ];
    if (filters?.status) {
        constraints.push((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .where */ .ar)("status", "==", filters.status));
    }
    if (filters?.paymentStatus) {
        constraints.push((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .where */ .ar)("paymentStatus", "==", filters.paymentStatus));
    }
    const q = (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .query */ .IO)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .collection */ .hJ)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__.db, "bookings"), ...constraints);
    return (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .onSnapshot */ .cf)(q, async (snapshot)=>{
        try {
            const docs = snapshot.docs;
            // Fetch related data only for current page
            const customerIds = [
                ...new Set(docs.map((d)=>d.data().customerId))
            ];
            const technicianIds = [
                ...new Set(docs.map((d)=>d.data().technicianId).filter(Boolean))
            ];
            const serviceIds = [
                ...new Set(docs.map((d)=>d.data().serviceId))
            ];
            const [usersSnap, techniciansSnap, servicesSnap] = await Promise.all([
                customerIds.length > 0 ? (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .getDocs */ .PL)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .query */ .IO)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .collection */ .hJ)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__.db, "users"), (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .where */ .ar)("__name__", "in", customerIds))) : Promise.resolve({
                    docs: []
                }),
                technicianIds.length > 0 ? (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .getDocs */ .PL)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .query */ .IO)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .collection */ .hJ)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__.db, "technicians"), (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .where */ .ar)("__name__", "in", technicianIds))) : Promise.resolve({
                    docs: []
                }),
                serviceIds.length > 0 ? (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .getDocs */ .PL)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .query */ .IO)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .collection */ .hJ)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__.db, "services"), (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .where */ .ar)("__name__", "in", serviceIds))) : Promise.resolve({
                    docs: []
                })
            ]);
            const usersMap = new Map(usersSnap.docs.map((d)=>[
                    d.id,
                    d.data()
                ]));
            const techniciansMap = new Map(techniciansSnap.docs.map((d)=>[
                    d.id,
                    d.data()
                ]));
            const servicesMap = new Map(servicesSnap.docs.map((d)=>[
                    d.id,
                    d.data()
                ]));
            const bookings = docs.map((bookingDoc)=>{
                const data = bookingDoc.data();
                const user = usersMap.get(data.customerId);
                const technician = data.technicianId ? techniciansMap.get(data.technicianId) : null;
                const service = servicesMap.get(data.serviceId);
                return parseBookingData(bookingDoc, user, technician, service);
            });
            callback(bookings, docs.length >= pageSize);
        } catch (error) {
            console.error("Error in booking subscription:", error);
            callback([], false);
        }
    });
}
// Get customer booking count
async function getCustomerBookingCount(customerId) {
    try {
        const snapshot = await (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .getDocs */ .PL)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .query */ .IO)((0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .collection */ .hJ)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__.db, "bookings"), (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .where */ .ar)("customerId", "==", customerId), (0,firebase_firestore__WEBPACK_IMPORTED_MODULE_1__/* .limit */ .b9)(1000)));
        return snapshot.size;
    } catch (error) {
        console.error("Error getting customer booking count:", error);
        return 0;
    }
}
// Cloud Function calls
async function approveBookingAction(bookingId) {
    const approve = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_2__/* .httpsCallable */ .V1)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__/* .functions */ .wk, "approveBooking");
    await approve({
        bookingId
    });
}
async function rejectBookingAction(bookingId, reason) {
    const reject = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_2__/* .httpsCallable */ .V1)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__/* .functions */ .wk, "rejectBooking");
    await reject({
        bookingId,
        reason
    });
}
async function assignTechnician(bookingId, technicianId) {
    const assign = httpsCallable(functions, "assignTechnician");
    await assign({
        bookingId,
        technicianId
    });
}
async function markBookingActive(bookingId) {
    const markActive = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_2__/* .httpsCallable */ .V1)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__/* .functions */ .wk, "markBookingActive");
    await markActive({
        bookingId
    });
}
async function markBookingCompleted(bookingId) {
    const complete = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_2__/* .httpsCallable */ .V1)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__/* .functions */ .wk, "completeBooking");
    await complete({
        bookingId
    });
}
async function updatePaymentStatus(bookingId, paymentStatus) {
    const updatePayment = (0,firebase_functions__WEBPACK_IMPORTED_MODULE_2__/* .httpsCallable */ .V1)(_lib_firebase__WEBPACK_IMPORTED_MODULE_0__/* .functions */ .wk, "updateBookingPayment");
    await updatePayment({
        bookingId,
        paymentStatus
    });
}


/***/ })

};
;