import { collection, query, where, onSnapshot, orderBy, limit, Unsubscribe } from 'firebase/firestore';
import { db } from './firebase';
import type { WalletWithdrawal, WithdrawalFilters } from '@/types/finance';

export function subscribeToWithdrawals(
  filters: WithdrawalFilters,
  onSuccess: (withdrawals: WalletWithdrawal[]) => void,
  onError: (error: Error) => void,
  limitCount: number = 100
): Unsubscribe {
  try {
    let q = query(
      collection(db, 'wallet_withdrawals'),
      orderBy('requestedAt', 'desc'),
      limit(limitCount)
    );

    if (filters.status) {
      q = query(q, where('status', '==', filters.status));
    }

    return onSnapshot(
      q,
      (snapshot) => {
        const withdrawals: WalletWithdrawal[] = snapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        } as WalletWithdrawal));
        onSuccess(withdrawals);
      },
      onError
    );
  } catch (error) {
    onError(error as Error);
    return () => {};
  }
}

export function filterWithdrawalsBySearch(
  withdrawals: WalletWithdrawal[],
  searchTerm: string
): WalletWithdrawal[] {
  if (!searchTerm) return withdrawals;
  
  const term = searchTerm.toLowerCase();
  return withdrawals.filter(w => 
    w.technicianName?.toLowerCase().includes(term) ||
    w.technicianId.toLowerCase().includes(term) ||
    w.id.toLowerCase().includes(term)
  );
}
