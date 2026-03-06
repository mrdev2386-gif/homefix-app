import React from 'react';
import { Search, X } from 'lucide-react';

export interface FilterConfig {
  key: string;
  label: string;
  options: { value: string; label: string }[];
}

interface FilterBarProps {
  searchPlaceholder?: string;
  searchValue?: string;
  onSearchChange?: (value: string) => void;
  filters?: FilterConfig[];
  filterValues?: Record<string, string>;
  onFilterChange?: (key: string, value: string) => void;
  onClearFilters?: () => void;
}

export default function FilterBar({
  searchPlaceholder = 'Search...',
  searchValue = '',
  onSearchChange,
  filters = [],
  filterValues = {},
  onFilterChange,
  onClearFilters
}: FilterBarProps) {
  const hasActiveFilters = searchValue || Object.values(filterValues).some(v => v);

  return (
    <div className="admin-card p-4">
      <div className="flex flex-col md:flex-row gap-4">
        {/* Search Input */}
        {onSearchChange && (
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#6B7280]" />
            <input
              type="text"
              placeholder={searchPlaceholder}
              value={searchValue}
              onChange={(e) => onSearchChange(e.target.value)}
              className="input-field w-full pl-10 pr-4"
            />
          </div>
        )}

        {/* Filter Dropdowns */}
        {filters.map((filter) => (
          <div key={filter.key} className="min-w-[200px]">
            <select
              value={filterValues[filter.key] || ''}
              onChange={(e) => onFilterChange?.(filter.key, e.target.value)}
              className="input-field w-full px-4 py-2"
            >
              <option value="">{filter.label}</option>
              {filter.options.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>
        ))}

        {/* Clear Filters Button */}
        {hasActiveFilters && onClearFilters && (
          <button
            onClick={onClearFilters}
            className="flex items-center gap-2 px-4 py-2 bg-[#1F2937] hover:bg-[#374151] text-[#E5E7EB] rounded-lg transition-colors whitespace-nowrap"
          >
            <X className="w-4 h-4" />
            Clear
          </button>
        )}
      </div>
    </div>
  );
}
