'use client'

import { ArrowDownLeft, ArrowUpRight, CalendarDays, Filter, Pencil, Plus, Search, Trash2, X } from 'lucide-react'
import { FormEvent, useEffect, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'

type Option = { id: number; name: string; code?: string; fund_id?: number | null }
type Transaction = { id: number; transaction_date: string; description: string; transaction_type: 'INCOME' | 'EXPENSE'; amount: number; fund_id: number; category_id: number; activity_id: number | null; vendor_id: number | null; person_id: number | null; account_id: number | null; funds: { name: string } | null; categories: { name: string } | null; accounts: { name: string } | null; vendors: { name: string } | null; persons: { name: string } | null }
type PriorTransaction = {
  transaction_type: 'INCOME' | 'EXPENSE'
  amount: number
  fund_id: number
  account_id: number | null
}
type FormState = { transaction_date: string; fund_id: string; category_id: string; activity_id: string; transaction_type: 'INCOME' | 'EXPENSE'; amount: string; description: string; vendor_id: string; person_id: string; account_id: string; reference_number: string; notes: string }

const money = (value: number) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value).replace('IDR', 'Rp')
const blankForm = (): FormState => ({ transaction_date: new Date().toISOString().slice(0, 10), fund_id: '', category_id: '', activity_id: '', transaction_type: 'EXPENSE', amount: '', description: '', vendor_id: '', person_id: '', account_id: '', reference_number: '', notes: '' })

