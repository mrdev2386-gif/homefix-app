'use client';

import React from 'react';
import { ChevronLeft, ChevronRight, ArrowUpDown } from 'lucide-react';

export interface Column {
    key: string;
    label: string;
    render?: (item: any, index: number) => React.ReactNode;
    sortable?: boolean;
    align?: 'left' | 'center' | 'right';
}

interface TableProps {
    columns: Column[];
    data: any[];
    loading?: boolean;
    pagination?: {
        currentPage: number;
        totalPages: number;
        onPageChange: (page: number) => void;
    };
    onSort?: (key: string) => void;
    sortConfig?: { key: string; direction: 'asc' | 'desc' };
    emptyMessage?: string;
    className?: string;
}

export default function Table({
    columns,
    data,
    loading,
    pagination,
    onSort,
    sortConfig,
    emptyMessage = "No data found.",
    className
}: TableProps) {

    if (loading) {
        return (
            <div className={`w-full bg-[#111827] rounded-xl border border-[#1F2937] p-8 space-y-4 ${className || ''}`}>
                {[1, 2, 3, 4, 5].map((i) => (
                    <div key={i} className="h-12 bg-[#1F2937] rounded-lg animate-pulse" />
                ))}
            </div>
        );
    }

    return (
        <div className={`bg-[#111827] rounded-xl border border-[#1F2937] shadow-lg overflow-hidden ${className || ''}`}>
            <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                    <thead>
                        <tr className="bg-[#0F172A] border-b border-[#1F2937]">
                            {columns.map((col) => (
                                <th
                                    key={col.key}
                                    className={`
                                        px-4 py-3 text-xs font-semibold text-[#9CA3AF] uppercase tracking-wider whitespace-nowrap
                                        ${col.sortable ? 'cursor-pointer hover:bg-[#1F2937] transition-colors group' : ''}
                                    `}
                                    style={{ textAlign: col.align || 'left' }}
                                    onClick={() => col.sortable && onSort && onSort(col.key)}
                                >
                                    <div className={`flex items-center gap-2 ${col.align === 'right' ? 'justify-end' : col.align === 'center' ? 'justify-center' : 'justify-start'}`}>
                                        {col.label}
                                        {col.sortable && (
                                            <ArrowUpDown size={14} className="text-[#6B7280] group-hover:text-[#6366F1]" />
                                        )}
                                    </div>
                                </th>
                            ))}
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-[#1F2937]">
                        {data.length > 0 ? (
                            data.map((item, index) => (
                                <tr key={item.id || index} className="hover:bg-[#1F2937]/50 transition-colors">
                                    {columns.map((col) => (
                                        <td key={`${item.id}-${col.key}`} className="px-4 py-3 align-middle" style={{ textAlign: col.align || 'left' }}>
                                            {col.render ? col.render(item, index) : (
                                                <span className="text-sm text-[#E5E7EB]">
                                                    {item[col.key]}
                                                </span>
                                            )}
                                        </td>
                                    ))}
                                </tr>
                            ))
                        ) : (
                            <tr>
                                <td colSpan={columns.length} className="px-4 py-16 text-center">
                                    <p className="text-[#6B7280] text-sm">{emptyMessage}</p>
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>

            {pagination && pagination.totalPages > 1 && (
                <div className="border-t border-[#1F2937] px-6 py-4 flex items-center justify-between bg-[#0F172A]">
                    <p className="text-sm text-[#9CA3AF]">
                        Page {pagination.currentPage} of {pagination.totalPages}
                    </p>
                    <div className="flex items-center gap-2">
                        <button
                            onClick={() => pagination.onPageChange(Math.max(1, pagination.currentPage - 1))}
                            disabled={pagination.currentPage === 1}
                            className="p-2 rounded-lg hover:bg-[#1F2937] text-[#9CA3AF] disabled:opacity-40 disabled:cursor-not-allowed transition-all border border-[#374151]"
                        >
                            <ChevronLeft size={18} />
                        </button>
                        <button
                            onClick={() => pagination.onPageChange(Math.min(pagination.totalPages, pagination.currentPage + 1))}
                            disabled={pagination.currentPage === pagination.totalPages}
                            className="p-2 rounded-lg hover:bg-[#1F2937] text-[#9CA3AF] disabled:opacity-40 disabled:cursor-not-allowed transition-all border border-[#374151]"
                        >
                            <ChevronRight size={18} />
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}
