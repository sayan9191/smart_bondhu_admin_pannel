import { useCallback, useEffect, useState } from 'react';
import {
  getBookings,
  updateBookingStatus,
  type AdminBooking,
  type Paginated,
} from '../api/client';

const STATUSES = [
  'pending',
  'confirmed',
  'assigned',
  'in_progress',
  'completed',
  'cancelled',
  'refunded',
];

function formatCurrency(value: string) {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(parseFloat(value) || 0);
}

export function BookingsPage() {
  const [data, setData] = useState<Paginated<AdminBooking> | null>(null);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const result = await getBookings(page, statusFilter || undefined, search);
      setData(result);
    } catch {
      setError('Failed to load bookings');
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter, search]);

  useEffect(() => {
    load();
  }, [load]);

  const handleStatusChange = async (booking: AdminBooking, status: string) => {
    setUpdatingId(booking.id);
    try {
      await updateBookingStatus(booking.id, status);
      await load();
    } catch {
      setError('Failed to update booking status');
    } finally {
      setUpdatingId(null);
    }
  };

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <h1>Bookings</h1>
          <p>Manage all customer bookings and update status</p>
        </div>
      </header>

      <div className="toolbar">
        <input
          className="search-input"
          placeholder="Search booking #, name, email…"
          value={search}
          onChange={(e) => {
            setPage(1);
            setSearch(e.target.value);
          }}
        />
        <select
          value={statusFilter}
          onChange={(e) => {
            setPage(1);
            setStatusFilter(e.target.value);
          }}
        >
          <option value="">All statuses</option>
          {STATUSES.map((status) => (
            <option key={status} value={status}>
              {status.replace('_', ' ')}
            </option>
          ))}
        </select>
      </div>

      {error ? <div className="alert error">{error}</div> : null}
      {loading ? (
        <div className="page-loading">Loading bookings…</div>
      ) : (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Booking #</th>
                  <th>Customer</th>
                  <th>Service</th>
                  <th>Scheduled</th>
                  <th>Amount</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data?.items.map((booking) => (
                  <tr key={booking.id}>
                    <td>
                      <strong>{booking.booking_number}</strong>
                      <small>{new Date(booking.created_at).toLocaleDateString('en-IN')}</small>
                    </td>
                    <td>
                      <div>{booking.customer_name || '—'}</div>
                      <small>{booking.customer_phone || booking.customer_email || '—'}</small>
                    </td>
                    <td>{booking.service_name}</td>
                    <td>{new Date(booking.scheduled_at).toLocaleString('en-IN')}</td>
                    <td>{formatCurrency(booking.total_amount)}</td>
                    <td>
                      <span className={`badge status-${booking.status}`}>{booking.status}</span>
                    </td>
                    <td>
                      <select
                        value={booking.status}
                        disabled={updatingId === booking.id}
                        onChange={(e) => handleStatusChange(booking, e.target.value)}
                      >
                        {STATUSES.map((status) => (
                          <option key={status} value={status}>
                            {status.replace('_', ' ')}
                          </option>
                        ))}
                      </select>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {data && data.total_pages > 1 ? (
            <div className="pagination">
              <button
                type="button"
                className="btn ghost"
                disabled={page <= 1}
                onClick={() => setPage((p) => p - 1)}
              >
                Previous
              </button>
              <span>
                Page {data.page} of {data.total_pages}
              </span>
              <button
                type="button"
                className="btn ghost"
                disabled={page >= data.total_pages}
                onClick={() => setPage((p) => p + 1)}
              >
                Next
              </button>
            </div>
          ) : null}
        </>
      )}
    </div>
  );
}
