'use client'

import Link from 'next/link'
import { ArrowLeft, Database, Pencil, Plus, Trash2, X } from 'lucide-react'
import { FormEvent, useEffect, useState } from 'react'
import { supabase } from '@/lib/supabaseClient'

type Field = { key: string; label: string; type?: string; required?: boolean }
type Row = Record<string, any>
type Config = { title: string; description: string; table: string; columns: string[]; fields: Field[] }

const configs: Record<string, Config> = {
  funds: { title: 'Funds', description: 'Separate pools that keep every rupiah accountable.', table: 'funds', columns: ['code', 'name', 'description', 'active'], fields: [{ key: 'code', label: 'Code', required: true }, { key: 'name', label: 'Name', required: true }, { key: 'description', label: 'Description', type: 'textarea' }, { key: 'active', label: 'Active', type: 'checkbox' }] },
  categories: { title: 'Categories', description: 'Consistent financial classification for the ledger.', table: 'categories', columns: ['code', 'name', 'parent_name', 'active'], fields: [{ key: 'code', label: 'Code', required: true }, { key: 'name', label: 'Name', required: true }, { key: 'parent_id', label: 'Parent category', type: 'category' }, { key: 'description', label: 'Description', type: 'textarea' }, { key: 'active', label: 'Active', type: 'checkbox' }] },
  activities: { title: 'Activities', description: 'Projects, events, and programs attached to transactions.', table: 'activities', columns: ['code', 'name', 'fund_name', 'start_date', 'end_date', 'active'], fields: [{ key: 'fund_id', label: 'Fund', type: 'fund' }, { key: 'code', label: 'Code' }, { key: 'name', label: 'Name', required: true }, { key: 'description', label: 'Description', type: 'textarea' }, { key: 'start_date', label: 'Start date', type: 'date' }, { key: 'end_date', label: 'End date', type: 'date' }, { key: 'active', label: 'Active', type: 'checkbox' }] },
  vendors: { title: 'Vendors', description: 'Suppliers, workers, and payment recipients.', table: 'vendors', columns: ['name', 'phone', 'bank_name', 'bank_account_number', 'active'], fields: [{ key: 'name', label: 'Name', required: true }, { key: 'phone', label: 'Phone' }, { key: 'address', label: 'Address', type: 'textarea' }, { key: 'bank_name', label: 'Bank' }, { key: 'bank_account_number', label: 'Bank account number' }, { key: 'bank_account_name', label: 'Account holder' }, { key: 'notes', label: 'Notes', type: 'textarea' }, { key: 'active', label: 'Active', type: 'checkbox' }] },
  persons: { title: 'Persons', description: 'People associated with payments and reimbursements.', table: 'persons', columns: ['name', 'role', 'phone', 'active'], fields: [{ key: 'name', label: 'Name', required: true }, { key: 'phone', label: 'Phone' }, { key: 'role', label: 'Role' }, { key: 'notes', label: 'Notes', type: 'textarea' }, { key: 'active', label: 'Active', type: 'checkbox' }] },
  accounts: { title: 'Accounts', description: 'Cash and bank payment sources used by the mosque.', table: 'accounts', columns: ['name', 'account_type', 'bank_name', 'account_number', 'active'], fields: [{ key: 'name', label: 'Name', required: true }, { key: 'account_type', label: 'Account type', type: 'account_type', required: true }, { key: 'bank_name', label: 'Bank' }, { key: 'account_number', label: 'Account number' }, { key: 'account_name', label: 'Account holder' }, { key: 'description', label: 'Description', type: 'textarea' }, { key: 'active', label: 'Active', type: 'checkbox' }] },
}

const initialValue = (field: Field) => field.type === 'checkbox' ? true : ''

