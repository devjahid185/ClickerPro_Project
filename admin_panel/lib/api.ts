// lib/api.ts — thin client for the Clicker Pro admin API.
//
// The JWT lives in localStorage (admin panel is a trusted internal tool on
// the operator's own machine). Every request attaches it as a Bearer token.
// A 401 clears the token and bounces to /login.

const TOKEN_KEY = 'cp_admin_token';

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string) {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

type Opts = {
  method?: string;
  body?: unknown;
};

export async function api<T = any>(path: string, opts: Opts = {}): Promise<T> {
  const token = getToken();
  const res = await fetch(path, {
    method: opts.method || 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });

  if (res.status === 401) {
    clearToken();
    if (typeof window !== 'undefined') window.location.href = '/login';
    throw new Error('Unauthorized');
  }

  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(json?.message || `Request failed (${res.status})`);
  }
  return json as T;
}

// Downloads a file from an authed endpoint (CSV export). Fetches as a blob
// with the Bearer token, then triggers a browser download.
export async function downloadFile(path: string, filename: string): Promise<void> {
  const token = getToken();
  const res = await fetch(path, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });
  if (!res.ok) throw new Error(`Download failed (${res.status})`);
  const blob = await res.blob();
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

// Auth uses the shared /api/auth/login endpoint, then we verify ADMIN role.
export async function login(email: string, password: string): Promise<void> {
  const res = await fetch('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json?.message || 'Login failed');

  // Laravel wraps the response in { data: { token, user } }
  const payload = json.data ?? json;
  const token = payload.token as string | undefined;
  const role = (payload?.user?.role || '').toString().toLowerCase();
  if (!token) throw new Error('No token returned');
  if (role !== 'admin') throw new Error('This account is not an admin');

  setToken(token);
}
