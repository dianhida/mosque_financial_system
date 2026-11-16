'use client'

import { ArrowDownLeft, ArrowUpRight, CalendarDays, ChevronDown, ChevronUp, Filter, Search } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'

type LedgerTransaction = {
  id: number
  transaction_date: string
  description: string
  transaction_type: 'INCOME' | 'EXPENSE'
  amount: number
  fund_id: number
  category_id: number
  activity_id: number | null
  vendor_id: number | null
  person_id: number | null
  account_id: number | null
  fund_name: string | null
  category_name: string | null
  activity_name: string | null
  vendor_name: string | null
  person_name: string | null
  account_name: string | null
  created_at: string
}

type LedgerRow = LedgerTransaction & { runningBalance: number }

const money = (value: number) =>
  new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 })
    .format(value)
    .replace('IDR', 'Rp')

const formatDate = (dateStr: string) =>
  new Intl.DateTimeFormat('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }).format(
    new Date(`${dateStr}T00:00:00`)
  )

function sortTransactions(transactions: LedgerTransaction[]): LedgerTransaction[] {
  return [...transactions].sort((a, b) => {
    const dateCompare = new Date(b.transaction_date).getTime() - new Date(a.transaction_date).getTime()
    if (dateCompare !== 0) return dateCompare
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  })
}

function calculateRunningBalances(transactions: LedgerTransaction[]): LedgerRow[] {
  const ascending = [...transactions].sort((a, b) => {
    const dateCompare = new Date(a.transaction_date).getTime() - new Date(b.transaction_date).getTime()
    if (dateCompare !== 0) return dateCompare
    return new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
  })

  let balance = 0
  const withBalance = ascending.map((tx) => {
    balance += tx.transaction_type === 'INCOME' ? Number(tx.amount) : -Number(tx.amount)
    return { ...tx, runningBalance: balance }
  })

  return withBalance.sort((a, b) => {
    const dateCompare = new Date(b.transaction_date).getTime() - new Date(a.transaction_date).getTime()
    if (dateCompare !== 0) return dateCompare
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  })
}

