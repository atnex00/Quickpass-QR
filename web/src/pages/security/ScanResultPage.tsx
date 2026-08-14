import { useEffect, useState, useRef } from "react"
import { useNavigate, Link } from "react-router"
import { useScanStore } from "@/stores/scanStore"
import { useAuthStore } from "@/stores/authStore"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { CheckCircle, XCircle, Loader2, Scan, LogOut, History } from "lucide-react"

const AUTO_REDIRECT_SECONDS = 2

export default function ScanResultPage() {
  const navigate = useNavigate()
  const { lastResult, isLoading, error, clearResult } = useScanStore()
  const { user, logout } = useAuthStore()
  const [countdown, setCountdown] = useState(AUTO_REDIRECT_SECONDS)
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const redirectRef = useRef(false)

  useEffect(() => {
    if (!lastResult && !isLoading) {
      navigate("/security/scan", { replace: true })
      return
    }

    if (redirectRef.current) return
    redirectRef.current = true

    const tick = () => {
      setCountdown((prev) => {
        const next = prev - 1
        if (next <= 0) {
          navigate("/security/scan")
          return 0
        }
        timerRef.current = setTimeout(tick, 1000)
        return next
      })
    }
    timerRef.current = setTimeout(tick, 1000)

    return () => {
      clearResult()
      if (timerRef.current) clearTimeout(timerRef.current)
    }
  }, [])

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="h-12 w-12 animate-spin text-primary" />
          <p className="text-lg font-medium text-muted-foreground">Validating QR code...</p>
        </div>
      </div>
    )
  }

  if (!lastResult) return null

  const isSuccess = lastResult.success
  const data = lastResult.data
  const isOut = data?.type === "OUT"

  return (
    <div className="flex min-h-screen flex-col bg-background">
      {/* Top bar */}
      <header className="flex items-center justify-between border-b border-border px-6 py-4">
        <div className="flex items-center gap-3">
          <img src="/logo.png" alt="ZANECO QuickPass" className="h-8 w-auto" />
          <span className="rounded border border-primary/30 px-2 py-0.5 text-[10px] font-black uppercase tracking-[0.08em] text-primary">
            Scanner
          </span>
        </div>
        <div className="flex items-center gap-3">
          {user && (
            <span className="hidden text-sm text-muted-foreground sm:block">
              {user.full_name}
            </span>
          )}
          <Link to="/security/history">
            <Button variant="ghost" size="sm" aria-label="Scan history" className="text-muted-foreground hover:text-foreground">
              <History className="h-4 w-4" />
            </Button>
          </Link>
          <Button variant="ghost" size="sm" aria-label="Logout" onClick={logout} className="text-muted-foreground hover:text-foreground">
            <LogOut className="h-4 w-4" />
          </Button>
        </div>
      </header>

      <main className="flex flex-1 items-center justify-center p-4">
        <div className="w-full max-w-md space-y-4">
          {isSuccess ? (
            <div className="flex flex-col items-center gap-6">
              <div className="flex h-24 w-24 items-center justify-center rounded-full bg-success/20">
                <CheckCircle className="h-14 w-14 text-success" />
              </div>
              <div className="text-center">
                <h2 className="text-2xl font-bold text-foreground font-display">
                  {isOut ? "Exit Recorded" : "Entry Recorded"}
                </h2>
                <span className="mt-2 inline-block rounded-full border border-success/40 px-4 py-1 text-sm font-bold tracking-wider text-success">
                  {isOut ? "OUT" : "IN"}
                </span>
              </div>

              {data && (
                <Card className="w-full border-border bg-card">
                  <CardContent className="space-y-3 p-4 text-sm">
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Employee</span>
                      <span className="font-medium text-foreground">{data.employee_name}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">ID</span>
                      <span className="font-medium text-foreground">{data.employee_id}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Schedule</span>
                      <span className="font-medium text-foreground">{data.start_time} - {data.end_time}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Status</span>
                      <span className="font-medium capitalize text-foreground">{data.new_status}</span>
                    </div>
                  </CardContent>
                </Card>
              )}
            </div>
          ) : (
            <div className="flex flex-col items-center gap-6">
              <div className="flex h-24 w-24 items-center justify-center rounded-full bg-destructive/20">
                <XCircle className="h-14 w-14 text-destructive" />
              </div>
              <div className="text-center">
                <h2 className="text-2xl font-bold text-foreground font-display">Invalid QR Code</h2>
              </div>

              {error && (
                <Card className="w-full border-destructive/30 bg-destructive/10">
                  <CardContent className="p-4 text-center text-sm text-destructive">
                    {error}
                  </CardContent>
                </Card>
              )}
            </div>
          )}

          <Button
            className="w-full gap-2 bg-success text-success-foreground hover:bg-success/90 hover:shadow-[0_0_12px_rgba(13,148,136,0.3)]"
            size="lg"
            onClick={() => {
              if (timerRef.current) clearTimeout(timerRef.current)
              navigate("/security/scan")
            }}
          >
            <Scan className="h-5 w-5" /> Scan Next {countdown > 0 && <span className="tabular-nums opacity-70">({countdown}s)</span>}
          </Button>
        </div>
      </main>
    </div>
  )
}
