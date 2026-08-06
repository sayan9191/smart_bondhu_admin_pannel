import { Route, Routes } from 'react-router-dom';
import { Layout } from './components/Layout';
import { BookingsPage } from './pages/BookingsPage';
import { DashboardPage } from './pages/DashboardPage';
import { UsersPage } from './pages/UsersPage';

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<DashboardPage />} />
        <Route path="bookings" element={<BookingsPage />} />
        <Route path="users" element={<UsersPage />} />
      </Route>
    </Routes>
  );
}
