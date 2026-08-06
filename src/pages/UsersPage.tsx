import { useCallback, useEffect, useState } from 'react';
import { getUsers, updateUser, type AdminUser, type Paginated } from '../api/client';

export function UsersPage() {
  const [data, setData] = useState<Paginated<AdminUser> | null>(null);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const result = await getUsers(page, search);
      setData(result);
    } catch {
      setError('Failed to load users');
    } finally {
      setLoading(false);
    }
  }, [page, search]);

  useEffect(() => {
    load();
  }, [load]);

  const toggleActive = async (user: AdminUser) => {
    try {
      await updateUser(user.id, { is_active: !user.is_active });
      await load();
    } catch {
      setError('Failed to update user');
    }
  };

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <h1>Users</h1>
          <p>View and manage registered customers and professionals</p>
        </div>
      </header>

      <div className="toolbar">
        <input
          className="search-input"
          placeholder="Search name, email, phone…"
          value={search}
          onChange={(e) => {
            setPage(1);
            setSearch(e.target.value);
          }}
        />
      </div>

      {error ? <div className="alert error">{error}</div> : null}
      {loading ? (
        <div className="page-loading">Loading users…</div>
      ) : (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Contact</th>
                  <th>Role</th>
                  <th>Bookings</th>
                  <th>Joined</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data?.items.map((user) => (
                  <tr key={user.id}>
                    <td>
                      <strong>{user.full_name || '—'}</strong>
                      <small>{user.is_verified ? 'Verified' : 'Unverified'}</small>
                    </td>
                    <td>
                      <div>{user.email || '—'}</div>
                      <small>{user.phone || '—'}</small>
                    </td>
                    <td>
                      <span className={`badge role-${user.role}`}>{user.role}</span>
                    </td>
                    <td>{user.bookings_count}</td>
                    <td>{new Date(user.created_at).toLocaleDateString('en-IN')}</td>
                    <td>
                      <span className={`badge ${user.is_active ? 'active' : 'inactive'}`}>
                        {user.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td>
                      <button
                        type="button"
                        className="btn ghost sm"
                        onClick={() => toggleActive(user)}
                      >
                        {user.is_active ? 'Deactivate' : 'Activate'}
                      </button>
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
