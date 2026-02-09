'use client';

import React from 'react';
import { ChevronLeft, ChevronRight, ArrowUpDown } from 'lucide-react';

interface Column {
    key: string;
    label: string;
    render?: (item: any) => React.ReactNode;
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
    className?: string; // Added className prop
}

export default function Table({
    columns,
    data,
    loading,
    pagination,
    onSort,
    sortConfig,
    emptyMessage = "No data found.",
    className // Destructure className
}: TableProps) {

    if (loading) {
        return (
            <div className={`w-full bg-slate-900/40 backdrop-blur-sm rounded-[32px] border border-slate-800/50 p-8 space-y-4 ${className}`}>
                {[1, 2, 3, 4, 5].map((i) => (
                    <div key={i} className="h-12 bg-slate-800/50 rounded-xl animate-pulse" />
                ))}
            </div>
        );
    }

    return (
        <div className={`bg-slate-900/40 backdrop-blur-sm rounded-[32px] border border-slate-800/50 shadow-sm overflow-hidden ${className}`}>
            <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                    <thead>
                        <tr className="bg-slate-950/20 border-b border-slate-800/50">
                            {columns.map((col) => (
                                <th
                                    key={col.key}
                                    className={`
                                        px-6 py-5 text-[10px] font-black text-slate-500 uppercase tracking-widest whitespace-nowrap
                                        ${col.sortable ? 'cursor-pointer hover:bg-slate-800/50 transition-colors group' : ''}
                                        text-${col.align || 'left'}
                                    `}
                                    onClick={() => col.sortable && onSort && onSort(col.key)}
                                >
                                    <div className={`flex items-center gap-2 ${col.align === 'right' ? 'justify-end' : col.align === 'center' ? 'justify-center' : 'justify-start'}`}>
                                        {col.label}
                                        {col.sortable && (
                                            <div className="flex flex-col text-slate-600 group-hover:text-indigo-400">
                                                <ArrowUpDown size={12} />
                                            </div>
                                        )}
                                    </div>
                                </th>
                            ))}
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/50">
                        {data.length > 0 ? (
                            data.map((item, index) => (
                                <tr key={item.id || index} className="group hover:bg-indigo-500/5 transition-colors duration-200">
                                    {columns.map((col) => (
                                        <td key={`${item.id}-${col.key}`} className={`px-6 py-5 align-middle text-${col.align || 'left'}`}>
                                            {col.render ? col.render(item) : (
                                                <span className="text-sm font-bold text-slate-300">
                                                    {item[col.key]}
                                                </span>
                                            )}
                                        </td>
                                    ))}
                                </tr>
                            ))
                        ) : (
                            <tr>
                                <td colSpan={columns.length} className="px-6 py-24 text-center">
                                    <p className="text-slate-600 font-bold text-sm">{emptyMessage}</p>
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>

            {/* Pagination */}
            {pagination && pagination.totalPages > 1 && (
                <div className="border-t border-slate-800/50 px-6 py-4 flex items-center justify-between bg-slate-950/20">
                    <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest">
                        Page {pagination.currentPage} of {pagination.totalPages}
                    </p>
                    <div className="flex items-center gap-2">
                        <button
                            onClick={() => pagination.onPageChange(Math.max(1, pagination.currentPage - 1))}
                            disabled={pagination.currentPage === 1}
                            className="p-2 rounded-lg hover:bg-slate-800 text-slate-400 disabled:opacity-30 disabled:pointer-events-none transition-all active:scale-90"
                        >
                            <ChevronLeft size={18} />
                        </button>
                        <button
                            onClick={() => pagination.onPageChange(Math.min(pagination.totalPages, pagination.currentPage + 1))}
                            disabled={pagination.currentPage === pagination.totalPages}
                            className="p-2 rounded-lg hover:bg-slate-800 text-slate-400 disabled:opacity-30 disabled:pointer-events-none transition-all active:scale-90"
                        >
                            <ChevronRight size={18} />
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}
