'use client'

import Image from 'next/image'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { ChevronDown, Database, LayoutDashboard, List, LogOut, Menu, X } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabaseClient'

const links = [{ href: '/', label: 'Overview', icon: LayoutDashboard }]
const transactionTypes = ['Infaq', 'Wakaf']
const masters = ['Funds', 'Categories', 'Activities', 'Vendors', 'Persons', 'Accounts']

export default function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname(); const router = useRouter(); const [open, setOpen] = useState(false); const [transOpen, setTransOpen] = useState(pathname.startsWith('/transactions')); const [masterOpen, setMasterOpen] = useState(pathname.startsWith('/master')); const [checkingSession, setCheckingSession] = useState(pathname !== '/login'); const [email, setEmail] = useState('')

  useEffect(() => {
    if (pathname === '/login') { setCheckingSession(false); return }
    let active = true
    supabase.auth.getUser().then(({ data }) => {
      if (!active) return
      if (!data.user) router.replace('/login')
      else setEmail(data.user.email || '')
      setCheckingSession(false)
    })
    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!session) router.replace('/login')
      else setEmail(session.user.email || '')
    })
    return () => { active = false; listener.subscription.unsubscribe() }
  }, [pathname, router])

  if (pathname === '/login') return <>{children}</>
  if (checkingSession) return <div className="page-shell grid min-h-screen place-items-center"><p className="text-sm font-semibold text-moss">Checking your secure workspace...</p></div>

  async function signOut() { await supabase.auth.signOut(); router.replace('/login') }

  return <div className="page-shell">
    <header className="sticky top-0 z-20 flex h-[76px] items-center justify-between border-b border-moss/10 bg-surface/90 px-5 backdrop-blur md:px-8">
      <div className="flex items-center gap-3"><button onClick={() => setOpen(!open)} className="rounded-lg p-2 text-moss md:hidden" aria-label="Toggle navigation">{open ? <X size={20}/> : <Menu size={20}/>}</button><Image src="/LOGO.png" alt="Al Fathoniah Mosque" width={52} height={52} className="object-contain"/><div><p className="font-display text-lg leading-none text-moss">Mosque Finance</p><p className="mt-1 text-[10px] font-semibold uppercase tracking-[.2em] text-muted">Al Fathoniah</p></div></div>
      <div className="flex items-center gap-3"><div className="hidden text-right md:block"><p className="text-xs font-semibold text-ink">{email}</p><p className="text-[10px] uppercase tracking-[.12em] text-muted">Authenticated</p></div><button onClick={signOut} className="flex items-center gap-2 rounded-lg border border-moss/15 px-3 py-2 text-xs font-bold text-moss hover:bg-canvas" title="Sign out"><LogOut size={15}/> <span className="hidden sm:inline">Sign out</span></button></div>
    </header>
    <div className="mx-auto flex max-w-[1540px]">
      <aside className={`${open ? 'block' : 'hidden'} absolute z-10 min-h-[calc(100vh-76px)] w-64 border-r border-moss/10 bg-canvas/95 p-5 backdrop-blur md:relative md:block`}>
        <nav className="space-y-2"><p className="mb-4 px-3 text-[10px] font-bold uppercase tracking-[.2em] text-muted">Workspace</p>{links.map(({ href, label, icon: Icon }) => <Link key={href} href={href} onClick={() => setOpen(false)} className={`flex items-center gap-3 rounded-xl px-3 py-3 text-sm font-semibold transition ${pathname === href ? 'bg-moss text-white shadow-sm' : 'text-ink/70 hover:bg-surface hover:text-moss'}`}><Icon size={18}/>{label}</Link>)}<button onClick={() => setTransOpen(!transOpen)} className={`flex w-full items-center justify-between rounded-xl px-3 py-3 text-sm font-semibold transition ${pathname.startsWith('/transactions') ? 'bg-moss text-white shadow-sm' : 'text-ink/70 hover:bg-surface hover:text-moss'}`}><span className="flex items-center gap-3"><List size={18}/>Transactions</span><ChevronDown size={16} className={`${transOpen ? 'rotate-180' : ''} transition-transform`}/></button>{transOpen && <div className="ml-7 space-y-1 border-l border-moss/20 pl-3">{transactionTypes.map(item => <Link key={item} href={`/transactions/${item.toLowerCase()}`} onClick={() => setOpen(false)} className="block py-2 text-xs font-medium text-muted hover:text-moss">{item}</Link>)}</div>}<Link href="/master" onClick={() => setMasterOpen(!masterOpen)} className="flex w-full items-center justify-between rounded-xl px-3 py-3 text-sm font-semibold text-ink/70 hover:bg-surface hover:text-moss"><span className="flex items-center gap-3"><Database size={18}/>Master Data</span><ChevronDown size={16} className={masterOpen ? 'rotate-180' : ''}/></Link>
          {masterOpen && <div className="ml-9 space-y-1 border-l border-moss/20 pl-3">{masters.map(item => <Link key={item} href={`/master/${item.toLowerCase()}`} onClick={() => setOpen(false)} className="block py-2 text-xs font-medium text-muted hover:text-moss">{item}</Link>)}</div>}
        </nav>
        <div className="absolute bottom-8 left-5 right-5 border-t border-moss/10 pt-5"><p className="text-xs leading-5 text-muted">A clear ledger for the community funds entrusted to us.</p></div>
      </aside>
      <main className="min-w-0 flex-1 px-5 py-8 md:px-10 lg:px-14">{children}</main>
    </div>
  </div>
}
