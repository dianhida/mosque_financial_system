'use client'

import Link from 'next/link'
import { ArrowUpRight, CalendarDays, Landmark, Plus, Save, Sparkles, WalletCards } from 'lucide-react'
import { FormEvent, useEffect, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'

type Focus = 'INFAQ' | 'WAKAF'
type InfaqSummary = {
  current_balance: number
  current_month?: string
  current_month_income?: number
  current_month_expense?: number
  current_as_of?: string
  previous_month?: string
  previous_month_closing_balance?: number
  previous_month_income?: number
  previous_month_expense?: number
  previous_month_as_of?: string
}
type WakafSummary = { target_amount: number | null; current_balance: number | null; current_cash_balance: number | null; total_expense: number; estimated_total_collected: number | null; progress_percentage: number | null }
type Category = { category_name: string; transaction_type: 'INCOME' | 'EXPENSE'; amount: number }
type Activity = { activity_name: string; expense_amount: number }

const money = (value: number | null | undefined) => value == null ? 'Not updated' : new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(Number(value)).replace('IDR', 'Rp')
const month = (value?: string) => value ? new Intl.DateTimeFormat('en-US', { month: 'long', year: 'numeric' }).format(new Date(`${value}T00:00:00`)) : 'No transactions yet'

export default function Dashboard({ focus }: { focus?: Focus }) {
  const [infaq, setInfaq] = useState<InfaqSummary | null>(null)
  const [wakaf, setWakaf] = useState<WakafSummary | null>(null)
  const [categories, setCategories] = useState<Category[]>([])
  const [activities, setActivities] = useState<Activity[]>([])
  const [wakafId, setWakafId] = useState<number | null>(null)
  const [balance, setBalance] = useState('')
  const [checkedAt, setCheckedAt] = useState(new Date().toISOString().slice(0, 10))
  const [notes, setNotes] = useState('')
  const [savingSnapshot, setSavingSnapshot] = useState(false)
  const [snapshotMessage, setSnapshotMessage] = useState('')
  const [error, setError] = useState('')

  async function loadDashboard() {
    const [infaqResult, wakafResult, categoryResult, activityResult, fundResult] = await Promise.all([
      supabase.from('v_infaq_summary').select('*').maybeSingle(),
      supabase.from('v_wakaf_summary').select('*').maybeSingle(),
      supabase.from('v_infaq_monthly_category_expense').select('*'),
      supabase.from('v_wakaf_activity_expense').select('*'),
      supabase.from('funds').select('id').eq('code', 'WAKAF').maybeSingle(),
    ])
    if (infaqResult.error || wakafResult.error || fundResult.error) setError('Connect the database migrations to see live financial data.')
    setInfaq(infaqResult.data)
    setWakaf(wakafResult.data)
    setCategories(categoryResult.data || [])
    setActivities(activityResult.data || [])
    setWakafId(fundResult.data?.id || null)
  }

  useEffect(() => { void loadDashboard() }, [])

  async function saveSnapshot(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!wakafId || !balance || Number(balance) < 0) return
    setSavingSnapshot(true)
    setSnapshotMessage('')
    const { data: userData } = await supabase.auth.getUser()
    const { error: insertError } = await supabase.from('fund_balance_snapshots').insert({
      fund_id: wakafId,
      balance: Number(balance),
      checked_at: `${checkedAt}T12:00:00+07:00`,
      checked_by: userData.user?.id || null,
      notes: notes.trim() || null,
    })
    if (insertError) setSnapshotMessage(`Unable to save the balance snapshot: ${insertError.message}`)
    else {
      setSnapshotMessage('Balance snapshot saved.')
      setBalance('')
      setNotes('')
      await loadDashboard()
    }
    setSavingSnapshot(false)
  }

  const showInfaq = !focus || focus === 'INFAQ'
  const showWakaf = !focus || focus === 'WAKAF'

  return (
    <div className="fade-up space-y-10">
      <div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-end">
        <div>
          <p className="mb-2 text-xs font-bold uppercase tracking-[.22em] text-moss">Financial workspace</p>
          <h1 className="font-display text-4xl leading-tight text-ink md:text-5xl">{focus || 'A steadier view of giving'}</h1>
          <p className="mt-3 max-w-xl text-sm leading-6 text-muted">{focus === 'INFAQ' ? 'Monthly operational clarity for every rupiah of infaq.' : focus === 'WAKAF' ? 'A verified balance, recorded expenses, and an honest progress estimate.' : 'One calm place to understand the mosque ledger.'}</p>
        </div>
        <Link href="/transactions" className="inline-flex items-center justify-center gap-2 rounded-xl bg-moss px-4 py-3 text-sm font-bold text-white shadow-lg shadow-moss/15 hover:bg-[#205f45]"><Plus size={17} /> Add transaction</Link>
      </div>
      {error && <div className="surface rounded-xl border-expense/20 px-4 py-3 text-sm text-expense">{error}</div>}

      {showInfaq && <InfaqSection summary={infaq} categories={categories} />}
      {showWakaf && <WakafSection summary={wakaf} activities={activities} wakafId={wakafId} balance={balance} setBalance={setBalance} checkedAt={checkedAt} setCheckedAt={setCheckedAt} notes={notes} setNotes={setNotes} savingSnapshot={savingSnapshot} snapshotMessage={snapshotMessage} saveSnapshot={saveSnapshot} />}
    </div>
  )
}

