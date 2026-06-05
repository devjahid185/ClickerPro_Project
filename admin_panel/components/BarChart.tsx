'use client';

// Dependency-free CSS bar chart. Renders labeled vertical bars scaled to the
// max value. Good enough for the admin dashboard — no charting library needed.

type Point = { label: string; value: number };

export default function BarChart({
  data,
  color = 'var(--orange)',
  height = 140,
}: {
  data: Point[];
  color?: string;
  height?: number;
}) {
  const max = Math.max(1, ...data.map((d) => d.value));
  if (data.length === 0) {
    return <p className="muted">No data</p>;
  }
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 12, height, paddingTop: 8 }}>
      {data.map((d, i) => (
        <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', height: '100%' }}>
          <div style={{ flex: 1, display: 'flex', alignItems: 'flex-end', width: '100%' }}>
            <div
              title={`${d.value}`}
              style={{
                width: '100%',
                height: `${(d.value / max) * 100}%`,
                minHeight: d.value > 0 ? 4 : 0,
                background: color,
                borderRadius: '6px 6px 0 0',
                transition: 'height 0.3s',
                position: 'relative',
              }}
            >
              <span style={{
                position: 'absolute', top: -18, left: 0, right: 0, textAlign: 'center',
                fontSize: 11, fontWeight: 700, color: 'var(--film-dim)',
              }}>
                {d.value > 0 ? d.value : ''}
              </span>
            </div>
          </div>
          <div style={{ fontSize: 10, color: 'var(--film-muted)', marginTop: 6, textAlign: 'center' }}>
            {d.label}
          </div>
        </div>
      ))}
    </div>
  );
}