export default function MasterTypePage({ params }: { params: { type: string } }) {
  const config = configs[params.type] || configs.funds
  const [rows, setRows] = useState<Row[]>([])
  const [funds, setFunds] = useState<Row[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [editing, setEditing] = useState<Row | undefined>()
  const [form, setForm] = useState<Row | null>(null)
  const [saving, setSaving] = useState(false)

  async function load() {
    setLoading(true)
    const select = params.type === 'activities' ? '*, funds(name)' : params.type === 'categories' ? '*, parent:categories!parent_id(name)' : '*'
    const result = await supabase.from(config.table).select(select).order('name', { ascending: true })
    const fundResult = params.type === 'activities' ? await supabase.from('funds').select('id, name, code').order('name') : { data: [] }
    if (result.error) setError('Unable to load records. Check the database schema and permissions.')
    setRows((result.data || []).map((row: any) => ({ ...row, fund_name: row.funds?.name || null, parent_name: row.parent?.name || null })) as Row[])
    setFunds((fundResult.data || []) as Row[])
    setLoading(false)
  }

  useEffect(() => { void load() }, [config.table, params.type])

  function openCreate() { setEditing(undefined); setForm(Object.fromEntries(config.fields.map(field => [field.key, initialValue(field)]))); setError('') }
  function openEdit(row: Row) { setEditing(row); setForm(Object.fromEntries(config.fields.map(field => [field.key, row[field.key] ?? initialValue(field)]))); setError('') }
  function closeForm() { setEditing(undefined); setForm(null) }

  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (!form) return
    setSaving(true); setError('')
    const payload = Object.fromEntries(config.fields.map(field => [field.key, field.type === 'checkbox' ? Boolean(form[field.key]) : form[field.key] === '' ? null : form[field.key]]))
    const result = editing ? await supabase.from(config.table).update(payload).eq('id', editing.id) : await supabase.from(config.table).insert(payload)
    if (result.error) setError(result.error.message)
    else { closeForm(); await load() }
    setSaving(false)
  }

  async function remove(row: Row) {
    if (!window.confirm(`Delete ${row.name || row.code || 'this record'}?`)) return
    const result = await supabase.from(config.table).delete().eq('id', row.id)
    if (result.error) setError(`Unable to delete record: ${result.error.message}`)
    else await load()
  }

  return <div className="fade-up space-y-8"><Link href="/master" className="inline-flex items-center gap-2 text-sm font-bold text-moss"><ArrowLeft size={16} /> Master data</Link><div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-end"><div><p className="mb-2 text-xs font-bold uppercase tracking-[.22em] text-moss">Configuration</p><h1 className="font-display text-4xl text-ink">{config.title}</h1><p className="mt-2 text-sm text-muted">{config.description}</p></div><button onClick={openCreate} className="inline-flex items-center justify-center gap-2 rounded-xl bg-moss px-4 py-3 text-sm font-bold text-white"><Plus size={17} /> Add {config.title.slice(0, -1)}</button></div>{error && <p className="rounded-xl bg-red-50 px-4 py-3 text-sm text-expense">{error}</p>}<div className="surface overflow-x-auto rounded-2xl"><table className="w-full min-w-[760px] text-left"><thead><tr className="text-[10px] font-bold uppercase tracking-[.16em] text-muted">{config.columns.map(column => <th key={column} className="px-5 py-4">{column.replaceAll('_', ' ')}</th>)}<th className="px-5 py-4 text-right">Actions</th></tr></thead><tbody>{loading ? <tr><td colSpan={config.columns.length + 1} className="px-5 py-10 text-sm text-muted">Loading records...</td></tr> : rows.length ? rows.map(row => <tr key={String(row.id)} className="table-row text-sm">{config.columns.map(column => <td key={column} className="px-5 py-4">{column === 'active' ? <span className={`rounded-full px-2.5 py-1 text-xs font-bold ${row[column] ? 'bg-[#d9f2df] text-moss' : 'bg-slate-100 text-muted'}`}>{row[column] ? 'Active' : 'Inactive'}</span> : String(row[column] ?? '—')}</td>)}<td className="px-5 py-4"><div className="flex justify-end gap-2"><button onClick={() => openEdit(row)} className="rounded-lg p-2 text-moss hover:bg-canvas" title="Edit"><Pencil size={16} /></button><button onClick={() => void remove(row)} className="rounded-lg p-2 text-expense hover:bg-red-50" title="Delete"><Trash2 size={16} /></button></div></td></tr>) : <tr><td colSpan={config.columns.length + 1} className="px-5 py-12 text-center text-sm text-muted">No records yet.</td></tr>}</tbody></table></div><div className="flex items-center gap-2 text-xs text-muted"><Database size={14} className="text-moss" /> Names are shown here; relational IDs remain database-only.</div>{form && <div className="fixed inset-0 z-30 grid place-items-center bg-ink/30 p-5"><form onSubmit={save} className="surface max-h-[90vh] w-full max-w-xl overflow-y-auto rounded-2xl p-6"><div className="flex items-center justify-between"><h2 className="font-display text-2xl">{editing ? `Edit ${config.title.slice(0, -1)}` : `Add ${config.title.slice(0, -1)}`}</h2><button type="button" onClick={closeForm} className="rounded-lg p-2 text-muted hover:bg-canvas"><X size={18} /></button></div><div className="mt-6 grid gap-4 sm:grid-cols-2">{config.fields.map(field => <label key={field.key} className={`${field.type === 'textarea' ? 'sm:col-span-2' : ''} text-xs font-bold uppercase tracking-[.1em] text-muted`}>{field.label}{field.type === 'checkbox' ? <span className="mt-2 flex items-center gap-2"><input type="checkbox" checked={Boolean(form[field.key])} onChange={event => setForm({ ...form, [field.key]: event.target.checked })} /> Active</span> : field.type === 'textarea' ? <textarea required={field.required} value={form[field.key] || ''} onChange={event => setForm({ ...form, [field.key]: event.target.value })} className="field mt-2 min-h-20" /> : field.type === 'fund' ? <select required={field.required} value={form[field.key] || ''} onChange={event => setForm({ ...form, [field.key]: event.target.value || null })} className="field mt-2"><option value="">No fund</option>{funds.map(fund => <option key={fund.id} value={fund.id}>{fund.name}</option>)}</select> : field.type === 'category' ? <select value={form[field.key] || ''} onChange={event => setForm({ ...form, [field.key]: event.target.value || null })} className="field mt-2"><option value="">No parent</option>{rows.filter(row => row.id !== editing?.id).map(row => <option key={row.id} value={row.id}>{row.name}</option>)}</select> : field.type === 'account_type' ? <select required={field.required} value={form[field.key] || ''} onChange={event => setForm({ ...form, [field.key]: event.target.value })} className="field mt-2"><option value="">Select type</option><option value="CASH">Cash</option><option value="BANK">Bank</option><option value="OTHER">Other</option></select> : <input required={field.required} type={field.type === 'date' ? 'date' : 'text'} value={form[field.key] || ''} onChange={event => setForm({ ...form, [field.key]: event.target.value })} className="field mt-2" />}</label>)}</div><div className="mt-6 flex justify-end gap-3"><button type="button" onClick={closeForm} className="rounded-xl border border-moss/20 px-4 py-3 text-sm font-bold text-moss">Cancel</button><button disabled={saving} className="rounded-xl bg-moss px-4 py-3 text-sm font-bold text-white">{saving ? 'Saving...' : 'Save'}</button></div></form></div>}</div>
}