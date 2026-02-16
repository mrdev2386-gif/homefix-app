'use client';

import { useState } from 'react';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';
import { useAuth } from '@/components/AuthProvider';

export default function SystemSetupPage() {
    const { isAdmin, loading: authLoading } = useAuth();
    const [isLoading, setIsLoading] = useState(false);
    const [message, setMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null);
    const [showModal, setShowModal] = useState(false);
    const [auditResults, setAuditResults] = useState<any>(null);
    const [isAuditing, setIsAuditing] = useState(false);

    if (authLoading) return <div className="p-8 text-slate-500">Loading authentication status...</div>;
    if (!isAdmin) return <div className="p-8 text-red-600 font-semibold">Access Denied: Admin privileges required.</div>;

    const handleInitialize = async () => {
        setIsLoading(true);
        setMessage(null);
        setShowModal(false);

        try {
            const fn = httpsCallable(functions, 'admin_initializeHomeContent');
            const result = await fn();
            // @ts-ignore
            setMessage({ type: 'success', text: result.data.message || 'Initialization successful!' });
        } catch (error: any) {
            console.error('Initialization error:', error);
            setMessage({ type: 'error', text: error.message || 'Initialization failed' });
        } finally {
            setIsLoading(false);
        }
    };

    const handleBackfillImages = async () => {
        setIsLoading(true);
        setMessage(null);

        try {
            const fn = httpsCallable(functions, 'admin_backfillImages');
            const result = await fn();
            const data = result.data as any;
            setMessage({
                type: 'success',
                text: `IMAGE BACKFILL: SUCCESS. categories updated: ${data.categoriesUpdated}, services updated: ${data.servicesUpdated}, subServices updated: ${data.subServicesUpdated}`
            });
        } catch (error: any) {
            console.error('Backfill error:', error);
            setMessage({ type: 'error', text: error.message || 'Backfill failed' });
        } finally {
            setIsLoading(false);
        }
    };

    const handleAudit = async () => {
        setIsAuditing(true);
        setAuditResults(null);
        setMessage(null);

        try {
            const fn = httpsCallable(functions, 'admin_auditServiceCatalog');
            const result = await fn();
            const data = result.data as any;
            setAuditResults(data);
            setMessage({ type: 'success', text: 'Audit completed successfully!' });
        } catch (error: any) {
            console.error('Audit error:', error);
            setMessage({ type: 'error', text: error.message || 'Audit failed' });
        } finally {
            setIsAuditing(false);
        }
    };



    return (
        <div className="p-8 max-w-4xl mx-auto">
            <h1 className="text-2xl font-bold mb-6 text-slate-800">System Initialization / Master Data Setup</h1>

            <div className="bg-white p-8 rounded-xl shadow-sm border border-slate-200">
                <div className="mb-6">
                    <h2 className="text-lg font-semibold text-slate-700 mb-2">Master Data Seeding</h2>
                    <p className="text-slate-600 leading-relaxed">
                        Use this tool to initialize the master data for the HomeFix application.
                        This includes populating the following collections if they are empty:
                    </p>
                    <ul className="list-disc list-inside mt-2 text-slate-600 space-y-1 ml-2">
                        <li>Technician Categories (30-40 items)</li>
                        <li>Technician Subcategories (4-7 per category)</li>
                        <li>Cleaning Essentials</li>
                        <li>Celebrating Professionals</li>
                        <li>Service Bottom Banners</li>
                    </ul>
                </div>

                <div className="bg-amber-50 border-l-4 border-amber-500 p-4 mb-8 rounded-r-md">
                    <div className="flex items-start">
                        <span className="text-2xl mr-3">⚠️</span>
                        <div>
                            <p className="text-amber-800 font-medium">Important Information</p>
                            <p className="text-amber-700 text-sm mt-1">
                                This operation is <strong>idempotent</strong> (safe to run multiple times).
                                It will strictly check if collections are empty before writing any data.
                                Existing data will NOT be overwritten.
                            </p>
                        </div>
                    </div>
                </div>

                <button
                    onClick={() => setShowModal(true)}
                    disabled={isLoading}
                    className="w-full sm:w-auto bg-red-600 hover:bg-red-700 text-white font-bold py-4 px-8 rounded-lg shadow-md transition-all hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-3 transform active:scale-95"
                >
                    {isLoading ? (
                        <>
                            <span className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
                            Processing Initialization...
                        </>
                    ) : (
                        <>🚀 Initialize Home & Service Master Data</>
                    )}
                </button>

                <div className="mt-12 pt-8 border-t border-slate-100">
                    <h2 className="text-lg font-semibold text-slate-700 mb-2">Image URL Backfill</h2>
                    <p className="text-slate-600 leading-relaxed mb-6">
                        Systematically check all categories, services, and sub-services.
                        Ensures every document has a valid `imageUrl` field.
                    </p>

                    <button
                        onClick={handleBackfillImages}
                        disabled={isLoading}
                        className="w-full sm:w-auto bg-slate-800 hover:bg-slate-900 text-white font-bold py-4 px-8 rounded-lg shadow-md transition-all hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-3 transform active:scale-95"
                    >
                        {isLoading ? (
                            <>
                                <span className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
                                Processing Backfill...
                            </>
                        ) : (
                            <>🖼️ Run Safe Image Backfill</>
                        )}
                    </button>
                </div>

                <div className="mt-12 pt-8 border-t border-slate-100">
                    <h2 className="text-lg font-semibold text-slate-700 mb-2">📊 Service Catalog Audit</h2>
                    <p className="text-slate-600 leading-relaxed mb-6">
                        Get real-time statistics about your service catalog including categories, services, and sub-services counts.
                        This is a read-only operation that does NOT modify any data.
                    </p>

                    <button
                        onClick={handleAudit}
                        disabled={isAuditing || isLoading}
                        className="w-full sm:w-auto bg-blue-600 hover:bg-blue-700 text-white font-bold py-4 px-8 rounded-lg shadow-md transition-all hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-3 transform active:scale-95"
                    >
                        {isAuditing ? (
                            <>
                                <span className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
                                Running Audit...
                            </>
                        ) : (
                            <>📊 Run Service Catalog Audit</>
                        )}
                    </button>

                    {auditResults && (
                        <div className="mt-6 bg-slate-50 border border-slate-200 rounded-lg p-6 space-y-6">
                            {/* Summary */}
                            <div>
                                <h3 className="text-lg font-bold text-slate-800 mb-4 border-b border-slate-300 pb-2">SUMMARY</h3>
                                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                                    <div className="bg-white p-4 rounded-lg border border-slate-200">
                                        <div className="text-2xl font-bold text-blue-600">{auditResults.totalCategories}</div>
                                        <div className="text-sm text-slate-600 mt-1">Total Categories</div>
                                    </div>
                                    <div className="bg-white p-4 rounded-lg border border-slate-200">
                                        <div className="text-2xl font-bold text-green-600">{auditResults.totalServices}</div>
                                        <div className="text-sm text-slate-600 mt-1">Total Services</div>
                                    </div>
                                    <div className="bg-white p-4 rounded-lg border border-slate-200">
                                        <div className="text-2xl font-bold text-purple-600">{auditResults.totalSubServices}</div>
                                        <div className="text-sm text-slate-600 mt-1">Total Sub-Services</div>
                                    </div>
                                    <div className="bg-white p-4 rounded-lg border border-slate-200">
                                        <div className="text-2xl font-bold text-orange-600">{auditResults.averageSubServicesPerService}</div>
                                        <div className="text-sm text-slate-600 mt-1">Avg Sub-Services</div>
                                    </div>
                                </div>
                            </div>

                            {/* Breakdown */}
                            <div>
                                <h3 className="text-lg font-bold text-slate-800 mb-4 border-b border-slate-300 pb-2">BREAKDOWN</h3>
                                <div className="space-y-3">
                                    <div className="flex justify-between items-center p-3 bg-white rounded-lg border border-slate-200">
                                        <span className="text-slate-700">Services with Zero Sub-Services</span>
                                        <span className={`font-bold text-lg ${(auditResults.servicesWithZeroSubServices?.length || 0) > 0 ? 'text-red-600' : 'text-green-600'}`}>
                                            {auditResults.servicesWithZeroSubServices?.length || 0}
                                        </span>
                                    </div>
                                    <div className="flex justify-between items-center p-3 bg-white rounded-lg border border-slate-200">
                                        <span className="text-slate-700">Services Below Minimum (&lt;4)</span>
                                        <span className={`font-bold text-lg ${(auditResults.servicesBelowMinimum?.length || 0) > 0 ? 'text-amber-600' : 'text-green-600'}`}>
                                            {auditResults.servicesBelowMinimum?.length || 0}
                                        </span>
                                    </div>
                                    <div className="flex justify-between items-center p-3 bg-white rounded-lg border border-slate-200">
                                        <span className="text-slate-700">Healthy Services (≥4)</span>
                                        <span className="font-bold text-lg text-green-600">
                                            {auditResults.servicesHealthy?.length || 0}
                                        </span>
                                    </div>
                                </div>
                            </div>

                            {/* Services with Zero Sub-Services List */}
                            {auditResults.servicesWithZeroSubServices && auditResults.servicesWithZeroSubServices.length > 0 && (
                                <div>
                                    <h3 className="text-md font-semibold text-red-700 mb-3">⚠️ Services with Zero Sub-Services</h3>
                                    <div className="bg-white rounded-lg border border-red-200 p-4 max-h-60 overflow-y-auto">
                                        <ul className="space-y-2">
                                            {auditResults.servicesWithZeroSubServices.map((service: string, idx: number) => (
                                                <li key={idx} className="text-sm text-slate-700 flex items-start gap-2">
                                                    <span className="text-red-500 mt-0.5">•</span>
                                                    <span>{service}</span>
                                                </li>
                                            ))}
                                        </ul>
                                    </div>
                                </div>
                            )}

                            {/* Services Below Minimum List */}
                            {auditResults.servicesBelowMinimum && auditResults.servicesBelowMinimum.length > 0 && (
                                <div>
                                    <h3 className="text-md font-semibold text-amber-700 mb-3">⚠️ Services Below Minimum</h3>
                                    <div className="bg-white rounded-lg border border-amber-200 p-4 max-h-60 overflow-y-auto">
                                        <ul className="space-y-2">
                                            {auditResults.servicesBelowMinimum.map((service: any, idx: number) => (
                                                <li key={idx} className="text-sm text-slate-700 flex items-start gap-2">
                                                    <span className="text-amber-500 mt-0.5">•</span>
                                                    <span>{service.name} ({service.count} sub-services)</span>
                                                </li>
                                            ))}
                                        </ul>
                                    </div>
                                </div>
                            )}
                        </div>
                    )}
                </div>


                {message && (
                    <div className={`mt-8 p-4 rounded-lg border flex items-center gap-3 animate-fadeIn ${message.type === 'success' ? 'bg-green-50 text-green-800 border-green-200' : 'bg-red-50 text-red-800 border-red-200'}`}>
                        <span className="text-xl">{message.type === 'success' ? '✅' : '❌'}</span>
                        <p className="font-medium">{message.text}</p>
                    </div>
                )}
            </div>

            {/* Confirmation Modal */}
            {showModal && (
                <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <div className="bg-white p-6 rounded-xl shadow-2xl max-w-md w-full mx-auto transform transition-all scale-100">
                        <h3 className="text-xl font-bold mb-3 text-slate-800">Confirm Initialization</h3>
                        <p className="text-slate-600 mb-8 leading-relaxed">
                            Are you sure you want to initialize the system master data? This will trigger a Cloud Function to check and populate key Firestore collections.
                        </p>
                        <div className="flex justify-end gap-3">
                            <button
                                onClick={() => setShowModal(false)}
                                className="px-5 py-2.5 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors font-medium"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={handleInitialize}
                                className="px-5 py-2.5 bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors font-medium shadow-sm"
                            >
                                Confirm Execution
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
