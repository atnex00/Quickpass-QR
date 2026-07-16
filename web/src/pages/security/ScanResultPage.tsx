import { useEffect, useState, useRef } from "react"
import { useNavigate } from "react-router"
import SecurityHeader from "@/components/layout/SecurityHeader"
import { useScanStore } from "@/stores/scanStore"
import { useAuthStore } from "@/stores/authStore"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { CheckCircle, XCircle, Loader2, Scan } from "lucide-react"

const AUTO_REDIRECT_SECONDS = 2

export default function ScanResultPage() {
  const navigate = useNavigate()
  const { lastResult, isLoading, error, clearResult } = useScanStore()
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
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
          <p className="text-sm font-medium text-muted-foreground">Validating QR code...</p>
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
      <main className="flex flex-1 items-center justify-center p-4">
        <div className="w-full max-w-md space-y-4">
          {isSuccess ? (
            <div className="flex flex-col items-center gap-6">
              <div className="flex h-24 w-24 items-center justify-center rounded-full bg-success/20">
                <CheckCircle className="h-14 w-14 text-success" />
              </div>
              <div className="text-center">
                <h2 className="text-2xl font-bold text-foreground">
                  {isOut ? "Exit Recorded" : "Entry Recorded"}
                </h2>
                <span className="mt-2 inline-block rounded-full border border-success/40 bg-success/5 px-4 py-1 text-sm font-semibold text-success">
                  {isOut ? "OUT" : "IN"}
                </span>
              </div>

              {data && (
                <Card>
                  <CardContent className="space-y-3 text-sm">
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
                <h2 className="text-2xl font-bold text-foreground">Invalid QR Code</h2>
              </div>

              {error && (
                <Card className="border-destructive/30 bg-destructive/5">
                  <CardContent className="text-center text-sm text-destructive">
                    {error}
                  </CardContent>
                </Card>
              )}
            </div>
          )}

          <Button
            variant="success"
            className="w-full gap-2"
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
