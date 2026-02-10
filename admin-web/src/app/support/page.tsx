'use client';

import { useState, useEffect } from 'react';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { supportAPI } from '@/lib/api';
import toast from 'react-hot-toast';

interface Ticket {
  id: string;
  customer_name: string;
  customer_email: string;
  customer_phone?: string;
  subject: string;
  message: string;
  status: string;
  priority: string;
  assigned_to_name?: string;
  response?: string;
  created_at?: string;
  resolved_at?: string;
}

export default function SupportPage() {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);
  const [showResponseModal, setShowResponseModal] = useState(false);
  const [responseText, setResponseText] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [priorityFilter, setPriorityFilter] = useState('all');
  const [search, setSearch] = useState('');

  useEffect(() => {
    loadTickets();
  }, [statusFilter, priorityFilter, search]);

  const loadTickets = async () => {
    try {
      setLoading(true);
      const params: any = {};
      if (statusFilter !== 'all') params.status = statusFilter;
      if (priorityFilter !== 'all') params.priority = priorityFilter;
      if (search) params.search = search;
      const res = await supportAPI.getAll(params);
      setTickets(res.data.data.tickets || []);
    } catch (error: any) {
      console.error('Failed to load tickets:', error);
      toast.error(error.response?.data?.message || 'Failed to load support tickets');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateStatus = async (ticketId: string, status: string) => {
    try {
      await supportAPI.update(ticketId, { status });
      toast.success('Ticket status updated');
      loadTickets();
      if (selectedTicket?.id === ticketId) {
        setSelectedTicket({ ...selectedTicket, status });
      }
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to update ticket');
    }
  };

  const handleUpdatePriority = async (ticketId: string, priority: string) => {
    try {
      await supportAPI.update(ticketId, { priority });
      toast.success('Ticket priority updated');
      loadTickets();
      if (selectedTicket?.id === ticketId) {
        setSelectedTicket({ ...selectedTicket, priority });
      }
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to update ticket');
    }
  };

  const handleSubmitResponse = async () => {
    if (!selectedTicket || !responseText.trim()) return;
    try {
      await supportAPI.update(selectedTicket.id, { 
        response: responseText,
        status: 'resolved'
      });
      toast.success('Response sent and ticket resolved');
      setShowResponseModal(false);
      setResponseText('');
      loadTickets();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to send response');
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this ticket?')) return;
    try {
      await supportAPI.delete(id);
      toast.success('Ticket deleted successfully');
      loadTickets();
      if (selectedTicket?.id === id) {
        setSelectedTicket(null);
      }
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to delete ticket');
    }
  };

  const getStatusColor = (status: string) => {
    const colors: any = {
      open: 'bg-blue-100 text-blue-800',
      in_progress: 'bg-yellow-100 text-yellow-800',
      resolved: 'bg-green-100 text-green-800',
      closed: 'bg-gray-100 text-gray-800',
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  };

  const getPriorityColor = (priority: string) => {
    const colors: any = {
      low: 'bg-gray-100 text-gray-800',
      medium: 'bg-blue-100 text-blue-800',
      high: 'bg-orange-100 text-orange-800',
      urgent: 'bg-red-100 text-red-800',
    };
    return colors[priority] || 'bg-gray-100 text-gray-800';
  };

  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto p-4 sm:p-6">
            <div className="max-w-7xl mx-auto">
              <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between mb-8">
                <h1 className="text-2xl md:text-3xl font-bold text-gray-800">Support Tickets</h1>
              </div>

              {/* Filters */}
              <div className="bg-white rounded-lg shadow p-4 mb-6">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Search</label>
                    <input
                      type="text"
                      placeholder="Search tickets..."
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Status</label>
                    <select
                      value={statusFilter}
                      onChange={(e) => setStatusFilter(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                    >
                      <option value="all">All Status</option>
                      <option value="open">Open</option>
                      <option value="in_progress">In Progress</option>
                      <option value="resolved">Resolved</option>
                      <option value="closed">Closed</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Priority</label>
                    <select
                      value={priorityFilter}
                      onChange={(e) => setPriorityFilter(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                    >
                      <option value="all">All Priorities</option>
                      <option value="low">Low</option>
                      <option value="medium">Medium</option>
                      <option value="high">High</option>
                      <option value="urgent">Urgent</option>
                    </select>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Tickets List */}
                <div className="lg:col-span-2">
                  {loading ? (
                    <div className="bg-white rounded-lg shadow p-8 text-center">
                      <p className="text-gray-500">Loading tickets...</p>
                    </div>
                  ) : tickets.length === 0 ? (
                    <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
                      No tickets found
                    </div>
                  ) : (
                    <div className="space-y-4">
                      {tickets.map((ticket) => (
                        <div
                          key={ticket.id}
                          onClick={() => setSelectedTicket(ticket)}
                          className={`bg-white rounded-lg shadow p-4 cursor-pointer transition ${
                            selectedTicket?.id === ticket.id ? 'ring-2 ring-primary-500' : 'hover:shadow-lg'
                          }`}
                        >
                          <div className="flex items-start justify-between mb-2">
                            <h3 className="font-semibold text-gray-800">{ticket.subject}</h3>
                            <div className="flex gap-2">
                              <span className={`px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(ticket.status)}`}>
                                {ticket.status}
                              </span>
                              <span className={`px-2 py-1 text-xs font-semibold rounded-full ${getPriorityColor(ticket.priority)}`}>
                                {ticket.priority}
                              </span>
                            </div>
                          </div>
                          <p className="text-sm text-gray-600 mb-2 line-clamp-2">{ticket.message}</p>
                          <div className="flex items-center justify-between text-xs text-gray-500">
                            <span>{ticket.customer_name} • {ticket.customer_email}</span>
                            <span>{ticket.created_at ? new Date(ticket.created_at).toLocaleDateString() : ''}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Ticket Details */}
                <div className="lg:col-span-1">
                  {selectedTicket ? (
                    <div className="bg-white rounded-lg shadow p-6 sticky top-4">
                      <div className="flex items-center justify-between mb-4">
                        <h2 className="text-xl font-bold text-gray-800">Ticket Details</h2>
                        <button
                          onClick={() => handleDelete(selectedTicket.id)}
                          className="text-red-600 hover:text-red-800 text-sm"
                        >
                          Delete
                        </button>
                      </div>

                      <div className="space-y-4">
                        <div>
                          <label className="text-sm font-medium text-gray-700">Status</label>
                          <select
                            value={selectedTicket.status}
                            onChange={(e) => handleUpdateStatus(selectedTicket.id, e.target.value)}
                            className="w-full mt-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                          >
                            <option value="open">Open</option>
                            <option value="in_progress">In Progress</option>
                            <option value="resolved">Resolved</option>
                            <option value="closed">Closed</option>
                          </select>
                        </div>

                        <div>
                          <label className="text-sm font-medium text-gray-700">Priority</label>
                          <select
                            value={selectedTicket.priority}
                            onChange={(e) => handleUpdatePriority(selectedTicket.id, e.target.value)}
                            className="w-full mt-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                          >
                            <option value="low">Low</option>
                            <option value="medium">Medium</option>
                            <option value="high">High</option>
                            <option value="urgent">Urgent</option>
                          </select>
                        </div>

                        <div>
                          <label className="text-sm font-medium text-gray-700">Customer</label>
                          <p className="text-sm text-gray-900 mt-1">{selectedTicket.customer_name}</p>
                          <p className="text-sm text-gray-600">{selectedTicket.customer_email}</p>
                          {selectedTicket.customer_phone && (
                            <p className="text-sm text-gray-600">{selectedTicket.customer_phone}</p>
                          )}
                        </div>

                        <div>
                          <label className="text-sm font-medium text-gray-700">Subject</label>
                          <p className="text-sm text-gray-900 mt-1">{selectedTicket.subject}</p>
                        </div>

                        <div>
                          <label className="text-sm font-medium text-gray-700">Message</label>
                          <p className="text-sm text-gray-900 mt-1 whitespace-pre-wrap">{selectedTicket.message}</p>
                        </div>

                        {selectedTicket.response && (
                          <div>
                            <label className="text-sm font-medium text-gray-700">Response</label>
                            <p className="text-sm text-gray-900 mt-1 whitespace-pre-wrap">{selectedTicket.response}</p>
                          </div>
                        )}

                        {selectedTicket.status !== 'resolved' && selectedTicket.status !== 'closed' && (
                          <button
                            onClick={() => setShowResponseModal(true)}
                            className="w-full px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                          >
                            Respond & Resolve
                          </button>
                        )}
                      </div>
                    </div>
                  ) : (
                    <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
                      Select a ticket to view details
                    </div>
                  )}
                </div>
              </div>

              {/* Response Modal */}
              {showResponseModal && selectedTicket && (
                <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                  <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4">
                    <h2 className="text-2xl font-bold mb-4">Respond to Ticket</h2>
                    <textarea
                      value={responseText}
                      onChange={(e) => setResponseText(e.target.value)}
                      placeholder="Enter your response..."
                      rows={6}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 mb-4"
                    />
                    <div className="flex gap-4">
                      <button
                        onClick={handleSubmitResponse}
                        className="flex-1 px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                      >
                        Send Response & Resolve
                      </button>
                      <button
                        onClick={() => {
                          setShowResponseModal(false);
                          setResponseText('');
                        }}
                        className="flex-1 px-6 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition"
                      >
                        Cancel
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </main>
        </div>
      </div>
    </AuthGuard>
  );
}
