/**
 * Validation Utilities
 * 
 * This file provides validation functions for form inputs in the finance
 * and settings module.
 */

/**
 * Validate email format
 */
export function validateEmail(email: string): string | null {
  if (!email) {
    return 'Email is required';
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return 'Invalid email format';
  }

  return null;
}

/**
 * Validate phone number format
 * Accepts formats: +91XXXXXXXXXX, XXXXXXXXXX, +91 XXXX XXXXXX, etc.
 */
export function validatePhoneNumber(phone: string): string | null {
  if (!phone) {
    return 'Phone number is required';
  }

  const phoneRegex = /^\+?[\d\s\-()]+$/;
  if (!phoneRegex.test(phone)) {
    return 'Invalid phone format. Use digits, spaces, +, -, or ()';
  }

  // Remove all non-digit characters to check length
  const digitsOnly = phone.replace(/\D/g, '');
  if (digitsOnly.length < 10) {
    return 'Phone number must have at least 10 digits';
  }

  return null;
}

/**
 * Validate commission percentage (0-100)
 */
export function validateCommissionPercentage(value: number): string | null {
  if (value === null || value === undefined) {
    return 'Commission percentage is required';
  }

  if (isNaN(value)) {
    return 'Commission must be a number';
  }

  if (value < 0 || value > 100) {
    return 'Commission must be between 0 and 100';
  }

  return null;
}

/**
 * Validate minimum withdrawal amount (positive number)
 */
export function validateMinWithdrawalAmount(value: number): string | null {
  if (value === null || value === undefined) {
    return 'Minimum withdrawal amount is required';
  }

  if (isNaN(value)) {
    return 'Amount must be a number';
  }

  if (value <= 0) {
    return 'Amount must be greater than zero';
  }

  return null;
}

/**
 * Validate rejection reason (min 10 characters)
 */
export function validateRejectionReason(reason: string): string | null {
  if (!reason || !reason.trim()) {
    return 'Rejection reason is required';
  }

  if (reason.trim().length < 10) {
    return 'Rejection reason must be at least 10 characters';
  }

  return null;
}

/**
 * Validate admin notes (optional, but if provided should be meaningful)
 */
export function validateAdminNotes(notes: string): string | null {
  if (notes && notes.trim().length > 0 && notes.trim().length < 5) {
    return 'Notes should be at least 5 characters if provided';
  }

  return null;
}

/**
 * Generic required field validator
 */
export function validateRequired(value: any, fieldName: string): string | null {
  if (value === null || value === undefined || value === '') {
    return `${fieldName} is required`;
  }

  if (typeof value === 'string' && !value.trim()) {
    return `${fieldName} is required`;
  }

  return null;
}

/**
 * Validate positive number
 */
export function validatePositiveNumber(value: number, fieldName: string): string | null {
  if (value === null || value === undefined) {
    return `${fieldName} is required`;
  }

  if (isNaN(value)) {
    return `${fieldName} must be a number`;
  }

  if (value < 0) {
    return `${fieldName} must be positive`;
  }

  return null;
}

/**
 * Validate number range
 */
export function validateNumberRange(
  value: number,
  min: number,
  max: number,
  fieldName: string
): string | null {
  if (value === null || value === undefined) {
    return `${fieldName} is required`;
  }

  if (isNaN(value)) {
    return `${fieldName} must be a number`;
  }

  if (value < min || value > max) {
    return `${fieldName} must be between ${min} and ${max}`;
  }

  return null;
}

/**
 * Validate minimum length
 */
export function validateMinLength(
  value: string,
  minLength: number,
  fieldName: string
): string | null {
  if (!value || !value.trim()) {
    return `${fieldName} is required`;
  }

  if (value.trim().length < minLength) {
    return `${fieldName} must be at least ${minLength} characters`;
  }

  return null;
}

/**
 * Validate maximum length
 */
export function validateMaxLength(
  value: string,
  maxLength: number,
  fieldName: string
): string | null {
  if (value && value.length > maxLength) {
    return `${fieldName} must not exceed ${maxLength} characters`;
  }

  return null;
}
