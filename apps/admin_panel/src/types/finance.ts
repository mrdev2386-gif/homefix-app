/**
 * Finance-related type definitions
 */

export interface WalletWithdrawal {
  id: string;
  technicianId: string;
  technicianName?: string;
  amount: number;
  status: 'pending' | 'approved' | 'rejected' | 'completed';
  requestedAt: any; // Firestore Timestamp
  processedAt?: any; // Firestore Timestamp
  bankDetails?: {
    accountHolderName: string;
    accountNumber: string;
    ifscCode: string;
    bankName: string;
  };
  notes?: string;
  rejectionReason?: string;
}

export interface WithdrawalFilters {
  status?: string;
  technicianId?: string;
  searchTerm?: string;
  dateFrom?: Date;
  dateTo?: Date;
}
