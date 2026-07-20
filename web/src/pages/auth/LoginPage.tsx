import { useState } from "react"
import { useNavigate } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { Loader2, Eye, EyeOff } from "lucide-react"
import ThemeToggle from "@/components/layout/ThemeToggle"

export default function LoginPage() {
  const [employeeId, setEmployeeId] = useState("")
  const [password, setPassword] = useState("")
  const [showPass, setShowPass] = useState(false)
  const { login, isLoading, error } = useAuthStore()
  const navigate = useNavigate()

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
    <main className="page-enter flex min-h-screen flex-col bg-background">
      <div className="absolute right-4 top-4 z-10">
        <ThemeToggle />
      </div>
      <div className="flex-1 flex items-center justify-center p-6">
        <div className="flex flex-col lg:flex-row items-start gap-8 lg:gap-14">
          {/* Left — Brand column */}
          <div className="border-l-4 border-l-primary pl-4 shrink-0">
            <img src="/app-icon.png" alt="ZANECO QuickPass" className="h-12 w-12 mb-3" />
            <p className="text-lg font-bold font-display text-foreground leading-tight">
              ZANECO<br />QuickPass
            </p>
            <div className="h-[3px] w-6 rounded-full bg-primary/40 mt-3" />
            <p className="text-[10px] font-semibold uppercase tracking-[0.12em] text-muted-foreground/50 mt-2">
              Gate Access
            </p>
          </div>

          {/* Right — Form panel */}
          <div className="panel-card w-72">
            <div className="panel-card-body space-y-4">
              <div>
                <p className="text-base font-bold text-foreground tracking-tight">Sign in</p>
                <p className="text-xs text-muted-foreground mt-0.5">Use your employee ID and password</p>
              </div>

              <form onSubmit={handleSubmit} className="space-y-3">
                <div className="space-y-1">
                  <label className="label-stitch">Employee ID</label>
                  <input
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
                    <label className="label-stitch">Password</label>
                    <a className="text-[9px] font-semibold uppercase tracking-[0.08em] text-muted-foreground/60 hover:text-primary transition-colors" href="#">Forgot?</a>
                  </div>
                  <div className="relative">
                    <input
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
                  className="btn-primary w-full h-10 text-[11px]"
                >
                  {isLoading ? <Loader2 className="h-4 w-4 animate-spin mx-auto" /> : "Sign in"}
                </button>
              </form>
            </div>
            <div className="panel-card-footer flex items-center justify-between">
              <span>v1.0</span>
              <a href="#" className="hover:text-primary transition-colors">Need help? Contact IT</a>
            </div>
          </div>
        </div>
      </div>

      <div className="flex items-center justify-between px-8 pb-4">
        <span className="text-[10px] text-muted-foreground/20">&copy; 2026 ZANECO QuickPass</span>
        <span className="text-[10px] text-muted-foreground/20">v1.0</span>
      </div>
    </main>
  )
}
