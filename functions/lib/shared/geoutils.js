"use strict";
/**
 * Geospatial utility functions for distance calculation and ETA estimation.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculateDistance = calculateDistance;
exports.estimateEta = estimateEta;
/**
 * Calculate the great-circle distance between two points in kilometers using the Haversine formula.
 * @param start LatLng of the starting point
 * @param end LatLng of the ending point
 * @returns Distance in kilometers
 */
function calculateDistance(start, end) {
    const R = 6371; // Radius of the Earth in km
    const dLat = degreesToRadians(end.lat - start.lat);
    const dLng = degreesToRadians(end.lng - start.lng);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(degreesToRadians(start.lat)) *
            Math.cos(degreesToRadians(end.lat)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}
/**
 * Convert degrees to radians.
 */
function degreesToRadians(degrees) {
    return degrees * (Math.PI / 180);
}
/**
 * Estimate the ETA (Estimated Time of Arrival) based on distance and average speed.
 * @param distanceKm Distance in kilometers
 * @param averageSpeedKmph Average speed in km/h (default: 30 km/h)
 * @returns Estimated time in minutes
 */
function estimateEta(distanceKm, averageSpeedKmph = 30) {
    if (distanceKm <= 0)
        return 0;
    const timeHours = distanceKm / averageSpeedKmph;
    const timeMinutes = timeHours * 60;
    // Add a buffer for traffic/parking (e.g., 5 mins + 10% variance)
    return Math.ceil(timeMinutes * 1.1 + 5);
}
//# sourceMappingURL=geoutils.js.map