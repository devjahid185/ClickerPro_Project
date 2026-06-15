import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/router';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';

const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

function statusBadge(s: string) {
  const map: Record<string, string> = {
    PENDING: 'gold', CONFIRMED: 'teal', IN_PROGRESS: 'orange',
    SHOT_COMPLETE: 'blue', DELIVERED: 'purple', COMPLETED: 'green', CANCELLED: 'red',
  };
  return <span className={`badge ${map[s] || 'gray'}`}>{s.replace(/_/g, ' ')}</span>;
}


export default function CalendarPage() {
  const router = useRouter();
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth());
  const [bookings, setBookings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedDay, setSelectedDay] = useState<number | null>(null);
  const [view, setView] = useState<'month' | 'week'>('month');

  useEffect(() => {
    setLoading(true);
    api<any>('/api/bookings?limit=500')
      .then((res) => setBookings(Array.isArray(res) ? res : res?.data ?? res?.bookings ?? []))
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const getDate = (b: any) => b.date?.split('T')[0] || b.event_date?.split('T')[0] || '';
  const getName = (b: any) => b.clientName || b.client_name || b.client?.name || '—';

  const todayStr = now.toISOString().split('T')[0];

  const prevMonth = () => { if (month === 0) { setYear(y => y - 1); setMonth(11); } else { setMonth(m => m - 1); } setSelectedDay(null); };
  const nextMonth = () => { if (month === 11) { setYear(y => y + 1); setMonth(0); } else { setMonth(m => m + 1); } setSelectedDay(null); };

  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();

  const monthPrefix = `${year}-${String(month + 1).padStart(2, '0')}`;
  const monthBookings = bookings.filter((b) => getDate(b).startsWith(monthPrefix));

  const bookingsByDay: Record<number, any[]> = {};
  monthBookings.forEach((b) => {
    const d = new Date(getDate(b)).getDate();
    if (!bookingsByDay[d]) bookingsByDay[d] = [];
    bookingsByDay[d].push(b);
  });

  const selectedDayBookings = selectedDay ? (bookingsByDay[selectedDay] || []) : [];
  const selectedDayStr = selectedDay ? `${year}-${String(month + 1).padStart(2, '0')}-${String(selectedDay).padStart(2, '0')}` : '';

  const cells: (number | null)[] = [];
  for (let i = 0; i < firstDay; i++) cells.push(null);
  for (let i = 1; i <= daysInMonth; i++) cells.push(i);

  // Week view
  const getWeekStart = () => {
    const d = new Date(now);
    d.setDate(d.getDate() - d.getDay());
    return d;
  };

  const weekDays = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(getWeekStart());
    d.setDate(d.getDate() + i);
    return d;
  });

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        {/* Header */}
        <div className="toolbar" style={{ marginBottom: 20 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Calendar</div>
          <span className="spacer" />
          <div className="row" style={{ gap: 8 }}>
            <div className="row" style={{ gap: 4 }}>
              <button className={`chip${view === 'month' ? ' active' : ''}`} onClick={() => setView('month')}>Month</button>
              <button className={`chip${view === 'week' ? ' active' : ''}`} onClick={() => setView('week')}>Week</button>
            </div>
            <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={() => router.push('/app/bookings?new=1')}>+ Add Booking</button>
          </div>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        <div style={{ display: 'grid', gridTemplateColumns: selectedDay ? '1fr 320px' : '1fr', gap: 20 }}>
          <div>
            {/* Month Navigation */}
            <div className="row" style={{ marginBottom: 16, gap: 12 }}>
              <button className="btn ghost sm" onClick={prevMonth}>←</button>
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 22, flex: 1, textAlign: 'center' }}>
                {MONTHS[month]} {year}
              </div>
              <button className="btn ghost sm" onClick={nextMonth}>→</button>
            </div>

            {view === 'month' && (
              <>
                {/* Day Headers */}
                <div className="cal-grid" style={{ gridTemplateColumns: 'repeat(7, 1fr)', marginBottom: 4 }}>
                  {DAYS.map((d) => (
                    <div key={d} className="cal-header-cell" style={{ textAlign: 'center', padding: '6px 0', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{d}</div>
                  ))}
                </div>

                {/* Calendar Grid */}
                <div className="cal-grid" style={{ gridTemplateColumns: 'repeat(7, 1fr)', gap: 3 }}>
                  {cells.map((day, idx) => {
                    if (!day) return <div key={idx} />;
                    const dayStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
                    const dayBookings = bookingsByDay[day] || [];
                    const isToday = dayStr === todayStr;
                    const isSelected = day === selectedDay;
                    const hasDayShift = dayBookings.some((b) => b.shift === 'DAY' || b.shift === 'BOTH');
                    const hasNightShift = dayBookings.some((b) => b.shift === 'NIGHT' || b.shift === 'BOTH');

                    return (
                      <div
                        key={day}
                        className="cal-day compact"
                        onClick={() => setSelectedDay(day === selectedDay ? null : day)}
                        style={{
                          cursor: 'pointer',
                          background: isSelected ? 'var(--orange-dim)' : dayBookings.length > 0 ? 'rgba(255,98,0,0.06)' : 'var(--surface-3)',
                          border: isToday ? '2px solid var(--orange)' : isSelected ? '1px solid var(--orange)' : '1px solid var(--border-2)',
                          position: 'relative',
                        }}
                      >
                        <div style={{ fontSize: 12, fontWeight: isToday ? 700 : 400, color: isToday ? 'var(--orange)' : 'var(--film)', marginBottom: 2 }}>{day}</div>
                        <div className="row" style={{ gap: 3, flexWrap: 'wrap' }}>
                          {hasDayShift && <div className="cal-event-dot" style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--gold)' }} />}
                          {hasNightShift && <div className="cal-event-dot" style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--purple)' }} />}
                        </div>
                        {dayBookings.length > 0 && (
                          <div style={{ fontSize: 9, color: 'var(--film-muted)', fontFamily: 'JetBrains Mono, monospace', marginTop: 2 }}>{dayBookings.length}</div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </>
            )}

            {view === 'week' && (
              <div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 8 }}>
                  {weekDays.map((wd) => {
                    const wdStr = wd.toISOString().split('T')[0];
                    const wdBookings = bookings.filter((b) => getDate(b) === wdStr);
                    const isToday = wdStr === todayStr;
                    return (
                      <div key={wdStr} style={{ background: 'var(--surface-3)', borderRadius: 8, padding: '10px 8px', border: isToday ? '2px solid var(--orange)' : '1px solid transparent', minHeight: 120 }}>
                        <div style={{ fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase', marginBottom: 6 }}>{DAYS[wd.getDay()]}</div>
                        <div style={{ fontSize: 18, fontFamily: 'Bebas Neue, sans-serif', color: isToday ? 'var(--orange)' : 'var(--film)', marginBottom: 8 }}>{wd.getDate()}</div>
                        {wdBookings.map((b) => (
                          <Link key={b.id} href={`/app/bookings/${b.id}`} style={{ textDecoration: 'none', display: 'block', padding: '4px 6px', marginBottom: 4, borderRadius: 4, background: b.shift === 'NIGHT' ? 'rgba(168,85,247,0.15)' : 'rgba(245,158,11,0.15)', borderLeft: `2px solid ${b.shift === 'NIGHT' ? 'var(--purple)' : 'var(--gold)'}` }}>
                            <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--film)', lineHeight: 1.3 }} className="truncate">{b.title || b.eventType || 'Event'}</div>
                            <div style={{ fontSize: 10, color: 'var(--film-muted)' }} className="truncate">{getName(b)}</div>
                          </Link>
                        ))}
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {loading && <div className="shimmer" style={{ height: 400, borderRadius: 8, marginTop: 8 }} />}

            {/* Legend */}
            <div className="row" style={{ gap: 16, marginTop: 16 }}>
              <div className="row" style={{ gap: 6 }}><div style={{ width: 10, height: 10, borderRadius: '50%', background: 'var(--gold)' }} /><span className="muted text-sm">Day Shift</span></div>
              <div className="row" style={{ gap: 6 }}><div style={{ width: 10, height: 10, borderRadius: '50%', background: 'var(--purple)' }} /><span className="muted text-sm">Night Shift</span></div>
              <div className="row" style={{ gap: 6 }}><div style={{ width: 10, height: 10, borderRadius: 4, border: '2px solid var(--orange)' }} /><span className="muted text-sm">Today</span></div>
            </div>
          </div>

          {/* Day Panel */}
          {selectedDay && (
            <div className="panel">
              <div className="panel-header">
                <span className="panel-title">{selectedDay} {MONTHS[month]}</span>
                <button className="btn ghost xs" onClick={() => setSelectedDay(null)}>×</button>
              </div>
              <div className="panel-body">
                {selectedDayBookings.length === 0 && <div className="empty">No bookings on this day.</div>}
                {selectedDayBookings.map((b) => (
                  <Link key={b.id} href={`/app/bookings/${b.id}`} style={{ textDecoration: 'none', display: 'block', marginBottom: 10 }}>
                    <div style={{ padding: '10px 12px', background: 'var(--surface-3)', borderRadius: 6, borderLeft: `3px solid ${b.shift === 'NIGHT' ? 'var(--purple)' : 'var(--gold)'}` }}>
                      <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--film)', marginBottom: 4 }}>{b.title || b.eventType || 'Booking'}</div>
                      <div className="muted text-sm" style={{ marginBottom: 4 }}>{getName(b)}</div>
                      <div className="row" style={{ gap: 6 }}>
                        {statusBadge(b.status)}
                        <span className={`pill ${b.shift === 'NIGHT' ? 'night' : b.shift === 'BOTH' ? 'both' : 'day'}`} style={{ fontSize: 10 }}>{b.shift}</span>
                      </div>
                      {b.venue && <div className="muted text-sm" style={{ marginTop: 4 }}>📍 {b.venue}</div>}
                    </div>
                  </Link>
                ))}
                <button className="btn sm" style={{ marginTop: 8, width: '100%', justifyContent: 'center', background: 'var(--orange)', color: '#000' }} onClick={() => router.push(`/app/bookings?new=1&date=${selectedDayStr}`)}>
                  + Add Booking This Day
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </AppShell>
  );
}
