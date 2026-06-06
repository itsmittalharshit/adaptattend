import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'AdaptAttend — Smart Attendance System',
  description: 'Multi-method attendance: rotating QR codes, GPS geofencing, and facial recognition. Built for modern teams.',
  openGraph: {
    title: 'AdaptAttend — Smart Attendance System',
    description: 'QR, GPS, and facial recognition attendance — all in one Flutter app.',
    type: 'website',
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="scroll-smooth">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
