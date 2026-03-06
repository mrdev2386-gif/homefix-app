import React from 'react';
import { Loader2 } from 'lucide-react';

interface LoadingStateProps {
  message?: string;
  variant?: 'spinner' | 'skeleton';
  rows?: number;
}

export default function LoadingState({
  message = 'Loading...',
  variant = 'spinner',
  rows = 5
}: LoadingStateProps) {
  if (variant === 'skeleton') {
    return (
      <div className="space-y-4">
        {Array.from({ length: rows }).map((_, i) => (
          <div
            key={i}
            className="bg-[#111827] border border-[#1F2937] rounded-lg p-6 animate-pulse"
          >
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-[#1F2937] rounded-lg" />
              <div className="flex-1 space-y-3">
                <div className="h-4 bg-[#1F2937] rounded w-1/4" />
                <div className="h-3 bg-[#1F2937] rounded w-3/4" />
              </div>
              <div className="w-20 h-8 bg-[#1F2937] rounded" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center justify-center py-12 px-4">
      <Loader2 className="w-12 h-12 text-[#6366F1] animate-spin mb-4" />
      <p className="text-[#9CA3AF] font-medium">{message}</p>
    </div>
  );
}

interface SkeletonProps {
  className?: string;
}

export function Skeleton({ className = '' }: SkeletonProps) {
  return (
    <div className={`bg-[#1F2937] rounded animate-pulse ${className}`} />
  );
}

interface TableSkeletonProps {
  rows?: number;
  columns?: number;
}

export function TableSkeleton({ rows = 5, columns = 5 }: TableSkeletonProps) {
  return (
    <div className="bg-[#111827] border border-[#1F2937] rounded-lg overflow-hidden">
      {/* Header */}
      <div className="border-b border-[#1F2937] p-4">
        <div className="grid gap-4" style={{ gridTemplateColumns: `repeat(${columns}, 1fr)` }}>
          {Array.from({ length: columns }).map((_, i) => (
            <Skeleton key={i} className="h-4 w-3/4" />
          ))}
        </div>
      </div>
      
      {/* Rows */}
      {Array.from({ length: rows }).map((_, rowIndex) => (
        <div key={rowIndex} className="border-b border-[#1F2937] p-4 last:border-b-0">
          <div className="grid gap-4" style={{ gridTemplateColumns: `repeat(${columns}, 1fr)` }}>
            {Array.from({ length: columns }).map((_, colIndex) => (
              <Skeleton key={colIndex} className="h-4" />
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

interface CardSkeletonProps {
  count?: number;
}

export function CardSkeleton({ count = 3 }: CardSkeletonProps) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="bg-[#111827] border border-[#1F2937] rounded-lg p-6 animate-pulse">
          <Skeleton className="h-4 w-1/2 mb-4" />
          <Skeleton className="h-8 w-3/4 mb-2" />
          <Skeleton className="h-3 w-1/3" />
        </div>
      ))}
    </div>
  );
}
