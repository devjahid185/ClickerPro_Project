import { useState, FormEvent } from 'react';
import Link from 'next/link';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { api, setToken } from '@/lib/api';

export default function RegisterPage() {
  const router = useRouter();
  const [form, setForm] = useState({
    name: '',
    email: '',
    phone: '',
    password: '',
    role: 'OWNER',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const set = (k: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
    setForm((f) => ({ ...f, [k]: e.target.value }));

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.name || !form.email || !form.password) {
      setError('Name, email, and password are required.');
      return;
    }
    setLoading(true);
    setError('');
    try {
      const res = await api<{ token: string; user: any }>('/api/auth/register', {
        method: 'POST',
        body: form,
      });
      if (res.token) setToken(res.token);
      if (res.user) localStorage.setItem('cp_web_user', JSON.stringify(res.user));
      router.replace('/app');
    } catch (err: any) {
      setError(err.message || 'Registration failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Head>
        <title>Register — ClickerPro</title>
      </Head>
      <div style={{
        minHeight: '100vh',
        background: '#000',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        overflow: 'hidden',
        padding: '40px 0',
      }}>
        <div style={{
          position: 'absolute',
          top: '40%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: '600px',
          height: '600px',
          background: 'radial-gradient(circle, rgba(255,98,0,0.07) 0%, transparent 70%)',
          pointerEvents: 'none',
        }} />

        <div style={{ position: 'relative', zIndex: 1, width: '100%', maxWidth: 440, padding: '0 24px' }}>
          <div style={{ textAlign: 'center', marginBottom: 36 }}>
            <Link href="/">
              <span style={{ fontFamily: "'Bebas Neue', sans-serif", fontSize: 36, letterSpacing: '0.08em', color: '#fff' }}>
                Clicker<span style={{ color: '#FF6200' }}>Pro</span>
              </span>
            </Link>
            <p style={{ color: 'rgba(255,255,255,0.35)', fontSize: 13, marginTop: 8 }}>
              Create your studio account
            </p>
          </div>

          <div style={{
            background: '#0d0300',
            border: '1px solid rgba(255,98,0,0.12)',
            borderRadius: 16,
            padding: 32,
          }}>
            <h1 style={{
              fontFamily: "'Bebas Neue', sans-serif",
              fontSize: 28,
              letterSpacing: '0.04em',
              color: '#fff',
              marginBottom: 24,
            }}>Get Started</h1>

            {error && <div className="error" style={{ marginBottom: 20 }}>{error}</div>}

            <form onSubmit={handleSubmit}>
              <div className="field">
                <label htmlFor="name">Full Name</label>
                <input
                  id="name"
                  type="text"
                  placeholder="Rafi Khan"
                  value={form.name}
                  onChange={set('name')}
                  disabled={loading}
                />
              </div>

              <div className="field">
                <label htmlFor="email">Email Address</label>
                <input
                  id="email"
                  type="email"
                  placeholder="rafi@studio.com"
                  value={form.email}
                  onChange={set('email')}
                  autoComplete="email"
                  disabled={loading}
                />
              </div>

              <div className="field">
                <label htmlFor="phone">Phone Number</label>
                <input
                  id="phone"
                  type="tel"
                  placeholder="+880 1700 000000"
                  value={form.phone}
                  onChange={set('phone')}
                  disabled={loading}
                />
              </div>

              <div className="field">
                <label htmlFor="password">Password</label>
                <input
                  id="password"
                  type="password"
                  placeholder="••••••••"
                  value={form.password}
                  onChange={set('password')}
                  autoComplete="new-password"
                  disabled={loading}
                />
              </div>

              <div className="field">
                <label htmlFor="role">Your Role</label>
                <select id="role" value={form.role} onChange={set('role')} disabled={loading}>
                  <option value="OWNER">Studio Owner</option>
                  <option value="FREELANCER">Freelancer</option>
                </select>
              </div>

              <button
                type="submit"
                className="btn"
                disabled={loading}
                style={{ width: '100%', justifyContent: 'center', marginTop: 8, padding: '12px 20px', fontSize: 15 }}
              >
                {loading ? 'Creating Account…' : 'Create Account →'}
              </button>
            </form>

            <div style={{ marginTop: 24, textAlign: 'center', color: 'rgba(255,255,255,0.35)', fontSize: 13 }}>
              Already have an account?{' '}
              <Link href="/login" style={{ color: '#FF6200', fontWeight: 600 }}>
                Sign In
              </Link>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
