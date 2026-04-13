'use client';

import React, { useState } from 'react';
import { X, AlertTriangle } from 'lucide-react';

interface ConfirmDialogProps {
  isOpen: boolean;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: (inputValue?: string) => void;
  onCancel: () => void;
  requireInput?: boolean;
  inputLabel?: string;
  inputPlaceholder?: string;
  inputValidation?: (value: string) => string | null;
  variant?: 'default' | 'danger';
}

export default function ConfirmDialog({
  isOpen,
  title,
  message,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  onConfirm,
  onCancel,
  requireInput = false,
  inputLabel,
  inputPlaceholder,
  inputValidation,
  variant = 'default'
}: ConfirmDialogProps) {
  const [inputValue, setInputValue] = useState('');
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleConfirm = () => {
    if (requireInput) {
      const validationError = inputValidation?.(inputValue);
      if (validationError) {
        setError(validationError);
        return;
      }
      onConfirm(inputValue);
    } else {
      onConfirm();
    }
    setInputValue('');
    setError(null);
  };

  const handleCancel = () => {
    setInputValue('');
    setError(null);
    onCancel();
  };

  const confirmButtonClass = variant === 'danger'
    ? 'bg-red-600 hover:bg-red-700 text-white'
    : 'bg-[#6366F1] hover:bg-[#4F46E5] text-white';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div className="bg-[#111827] border border-[#1F2937] rounded-xl shadow-2xl max-w-md w-full">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-[#1F2937]">
          <div className="flex items-center gap-3">
            {variant === 'danger' && (
              <div className="w-10 h-10 rounded-full bg-red-500/10 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5 text-red-400" />
              </div>
            )}
            <h2 className="text-xl font-bold text-[#E5E7EB]">{title}</h2>
          </div>
          <button
            onClick={handleCancel}
            className="text-[#6B7280] hover:text-[#E5E7EB] transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6">
          <p className="text-[#9CA3AF] mb-4">{message}</p>

          {requireInput && (
            <div className="space-y-2">
              {inputLabel && (
                <label className="block text-sm font-medium text-[#9CA3AF]">
                  {inputLabel}
                </label>
              )}
              <textarea
                value={inputValue}
                onChange={(e) => {
                  setInputValue(e.target.value);
                  setError(null);
                }}
                placeholder={inputPlaceholder}
                rows={3}
                className="w-full px-4 py-2 bg-[#1F2937] border border-[#374151] rounded-lg text-[#E5E7EB] placeholder-[#6B7280] focus:outline-none focus:ring-2 focus:ring-[#6366F1] focus:border-transparent resize-none"
              />
              {error && (
                <p className="text-sm text-red-400">{error}</p>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-3 p-6 border-t border-[#1F2937]">
          <button
            onClick={handleCancel}
            className="px-4 py-2 bg-[#1F2937] hover:bg-[#374151] text-[#E5E7EB] rounded-lg transition-colors font-medium"
          >
            {cancelText}
          </button>
          <button
            onClick={handleConfirm}
            className={`px-4 py-2 rounded-lg transition-colors font-medium ${confirmButtonClass}`}
          >
            {confirmText}
          </button>
        </div>
      </div>
    </div>
  );
}
