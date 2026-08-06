import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1';

export const api = axios.create({
  baseURL: API_BASE,
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('admin_access_token');
      localStorage.removeItem('admin_user');
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  },
);

export interface AuthResponse {
  user: {
    id: string;
    email: string;
    full_name: string;
    role: string;
  };
  tokens: {
    access_token: string;
    refresh_token: string;
    token_type: string;
  };
}

export interface DashboardStats {
  total_users: number;
  total_bookings: number;
  bookings_today: number;
  new_users_today: number;
  pending_bookings: number;
  completed_bookings: number;
  total_revenue: string;
  revenue_today: string;
  active_vendors: number;
}

export interface RevenuePoint {
  date: string;
  revenue: string;
  bookings: number;
}

export interface Paginated<T> {
  items: T[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

export interface AdminUser {
  id: string;
  email: string | null;
  phone: string | null;
  full_name: string | null;
  role: string;
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
  bookings_count: number;
}

export interface AdminBooking {
  id: string;
  booking_number: string;
  customer_id: string;
  customer_name: string | null;
  customer_email: string | null;
  customer_phone: string | null;
  service_name: string;
  address_summary: string | null;
  scheduled_at: string;
  status: string;
  total_amount: string;
  created_at: string;
}

export async function login(email: string, password: string): Promise<AuthResponse> {
  const { data } = await api.post<AuthResponse>('/auth/login', { email, password });
  return data;
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const { data } = await api.get<DashboardStats>('/admin/dashboard/stats');
  return data;
}

export async function getRevenueChart(days = 30): Promise<{ points: RevenuePoint[] }> {
  const { data } = await api.get<{ points: RevenuePoint[] }>('/admin/dashboard/revenue', {
    params: { days },
  });
  return data;
}

export async function getUsers(page = 1, search = ''): Promise<Paginated<AdminUser>> {
  const { data } = await api.get<Paginated<AdminUser>>('/admin/users', {
    params: { page, page_size: 20, search: search || undefined },
  });
  return data;
}

export async function updateUser(
  userId: string,
  payload: { is_active?: boolean; role?: string },
): Promise<AdminUser> {
  const { data } = await api.patch<AdminUser>(`/admin/users/${userId}`, payload);
  return data;
}

export async function getBookings(
  page = 1,
  status?: string,
  search = '',
): Promise<Paginated<AdminBooking>> {
  const { data } = await api.get<Paginated<AdminBooking>>('/admin/bookings', {
    params: { page, page_size: 20, status: status || undefined, search: search || undefined },
  });
  return data;
}

export async function updateBookingStatus(
  bookingId: string,
  status: string,
  notes?: string,
): Promise<AdminBooking> {
  const { data } = await api.patch<AdminBooking>(`/admin/bookings/${bookingId}/status`, {
    status,
    notes,
  });
  return data;
}
