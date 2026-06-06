import axios from 'axios';

export const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/v1';

export const api = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});

// Attach JWT from localStorage on every request
api.interceptors.request.use((config) => {
  const token = typeof window !== 'undefined' ? localStorage.getItem('access_token') : null;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Redirect to enter-key on 401
api.interceptors.response.use(
  (r) => r,
  (err) => {
    if (err.response?.status === 401 && typeof window !== 'undefined') {
      localStorage.clear();
      window.location.href = '/enter-key';
    }
    return Promise.reject(err);
  }
);

// ── Auth ──────────────────────────────────────────────────────────────────────
export const auth = {
  demoInfo: () => api.get('/auth/demo/info'),
  register: (org_name: string, manager_username: string, manager_password: string) =>
    api.post('/auth/register', { org_name, manager_username, manager_password }),
  login: (guest_key: string, username: string, password: string, manager_key?: string) =>
    api.post('/auth/login', { guest_key, username, password, manager_key }),
  logout: () => api.post('/auth/logout'),
};

// ── Attendance ────────────────────────────────────────────────────────────────
export const attendance = {
  methods: () => api.get('/attendance/methods'),
  generateQr: () => api.get('/attendance/qr/generate'),
  verifyQr: (qr_jwt: string) => api.post('/attendance/qr/verify', { qr_jwt }),
  markGeo: (lat: number, lng: number, accuracy?: number) =>
    api.post('/attendance/geo/mark', { lat, lng, accuracy }),
  faceChallenge: () => api.post('/attendance/face/challenge'),
  faceVerify: (challenge_id: string, image_b64: string) =>
    api.post('/attendance/face/verify', { challenge_id, image_b64 }),
  today: () => api.get('/attendance/today'),
  history: (page = 1, month?: number, year?: number) =>
    api.get('/attendance/history', { params: { page, month, year } }),
  checkout: () => api.post('/attendance/checkout'),
};

// ── Manager ───────────────────────────────────────────────────────────────────
export const manager = {
  profile: () => api.get('/manager/profile'),
  // Employees
  listEmployees: () => api.get('/manager/employees'),
  getEmployee: (id: string) => api.get(`/manager/employees/${id}`),
  createEmployee: (data: { username: string; password: string; full_name?: string; email?: string }) =>
    api.post('/manager/employees', data),
  updateEmployee: (id: string, data: object) => api.put(`/manager/employees/${id}`, data),
  deactivateEmployee: (id: string) => api.delete(`/manager/employees/${id}`),
  enrollFace: (id: string, formData: FormData) =>
    api.post(`/manager/employees/${id}/face`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),
  removeFace: (id: string) => api.delete(`/manager/employees/${id}/face`),
  // Settings
  getSettings: () => api.get('/manager/settings'),
  updateSettings: (data: object) => api.put('/manager/settings', data),
  // Attendance
  getAttendance: (params?: object) => api.get('/manager/attendance', { params }),
  exportAttendance: (params?: object) => api.get('/manager/attendance/export', { params, responseType: 'blob' }),
  // Key
  changeKey: (current_key: string, new_key?: string) =>
    api.put('/manager/change-key', { current_key, new_key }),
};

// ── Employee ──────────────────────────────────────────────────────────────────
export const employee = {
  profile: () => api.get('/employee/profile'),
  history: (page = 1, month?: number, year?: number) =>
    api.get('/employee/history', { params: { page, month, year } }),
  weeklyReport: () => api.get('/employee/report/weekly'),
  monthlyReport: () => api.get('/employee/report/monthly'),
  calendar: (year?: number, month?: number) =>
    api.get('/employee/calendar', { params: { year, month } }),
};

// ── Analytics ─────────────────────────────────────────────────────────────────
export const analytics = {
  summary: () => api.get('/analytics/summary'),
  trends: (days = 30) => api.get('/analytics/trends', { params: { days } }),
  methodBreakdown: () => api.get('/analytics/methods'),
  leaderboard: () => api.get('/analytics/leaderboard'),
  individual: (id: string, days = 30) => api.get(`/analytics/individual/${id}`, { params: { days } }),
  hoursChart: (id: string) => api.get(`/analytics/individual/${id}/hours`),
};
