const TOKEN_KEY = 'cp_web_token';

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(TOKEN_KEY);
}
export function setToken(t: string) { localStorage.setItem(TOKEN_KEY, t); }
export function clearToken() { localStorage.removeItem(TOKEN_KEY); }

type Opts = { method?: string; body?: unknown };

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
    // Surface the real backend message — Laravel validation puts the
    // human text in `message` (e.g. "The email has already been taken.")
    // and field errors under `errors`. Fall back to the status only when
    // nothing useful is present.
    const firstFieldError =
      json?.errors && typeof json.errors === 'object'
        ? (Object.values(json.errors)[0] as string[] | undefined)?.[0]
        : undefined;
    throw new Error(json?.message || firstFieldError || `Error ${res.status}`);
  }
  return json as T;
}

export async function login(email: string, password: string): Promise<void> {
  const res = await fetch('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json?.message || 'Login failed');
  // Laravel wraps response in { data: { token, user } }
  const payload = json.data ?? json;
  if (!payload.token) throw new Error('No token returned');
  setToken(payload.token);
  if (payload.user) localStorage.setItem('cp_web_user', JSON.stringify(payload.user));
}

export function getUser(): any {
  if (typeof window === 'undefined') return null;
  try { return JSON.parse(localStorage.getItem('cp_web_user') || 'null'); } catch { return null; }
}

export function logout() {
  clearToken();
  localStorage.removeItem('cp_web_user');
}