export default function Transactions({ focus = 'INFAQ' }: { focus?: 'INFAQ' | 'WAKAF' }) {
  const [rows, setRows] = useState<Transaction[]>([])
  const [priorRows, setPriorRows] = useState<PriorTransaction[]>([])
  const [funds, setFunds] = useState<Option[]>([])
  const [categories, setCategories] = useState<Option[]>([])
  const [activities, setActivities] = useState<Option[]>([])
  const [vendors, setVendors] = useState<Option[]>([])
  const [persons, setPersons] = useState<Option[]>([])
  const [accounts, setAccounts] = useState<Option[]>([])
  const [loading, setLoading] = useState(true)
  const [query, setQuery] = useState('')
  const [type, setType] = useState('ALL')
  const [fundFilter, setFundFilter] = useState('ALL')
  const [accountFilter, setAccountFilter] = useState('ALL')
  const [error, setError] = useState('')
  const [month, setMonth] = useState(new Date().toISOString().slice(0, 7))
  const [form, setForm] = useState<FormState | null>(null)
  const [editing, setEditing] = useState<Transaction | null>(null)
  const [saving, setSaving] = useState(false)
  const [fundFilterSet, setFundFilterSet] = useState(false)

  async function loadTransactions() {
    setLoading(true)

    const start = `${month}-01`

    const end = new Date(
      Number(month.slice(0, 4)),
      Number(month.slice(5, 7)),
      1
    )
      .toISOString()
      .slice(0, 10)

    const [monthResult, priorResult] = await Promise.all([
      supabase
        .from('transactions')
        .select(
          'id, transaction_date, description, transaction_type, amount, fund_id, category_id, activity_id, vendor_id, person_id, account_id, reference_number, notes, funds(name), categories(name), accounts(name), vendors(name), persons(name)'
        )
        .gte('transaction_date', start)
        .lte('transaction_date', end)
        .order('transaction_date', { ascending: false }),

      supabase
        .from('transactions')
        .select('transaction_type, amount, fund_id, account_id')
        .lt('transaction_date', start),
    ])

    if (monthResult.error || priorResult.error) {
      setError(
        'Unable to load transactions. Check the schema and permissions.'
      )
    }

    setRows((monthResult.data || []) as unknown as Transaction[])
    setPriorRows((priorResult.data || []) as PriorTransaction[])

    setLoading(false)
  }

  async function loadOptions() {
    const [fundsResult, categoriesResult, activitiesResult, vendorsResult, personsResult, accountsResult] = await Promise.all([
      supabase.from('funds').select('id, name, code').order('name'),
      supabase.from('categories').select('id, name, code').order('name'),
      supabase.from('activities').select('id, name, code, fund_id').order('name'),
      supabase.from('vendors').select('id, name').order('name'),
      supabase.from('persons').select('id, name').order('name'),
      supabase.from('accounts').select('id, name').order('name'),
    ])
    setFunds(fundsResult.data || []); setCategories(categoriesResult.data || []); setActivities(activitiesResult.data || []); setVendors(vendorsResult.data || []); setPersons(personsResult.data || []); setAccounts(accountsResult.data || [])
  }

  useEffect(() => { void loadTransactions() }, [month])
  useEffect(() => { void loadOptions() }, [])

  useEffect(() => {
    if (!fundFilterSet && funds.length > 0) {
      const fund = funds.find(f => f.name.toUpperCase() === focus)
      if (fund) setFundFilter(String(fund.id))
      setFundFilterSet(true)
    }
  }, [funds, focus, fundFilterSet])

  function openCreate() { setEditing(null); setForm(blankForm()); setError('') }
  function openEdit(row: Transaction) { setEditing(row); setForm({ transaction_date: row.transaction_date, fund_id: String(row.fund_id), category_id: String(row.category_id), activity_id: row.activity_id ? String(row.activity_id) : '', transaction_type: row.transaction_type, amount: String(row.amount), description: row.description, vendor_id: row.vendor_id ? String(row.vendor_id) : '', person_id: row.person_id ? String(row.person_id) : '', account_id: row.account_id ? String(row.account_id) : '', reference_number: '', notes: '' }); setError('') }
  function closeForm() { setEditing(null); setForm(null) }

  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (!form) return
    setSaving(true); setError('')
    const payload = { transaction_date: form.transaction_date, fund_id: Number(form.fund_id), category_id: Number(form.category_id), activity_id: form.activity_id ? Number(form.activity_id) : null, transaction_type: form.transaction_type, amount: Number(form.amount), description: form.description.trim(), vendor_id: form.vendor_id ? Number(form.vendor_id) : null, person_id: form.person_id ? Number(form.person_id) : null, account_id: form.account_id ? Number(form.account_id) : null, reference_number: form.reference_number.trim() || null, notes: form.notes.trim() || null }
    const result = editing ? await supabase.from('transactions').update(payload).eq('id', editing.id) : await supabase.from('transactions').insert(payload)
    if (result.error) setError(result.error.message); else { closeForm(); await loadTransactions() }
    setSaving(false)
  }

  async function remove(row: Transaction) {
    if (!window.confirm(`Delete transaction "${row.description}"?`)) return
    const result = await supabase.from('transactions').delete().eq('id', row.id)
    if (result.error) setError(`Unable to delete transaction: ${result.error.message}`); else await loadTransactions()
  }

  const filtered = rows.filter(row => (type === 'ALL' || row.transaction_type === type) && (fundFilter === 'ALL' || String(row.fund_id) === fundFilter) && (accountFilter === 'ALL' || String(row.account_id || '') === accountFilter) && `${row.description} ${row.funds?.name || ''} ${row.categories?.name || ''}`.toLowerCase().includes(query.toLowerCase()))
  const balanceRows = rows.filter(row => {
    const matchesFund =
      fundFilter === 'ALL' ||
      String(row.fund_id) === fundFilter

    const matchesAccount =
      accountFilter === 'ALL' ||
      String(row.account_id ?? '') === accountFilter

    return matchesFund && matchesAccount
  })

  const balancePriorRows = priorRows.filter(row => {
    const matchesFund =
      fundFilter === 'ALL' ||
      String(row.fund_id) === fundFilter

    const matchesAccount =
      accountFilter === 'ALL' ||
      String(row.account_id ?? '') === accountFilter

    return matchesFund && matchesAccount
  })

  const openingBalance = balancePriorRows.reduce(
    (total, row) =>
      total +
      (row.transaction_type === 'EXPENSE'
        ? -Number(row.amount)
        : Number(row.amount)),
    0
  )

  const movement = balanceRows.reduce(
    (total, row) =>
      total +
      (row.transaction_type === 'EXPENSE'
        ? -Number(row.amount)
        : Number(row.amount)),
    0
  )

  const closingBalance = openingBalance + movement
  const selectedFund = form?.fund_id ? Number(form.fund_id) : null
  const visibleActivities = activities.filter(activity => !selectedFund || !activity.fund_id || activity.fund_id === selectedFund)

  const titleLabel = focus === 'WAKAF' ? 'Wakaf Transaction' : 'Infaq Transaction'

  return <div className="fade-up space-y-8">
    <div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-end"><div><p className="mb-2 text-xs font-bold uppercase tracking-[.22em] text-moss">Ledger</p><h1 className="font-display text-4xl text-ink">{titleLabel}</h1><p className="mt-2 text-sm text-muted">A clean record of every movement across mosque funds.</p></div><button onClick={openCreate} className="inline-flex items-center justify-center gap-2 rounded-xl bg-moss px-4 py-3 text-sm font-bold text-white"><Plus size={17} /> Add transaction</button></div>
    <div className="flex flex-col gap-3 md:flex-row"><label className="relative flex-1"><Search size={17} className="field-icon text-muted" /><input className="field field-with-icon" placeholder="Search description, fund, category..." value={query} onChange={event => setQuery(event.target.value)} /></label><label className="relative"><CalendarDays size={17} className="field-icon text-moss" /><input type="month" className="field field-with-icon" value={month} onChange={event => setMonth(event.target.value)} /></label><label className="relative"><Filter size={17} className="field-icon text-moss" /><select className="field field-with-icon pr-8" value={type} onChange={event => setType(event.target.value)}><option value="ALL">All types</option><option value="INCOME">Income</option><option value="EXPENSE">Expense</option></select></label></div>
    <div className="flex flex-col gap-3 border-t border-moss/10 pt-3 md:flex-row"><label className="flex-1"><select className="field" value={fundFilter} onChange={event => setFundFilter(event.target.value)}><option value="ALL">All funds</option>{funds.map(fund => <option key={fund.id} value={fund.id}>{fund.name}</option>)}</select></label><label className="flex-1"><select className="field" value={accountFilter} onChange={event => setAccountFilter(event.target.value)}><option value="ALL">All accounts</option>{accounts.map(account => <option key={account.id} value={account.id}>{account.name}</option>)}</select></label></div>
    <div className="grid gap-4 sm:grid-cols-2"><BalanceCard label="This month opening balance" value={openingBalance} /><BalanceCard label="This month closing balance" value={closingBalance} /></div>
    {error && <p className="rounded-xl bg-red-50 px-4 py-3 text-sm text-expense">{error}</p>}
    {focus === 'WAKAF' ? < WakafTable rows={filtered} loading={loading} onEdit={openEdit} onDelete={remove} /> : < InfaqTable rows={filtered} loading={loading} onEdit={openEdit} onDelete={remove} />}
    {form && <TransactionForm form={form} setForm={setForm} onSave={save} onClose={closeForm} saving={saving} editing={Boolean(editing)} funds={funds} categories={categories} activities={visibleActivities} vendors={vendors} persons={persons} accounts={accounts} />}
  </div>
}

