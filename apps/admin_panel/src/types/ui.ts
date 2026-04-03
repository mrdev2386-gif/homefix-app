/**
 * Shared type definitions for UI components
 */

/**
 * State type for ConfirmDialog component
 * Used across admin pages for consistent modal state management
 */
export interface ConfirmDialogState {
  isOpen: boolean;
  title: string;
  message: string;
  onConfirm: (inputValue?: string) => void;
  variant?: 'default' | 'danger';
  requireInput?: boolean;
  inputLabel?: string;
  inputPlaceholder?: string;
}

/**
 * Initial state for ConfirmDialog
 */
export const initialConfirmDialogState: ConfirmDialogState = {
  isOpen: false,
  title: '',
  message: '',
  onConfirm: () => {},
};
