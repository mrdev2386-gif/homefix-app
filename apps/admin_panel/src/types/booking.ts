export interface Booking {
  bookingId: string;
  customerId: string;
  customerName: string;
  technicianId: string;
  technicianName: string;
  serviceId: string;
  serviceName: string;
  categoryId: string;
  categoryName: string;
  scheduledDate: string;
  scheduledTime: string;
  address: {
    fullAddress?: string;
    district?: string;
    state?: string;
    pincode?: string;
  };
  price: number;
  finalAmount: number;
  paymentMode: 'before_work' | 'after_work';
  paymentMethod: 'online' | 'after_service';
  bookingStatus: string;
  status: string;
  statusHistory: Array<{
    status: string;
    timestamp: any;
  }>;
  paymentStatus: string;
  createdAt: any;
  updatedAt: any;
}

export type BookingStatus = 
  | 'pending'
  | 'pending_admin_approval'
  | 'approved_by_admin'
  | 'technician_accepted'
  | 'service_in_progress'
  | 'service_completed'
  | 'completed'
  | 'cancelled'
  | 'rejected_by_admin'
  | 'technician_rejected';
