import { useState, FormEvent } from 'react';
import Link from 'next/link';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { login } from '@/lib/api';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!email || !password) { setError('Please fill in all fields.'); return; }
    setLoading(true);
    setError('');
    try {
      await login(email, password);
      router.replace('/app');
    } catch (err: any) {
      setError(err.message || 'Login failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Head>
        <title>Sign In — ClickerPro</title>
      </Head>
      <div style={{
        minHeight: '100vh',
        background: '#000',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        overflow: 'hidden',
      }}>
        {/* Background glow */}
        <div style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: '600px',
          height: '600px',
          background: 'radial-gradient(circle, rgba(255,98,0,0.08) 0%, transparent 70%)',
          pointerEvents: 'none',
        }} />

        <div style={{ position: 'relative', zIndex: 1, width: '100%', maxWidth: 420, padding: '0 24px' }}>
          {/* Logo */}
          <div style={{ textAlign: 'center', marginBottom: 40 }}>
            <Link href="/">
              <span style={{
                fontFamily: "'Bebas Neue', sans-serif",
                fontSize: 36,
                letterSpacing: '0.08em',
                color: '#fff',
              }}>
                Clicker<span style={{ color: '#FF6200' }}>Pro</span>
              </span>
            </Link>
            <p style={{ color: 'rgba(255,255,255,0.35)', fontSize: 13, marginTop: 8 }}>
              Sign in to your studio dashboard
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
            }}>Welcome Back</h1>

            {error && <div className="error" style={{ marginBottom: 20 }}>{error}</div>}

            <form onSubmit={handleSubmit}>
              <div className="field">
                <label htmlFor="email">Email Address</label>
                <input
                  id="email"
                  type="email"
                  placeholder="you@studio.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  autoComplete="email"
                  disabled={loading}
                />
              </div>

              <div className="field">
                <label htmlFor="password">Password</label>
                <input
                  id="password"
                  type="password"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  disabled={loading}
                />
              </div>

              <button
                type="submit"
                className="btn"
                disabled={loading}
                style={{ width: '100%', justifyContent: 'center', marginTop: 8, padding: '12px 20px', fontSize: 15 }}
              >
                {loading ? 'Signing in…' : 'Sign In →'}
              </button>
            </form>

            <div style={{ marginTop: 24, textAlign: 'center', color: 'rgba(255,255,255,0.35)', fontSize: 13 }}>
              Don&apos;t have an account?{' '}
              <Link href="/register" style={{ color: '#FF6200', fontWeight: 600 }}>
                Register
              </Link>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
