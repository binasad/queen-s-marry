import React from 'react';

export default function PaymentsTable({ payments }: { payments: any[] }) {
  return (
    <div className="bg-white rounded-lg shadow p-6 mb-6">
      <h2 className="text-xl font-semibold text-gray-800 mb-4">Recent Payments</h2>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-200">
              <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Customer</th>
              <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Amount</th>
              <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Status</th>
              <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Date</th>
              <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Offer</th>
            </tr>
          </thead>
          <tbody>
            {(payments || []).map((payment) => (
              <tr key={payment.id} className="border-b border-gray-100 hover:bg-gray-50">
                <td className="py-3 px-4 text-sm text-gray-800">{payment.customer_name}</td>
                <td className="py-3 px-4 text-sm text-gray-800">${payment.total_price}</td>
                <td className="py-3 px-4 text-sm text-gray-600">{payment.payment_status}</td>
                <td className="py-3 px-4 text-sm text-gray-600">{new Date(payment.paid_at || payment.created_at).toLocaleString()}</td>
                <td className="py-3 px-4 text-sm">
                  {payment.offer_title ? (
                    <span className="px-2 py-0.5 text-xs rounded-full bg-pink-100 text-pink-800">🎁 {payment.offer_title}</span>
                  ) : '—'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
