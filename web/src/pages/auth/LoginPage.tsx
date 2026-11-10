import { useState, useEffect } from "react"
import { useNavigate } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { Loader2, Eye, EyeOff } from "lucide-react"
import ThemeToggle from "@/components/layout/ThemeToggle"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogClose } from "@/components/ui/dialog"

export default function LoginPage() {
  const [employeeId, setEmployeeId] = useState("")
  const [password, setPassword] = useState("")
  const [showPass, setShowPass] = useState(false)
  const [showTerms, setShowTerms] = useState(false)
  const { login, isLoading, error } = useAuthStore()
  const navigate = useNavigate()

  useEffect(() => {
    if (!sessionStorage.getItem("termsSeen")) {
      setShowTerms(true)
      sessionStorage.setItem("termsSeen", "true")
    }
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!employeeId.trim() || !password.trim()) return
    const success = await login(employeeId, password)
    if (success) {
      const user = useAuthStore.getState().user
      if (user?.is_security) navigate("/security/scan", { replace: true })
      else if (user?.is_admin) navigate("/admin/employees", { replace: true })
      else if (user?.is_supervisor) navigate("/supervisor", { replace: true })
      else navigate("/employee", { replace: true })
    }
  }

  return (
    <main className="app-aurora page-enter relative flex min-h-screen flex-col">
      <div className="glow-blob h-80 w-80 bg-primary/20 left-1/4 -top-20" />
      <div className="glow-blob h-72 w-72 bg-success/15 right-10 bottom-0" />
      <div className="absolute right-4 top-4 z-10">
        <ThemeToggle />
      </div>
      <div className="relative z-[1] flex flex-1 items-center justify-center p-6">
        <div className="flex w-full max-w-3xl flex-col overflow-hidden rounded-2xl border border-border shadow-2xl lg:flex-row card-elevated">
          {/* Left — Brand hero */}
          <div className="brand-gradient relative hidden flex-col justify-between p-8 lg:flex lg:w-1/2">
            <div className="flex items-center gap-3">
              <div className="brand-gradient flex h-11 w-11 items-center justify-center rounded-xl border border-primary/30">
                <img src="/app-icon.png" alt="" className="h-6 w-6" />
              </div>
              <div>
                <p className="text-lg font-bold font-display leading-tight text-foreground">QuickPass</p>
                <p className="text-[9px] font-semibold uppercase tracking-[0.14em] text-muted-foreground/70">Gate Access</p>
              </div>
            </div>
            <div className="space-y-3">
              <h2 className="text-2xl font-bold font-display leading-tight text-foreground">
                Leave & gate access,<br /><span className="text-gradient">made effortless.</span>
              </h2>
              <p className="text-sm text-muted-foreground/80">
                Request temporary leaves, get supervisor approval, and scan in and out at the gate — all in one place.
              </p>
            </div>
            <p className="text-[10px] font-semibold uppercase tracking-[0.1em] text-muted-foreground/40">ZANECO &middot; QuickPass</p>
          </div>

          {/* Right — Form panel */}
          <div className="glass flex-1 p-7">
            <div className="space-y-5">
              <div>
                <p className="text-xl font-bold text-foreground tracking-tight">Sign in</p>
                <p className="text-xs text-muted-foreground mt-1">Use your employee ID and password</p>
              </div>

              <form onSubmit={handleSubmit} className="space-y-3">
                <div className="space-y-1">
                  <label htmlFor="employee-id" className="label-stitch">Employee ID</label>
                  <input
                    id="employee-id"
                    className="input-stitch h-10"
                    placeholder="000001"
                    maxLength={6}
                    value={employeeId}
                    onChange={(e) => setEmployeeId(e.target.value.replace(/\D/g, "").slice(0, 6))}
                    required
                  />
                </div>

                <div className="space-y-1">
                  <div className="flex items-center justify-between">
                    <label htmlFor="password" className="label-stitch">Password</label>
                    <span className="text-[9px] font-semibold uppercase tracking-[0.08em] text-muted-foreground/60">Forgot?</span>
                  </div>
                  <div className="relative">
                    <input
                      id="password"
                      className="input-stitch h-10 pr-10"
                      type={showPass ? "text" : "password"}
                      placeholder="Enter your password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                    />
                    <button type="button" onClick={() => setShowPass(!showPass)} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground/40 hover:text-muted-foreground transition-colors">
                      {showPass ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                </div>

                {error && (
                  <div className="rounded border border-destructive/30 bg-destructive/5 px-3 py-2">
                    <p className="text-[11px] font-medium text-destructive">{error}</p>
                  </div>
                )}

                <button
                  type="submit"
                  disabled={isLoading}
                  className="btn-gradient w-full h-10 text-[11px]"
                >
                  {isLoading ? <Loader2 className="h-4 w-4 animate-spin mx-auto" /> : "Sign in"}
                </button>
              </form>
            </div>
            <div className="mt-5 flex items-center justify-between border-t border-border/60 pt-4 text-[10px] text-muted-foreground/60">
              <span>v1.0</span>
              <button type="button" onClick={() => setShowTerms(true)} className="underline underline-offset-2 hover:text-foreground">Terms of Service</button>
            </div>
          </div>
        </div>
      </div>

      <div className="relative z-[1] flex items-center justify-between px-8 pb-4">
        <span className="text-[10px] text-muted-foreground/30">&copy; 2026 ZANECO QuickPass</span>
        <span className="text-[10px] text-muted-foreground/30">v1.0</span>
      </div>

      <Dialog open={showTerms} onOpenChange={setShowTerms}>
        <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Terms of Service</DialogTitle>
          </DialogHeader>
          <div className="space-y-3 text-sm text-muted-foreground">
            <p><strong className="text-foreground">1. Acceptance of Terms</strong></p>
            <p>By logging into and using the QuickPass Gate Pass System ("System"), you acknowledge that you have read, understood, and agree to be bound by these Terms of Service and any applicable policies referenced herein.</p>
            <p><strong className="text-foreground">2. Authorized Use</strong></p>
            <p>The System is provided to ZANECO employees solely for submitting leave requests, receiving approvals, and scanning gate passes. You may use the System only in accordance with company policy and these terms. Any unauthorized access, sharing of credentials, misuse of QR codes, or tampering with gate access records is strictly prohibited.</p>
            <p><strong className="text-foreground">3. Account Responsibility</strong></p>
            <p>You are responsible for maintaining the confidentiality of your employee ID and password. You agree to notify the IT department immediately of any suspected unauthorized use of your account. ZANECO is not liable for losses resulting from your failure to safeguard your credentials.</p>
            <p><strong className="text-foreground">4. Gate Access &amp; Leave Records</strong></p>
            <p>QR codes generated through the System are single-use, time-limited, and issued only after supervisor approval. You may not share, copy, resell, or lend your QR codes to any other person. All scans are logged and monitored. Unauthorized or invalid scans may result in denial of entry, disciplinary action, or loss of gate access privileges.</p>
            <p><strong className="text-foreground">5. Data Privacy</strong></p>
            <p>The System stores your personal information, leave requests, and scan history. This data is processed solely for gate access, leave management, and reporting purposes. Your data will not be disclosed to third parties except as required by law or as necessary to operate the System.</p>
            <p><strong className="text-foreground">6. Availability</strong></p>
            <p>ZANECO strives to keep the System available, but it may be temporarily unavailable for maintenance, updates, or unforeseen failures. ZANECO is not liable for any loss, damage, or inconvenience caused by System downtime or errors.</p>
            <p><strong className="text-foreground">7. Termination</strong></p>
            <p>ZANECO may suspend or terminate your System access at any time if you violate these terms, company policy, or applicable law.</p>
            <p><strong className="text-foreground">8. Contact</strong></p>
            <p>For questions about these Terms of Service, please contact your manager or the IT Helpdesk.</p>
          </div>
          <div className="flex justify-end pt-2">
            <DialogClose asChild>
              <Button variant="default" size="sm">Close</Button>
            </DialogClose>
          </div>
        </DialogContent>
      </Dialog>
    </main>
  )
}
