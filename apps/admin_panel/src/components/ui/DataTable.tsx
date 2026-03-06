'use client';

import { ReactNode } from 'react';
import Table, { Column } from './Table';

interface DataTableProps {
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
  actions?: ReactNode;
  title?: string;
}

export default function DataTable({
  columns,
  data,
  loading,
  pagination,
  onSort,
  sortConfig,
  emptyMessage,
  actions,
  title,
}: DataTableProps) {
  return (
    <div className="space-y-4">
      {(title || actions) && (
        <div className="flex items-center justify-between">
          {title && <h3 className="text-lg font-semibold text-[#E5E7EB]">{title}</h3>}
          {actions && <div className="flex items-center gap-2">{actions}</div>}
        </div>
      )}
      
      <Table
        columns={columns}
        data={data}
        loading={loading}
        pagination={pagination}
        onSort={onSort}
        sortConfig={sortConfig}
        emptyMessage={emptyMessage}
      />
    </div>
  );
}