function InfaqSection({ summary, categories }: { summary: InfaqSummary | null; categories: Category[] }) {
  const incomeCategories = categories.filter(item => item.transaction_type === 'INCOME').sort((a, b) => b.amount - a.amount)
  const expenseCategories = categories.filter(item => item.transaction_type === 'EXPENSE').sort((a, b) => b.amount - a.amount)
  const currentCards = [
    ['Current Balance', money(summary?.current_balance), 'balance'],
    ['Income', money(summary?.current_month_income), 'income'],
    ['Expense', money(summary?.current_month_expense), 'expense'],
    ['As of', formatDate(summary?.current_as_of), 'date'],
  ]
  const previousCards = [
    ['Closing Balance', money(summary?.previous_month_closing_balance), 'balance'],
    ['Income', money(summary?.previous_month_income), 'income'],
    ['Expense', money(summary?.previous_month_expense), 'expense'],
    ['As of', formatDate(summary?.previous_month_as_of), 'date'],
  ]
  return <section className="space-y-6"><div className="flex items-center justify-between"><div><p className="text-xs font-bold uppercase tracking-[.18em] text-moss">INFAQ</p><h2 className="font-display text-2xl">Monthly financial overview</h2></div><Link href="/dashboard/infaq" className="flex items-center gap-1 text-sm font-bold text-moss">Detailed view <ArrowUpRight size={16} /></Link></div><MonthMetricSection title={`This month - ${monthName(summary?.current_month)}`} cards={currentCards} /><MonthMetricSection title={`Last month - ${monthName(summary?.previous_month)}`} cards={previousCards} /><div className="surface overflow-hidden rounded-2xl"><div className="px-5 py-5"><h3 className="font-bold">Last month Cashflow by category</h3><p className="mt-1 text-xs text-muted">{month(summary?.previous_month)}</p></div>{categories.length ? <div className="pb-3"><CategoryGroup title="Income" items={incomeCategories} type="INCOME" /><CategoryGroup title="Expense" items={expenseCategories} type="EXPENSE" /></div> : <p className="px-5 pb-5 text-sm text-muted">Category cashflow will appear here once transactions are recorded.</p>}</div></section>
}

function monthName(value?: string) {
  return value ? new Intl.DateTimeFormat('en-US', { month: 'long' }).format(new Date(`${value}T00:00:00`)) : 'Not available'
}

function formatDate(value?: string) {
  return value ? new Intl.DateTimeFormat('en-GB', { day: '2-digit', month: 'long', year: 'numeric' }).format(new Date(`${value}T00:00:00`)) : 'Not available'
}

function MonthMetricSection({ title, cards }: { title: string; cards: string[][] }) {
  return <div><h3 className="mb-3 font-display text-xl text-ink">{title}</h3><div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{cards.map(([label, value, type]) => <div key={label} className="surface rounded-2xl p-5"><p className="text-xs font-semibold uppercase tracking-[.12em] text-muted">{label}</p><p className={`mt-4 font-display text-2xl ${type === 'expense' ? 'text-expense' : 'text-moss'}`}>{value}</p></div>)}</div></div>
}

function CategoryGroup({ title, items, type }: { title: string; items: Category[]; type: 'INCOME' | 'EXPENSE' }) {
  return <div><div className="px-5 pb-2 pt-3 text-xs font-bold uppercase tracking-[.14em] text-muted">{title}</div>{items.length ? items.map(item => <div key={`${type}-${item.category_name}`} className="table-row grid grid-cols-[minmax(0,1fr)_auto] items-center gap-6 px-5 py-4 text-sm"><span className="min-w-0">{item.category_name}</span><strong className={`whitespace-nowrap text-right ${type === 'EXPENSE' ? 'text-expense' : 'text-moss'}`}>{money(item.amount)}</strong></div>) : <p className="px-5 py-3 text-sm text-muted">No {title.toLowerCase()} recorded.</p>}</div>
}

