'use client';

import { useEffect, useState } from 'react';

export default function DashboardCharts({ data }: { data: any[] }) {
    const [ChartComponents, setChartComponents] = useState<any>(null);

    useEffect(() => {
        const loadCharts = async () => {
            const Recharts = await import('recharts');
            setChartComponents(Recharts);
        };
        loadCharts();
    }, []);

    if (!ChartComponents) return (
        <div className="h-[400px] flex items-center justify-center bg-white rounded-3xl border border-dashed border-slate-200 text-slate-400">
            <div className="flex flex-col items-center gap-3">
                <div className="w-8 h-8 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
                <p className="text-[10px] font-black uppercase tracking-widest">Compiling Analytics</p>
            </div>
        </div>
    );

    const { CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line, XAxis, YAxis } = ChartComponents;

    return (
        <div className="grid grid-cols-1 mb-8">
            <div className="card-premium p-8 h-[400px]">
                <div className="flex items-center justify-between mb-8">
                    <div>
                        <h3 className="text-xl font-black text-slate-900 tracking-tight">Booking Trends</h3>
                        <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1">Bookings over last 7 days</p>
                    </div>
                </div>
                <div className="h-full pb-8">
                    <ResponsiveContainer width="100%" height="100%">
                        <LineChart data={data}>
                            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
                            <XAxis
                                dataKey="date"
                                axisLine={false}
                                tickLine={false}
                                tick={{ fill: '#94A3B8', fontSize: 10, fontWeight: 800 }}
                                dy={10}
                            />
                            <YAxis
                                axisLine={false}
                                tickLine={false}
                                tick={{ fill: '#94A3B8', fontSize: 10, fontWeight: 800 }}
                            />
                            <Tooltip
                                contentStyle={{
                                    borderRadius: '16px',
                                    border: 'none',
                                    boxShadow: '0 20px 50px rgba(0,0,0,0.1)',
                                    padding: '12px'
                                }}
                            />
                            <Line
                                type="monotone"
                                dataKey="count"
                                stroke="#4F46E5"
                                strokeWidth={4}
                                dot={{ fill: '#4F46E5', strokeWidth: 2, r: 6, stroke: '#fff' }}
                                activeDot={{ r: 8, strokeWidth: 0 }}
                            />
                        </LineChart>
                    </ResponsiveContainer>
                </div>
            </div>
        </div>
    );
}
