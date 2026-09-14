'use client'

import Image from 'next/image'
import { ArrowRight, LockKeyhole, Mail, UserRoundPlus } from 'lucide-react'
import { FormEvent, useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabaseClient'

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [notice, setNotice] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (data.user) router.replace('/')
    })
  }, [router])

  async function signIn(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError('')
    setNotice('')
    setLoading(true)
    const { error: signInError } = await supabase.auth.signInWithPassword({ email: email.trim(), password })
    setLoading(false)
    if (signInError) {
      setError('The email or password could not be verified.')
      return
    }
    router.replace('/')
    router.refresh()
  }

  return <main className="login-page">
    <Image src="/Login.png" alt="Interior of the mosque prayer hall" fill priority sizes="100vw" className="login-photo" />
    <div className="login-wash" />
    <div className="login-layout">
      <section className="login-intro">
        <p className="text-xs font-bold uppercase tracking-[.28em] text-white/75">Al Fathoniah Mosque</p>
        <h1 className="mt-5 max-w-xl font-display text-5xl leading-[1.05] text-white md:text-7xl">A clear record for every trust.</h1>
        <p className="mt-6 max-w-md text-sm leading-7 text-white/80">Mosque Finance keeps infaq and wakaf reporting calm, connected, and ready for the people who care for it.</p>
      </section>
      <section className="login-panel">
        <div className="mb-8 flex items-center gap-3"><div className="grid h-12 w-12 place-items-center rounded-2xl bg-moss text-xl font-bold text-white shadow-lg shadow-moss/20">MF</div><div><p className="font-display text-2xl text-moss">Mosque Finance</p><p className="text-[10px] font-bold uppercase tracking-[.18em] text-muted">Secure workspace</p></div></div>
        <div className="mb-7"><h2 className="font-display text-3xl text-ink">Welcome back</h2><p className="mt-2 text-sm leading-6 text-muted">Sign in to continue to the financial ledger.</p></div>
        <form onSubmit={signIn} className="space-y-5">
          <label className="block"><span className="mb-2 block text-xs font-bold uppercase tracking-[.12em] text-ink/70">Username / email</span><span className="relative block"><Mail size={17} className="field-icon text-moss"/><input className="field field-with-icon" type="email" autoComplete="username" required value={email} onChange={event => setEmail(event.target.value)} placeholder="you@example.com" /></span></label>
          <label className="block"><span className="mb-2 block text-xs font-bold uppercase tracking-[.12em] text-ink/70">Password</span><span className="relative block"><LockKeyhole size={17} className="field-icon text-moss"/><input className="field field-with-icon" type="password" autoComplete="current-password" required value={password} onChange={event => setPassword(event.target.value)} placeholder="Enter your password" /></span></label>
          {error && <p role="alert" className="rounded-xl bg-[#fff1ef] px-3 py-2.5 text-xs font-semibold text-expense">{error}</p>}
          {notice && <p role="status" className="rounded-xl bg-canvas px-3 py-2.5 text-xs font-semibold text-moss">{notice}</p>}
          <button type="submit" disabled={loading} className="flex w-full items-center justify-center gap-2 rounded-xl bg-moss px-4 py-3.5 text-sm font-bold text-white shadow-lg shadow-moss/15 transition hover:bg-[#205f45] disabled:cursor-wait disabled:opacity-60">{loading ? 'Signing in...' : 'Sign in'}{!loading && <ArrowRight size={17}/>}</button>
        </form>
        <div className="my-7 flex items-center gap-3 text-[10px] font-bold uppercase tracking-[.15em] text-muted"><span className="h-px flex-1 bg-moss/10"/>New to the workspace?<span className="h-px flex-1 bg-moss/10"/></div>
        <button type="button" onClick={() => { setError(''); setNotice('Registration is managed by the mosque administrator. Please contact admin to request access.') }} className="flex w-full items-center justify-center gap-2 rounded-xl border border-moss/20 bg-white/60 px-4 py-3 text-sm font-bold text-moss hover:bg-canvas"><UserRoundPlus size={17}/> Request access</button>
      </section>
    </div>
  </main>
}