function WakafSection({ summary, activities, wakafId, balance, setBalance, checkedAt, setCheckedAt, notes, setNotes, savingSnapshot, snapshotMessage, saveSnapshot }: { summary: WakafSummary | null; activities: Activity[]; wakafId: number | null; balance: string; setBalance: (value: string) => void; checkedAt: string; setCheckedAt: (value: string) => void; notes: string; setNotes: (value: string) => void; savingSnapshot: boolean; snapshotMessage: string; saveSnapshot: (event: FormEvent<HTMLFormElement>) => void }) {
  const progress = Math.min(summary?.progress_percentage || 0, 100)
  return <section className="space-y-5"><div className="flex items-center justify-between"><div><p className="text-xs font-bold uppercase tracking-[.18em] text-moss">WAKAF</p><h2 className="font-display text-2xl">Fundraising progress, verified honestly</h2></div><Link href="/dashboard/wakaf" className="flex items-center gap-1 text-sm font-bold text-moss">Detailed view <ArrowUpRight size={16} /></Link></div><div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4"><WakafKpi label="Current Cash Balance" value={money(summary?.current_cash_balance)} icon={Landmark} /><WakafKpi label="Current Bank Balance" value={money(summary?.current_balance)} icon={WalletCards} empty={summary?.current_balance == null} /><WakafKpi label="Total Expenses" value={money(summary?.total_expense)} icon={ArrowUpRight} /><WakafKpi label="Estimated Total Collected" value={money(summary?.estimated_total_collected)} icon={Sparkles} empty={summary?.estimated_total_collected == null} /></div><div className="surface rounded-2xl p-5"><div className="flex items-end justify-between gap-4"><div><p className="text-xs font-bold uppercase tracking-[.16em] text-muted">Progress</p><p className="mt-2 font-display text-4xl text-moss">{summary?.progress_percentage == null ? 'Not available' : `${summary.progress_percentage}%`}</p></div><div className="text-right"><p className="text-xs font-bold uppercase tracking-[.16em] text-muted">Target</p><p className="mt-2 font-display text-4xl text-moss">{money(summary?.target_amount)}</p></div></div><div className="mt-5 h-3 overflow-hidden rounded-full bg-canvas"><div className="h-full rounded-full bg-moss transition-all" style={{ width: `${progress}%` }} /></div>{summary?.current_balance == null && <div className="mt-4 rounded-xl bg-canvas px-4 py-3 text-sm font-semibold text-moss">Current balance has not been updated. Add a verified balance below to calculate progress.</div>}</div><div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_minmax(20rem,26rem)]"><div className="surface rounded-2xl p-5"><h3 className="font-bold">Programs and activities</h3><div className="mt-4 grid gap-3 md:grid-cols-3">{activities.length ? activities.map(item => <div key={item.activity_name} className="border-t border-moss/10 pt-3"><p className="font-semibold">{item.activity_name}</p><p className="mt-1 text-sm text-expense">{money(item.expense_amount)} used</p></div>) : <p className="text-sm text-muted">Wakaf programs will appear here after expenses are recorded.</p>}</div></div><form onSubmit={saveSnapshot} className="surface rounded-2xl p-5"><div className="flex items-center gap-2"><CalendarDays size={17} className="text-moss" /><h3 className="font-bold">Update current balance</h3></div><p className="mt-2 text-xs leading-5 text-muted">Insert a new verified snapshot. Previous checks remain in history.</p><label className="mt-5 block text-xs font-bold uppercase tracking-[.1em] text-muted">Current balance<input required min="0" type="number" step="0.01" value={balance} onChange={event => setBalance(event.target.value)} className="field mt-2" placeholder="60000000" /></label><label className="mt-4 block text-xs font-bold uppercase tracking-[.1em] text-muted">Check date<input required type="date" value={checkedAt} onChange={event => setCheckedAt(event.target.value)} className="field mt-2" /></label><label className="mt-4 block text-xs font-bold uppercase tracking-[.1em] text-muted">Notes<textarea value={notes} onChange={event => setNotes(event.target.value)} className="field mt-2 min-h-20 resize-y" placeholder="Optional verification note" /></label>{snapshotMessage && <p className="mt-3 text-xs font-semibold text-moss">{snapshotMessage}</p>}<button disabled={savingSnapshot || !wakafId} className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-moss px-4 py-3 text-sm font-bold text-white disabled:opacity-50"><Save size={16} />{savingSnapshot ? 'Saving...' : 'Save balance snapshot'}</button></form></div></section>
}

function WakafKpi({ label, value, icon: Icon, empty = false }: { label: string; value: string; icon: typeof Landmark; empty?: boolean }) {
  return <div className="surface rounded-2xl p-5"><Icon size={18} className="text-moss" /><p className="mt-4 text-xs font-semibold uppercase tracking-[.12em] text-muted">{label}</p><p className={`mt-2 font-display text-2xl ${empty ? 'text-muted' : 'text-moss'}`}>{value}</p></div>
}