function InfaqTable({ rows, loading, onEdit, onDelete }: { rows: Transaction[]; loading: boolean; onEdit: (row: Transaction) => void; onDelete: (row: Transaction) => void }) {
  return <div className="surface overflow-hidden rounded-2xl"><div className="hidden grid-cols-[110px_1fr_120px_150px_80px] gap-4 px-5 py-4 text-[10px] font-bold uppercase tracking-[.16em] text-muted md:grid"><span>Date</span><span>Description</span><span>Fund</span><span className="text-right">Amount</span><span /></div>{loading ? <p className="px-5 py-10 text-sm text-muted">Loading ledger...</p> : rows.length ? rows.map(row => <div key={row.id} className="table-row grid gap-3 px-5 py-4 md:grid-cols-[110px_1fr_120px_150px_80px] md:items-center md:gap-4"><span className="text-xs font-semibold text-muted">{new Intl.DateTimeFormat('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(`${row.transaction_date}T00:00:00`))}</span><div><p className="font-semibold">{row.description}</p><p className="mt-1 text-xs text-muted">{row.categories?.name || 'Uncategorized'} · {row.accounts?.name || 'No account'}</p></div><span className="text-sm text-moss">{row.funds?.name || '—'}</span><span className={`flex items-center gap-1 font-bold md:justify-end ${row.transaction_type === 'EXPENSE' ? 'text-expense' : 'text-moss'}`}>{row.transaction_type === 'EXPENSE' ? <ArrowDownLeft size={15} /> : <ArrowUpRight size={15} />} {money(row.amount)}</span><span className="flex justify-end gap-1"><button onClick={() => onEdit(row)} className="rounded-lg p-2 text-moss hover:bg-canvas" title="Edit"><Pencil size={15} /></button><button onClick={() => void onDelete(row)} className="rounded-lg p-2 text-expense hover:bg-red-50" title="Delete"><Trash2 size={15} /></button></span></div>) : <div className="px-5 py-14 text-center"><p className="font-display text-2xl text-ink">No transactions found</p><p className="mt-2 text-sm text-muted">Try another month or add the first ledger entry.</p></div>}</div>
}

function WakafTable({ rows, loading, onEdit, onDelete }: { rows: Transaction[]; loading: boolean; onEdit: (row: Transaction) => void; onDelete: (row: Transaction) => void }) {
  return <div className="surface overflow-hidden rounded-2xl"><div className="hidden grid-cols-[100px_1fr_100px_120px_100px_100px_100px_80px] gap-3 px-4 py-4 text-[10px] font-bold uppercase tracking-[.16em] text-muted md:grid"><span>Date</span><span>Description</span><span>Fund</span><span className="text-right">Amount</span><span>Vendor</span><span>Person</span><span>Category</span><span /></div>{loading ? <p className="px-5 py-10 text-sm text-muted">Loading ledger...</p> : rows.length ? rows.map(row => <div key={row.id} className="table-row grid gap-3 px-4 py-4 md:grid-cols-[100px_1fr_100px_120px_100px_100px_100px_80px] md:items-center md:gap-3"><span className="text-xs font-semibold text-muted">{new Intl.DateTimeFormat('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(`${row.transaction_date}T00:00:00`))}</span><p className="font-semibold text-sm">{row.description}</p><span className="text-sm text-moss">{row.funds?.name || '—'}</span><span className={`flex items-center gap-1 font-bold md:justify-end ${row.transaction_type === 'EXPENSE' ? 'text-expense' : 'text-moss'}`}>{row.transaction_type === 'EXPENSE' ? <ArrowDownLeft size={15} /> : <ArrowUpRight size={15} />} {money(row.amount)}</span><span className="text-sm text-muted">{row.vendors?.name || '—'}</span><span className="text-sm text-muted">{row.persons?.name || '—'}</span><span className="text-sm text-muted">{row.categories?.name || 'Uncategorized'}</span><span className="flex justify-end gap-1"><button onClick={() => onEdit(row)} className="rounded-lg p-2 text-moss hover:bg-canvas" title="Edit"><Pencil size={15} /></button><button onClick={() => void onDelete(row)} className="rounded-lg p-2 text-expense hover:bg-red-50" title="Delete"><Trash2 size={15} /></button></span></div>) : <div className="px-5 py-14 text-center"><p className="font-display text-2xl text-ink">No transactions found</p><p className="mt-2 text-sm text-muted">Try another month or add the first ledger entry.</p></div>}</div>
}

function BalanceCard({ label, value }: { label: string; value: number }) { return <div className="surface rounded-2xl p-5"><p className="text-xs font-semibold uppercase tracking-[.12em] text-muted">{label}</p><p className="mt-3 font-display text-2xl text-moss">{money(value)}</p></div> }
function Select({ label, value, options, required = false, onChange }: { label: string; value: string; options: Option[]; required?: boolean; onChange: (value: string) => void }) { return <label className="text-xs font-bold uppercase tracking-[.1em] text-muted">{label}<select required={required} value={value} onChange={event => onChange(event.target.value)} className="field mt-2"><option value="">Select {label.toLowerCase()}</option>{options.map(option => <option key={option.id} value={option.id}>{option.name}</option>)}</select></label> }
function TransactionForm({ form, setForm, onSave, onClose, saving, editing, funds, categories, activities, vendors, persons, accounts }: { form: FormState; setForm: (form: FormState) => void; onSave: (event: FormEvent<HTMLFormElement>) => void; onClose: () => void; saving: boolean; editing: boolean; funds: Option[]; categories: Option[]; activities: Option[]; vendors: Option[]; persons: Option[]; accounts: Option[] }) { const update = (patch: Partial<FormState>) => setForm({ ...form, ...patch }); return <div className="fixed inset-0 z-30 grid place-items-start pt-[8vh] bg-ink/30 p-5"><form onSubmit={onSave} className="surface max-h-[85vh] w-full max-w-3xl overflow-y-auto rounded-2xl p-6"><div className="flex items-center justify-between"><h2 className="font-display text-2xl">{editing ? 'Edit transaction' : 'View transaction'}</h2><button type="button" onClick={onClose} className="rounded-lg p-2 text-muted hover:bg-canvas"><X size={18} /></button></div><div className="mt-6 grid gap-4 sm:grid-cols-2"><label className="text-xs font-bold uppercase tracking-[.1em] text-muted">Transaction date<input required type="date" value={form.transaction_date} onChange={event => update({ transaction_date: event.target.value })} className="field mt-2" /></label><label className="text-xs font-bold uppercase tracking-[.1em] text-muted">Type<select required value={form.transaction_type} onChange={event => update({ transaction_type: event.target.value as FormState['transaction_type'] })} className="field mt-2"><option value="INCOME">Income</option><option value="EXPENSE">Expense</option></select></label><Select label="Fund" value={form.fund_id} options={funds} required onChange={value => update({ fund_id: value, activity_id: '' })} /><Select label="Category" value={form.category_id} options={categories} required onChange={value => update({ category_id: value })} /><Select label="Activity" value={form.activity_id} options={activities} onChange={value => update({ activity_id: value })} /><label className="text-xs font-bold uppercase tracking-[.1em] text-muted">Amount<input required min="0.01" step="0.01" type="number" value={form.amount} onChange={event => update({ amount: event.target.value })} className="field mt-2" /></label><Select label="Vendor" value={form.vendor_id} options={vendors} onChange={value => update({ vendor_id: value })} /><Select label="Person" value={form.person_id} options={persons} onChange={value => update({ person_id: value })} /><Select label="Account" value={form.account_id} options={accounts} onChange={value => update({ account_id: value })} /><label className="text-xs font-bold uppercase tracking-[.1em] text-muted">Reference number<input value={form.reference_number} onChange={event => update({ reference_number: event.target.value })} className="field mt-2" /></label><label className="sm:col-span-2 text-xs font-bold uppercase tracking-[.1em] text-muted">Description<input required value={form.description} onChange={event => update({ description: event.target.value })} className="field mt-2" /></label><label className="sm:col-span-2 text-xs font-bold uppercase tracking-[.1em] text-muted">Notes<textarea value={form.notes} onChange={event => update({ notes: event.target.value })} className="field mt-2 min-h-20" /></label></div><div className="mt-6 flex justify-end gap-3"><button type="button" onClick={onClose} className="rounded-xl border border-moss/20 px-4 py-3 text-sm font-bold text-moss">Cancel</button><button disabled={saving} className="rounded-xl bg-moss px-4 py-3 text-sm font-bold text-white">{saving ? 'Saving...' : 'Save transaction'}</button></div></form></div> }