export default function TransactionLedger({ focus }: { focus: 'INFAQ' | 'WAKAF' }) {
  const [rows, setRows] = useState<LedgerRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [query, setQuery] = useState('')
  const [typeFilter, setTypeFilter] = useState<'ALL' | 'INCOME' | 'EXPENSE'>('ALL')
  const [sortDesc, setSortDesc] = useState(true)

  async function loadTransactions() {
    setLoading(true)
    setError('')

    const viewName = focus === 'INFAQ' ? 'v_infaq_transaction_ledger' : 'v_wakaf_transaction_ledger'

    const { data, error: fetchError } = await supabase
      .from(viewName)
      .select(
        'id, transaction_date, description, transaction_type, amount, fund_id, category_id, activity_id, vendor_id, person_id, account_id, created_at, fund_name, category_name, activity_name, vendor_name, person_name, account_name'
      )

    if (fetchError) {
      setError('Unable to load transactions. Check the schema and permissions.')
      setLoading(false)
      return
    }

    const transactions = (data || []) as unknown as LedgerTransaction[]
    const withBalances = calculateRunningBalances(transactions)
    setRows(withBalances)
    setLoading(false)
  }

  useEffect(() => {
    void loadTransactions()
  }, [focus])

  const filteredRows = useMemo(() => {
    return rows.filter((row) => {
      const matchesType = typeFilter === 'ALL' || row.transaction_type === typeFilter
      const matchesQuery =
        query === '' ||
        `${row.description} ${row.fund_name || ''} ${row.category_name || ''} ${row.account_name || ''}`
          .toLowerCase()
          .includes(query.toLowerCase())
      return matchesType && matchesQuery
    })
  }, [rows, query, typeFilter])

  const sortedRows = useMemo(() => {
    return [...filteredRows].sort((a, b) => {
      const dateCompare = sortDesc
        ? new Date(b.transaction_date).getTime() - new Date(a.transaction_date).getTime()
        : new Date(a.transaction_date).getTime() - new Date(b.transaction_date).getTime()
      if (dateCompare !== 0) return dateCompare
      return sortDesc
        ? new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
        : new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
    })
  }, [filteredRows, sortDesc])

  const totalIncome = rows
    .filter((r) => r.transaction_type === 'INCOME')
    .reduce((sum, r) => sum + Number(r.amount), 0)
  const totalExpense = rows
    .filter((r) => r.transaction_type === 'EXPENSE')
    .reduce((sum, r) => sum + Number(r.amount), 0)
  const currentBalance = rows.length > 0 ? rows[0].runningBalance : 0

  const titleLabel = focus === 'WAKAF' ? 'Wakaf Transaction Ledger' : 'Infaq Transaction Ledger'
  const emptyMessage = focus === 'WAKAF' ? 'No Wakaf transactions recorded.' : 'No Infaq transactions recorded.'

  return (
    <div className="fade-up space-y-6">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
          <p className="mb-2 text-xs font-bold uppercase tracking-[.22em] text-moss">Ledger</p>
          <h1 className="font-display text-4xl text-ink">{titleLabel}</h1>
          <p className="mt-2 text-sm text-muted">
            Complete historical record of every {focus === 'INFAQ' ? 'infaq' : 'wakaf'} movement.
          </p>
        </div>
        <div className="grid gap-3 sm:grid-cols-3">
          <div className="surface rounded-xl p-4">
            <p className="text-xs font-semibold uppercase tracking-[.12em] text-muted">Total Income</p>
            <p className="mt-1 font-display text-xl text-moss">+{money(totalIncome)}</p>
          </div>
          <div className="surface rounded-xl p-4">
            <p className="text-xs font-semibold uppercase tracking-[.12em] text-muted">Total Expense</p>
            <p className="mt-1 font-display text-xl text-expense">-{money(totalExpense)}</p>
          </div>
          <div className="surface rounded-xl p-4">
            <p className="text-xs font-semibold uppercase tracking-[.12em] text-muted">Current Balance</p>
            <p className={`mt-1 font-display text-xl ${currentBalance >= 0 ? 'text-moss' : 'text-expense'}`}>
              {money(currentBalance)}
            </p>
          </div>
        </div>
      </div>

      {error && <p className="rounded-xl bg-red-50 px-4 py-3 text-sm text-expense">{error}</p>}

      <div className="flex flex-col gap-3 md:flex-row">
        <label className="relative flex-1">
          <Search size={17} className="field-icon text-muted" />
          <input
            className="field field-with-icon"
            placeholder="Search description, category, account..."
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </label>
        <label className="relative">
          <Filter size={17} className="field-icon text-moss" />
          <select
            className="field field-with-icon pr-8"
            value={typeFilter}
            onChange={(event) => setTypeFilter(event.target.value as 'ALL' | 'INCOME' | 'EXPENSE')}
          >
            <option value="ALL">All types</option>
            <option value="INCOME">Income</option>
            <option value="EXPENSE">Expense</option>
          </select>
        </label>
        <button
          onClick={() => setSortDesc(!sortDesc)}
          className="inline-flex items-center gap-2 rounded-xl border border-moss/15 px-3 py-2 text-sm font-semibold text-moss hover:bg-canvas"
          title="Toggle sort order"
        >
          {sortDesc ? <ChevronDown size={16} /> : <ChevronUp size={16} />}
          <span>Date {sortDesc ? 'Newest' : 'Oldest'} First</span>
        </button>
      </div>

      <div className="surface overflow-hidden rounded-2xl">
        <div className="hidden grid-cols-[110px_1fr_160px_160px] gap-4 px-5 py-4 text-[10px] font-bold uppercase tracking-[.16em] text-muted md:grid">
          <span>Date</span>
          <span>Description</span>
          <span className="text-right">Income / Expense</span>
          <span className="text-right">Current Balance</span>
        </div>
        {loading ? (
          <p className="px-5 py-10 text-sm text-muted">Loading ledger...</p>
        ) : sortedRows.length ? (
          sortedRows.map((row) => (
            <div
              key={row.id}
              className="table-row grid gap-3 px-5 py-4 md:grid-cols-[110px_1fr_160px_160px] md:items-center md:gap-4"
            >
              <span className="text-xs font-semibold text-muted">{formatDate(row.transaction_date)}</span>
              <div className="min-w-0">
                <p className="font-semibold truncate">{row.description}</p>
                <p className="mt-1 text-xs text-muted">
                  {row.category_name || 'Uncategorized'}
                  {row.account_name && ` · ${row.account_name}`}
                </p>
              </div>
              <span
                className={`flex items-center gap-1 font-bold md:justify-end ${
                  row.transaction_type === 'EXPENSE' ? 'text-expense' : 'text-moss'
                }`}
              >
                {row.transaction_type === 'EXPENSE' ? (
                  <>
                    <ArrowDownLeft size={15} /> -{money(row.amount)}
                  </>
                ) : (
                  <>
                    <ArrowUpRight size={15} /> +{money(row.amount)}
                  </>
                )}
              </span>
              <span
                className={`font-mono text-sm md:justify-end md:text-right ${
                  row.runningBalance >= 0 ? 'text-moss' : 'text-expense'
                }`}
              >
                {money(row.runningBalance)}
              </span>
            </div>
          ))
        ) : (
          <div className="px-5 py-14 text-center">
            <p className="font-display text-2xl text-ink">{emptyMessage}</p>
          </div>
        )}
      </div>
    </div>
  )
}