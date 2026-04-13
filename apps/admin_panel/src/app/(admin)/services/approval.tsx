'use client';

import { useState, useEffect } from 'react';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebaseClient';

interface PendingService {
  id: string;
  technicianId: string;
  technicianName: string;
  title: string;
  categoryId: string;
  price: number;
  durationMinutes: number;
  createdAt: string;
}

export default function ServiceApprovalPage() {
  const [services, setServices] = useState<PendingService[]>([]);
  const [loading, setLoading] = useState(true);
  const [approving, setApproving] = useState<string | null>(null);

  useEffect(() => {
    fetchPendingServices();
  }, []);

  const fetchPendingServices = async () => {
    try {
      setLoading(true);
      const getPendingServices = httpsCallable(functions, 'getPendingServices');
      const result = await getPendingServices({});
      setServices((result.data as any)?.services || []);
    } catch (error) {
      console.error('Error fetching services:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (serviceId: string, technicianId: string) => {
    try {
      setApproving(serviceId);
      const approveTechnicianService = httpsCallable(functions, 'approveTechnicianService');
      await approveTechnicianService({ serviceId, technicianId });
      setServices(services.filter(s => s.id !== serviceId));
    } catch (error) {
      console.error('Error approving service:', error);
    } finally {
      setApproving(null);
    }
  };

  const handleReject = async (serviceId: string, technicianId: string) => {
    try {
      setApproving(serviceId);
      const rejectTechnicianService = httpsCallable(functions, 'rejectTechnicianService');
      await rejectTechnicianService({ serviceId, technicianId });
      setServices(services.filter(s => s.id !== serviceId));
    } catch (error) {
      console.error('Error rejecting service:', error);
    } finally {
      setApproving(null);
    }
  };

  if (loading) return <div className="p-8">Loading...</div>;

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-8">Technician Services Approval</h1>
      
      {services.length === 0 ? (
        <div className="text-gray-500">No pending services</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full border-collapse border border-gray-300">
            <thead className="bg-gray-100">
              <tr>
                <th className="border p-3 text-left">Technician</th>
                <th className="border p-3 text-left">Service</th>
                <th className="border p-3 text-left">Category</th>
                <th className="border p-3 text-right">Price</th>
                <th className="border p-3 text-right">Duration</th>
                <th className="border p-3 text-left">Created</th>
                <th className="border p-3 text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {services.map(service => (
                <tr key={service.id} className="hover:bg-gray-50">
                  <td className="border p-3">{service.technicianName}</td>
                  <td className="border p-3">{service.title}</td>
                  <td className="border p-3">{service.categoryId}</td>
                  <td className="border p-3 text-right">₹{service.price}</td>
                  <td className="border p-3 text-right">{service.durationMinutes}m</td>
                  <td className="border p-3">{new Date(service.createdAt).toLocaleDateString()}</td>
                  <td className="border p-3 text-center">
                    <button
                      onClick={() => handleApprove(service.id, service.technicianId)}
                      disabled={approving === service.id}
                      className="bg-green-500 text-white px-3 py-1 rounded mr-2 disabled:opacity-50"
                    >
                      Approve
                    </button>
                    <button
                      onClick={() => handleReject(service.id, service.technicianId)}
                      disabled={approving === service.id}
                      className="bg-red-500 text-white px-3 py-1 rounded disabled:opacity-50"
                    >
                      Reject
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
