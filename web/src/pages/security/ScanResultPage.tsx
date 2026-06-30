import { useEffect } from "react"
import { useNavigate, Link } from "react-router"
import { useScanStore } from "@/stores/scanStore"
import { useAuthStore } from "@/stores/authStore"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { CheckCircle, XCircle, Loader2, Scan, QrCode, LogOut, History } from "lucide-react"

export default function ScanResultPage() {
  const navigate = useNavigate()
  const { lastResult, isLoading, error, clearResult } = useScanStore()
  const { user, logout } = useAuthStore()

  useEffect(() => {
    if (!lastResult && !isLoading) {
      navigate("/security/scan", { replace: true })
    }
    return () => clearResult()
  }, [])

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="h-12 w-12 animate-spin text-emerald-400" />
          <p className="text-lg font-medium text-white/70">Validating QR code...</p>
        </div>
      </div>
    )
  }

  if (!lastResult) return null

  const isSuccess = lastResult.success
  const data = lastResult.data
  const isOut = data?.type === "OUT"

  return (
    <div className="flex min-h-screen flex-col bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      {/* Top bar */}
      <header className="flex items-center justify-between border-b border-white/10 px-6 py-4">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-white/10">
            <QrCode className="h-5 w-5 text-white" />
          </div>
          <span className="text-lg font-bold text-white">
            Pass<span className="text-emerald-400">Lynx</span>
            <span className="ml-2 rounded bg-emerald-500/20 px-2 py-0.5 text-xs font-medium text-emerald-400">
              Scanner
            </span>
          </span>
        </div>
        <div className="flex items-center gap-3">
          {user && (
            <span className="hidden text-sm text-white/60 sm:block">
              {user.full_name}
            </span>
          )}
          <Link to="/security/history">
            <Button variant="ghost" size="sm" className="text-white/60 hover:text-white">
              <History className="h-4 w-4" />
            </Button>
          </Link>
          <Button variant="ghost" size="sm" onClick={logout} className="text-white/60 hover:text-white">
            <LogOut className="h-4 w-4" />
          </Button>
        </div>
      </header>

      <main className="flex flex-1 items-center justify-center p-4">
        <div className="w-full max-w-md space-y-6">
          {isSuccess ? (
            <div className="flex flex-col items-center gap-6">
              <div className="flex h-24 w-24 items-center justify-center rounded-full bg-emerald-500/20">
                <CheckCircle className="h-14 w-14 text-emerald-400" />
              </div>
              <div className="text-center">
                <h2 className="text-2xl font-bold text-white">
                  {isOut ? "Exit Recorded" : "Entry Recorded"}
                </h2>
                <span className="mt-2 inline-block rounded-full bg-emerald-500/20 px-4 py-1 text-sm font-bold tracking-wider text-emerald-400">
                  {isOut ? "OUT SCAN" : "IN SCAN"}
                </span>
              </div>

              {data && (
                <Card className="w-full border-white/10 bg-white/5 backdrop-blur">
                  <CardContent className="space-y-3 p-4 text-sm">
                    <div className="flex justify-between">
                      <span className="text-white/40">Employee</span>
                      <span className="font-medium text-white">{data.employee_name}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-white/40">ID</span>
                      <span className="font-medium text-white">{data.employee_id}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-white/40">Schedule</span>
                      <span className="font-medium text-white">{data.start_time} - {data.end_time}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-white/40">Status</span>
                      <span className="font-medium capitalize text-white">{data.new_status}</span>
                    </div>
                  </CardContent>
                </Card>
              )}
            </div>
          ) : (
            <div className="flex flex-col items-center gap-6">
              <div className="flex h-24 w-24 items-center justify-center rounded-full bg-red-500/20">
                <XCircle className="h-14 w-14 text-red-400" />
              </div>
              <div className="text-center">
                <h2 className="text-2xl font-bold text-white">Invalid QR Code</h2>
              </div>

              {error && (
                <Card className="w-full border-red-400/20 bg-red-500/10">
                  <CardContent className="p-4 text-center text-sm text-red-400">
                    {error}
                  </CardContent>
                </Card>
              )}
            </div>
          )}

          <Button
            className="w-full gap-2 bg-emerald-600 hover:bg-emerald-700"
            size="lg"
            onClick={() => navigate("/security/scan")}
          >
            <Scan className="h-5 w-5" /> Scan Next
          </Button>
        </div>
      </main>
    </div>
  )
}
