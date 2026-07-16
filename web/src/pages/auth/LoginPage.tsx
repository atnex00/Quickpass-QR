import { useState } from "react"
import { useNavigate } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { Card, CardContent, CardFooter } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Button } from "@/components/ui/button"
import { Loader2, Eye, EyeOff } from "lucide-react"

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
      <div className="flex-1 flex items-center justify-center p-6">
        <div className="flex flex-col lg:flex-row items-start gap-8 lg:gap-14">
          {/* Left — Brand column */}
          <div className="border-l-4 border-l-gold pl-4 shrink-0">
            <img src="/app-icon.png" alt="ZANECO QuickPass" className="h-12 w-12 rounded-lg mb-3" />
            <p className="text-lg font-bold text-foreground leading-tight">
              ZANECO<br />QuickPass
            </p>
            <p className="text-xs font-medium text-muted-foreground mt-2">
              Gate Access Management
            </p>
          </div>

          {/* Right — Form panel */}
          <Card className="w-72">
            <CardContent className="space-y-4 pt-6">
              <div>
                <p className="text-base font-semibold text-foreground">Sign in</p>
                <p className="text-sm text-muted-foreground mt-0.5">Use your employee ID and password</p>
              </div>

              <form onSubmit={handleSubmit} className="space-y-3">
                <div className="space-y-1.5">
                  <Label>Employee ID</Label>
                  <Input
                    placeholder="000001"
                    maxLength={6}
                    value={employeeId}
                    onChange={(e) => setEmployeeId(e.target.value.replace(/\D/g, "").slice(0, 6))}
                    required
                  />
                </div>

                <div className="space-y-1.5">
                  <div className="flex items-center justify-between">
                    <Label>Password</Label>
                    <a className="text-xs text-muted-foreground hover:text-primary transition-colors" href="#">Forgot?</a>
                  </div>
                  <div className="relative">
                    <Input
                      type={showPass ? "text" : "password"}
                      placeholder="Enter your password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                    />
                    <button type="button" onClick={() => setShowPass(!showPass)} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors">
                      {showPass ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                </div>

                {error && (
                  <div className="rounded-md border border-destructive/30 bg-destructive/5 px-3 py-2">
                    <p className="text-sm text-destructive">{error}</p>
                  </div>
                )}

                <Button type="submit" className="w-full" disabled={isLoading}>
                  {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : "Sign in"}
                </Button>
              </form>
            </CardContent>
            <CardFooter className="flex items-center justify-between text-xs text-muted-foreground">
              <span>v1.0</span>
              <a href="#" className="hover:text-primary transition-colors">Need help? Contact IT</a>
            </CardFooter>
          </Card>
        </div>
      </div>

      <div className="flex items-center justify-between px-8 pb-4">
        <span className="text-xs text-muted-foreground">&copy; 2026 ZANECO QuickPass</span>
        <span className="text-xs text-muted-foreground">v1.0</span>
      </div>
    </main>
  )
}
