import React from 'react';

interface PageContainerProps {
    children: React.ReactNode;
    title: string;
    description?: string;
    action?: React.ReactNode;
}

export default function PageContainer({
    children,
    title,
    description,
    action
}: PageContainerProps) {
    return (
        <div className="flex flex-col gap-8 max-w-full">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl md:text-3xl font-black text-slate-900 tracking-tight">{title}</h1>
                    {description && (
                        <p className="text-slate-500 font-medium mt-1">{description}</p>
                    )}
                </div>
                {action && (
                    <div className="flex-shrink-0">
                        {action}
                    </div>
                )}
            </div>

            <div className="flex flex-col gap-6 w-full">
                {children}
            </div>
        </div>
    );
}
