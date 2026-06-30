import { useState } from "react"
import { useNavigate } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { Loader2, Eye, EyeOff, Shield } from "lucide-react"

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
    <main className="page-enter flex min-h-screen bg-[#f8f7fc]">
      {/* Left — Brand panel */}
      <div className="hidden lg:flex w-[45%] relative flex-col justify-between bg-[#1a1a2e] p-12 overflow-hidden">
        <div className="absolute inset-0 opacity-[0.04] bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMjAgMjBIMFYwaDQwdjQwSDIwIDB6IiBmaWxsPSJub25lIiBzdHJva2U9IiNmZmYiIHN0cm9rZS13aWR0aD0iMC41Ii8+PC9zdmc+')]" />
        <div className="absolute top-1/3 -right-20 w-80 h-80 rounded-full bg-[#2563eb]/10 blur-3xl" />
        <div className="absolute bottom-1/4 -left-20 w-64 h-64 rounded-full bg-[#1e40af]/10 blur-3xl" />

        <div className="relative z-10">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-white/10">
              <Shield className="h-5 w-5 text-white" />
            </div>
            <span className="text-lg font-semibold tracking-tight text-white">Quickpass</span>
          </div>
        </div>

        <div className="relative z-10 space-y-6 max-w-md">
          <div className="space-y-2">
            <div className="h-1 w-12 rounded-full bg-blue-400/60" />
            <h2 className="text-[40px] leading-[1.15] font-medium text-white tracking-tight">
              Gate Pass<br />Access Control
            </h2>
          </div>
          <p className="text-[15px] leading-relaxed text-white/50">
            Manage employees' temporary leave and re-entry while on same day duty.
          </p>
        </div>

        <div className="relative z-10 flex items-center gap-4 text-xs text-white/20">
          <span>&copy; 2026 Quickpass</span>
          <span className="w-1 h-1 rounded-full bg-white/20" />
          <span>v1.0</span>
        </div>
      </div>

      {/* Right — Login form */}
      <div className="flex flex-1 items-center justify-center p-6">
        <div className="w-full max-w-sm">
          <div className="text-center mb-10">
            <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-[#1a1a2e]">
              <Shield className="h-6 w-6 text-white" />
            </div>
            <h1 className="text-2xl font-semibold text-[#1a1a2e] tracking-tight">Sign in</h1>
            <p className="mt-1.5 text-sm text-[#8a8a9e]">Use your employee ID and password</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            <div className="space-y-1.5">
              <label className="text-xs font-medium text-[#5a5a6e] tracking-wide">Employee ID</label>
              <input
                className="w-full h-11 rounded-lg border border-[#e0dfe8] bg-white px-4 text-sm text-[#1a1a2e] outline-none transition-colors placeholder:text-[#b0afc0] focus:border-[#1a1a2e] focus:ring-2 focus:ring-[#1a1a2e]/5"
                placeholder="000001"
                maxLength={6}
                value={employeeId}
                onChange={(e) => setEmployeeId(e.target.value.replace(/\D/g, "").slice(0, 6))}
                required
              />
            </div>

            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <label className="text-xs font-medium text-[#5a5a6e] tracking-wide">Password</label>
                <a className="text-xs text-[#8a8a9e] hover:text-[#1a1a2e] transition-colors" href="#">Forgot?</a>
              </div>
              <div className="relative">
                <input
                  className="w-full h-11 rounded-lg border border-[#e0dfe8] bg-white px-4 pr-10 text-sm text-[#1a1a2e] outline-none transition-colors placeholder:text-[#b0afc0] focus:border-[#1a1a2e] focus:ring-2 focus:ring-[#1a1a2e]/5"
                  type={showPass ? "text" : "password"}
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
                <button type="button" onClick={() => setShowPass(!showPass)} className="absolute right-3 top-1/2 -translate-y-1/2 text-[#b0afc0] hover:text-[#5a5a6e] transition-colors">
                  {showPass ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            {error && (
              <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3">
                <p className="text-xs font-medium text-red-600">{error}</p>
              </div>
            )}

            <button
              type="submit"
              disabled={isLoading}
              className="w-full h-11 rounded-lg bg-[#1a1a2e] text-sm font-medium text-white transition-all hover:bg-[#2a2a3e] active:scale-[0.98] disabled:opacity-50"
            >
              {isLoading ? <Loader2 className="h-4 w-4 animate-spin mx-auto" /> : "Sign in"}
            </button>
          </form>

          <p className="mt-8 text-center text-xs text-[#b0afc0]">
            Need help?{" "}
            <a href="#" className="font-medium text-[#5a5a6e] hover:text-[#1a1a2e] transition-colors">
              Contact IT Support
            </a>
          </p>
        </div>
      </div>
    </main>
  )
}
