import './globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Clicker Pro — Admin',
  description: 'Platform administration for Clicker Pro',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
