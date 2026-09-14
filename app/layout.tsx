import Image from 'next/image'
import { Montserrat, Playfair_Display } from 'next/font/google'
import './globals.css'
import AppShell from '@/components/AppShell'

const montserrat = Montserrat({ subsets: ['latin'], variable: '--font-montserrat' })
const playfair = Playfair_Display({ subsets: ['latin'], variable: '--font-playfair' })

export const metadata = { title: 'Mosque Finance', description: 'Financial management for Al Fathoniah Mosque' }

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body className={`${montserrat.variable} ${playfair.variable}`}><AppShell>{children}</AppShell></body></html>
}
