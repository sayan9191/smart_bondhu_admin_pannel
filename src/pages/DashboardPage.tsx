import { useEffect, useState } from 'react';
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import {
  getDashboardStats,
  getRevenueChart,
  type DashboardStats,
  type RevenuePoint,
} from '../api/client';

function formatCurrency(value: string | number) {
  const num = typeof value === 'string' ? parseFloat(value) : value;
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(num || 0);
}

export function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [revenue, setRevenue] = useState<RevenuePoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([getDashboardStats(), getRevenueChart(30)])
      .then(([statsData, chartData]) => {
        setStats(statsData);
        setRevenue(
          chartData.points.map((point) => ({
            ...point,
            label: new Date(point.date).toLocaleDateString('en-IN', {
              day: 'numeric',
              month: 'short',
            }),
            revenueNum: parseFloat(point.revenue),
          })) as RevenuePoint[],
        );
      })
      .catch(() => setError('Failed to load dashboard data'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="page-loading">Loading dashboard…</div>;
  if (error || !stats) return <div className="alert error">{error || 'No data'}</div>;

  const cards = [
    { label: 'Total Revenue', value: formatCurrency(stats.total_revenue), hint: 'All time' },
    { label: 'Revenue Today', value: formatCurrency(stats.revenue_today), hint: 'Today' },
    { label: 'Total Bookings', value: stats.total_bookings, hint: `${stats.bookings_today} today` },
    { label: 'Total Users', value: stats.total_users, hint: `${stats.new_users_today} new today` },
    { label: 'Pending Bookings', value: stats.pending_bookings, hint: 'Needs action' },
    { label: 'Completed', value: stats.completed_bookings, hint: 'Finished jobs' },
    { label: 'Active Vendors', value: stats.active_vendors, hint: 'Verified pros' },
  ];

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <h1>Dashboard</h1>
          <p>Overview of SmartBondhu platform performance</p>
        </div>
      </header>

      <section className="stats-grid">
        {cards.map((card) => (
          <article key={card.label} className="stat-card">
            <span className="stat-label">{card.label}</span>
            <strong className="stat-value">{card.value}</strong>
            <small>{card.hint}</small>
          </article>
        ))}
      </section>

      <section className="charts-grid">
        <article className="panel">
          <div className="panel-header">
            <h2>Revenue (30 days)</h2>
          </div>
          <div className="chart-wrap">
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={revenue as unknown as Record<string, unknown>[]}>
                <defs>
                  <linearGradient id="revenueGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2563eb" stopOpacity={0.35} />
                    <stop offset="95%" stopColor="#2563eb" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="label" tick={{ fontSize: 12 }} />
                <YAxis tickFormatter={(v) => `₹${v}`} tick={{ fontSize: 12 }} />
                <Tooltip formatter={(value) => formatCurrency(Number(value))} />
                <Area
                  type="monotone"
                  dataKey="revenueNum"
                  stroke="#2563eb"
                  fill="url(#revenueGradient)"
                  strokeWidth={2}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </article>

        <article className="panel">
          <div className="panel-header">
            <h2>Bookings (30 days)</h2>
          </div>
          <div className="chart-wrap">
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={revenue as unknown as Record<string, unknown>[]}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="label" tick={{ fontSize: 12 }} />
                <YAxis allowDecimals={false} tick={{ fontSize: 12 }} />
                <Tooltip />
                <Bar dataKey="bookings" fill="#10b981" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </article>
      </section>
    </div>
  );
}
