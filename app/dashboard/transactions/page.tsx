'use client'

import Link from 'next/link'
import { List } from 'lucide-react'

const cards = [
  { label: 'Infaq', desc: 'View and manage Infaq fund transactions', href: '/transactions/infaq' },
  { label: 'Wakaf', desc: 'View and manage Wakaf fund transactions', href: '/transactions/wakaf' },
]

export default function TransactionsDashboard() {
  return <div className="fade-up space-y-8"><div><p className="mb-2 text-xs font-bold uppercase tracking-[.22em] text-moss">Ledger</p><h1 className="font-display text-4xl text-ink">Transactions</h1><p className="mt-2 max-w-2xl text-sm leading-6 text-muted">Browse and manage transactions for each mosque fund separately.</p></div><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-2">{cards.map(({ label, desc, href }) => (<Link key={label} href={href} className="surface group rounded-2xl p-5 transition hover:-translate-y-0.5 hover:border-moss/30"><div className="flex items-start justify-between"><span className="rounded-xl bg-canvas p-3 text-moss"><List size={20}/></span></div><h2 className="mt-5 font-display text-2xl">{label} Transaction</h2><p className="mt-2 text-sm leading-6 text-muted">{desc}</p><p className="mt-5 text-xs font-bold uppercase tracking-[.15em] text-moss">Manage records</p></Link>))}</div></div>}
